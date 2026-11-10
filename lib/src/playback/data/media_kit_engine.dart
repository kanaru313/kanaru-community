import 'dart:async';

import 'package:logging/logging.dart';
import 'package:media_kit/media_kit.dart';

import '../domain/audio_engine.dart';
import 'leaked_start.dart';
import 'load_failure_guard.dart';
import 'mpv_options.dart';
import 'mpv_playlist_tracker.dart';

final _log = Logger('MediaKitEngine');

/// [AudioEngine] on media_kit (libmpv).
///
/// mpv's playlist is `[current, next]`. media_kit keeps `keep-open=yes`: at
/// the end of the last entry mpv pauses with `eof-reached` instead of going
/// idle, and media_kit's own completion handling relies on that, so it is
/// left alone. All bookkeeping is in [MpvPlaylistTracker]; this class reads
/// fresh values from mpv (never `player.state.playlist`, which lags) and does
/// the commands.
///
/// Resume uses `Media(uri, start:)`: media_kit applies it in its `on_load`
/// hook and resets mpv's `start` in `on_unload`, so setting the property
/// directly would be undone. An entry appended with a raw `loadfile` has no
/// media_kit counterpart; its lookup in `on_load` is out of range and
/// swallowed there, which is harmless because only `open` (which resets
/// media_kit's list) ever reloads an entry.
class MediaKitEngine implements AudioEngine, MpvProperties {
  MediaKitEngine({Player? player}) : _player = player ?? Player() {
    _native = _player.platform as NativePlayer;
  }

  final Player _player;
  late final NativePlayer _native;
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

  /// The resume offset of the last `load`. media_kit's `on_load` hook can
  /// apply it to the entry that follows (it picks the media by playlist
  /// index, which a trim can shift), so after the first advance the position
  /// is checked and put back to 0.
  Duration _resumeStart = Duration.zero;

  /// Counts user seeks, to tell a seek from a leaked offset.
  int _seeks = 0;
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
    for (final p in _observed) {
      await _native.observeProperty(p, (_) async => _poke());
    }
    _subs.add(
      _player.stream.playing.listen((p) {
        if (!_disposed && !_eof) _playing.add(p);
      }),
    );
  }();

  bool _eof = false;

  @override
  Future<void> set(String name, String value) =>
      _native.setProperty(name, value);

  @override
  Future<String> get(String name) => _native.getProperty(name);

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
      return await _native.getProperty(property);
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
      await _native.command(['playlist-next']);
      if (_wantPlay) await _unpause();
    }
    for (var i = _tracker.entriesToTrim(s); i > 0; i--) {
      await _native.command(['playlist-remove', '0']);
    }
    if (events.any((e) => e is EngineAdvanced)) {
      await _undoLeakedStart(_seeks);
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
        _resumeStart = start;
        _wantPlay = play;
        await _player.open(
          Media(
            Uri.file(current.path).toString(),
            start: start > Duration.zero ? start : null,
          ),
          play: false,
        );
        final id = await _idOfIndex(0);
        if (id == null) throw StateError('mpv has no entry after open');
        _tracker.startLoad(current.token, id);
        await _setNext(next);
        if (play) await _player.play();
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
      await _native.command([
        'loadfile',
        Uri.file(next.path).toString(),
        'append',
        '-1',
        // An appended entry has no media_kit counterpart, so the resume
        // offset of the entry before it would otherwise apply to it too.
        'start=0',
      ]);
      final count = int.tryParse(await _try('playlist-count') ?? '') ?? 0;
      s = await _snapshot();
      if (s.idle) {
        // mpv went idle while the append was in flight: drop it.
        if (count > 0) await _native.command(['playlist-clear']);
        _tracker.clearNext();
        _emit(_tracker.onSnapshot(s));
        return;
      }
      final newId = await _idOfIndex(count - 1);
      if (newId == null) {
        throw StateError('mpv has no id for the appended entry');
      }
      // Remove the previous next only after the new one is in (a playlist
      // never goes empty behind the playing entry).
      if (hadNext && s.playingPos + 1 < count - 1) {
        await _native.command(['playlist-remove', '${s.playingPos + 1}']);
      }
      _tracker.registerNext(next.token, newId);
      s = await _snapshot();
      if (_tracker.needsPlaylistNext(s)) {
        // The file ended before the append: step on, and unpause if asked.
        await _native.command(['playlist-next']);
        if (_wantPlay) await _unpause();
      }
    } else if (hadNext) {
      if (s.count > s.playingPos + 1) {
        await _native.command(['playlist-remove', '${s.playingPos + 1}']);
      }
      _tracker.clearNext();
    }
  }

  Future<void> _undoLeakedStart(int seeksAtAdvance) async {
    final leaked = _resumeStart;
    _resumeStart = Duration.zero;
    if (leaked <= Duration.zero) return;
    // The offset is applied while the file opens, so wait (briefly) until
    // mpv reports a position.
    for (var i = 0; i < 10 && !_disposed; i++) {
      final at = double.tryParse(await _try('time-pos') ?? '');
      if (at != null) {
        if (isLeakedStart(
          resumeStart: leaked,
          positionSeconds: at,
          seekedSinceAdvance: _seeks != seeksAtAdvance,
        )) {
          await _native.command(['seek', '0', 'absolute']);
        }
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  /// Unpauses mpv directly. After `playlist-next` at the end of a file,
  /// media_kit's `play()` would seek to the first playlist entry while its
  /// `completed` flag is still set, so it is not used here.
  Future<void> _unpause() => _native.setProperty('pause', 'no');

  void _emit(List<EngineEvent> events) {
    // A promotion seen here consumes the offset: a later advance is unrelated.
    if (events.any((e) => e is EngineAdvanced)) _resumeStart = Duration.zero;
    for (final e in events) {
      if (!_events.isClosed) _events.add(e);
    }
  }

  @override
  Future<void> play() => _run(() async {
    _wantPlay = true;
    if (_afterEnd) {
      await _unpause();
    } else {
      await _player.play();
    }
  });

  @override
  Future<void> pause() => _run(() async {
    _wantPlay = false;
    await _player.pause();
  });

  @override
  Future<void> stop() => _run(() async {
    _wantPlay = false;
    _tracker.reset();
    await _player.stop();
  });

  @override
  Future<void> seek(Duration position) => _run(() async {
    _seeks++;
    await _player.seek(position);
    _eof = false;
    if (!_events.isClosed) _events.add(EngineSeeked(position));
  });

  @override
  Future<void> setVolume(double volume0to100) =>
      _run(() => _player.setVolume(volume0to100.clamp(0, 100).toDouble()));

  @override
  Stream<EngineEvent> get events => _events.stream;

  @override
  Stream<Duration> get position => _player.stream.position;

  @override
  Stream<bool> get playing => _playing.stream;

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final p in _observed) {
      try {
        await _native.unobserveProperty(p);
      } on Object {
        // already gone
      }
    }
    for (final s in _subs) {
      await s.cancel();
    }
    await _chain;
    await _player.dispose();
    await _events.close();
    await _playing.close();
  }
}
