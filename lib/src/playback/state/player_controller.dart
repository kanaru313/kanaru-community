import 'dart:async';
import 'dart:math';

import 'package:logging/logging.dart';

import '../../media/domain/play_context.dart';
import '../../media/domain/track_id.dart';
import '../../platform/domain/settings_store.dart';
import '../data/queue_repository.dart';
import '../domain/audio_engine.dart';
import '../domain/cleanup_kind.dart';
import '../domain/now_playing.dart';
import '../domain/play_intent.dart';
import '../domain/playable.dart';
import '../domain/playback_commands.dart';
import '../domain/playback_focus.dart';
import '../domain/track_title_lookup.dart';
import '../domain/playback_notice.dart';
import '../domain/playback_settings.dart';
import '../domain/playback_views.dart';
import '../domain/queue_logic.dart' hide remove, move, undo, enqueue;
import '../domain/queue_logic.dart' as q show remove, move, undo, enqueue;
import 'command_chain.dart';
import 'replay_stream.dart';

part 'player_controller_events.dart';
part 'player_controller_reconcile.dart';

final _log = Logger('PlayerController');

/// The player: one serial command chain that owns the queue, the play intent
/// and the engine. Every command updates memory (after the database accepted
/// it), then one reconcile per burst of commands makes the engine match.
///
/// Commands from the UI, media controls and engine events all go through the
/// same chain, in call order. A command's future completes after validation
/// and persistence, never after the engine has loaded anything.
class PlayerController implements PlaybackCommands {
  PlayerController({
    required this._repo,
    required this._resolver,
    required this._settings,
    required this._engineFactory,
    required this._focus,
    required this._titles,
    int Function()? clock,
    Random? random,
    this._keys = const KeyGen(),
    this._undoWindow = const Duration(seconds: 4),
    this._focusTimeout = const Duration(seconds: 2),
  }) : _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch),
       _random = random ?? Random(),
       _homeZone = Zone.current {
    _chain = SerialChain(onDrain: _reconcileIfDirty);
  }

  final QueueRepository _repo;
  final PlayableResolver _resolver;
  final SettingsStore _settings;
  final AudioEngine Function() _engineFactory;
  final PlaybackFocus _focus;
  final TrackTitleLookup _titles;
  final int Function() _clock;
  final Random _random;
  final KeyGen _keys;
  final Duration _undoWindow;
  final Duration _focusTimeout;
  final Zone _homeZone;
  late final SerialChain _chain;

  // Desired state.
  QueueState _queue = const QueueState();
  PlayIntent _intent = PlayIntent.paused;
  PlayContext? _context;
  Duration _position = Duration.zero;

  /// Where the next load starts. Commands set it; the live [_position] never
  /// feeds a load, so a tick of the old file cannot leak into the new one.
  Duration _startAt = Duration.zero;
  Duration? _duration;
  int _volume = 100;
  bool _atEnd = false;

  /// Persistence and skipping stay quiet while a restored session is held
  /// (set by the restore code).
  bool restoring = false;

  // What the engine has.
  AudioEngine? _engine;
  final _subs = <StreamSubscription<Object?>>[];
  int _generation = 0;
  int _handoff = 0;
  EngineToken? _loaded;
  EngineToken? _handedNext;
  bool _loadedOk = false;
  bool _enginePlaying = false;
  bool _forceReload = false;
  bool _dirty = false;
  bool _disposed = false;
  int _failuresInRow = 0;
  final Set<int> _bad = {};
  int? _savedCurrent;

  /// Entries skipped on the way to the handed-over next, announced when the
  /// engine really gets there.
  ({TrackId track, UnplayableReason reason, int count})? _handedSkip;

  // Undo.
  UndoToken? _undo;
  int _undoAt = 0;

  // Outputs.
  final _now = ReplayStream<NowPlaying>(NowPlaying.none);
  final _view = ReplayStream<QueueView>(const QueueView());
  final _pos = ReplayStream<PlaybackPosition>(PlaybackPosition.none);
  final _noticeCtrl = StreamController<PlaybackNotice>.broadcast();

  /// What is loaded, with the latest value for a late listener.
  Stream<NowPlaying> get nowPlaying => _now.stream;
  Stream<QueueView> get queueView => _view.stream;
  Stream<PlaybackPosition> get position => _pos.stream;
  Stream<PlaybackNotice> get notices => _noticeCtrl.stream;
  QueueState get queueState => _queue;
  PlayIntent get intent => _intent;
  PlayContext? get context => _context;

  Future<T> _cmd<T>(Future<T> Function() body, {bool reconcile = true}) =>
      _chain.run(() async {
        if (reconcile) _dirty = true;
        try {
          return await body();
        } finally {
          _publish();
        }
      });

  /// Completes when the queued commands and the reconcile after them are done.
  Future<void> settled() => _chain.whenIdle();

  int _nowMs() => _clock();

  void _notice(PlaybackNotice n) {
    if (!_noticeCtrl.isClosed) _noticeCtrl.add(n);
  }

  void _publish() {
    final cur = _queue.currentItem;
    _now.add(
      NowPlaying(
        entryId: cur?.entryId,
        trackId: cur?.trackId,
        playing: cur != null && _intent == PlayIntent.playing,
        index: _queue.current,
        length: _queue.length,
        context: cur == null ? null : _context,
      ),
    );
    _view.add(
      QueueView(
        items: _queue.items,
        current: _queue.current,
        shuffled: _queue.shuffled,
        repeat: _queue.repeat,
      ),
    );
    _pos.add(
      PlaybackPosition(
        entryId: cur?.entryId,
        position: _position,
        duration: _loadedOk ? _duration : null,
      ),
    );
    _persistCurrent();
  }

  void _persistCurrent() {
    if (restoring) return;
    final id = _queue.currentItem?.entryId;
    if (id == _savedCurrent) return;
    _savedCurrent = id;
    _write(currentEntrySetting.key, id);
  }

  void _write(String key, Object? value) {
    _settings.write(key, value).catchError((Object e) {
      _log.warning('could not save $key: $e');
    });
  }

  /// Writes [edit] to the database; memory changes only when that worked.
  Future<QueueEdit> _applyEdit(QueueEdit edit) async {
    final applied = await _repo.apply(edit, _nowMs());
    _queue = applied.next;
    return applied;
  }

  // ---- PlaybackCommands ----

  @override
  Future<void> playTracks(
    List<TrackId> tracks, {
    int startIndex = 0,
    bool shuffle = false,
    required PlayContext context,
  }) {
    if (tracks.isEmpty) {
      return Future.error(ArgumentError.value(tracks, 'tracks', 'is empty'));
    }
    if (startIndex < 0 || startIndex >= tracks.length) {
      return Future.error(RangeError.index(startIndex, tracks, 'startIndex'));
    }
    return _cmd(() => _replaceQueue(tracks, startIndex, shuffle, context));
  }

  Future<void> _replaceQueue(
    List<TrackId> tracks,
    int startIndex,
    bool shuffle,
    PlayContext context,
  ) async {
    List<int>? order;
    if (shuffle) {
      final rest = [
        for (var i = 0; i < tracks.length; i++)
          if (i != startIndex) i,
      ]..shuffle(_random);
      order = [startIndex, ...rest];
    }
    final items = await _repo.replace(tracks, _nowMs(), shuffleOrder: order);
    _queue = QueueState(
      items: items,
      current: shuffle ? 0 : startIndex,
      shuffled: shuffle,
      repeat: _queue.repeat,
    );
    _context = context;
    _intent = PlayIntent.playing;
    _undo = null;
    _resetPlayback();
    _write(shuffleSetting.key, shuffle);
    _write(contextSetting.key, contextSetting.encode(context));
    _write(positionMsSetting.key, 0);
  }

  /// The next load starts at 0 and ticks of the old file are ignored until
  /// the new one reports it opened.
  void _rewind() {
    _position = Duration.zero;
    _startAt = Duration.zero;
    _loadedOk = false;
  }

  /// A new current entry: forget position, failures and skipped marks.
  void _resetPlayback() {
    _rewind();
    _duration = null;
    _failuresInRow = 0;
    _bad.clear();
    _atEnd = false;
    _forceReload = true;
  }

  @override
  Future<void> playNext(List<TrackId> tracks) {
    if (tracks.isEmpty) return Future.value();
    return _cmd(() async {
      if (_queue.items.isEmpty) {
        return _replaceQueue(
          tracks,
          0,
          false,
          const PlayContext(PlayContextKind.queue),
        );
      }
      await _applyEdit(insertPlayNext(_queue, tracks, _keys));
    });
  }

  @override
  Future<void> enqueue(List<TrackId> tracks) {
    if (tracks.isEmpty) return Future.value();
    return _cmd(() async {
      if (_queue.items.isEmpty) {
        return _replaceQueue(
          tracks,
          0,
          false,
          const PlayContext(PlayContextKind.queue),
        );
      }
      await _applyEdit(q.enqueue(_queue, tracks, _keys));
    });
  }

  // ---- transport ----

  Future<void> play() => _cmd(() async {
    if (_queue.items.isEmpty) {
      _notice(const QueueEmpty());
      return;
    }
    _failuresInRow = 0;
    _bad.clear();
    if (_atEnd) {
      _rewind();
      _atEnd = false;
      _forceReload = true;
    }
    _intent = PlayIntent.playing;
  });

  Future<void> pause() => _cmd(() async {
    if (_intent == PlayIntent.playing) _intent = PlayIntent.paused;
  });

  Future<void> playPause() => _cmd(() async {
    if (_intent == PlayIntent.playing) {
      _intent = PlayIntent.paused;
    } else if (_queue.items.isEmpty) {
      _notice(const QueueEmpty());
    } else {
      _failuresInRow = 0;
      _bad.clear();
      if (_atEnd) {
        _rewind();
        _atEnd = false;
        _forceReload = true;
      }
      _intent = PlayIntent.playing;
    }
  });

  /// A real state: the entry stays current, the engine is emptied.
  Future<void> stop() => _cmd(() async {
    _intent = PlayIntent.stopped;
  });

  Future<void> next() => _cmd(() async {
    if (_queue.items.isEmpty) return;
    final i = nextIndex(_queue, auto: false);
    if (i == null) {
      _notice(const QueueEnd());
      return;
    }
    _jump(i);
  });

  /// Always the previous entry; at the first one, back to the start.
  Future<void> previous() => _cmd(() async {
    if (_queue.items.isEmpty) return;
    final i = previousIndex(_queue);
    if (i == null) {
      _notice(const FirstTrack());
      await _seekTo(Duration.zero);
      return;
    }
    _jump(i);
  });

  Future<void> playEntry(int entryId) => _cmd(() async {
    final i = _queue.indexOfEntry(entryId);
    if (i < 0) return;
    _jump(i);
    _intent = PlayIntent.playing;
  });

  /// Makes the entry at play-order [index] current (a user action).
  void _jump(int index, {bool user = true}) {
    _queue = _queue.withCurrent(index, _queue.playNextRunIds);
    _rewind();
    _duration = null;
    _atEnd = false;
    _forceReload = true;
    if (user) {
      _failuresInRow = 0;
      _bad.clear();
      if (_intent == PlayIntent.stopped) _intent = PlayIntent.playing;
    }
  }

  Future<void> seek(Duration position) =>
      _cmd(() => _seekTo(position), reconcile: false);

  Future<void> seekRelative(Duration delta) =>
      _cmd(() => _seekTo(_position + delta), reconcile: false);

  Future<void> _seekTo(Duration target) async {
    var p = target < Duration.zero ? Duration.zero : target;
    final d = _duration;
    if (d != null && p > d) p = d;
    _position = p;
    _startAt = p;
    _atEnd = false;
    if (_loaded != null) await _engine?.seek(p);
  }

  Future<void> setVolume(int volume) => _cmd(() async {
    _volume = volume.clamp(0, 100);
    _write(volumeSetting.key, _volume);
    await _engine?.setVolume(_volume.toDouble());
  }, reconcile: false);

  Future<void> setRepeat(RepeatMode mode) => _cmd(() async {
    _queue = _queue.copyWith(repeat: mode);
    _write(repeatSetting.key, repeatSetting.encode(mode));
  });

  Future<void> cycleRepeat() => _cmd(() async {
    final mode =
        RepeatMode.values[(_queue.repeat.index + 1) % RepeatMode.values.length];
    _queue = _queue.copyWith(repeat: mode);
    _write(repeatSetting.key, repeatSetting.encode(mode));
  });

  /// Shuffle on shuffles the entries after the current one; off restores the
  /// order the user built.
  Future<void> setShuffle(bool on) => _cmd(() async {
    if (on == _queue.shuffled) return;
    await _applyEdit(
      on ? shuffleUpcoming(_queue, _random, _keys) : unshuffle(_queue),
    );
    _write(shuffleSetting.key, on);
  });

  /// Shuffles the upcoming entries again (shuffle turns on if it was off).
  Future<void> reshuffleUpcoming() => _cmd(() async {
    await _applyEdit(shuffleUpcoming(_queue, _random, _keys));
    _write(shuffleSetting.key, true);
  });

  // ---- queue edits ----

  /// Removes entries; the result undoes it for a few seconds. Null when
  /// nothing matched.
  Future<UndoToken?> remove(Set<int> entryIds) => _cmd(() async {
    final currentId = _queue.currentItem?.entryId;
    final edit = q.remove(
      _queue,
      entryIds,
      positionMs: _position.inMilliseconds,
      playing: _intent == PlayIntent.playing,
    );
    if (edit.isNoop) return null;
    await _applyEdit(edit);
    if (currentId != null && entryIds.contains(currentId)) {
      _resetPlayback();
      if (_queue.current == null) _intent = PlayIntent.stopped;
    }
    return _remember(edit.undo);
  });

  Future<UndoToken?> cleanup(CleanupKind kind) => _cmd(() async {
    final ids = switch (kind) {
      CleanupKind.duplicates => duplicateEntryIds(_queue),
      CleanupKind.before => entriesBefore(_queue),
      CleanupKind.after => entriesAfter(_queue),
      CleanupKind.allButCurrent => allButCurrent(_queue),
    };
    if (ids.isEmpty) return null;
    // Cleanup never removes the current entry.
    final edit = q.remove(
      _queue,
      ids,
      positionMs: _position.inMilliseconds,
      playing: _intent == PlayIntent.playing,
    );
    await _applyEdit(edit);
    return _remember(edit.undo);
  });

  UndoToken? _remember(UndoToken? token) {
    _undo = token;
    _undoAt = _nowMs();
    return token;
  }

  /// Puts removed entries back; ignored after the undo window or when a newer
  /// removal replaced [token].
  Future<void> undo(UndoToken token) => _cmd(() async {
    if (!identical(token, _undo) ||
        _nowMs() - _undoAt > _undoWindow.inMilliseconds) {
      return;
    }
    final before = _queue.currentItem?.entryId;
    await _applyEdit(q.undo(_queue, token, _keys));
    _undo = null;
    final now = _queue.currentItem?.entryId;
    if (now != null && now != before && now != _loaded?.entryId) {
      _forceReload = true;
      if (now == token.previousCurrentEntryId) {
        _position = Duration(milliseconds: token.positionMs);
        _startAt = _position;
      }
      if (_intent == PlayIntent.stopped) {
        _intent = token.wasPlaying ? PlayIntent.playing : PlayIntent.paused;
      }
    }
  });

  Future<void> move(int entryId, int toIndex) => _cmd(() async {
    await _applyEdit(q.move(_queue, entryId, toIndex, _keys));
  });

  /// Stops the chain and the engine. Safe to call twice.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _chain.close();
    for (final s in _subs) {
      await s.cancel();
    }
    await _engine?.dispose();
    await _now.close();
    await _view.close();
    await _pos.close();
    await _noticeCtrl.close();
  }
}
