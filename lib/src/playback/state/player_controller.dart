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
import 'listen_recorder.dart';
import 'position_saver.dart';
import 'replay_stream.dart';
import 'session_restore.dart';

part 'player_controller_events.dart';
part 'player_controller_reconcile.dart';
part 'player_controller_session.dart';

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
    required this._listens,
    int Function()? clock,
    Random? random,
    this._keys = const KeyGen(),
    this._undoWindow = const Duration(seconds: 4),
    this._focusTimeout = const Duration(seconds: 2),
  }) : _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch),
       _random = random ?? Random(),
       _homeZone = Zone.current,
       _saver = PositionSaver(_settings) {
    _chain = SerialChain(onDrain: _reconcileIfDirty);
    // The saved session comes back as the first task: commands made while it
    // runs apply to the restored state.
    unawaited(
      _chain
          .run(_restore)
          .then<void>(
            (_) {},
            onError: (Object e, StackTrace st) {
              _log.warning('restore failed: $e', e, st);
              restoring = false;
            },
          ),
    );
  }

  final QueueRepository _repo;
  final PlayableResolver _resolver;
  final SettingsStore _settings;
  final AudioEngine Function() _engineFactory;
  final PlaybackFocus _focus;
  final TrackTitleLookup _titles;
  final ListenRecorder _listens;
  final PositionSaver _saver;
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

  /// Where the last seek was sent, the file it was sent to and when the
  /// guard against older position ticks ends. Until the engine reports a
  /// tick near the target (or the deadline passes) a tick far from it is a
  /// leftover from before the seek and is dropped; the deadline keeps a seek
  /// that never lands from freezing the position.
  Duration? _seekTarget;
  EngineToken? _seekFile;
  int _seekDeadlineMs = 0;
  static const _seekGuard = Duration(seconds: 3);
  static const _seekLanded = Duration(seconds: 1);

  /// Where the next load starts. Commands set it; the live [_position] never
  /// feeds a load, so a tick of the old file cannot leak into the new one.
  Duration _startAt = Duration.zero;
  Duration? _duration;
  int _volume = 100;

  /// The level a mute (volume 0) came from; null while not muted.
  int? _volumeBeforeMute;
  bool _atEnd = false;

  /// Extra plays of the current entry still to come under a counted repeat;
  /// 0 = none. The base mode stays in `_queue.repeat` and takes over when the
  /// count runs out. Any change of the current entry ends the count.
  int _repeatTimes = 0;

  /// A restored session is held: nothing about position, current entry or
  /// context is written, and an unplayable current is not skipped. Lifted
  /// when the restored file loads or the user starts something.
  bool get restoring => _saver.frozen;
  set restoring(bool value) => _saver.frozen = value;

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
  List<int> _savedRun = const [];

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
  final _transport = ReplayStream<TransportView>(const TransportView());
  final _seekCtrl = StreamController<Duration>.broadcast();
  final _noticeCtrl = StreamController<PlaybackNotice>.broadcast();

  /// What is loaded, with the latest value for a late listener.
  Stream<NowPlaying> get nowPlaying => _now.stream;
  Stream<QueueView> get queueView => _view.stream;
  Stream<PlaybackPosition> get position => _pos.stream;
  Stream<PlaybackNotice> get notices => _noticeCtrl.stream;

  /// Play, pause or stop, and the volume.
  Stream<TransportView> get transport => _transport.stream;

  /// The position after each explicit seek (a seek command, or Previous at
  /// the first entry), not the ticks of normal playback.
  Stream<Duration> get seeks => _seekCtrl.stream;
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

  /// Writes the session (position, current entry, context) and the open
  /// listen, for the exit and background flushes. It reads the saver's last
  /// snapshot and the recorder's own queue, never the command chain, so a
  /// command stuck on the engine cannot hold it up. Does not flush the
  /// settings store itself.
  Future<void> flushPlayback({bool listens = true}) async {
    final saved = _saver.snapshot();
    if (saved != null) {
      for (final (key, value) in [
        (positionMsSetting.key, saved.position.inMilliseconds),
        (currentEntrySetting.key, saved.entryId),
        (contextSetting.key, contextSetting.encode(saved.context)),
      ]) {
        try {
          await _settings.write(key, value);
        } on Object catch (e) {
          _log.warning('could not save $key on flush: $e');
        }
      }
    }
    if (listens) await _listens.flush();
  }

  /// Writes the open listen and waits for the recorder's own queue.
  Future<void> flushListens() => _listens.flush();

  int _nowMs() => _clock();

  void _notice(PlaybackNotice n) {
    if (!_noticeCtrl.isClosed) _noticeCtrl.add(n);
  }

  void _publish() {
    // Playback stopped or ran out: a count has nothing left to loop.
    if (_stoppedOrEnded) _dropRepeatTimes();
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
        repeatTimes: _repeatTimes,
        stopped: _stoppedOrEnded,
      ),
    );
    _pos.add(
      PlaybackPosition(
        entryId: cur?.entryId,
        position: _position,
        duration: _loadedOk ? _duration : null,
      ),
    );
    _transport.add(TransportView(intent: _intent, volume: _volume));
    _saver.observe(
      entryId: cur?.entryId,
      context: _context,
      position: _position,
      playing: _intent == PlayIntent.playing && _enginePlaying,
    );
    _observeListen();
    _persistCurrent();
    _persistRun();
  }

  void _persistCurrent() {
    if (restoring) return;
    final id = _queue.currentItem?.entryId;
    if (id == _savedCurrent) return;
    _savedCurrent = id;
    _write(currentEntrySetting.key, id);
  }

  /// The play-next run, written when it changes, so a "play next" after a
  /// restart still goes behind it.
  void _persistRun() {
    if (restoring) return;
    final ids = _queue.playNextRunIds.toList();
    if (_sameIds(ids, _savedRun)) return;
    _savedRun = ids;
    _write(playNextRunSetting.key, playNextRunSetting.encode(ids));
  }

  static bool _sameIds(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
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
    // Opening a queue keeps the user's shuffle mode: with shuffle already on
    // the new queue is shuffled too, and `shuffle: true` turns it on.
    final shuffled = shuffle || _queue.shuffled;
    List<int>? order;
    if (shuffled) {
      final rest = [
        for (var i = 0; i < tracks.length; i++)
          if (i != startIndex) i,
      ]..shuffle(_random);
      order = [startIndex, ...rest];
    }
    final items = await _repo.replace(tracks, _nowMs(), shuffleOrder: order);
    _queue = QueueState(
      items: items,
      current: shuffled ? 0 : startIndex,
      shuffled: shuffled,
      repeat: _queue.repeat,
    );
    _context = context;
    _intent = PlayIntent.playing;
    _undo = null;
    _resetPlayback();
    _thaw();
    _write(shuffleSetting.key, shuffled);
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
    _dropRepeatTimes();
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
    _startPlaying();
  });

  /// Play intent on. After the queue ran out, play starts it over from the
  /// first entry in play order.
  void _startPlaying() {
    if (_atEnd) {
      _jump(0);
    } else {
      _thaw();
      _failuresInRow = 0;
      _bad.clear();
    }
    _intent = PlayIntent.playing;
  }

  Future<void> pause() => _cmd(() async {
    if (_intent == PlayIntent.playing) {
      _intent = PlayIntent.paused;
      _saveNow();
    }
  });

  Future<void> playPause() => _cmd(() async {
    if (_intent == PlayIntent.playing) {
      _intent = PlayIntent.paused;
      _saveNow();
    } else if (_queue.items.isEmpty) {
      _notice(const QueueEmpty());
    } else {
      _startPlaying();
    }
  });

  /// A real state: the entry stays current, the engine is emptied and the
  /// position goes back to 0 (also the saved one), so Play starts the entry
  /// from the beginning.
  Future<void> stop() => _cmd(() async {
    _thaw();
    _intent = PlayIntent.stopped;
    _rewind();
    _saveNow();
  });

  Future<void> next() => _cmd(() async {
    if (_queue.items.isEmpty) return;
    final i = await _stepIndex(auto: false);
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
    _dropRepeatTimes();
    _queue = _queue.withCurrent(index, _queue.playNextRunIds);
    _rewind();
    _duration = null;
    _atEnd = false;
    _forceReload = true;
    if (user) _thaw();
    _saveNow();
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
    if (_loaded != null) {
      _thaw();
      _seekTarget = p;
      _seekFile = _loaded;
      _seekDeadlineMs = _nowMs() + _seekGuard.inMilliseconds;
      await _engine?.seek(p);
    }
    // The target, not whatever tick came in while the seek was in flight.
    _saver.save(p);
    if (!_seekCtrl.isClosed) _seekCtrl.add(p);
  }

  /// Sets the volume (0-100). Reaching 0 remembers the level it left, a
  /// later non-zero volume forgets it (see [toggleMute]).
  Future<void> setVolume(int volume) =>
      _cmd(() => _applyVolume(volume.clamp(0, 100)), reconcile: false);

  /// Mutes (volume 0), or returns to the level before the mute (100 when
  /// none is known).
  Future<void> toggleMute() => _cmd(
    () => _applyVolume(_volume == 0 ? (_volumeBeforeMute ?? 100) : 0),
    reconcile: false,
  );

  /// Volume steps from a scroll wheel. A muted player continues from the
  /// level before the mute, which also unmutes it.
  Future<void> changeVolumeBy(int delta) => _cmd(() {
    final base = _volume == 0 ? (_volumeBeforeMute ?? 0) : _volume;
    return _applyVolume((base + delta).clamp(0, 100));
  }, reconcile: false);

  Future<void> _applyVolume(int volume) async {
    if (volume == 0 && _volume > 0) {
      _volumeBeforeMute = _volume;
      _write(volumeBeforeMuteSetting.key, _volumeBeforeMute);
    } else if (volume > 0 && _volumeBeforeMute != null) {
      _volumeBeforeMute = null;
      _write(volumeBeforeMuteSetting.key, null);
    }
    _volume = volume;
    _write(volumeSetting.key, volume);
    await _engine?.setVolume(volume.toDouble());
  }

  /// Sets the base repeat mode. Also ends a counted repeat, even when the mode
  /// is the one already set.
  Future<void> setRepeat(RepeatMode mode) => _cmd(() async {
    if (_queue.repeat == mode && _repeatTimes == 0) return;
    _queue = _queue.copyWith(repeat: mode);
    _write(repeatSetting.key, repeatSetting.encode(mode));
    _dropRepeatTimes();
  });

  /// Plays the current entry [times] more times, then goes on in the repeat
  /// mode set now (1 to [maxRepeatTimes]; 0 ends the count). Under repeat one
  /// the base becomes off: looping forever would make the count meaningless.
  /// Does nothing without a queue, or while stopped or after the queue ran out.
  Future<void> setRepeatTimes(int times) => _cmd(() async {
    if (_stoppedOrEnded) return;
    final count = times.clamp(0, maxRepeatTimes);
    if (count == _repeatTimes) return;
    if (count == 0) {
      _dropRepeatTimes();
      return;
    }
    if (_queue.repeat == RepeatMode.one) {
      _queue = _queue.copyWith(repeat: RepeatMode.off);
      _write(repeatSetting.key, repeatSetting.encode(RepeatMode.off));
    }
    _repeatTimes = count;
    _write(repeatCountSetting.key, count);
  });

  /// Playback is stopped, or the queue is empty or ran out and waits for Play.
  bool get _stoppedOrEnded =>
      _queue.items.isEmpty || _intent == PlayIntent.stopped || _atEnd;

  /// Ends a counted repeat. Nothing happens when none runs.
  void _dropRepeatTimes() {
    if (_repeatTimes == 0) return;
    _repeatTimes = 0;
    _write(repeatCountSetting.key, 0);
  }

  /// The last entry of a pass under "repeat all, reshuffled", with no extra
  /// plays of it left (for an automatic advance): going on starts a new pass.
  bool _endsPass({required bool auto}) =>
      _queue.repeat == RepeatMode.allShuffled &&
      _queue.current != null &&
      _queue.current == _queue.length - 1 &&
      (!auto || _repeatTimes == 0);

  /// Starts a new pass: a fresh random order of the whole queue, shuffle on,
  /// the first entry current.
  Future<void> _newPass() async {
    await _applyEdit(reshufflePass(_queue, _random, _keys));
    _write(shuffleSetting.key, true);
  }

  /// The index to go on to. At the end of a reshuffled pass the new pass is
  /// made first and its first entry is returned.
  Future<int?> _stepIndex({required bool auto}) async {
    if (_endsPass(auto: auto)) {
      await _newPass();
      return 0;
    }
    return nextIndex(_queue, auto: auto, loops: _repeatTimes);
  }

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
      _thaw();
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
    _thaw();
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
    await _listens.close();
    await _now.close();
    await _view.close();
    await _pos.close();
    await _transport.close();
    await _seekCtrl.close();
    await _noticeCtrl.close();
  }
}
