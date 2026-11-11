import 'dart:async';

import 'package:logging/logging.dart';
import 'package:media_kit/media_kit.dart';

import '../domain/audio_engine.dart';
import 'load_failure_guard.dart';
import 'mpv_append.dart';
import 'mpv_log_filter.dart';
import 'mpv_options.dart';
import 'mpv_playlist_tracker.dart';
import 'mpv_resume.dart';

final _log = Logger('MediaKitEngine');

class _PlayerMpvConsole implements MpvConsole {
  const _PlayerMpvConsole(this._native);
  final NativePlayer _native;

  @override
  Future<void> set(String name, String value) =>
      _native.setProperty(name, value);

  @override
  Future<String> get(String name) => _native.getProperty(name);

  @override
  Future<void> command(List<String> args) => _native.command(args);
}

/// [AudioEngine] on media_kit (libmpv).
///
/// mpv's playlist is `[current, next]`. media_kit keeps `keep-open=yes`: at
/// the end of the last entry mpv pauses with `eof-reached` instead of going
/// idle, and media_kit's own completion handling relies on that, so it is
/// left alone. All bookkeeping is in [MpvPlaylistTracker]; this class reads
/// fresh values from mpv (never `player.state.playlist`, which lags) and does
/// the commands.
///
/// Resume: the file opens paused without a start offset, then one seek moves
/// it (see [seekToResume]). An entry appended with a raw `loadfile` has no
/// media_kit counterpart; its lookup in `on_load` is out of range and
/// swallowed there, which is harmless because only `open` (which resets
/// media_kit's list) ever reloads an entry.
class MediaKitEngine implements AudioEngine, MpvConsole {
  MediaKitEngine({Player? player, MpvConsole? mpv})
    : _player = mpv != null
          ? null
          : (player ??
                Player(
                  configuration: const PlayerConfiguration(
                    logLevel: MPVLogLevel.warn,
                  ),
                )) {
    final p = _player;
    if (p != null) {
      final native = p.platform as NativePlayer;
      _native = native;
      _mpv = _PlayerMpvConsole(native);
      // A rejected mpv command does not throw: it only shows in mpv's log.
      // `stream.error` repeats part of this stream, so it is not listened to.
      _subs.add(p.stream.log.listen(_logMpv));
    } else {
      _native = null;
      _mpv = mpv!;
    }
  }

  final _logFilter = MpvLogFilter();

  void _logMpv(PlayerLog l) {
    final lines = _logFilter.accept(
      level: l.level,
      prefix: l.prefix,
      text: l.text,
      nowMs: DateTime.now().millisecondsSinceEpoch,
    );
    for (final line in lines) {
      _log.warning(line);
    }
  }

  final Player? _player;
  late final NativePlayer? _native;
  late final MpvConsole _mpv;
  final _tracker = MpvPlaylistTracker();
  final _events = StreamController<EngineEvent>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  final _subs = <StreamSubscription<Object?>>[];
  Future<void> _chain = Future.value();
  Future<void>? _started;
  bool _disposed = false;
  bool _wantPlay = false;

  /// The last file ended: media_kit's `completed` flag may still be set, so
  /// Play unpauses mpv directly (its own `play()` would seek to entry 0).
  bool _afterEnd = false;

  bool _polling = false;
  bool _pollAgain = false;

  static const _observed = [
    'playlist-playing-pos',
    'playlist-count',
    'duration',
    'idle-active',
    'eof-reached',
  ];

  Future<T?> _run<T>(Future<T> Function() task) {
    final c = Completer<T?>();
    _chain = _chain.then((_) async {
      if (_disposed) {
        c.complete(null);
        return;
      }
      try {
        c.complete(await task());
      } on Object catch (e, st) {
        _log.warning('engine command failed: $e', e, st);
        c.complete(null);
      }
    });
    return c.future;
  }

  Future<void> _start() => _started ??= () async {
    await applyMpvOptions(this);
    final native = _native;
    if (native != null) {
      for (final p in _observed) {
        await native.observeProperty(p, (_) async => _poke());
      }
    }
    final player = _player;
    if (player != null) {
      _subs.add(
        player.stream.playing.listen((p) {
          if (!_disposed && !_eof) _playing.add(p);
        }),
      );
    }
  }();

  bool _eof = false;

  @override
  Future<void> set(String name, String value) => _mpv.set(name, value);

  @override
  Future<String> get(String name) => _mpv.get(name);

  @override
  Future<void> command(List<String> args) => _mpv.command(args);

  /// Reads one mpv snapshot and processes any resulting transitions on the
  /// command chain. Used by property observers and direct engine tests.
  Future<void> poll() => _run(_pollLoop);

  /// A property changed: read a snapshot and act, once at a time. Bursts
  /// collapse into one more read.
  void _poke() {
    if (_disposed) return;
    if (_polling) {
      _pollAgain = true;
      return;
    }
    _polling = true;
    _run(_pollLoop).whenComplete(() => _polling = false);
  }

  Future<void> _pollLoop() async {
    do {
      _pollAgain = false;
      await _poll();
    } while (_pollAgain && !_disposed);
  }

  Future<String?> _try(String property) async {
    try {
      return await get(property);
    } on Object {
      return null; // unavailable while nothing is loaded
    }
  }

  Future<MpvSnapshot> _snapshot() async {
    final pos = int.tryParse(await _try('playlist-playing-pos') ?? '') ?? -1;
    final count = int.tryParse(await _try('playlist-count') ?? '') ?? 0;
    final idle = (await _try('idle-active')) == 'yes';
    final eof = (await _try('eof-reached')) == 'yes';
    final seconds = double.tryParse(await _try('duration') ?? '');
    final id = pos >= 0
        ? int.tryParse(await _try('playlist/$pos/id') ?? '')
        : null;
    _eof = eof;
    return MpvSnapshot(
      playingPos: pos,
      playingId: id,
      count: count,
      idle: idle,
      eofReached: eof,
      duration: seconds == null
          ? null
          : Duration(microseconds: (seconds * 1e6).round()),
    );
  }

  Future<void> _poll() async {
    final s = await _snapshot();
    final events = _tracker.onSnapshot(s);
    if (_tracker.needsPlaylistNext(s)) {
      await command(['playlist-next']);
      if (_wantPlay) await _unpause();
    }
    for (var i = _tracker.entriesToTrim(s); i > 0; i--) {
      await command(['playlist-remove', '0']);
    }
    for (final e in events) {
      if (e is EngineEnded) _afterEnd = true;
      if (!_events.isClosed) _events.add(e);
    }
  }

  Future<int?> _idOfIndex(int index) async =>
      int.tryParse(await _try('playlist/$index/id') ?? '');

  @override
  Future<void> load(
    EngineMedia current, {
    EngineMedia? next,
    required bool play,
    Duration start = Duration.zero,
  }) => _run(
    () => guardLoad(
      current: current,
      emit: (e) => _emit([e]),
      onFailed: _tracker.reset,
      body: () async {
        await _start();
        _tracker.reset();
        _afterEnd = false;
        _wantPlay = play;
        final uri = Uri.file(current.path).toString();
        if (_player case final p?) {
          await p.open(Media(uri), play: false);
        } else {
          await set('pause', 'yes');
          await command(['loadfile', uri, 'replace']);
        }
        final id = await _idOfIndex(0);
        if (id == null) throw StateError('mpv has no entry after open');
        _tracker.startLoad(current.token, id);
        await seekToResume(this, start, disposed: () => _disposed);
        await _setNext(next);
        if (play) {
          if (_player case final p?) {
            await p.play();
          } else {
            await _unpause();
          }
        }
        await _poll();
      },
    ),
  );

  @override
  Future<void> setNext(EngineMedia? next) => _run(() => _setNext(next));

  Future<void> _setNext(EngineMedia? next) async {
    // mpv may already have moved to the old next: promote first.
    var s = await _snapshot();
    _emit(_tracker.onSnapshot(s));
    final hadNext = _tracker.nextMpvId != null;
    if (next != null) {
      final appended = await appendEntry(
        this,
        Uri.file(next.path).toString(),
        currentId: _tracker.currentMpvId,
      );

      // mpv may have advanced to the old next while the append was in flight:
      // feed the fresh snapshot to the tracker so it promotes before any
      // next-state decision below.
      s = await _snapshot();
      _emit(_tracker.onSnapshot(s));

      if (s.idle) {
        // mpv went idle while the append was in flight: drop it.
        if (s.count > 0) await command(['playlist-clear']);
        _tracker.clearNext();
        return;
      }
      if (appended == null) {
        // Not appended (already logged): the current entry plays fine, so it
        // is not failed. No next is handed; at its end the controller loads
        // the following entry instead of a gapless advance. Whatever mpv
        // holds after the playing entry (a stale next, or an append that
        // landed but could not be verified) would advance untracked: remove it.
        await removeEntriesAfter(this, s.playingPos);
        _tracker.clearNext();
        return;
      }

      final count = appended.count;
      // Re-evaluated after promotion: false if mpv already moved onto the old
      // next (it is then the playing entry, not a stale one to remove).
      final staleNextRemains = _tracker.nextMpvId != null;
      // Remove the previous next only after the new one is in (a playlist
      // never goes empty behind the playing entry).
      if (staleNextRemains && s.playingPos + 1 < count - 1) {
        await command(['playlist-remove', '${s.playingPos + 1}']);
      }
      _tracker.registerNext(next.token, appended.id);
      s = await _snapshot();
      if (_tracker.needsPlaylistNext(s)) {
        // The file ended before the append: step on, and unpause if asked.
        await command(['playlist-next']);
        if (_wantPlay) await _unpause();
      }
    } else if (hadNext) {
      if (s.count > s.playingPos + 1) {
        await command(['playlist-remove', '${s.playingPos + 1}']);
      }
      _tracker.clearNext();
    }
  }

  /// Unpauses mpv directly. After `playlist-next` at the end of a file,
  /// media_kit's `play()` would seek to the first playlist entry while its
  /// `completed` flag is still set, so it is not used here.
  Future<void> _unpause() => set('pause', 'no');

  void _emit(List<EngineEvent> events) {
    for (final e in events) {
      if (!_events.isClosed) _events.add(e);
    }
  }

  @override
  Future<void> play() => _run(() async {
    _wantPlay = true;
    final p = _player;
    if (_afterEnd || p == null) {
      await _unpause();
    } else {
      await p.play();
    }
  });

  @override
  Future<void> pause() => _run(() async {
    _wantPlay = false;
    if (_player case final p?) {
      await p.pause();
    } else {
      await set('pause', 'yes');
    }
  });

  @override
  Future<void> stop() => _run(() async {
    _wantPlay = false;
    _tracker.reset();
    if (_player case final p?) {
      await p.stop();
    } else {
      await command(['stop']);
    }
  });

  @override
  Future<void> seek(Duration position) => _run(() async {
    if (_player case final p?) {
      await p.seek(position);
    } else {
      final s = (position.inMicroseconds / 1e6).toStringAsFixed(3);
      await command(['seek', s, 'absolute']);
    }
    _eof = false;
    if (!_events.isClosed) _events.add(EngineSeeked(position));
  });

  @override
  Future<void> setVolume(double volume0to100) => _run(() async {
    final v = volume0to100.clamp(0, 100).toDouble();
    if (_player case final p?) {
      await p.setVolume(v);
    } else {
      await set('volume', '$v');
    }
  });

  @override
  Stream<EngineEvent> get events => _events.stream;

  @override
  Stream<Duration> get position =>
      _player?.stream.position ?? const Stream.empty();

  @override
  Stream<bool> get playing => _playing.stream;

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final native = _native;
    if (native != null) {
      for (final p in _observed) {
        try {
          await native.unobserveProperty(p);
        } on Object {
          // already gone
        }
      }
    }
    for (final s in _subs) {
      await s.cancel();
    }
    await _chain;
    await _player?.dispose();
    await _events.close();
    await _playing.close();
  }
}
