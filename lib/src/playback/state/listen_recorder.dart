import 'package:logging/logging.dart';

import '../../media/domain/play_context.dart';
import '../../media/domain/track_id.dart';
import '../data/play_log_writer.dart';
import '../domain/audio_engine.dart';
import '../domain/listen_accumulator.dart';
import 'command_chain.dart';

final _log = Logger('ListenRecorder');

/// What the player shows at one moment, for the recorder.
class ListenObservation {
  const ListenObservation({
    required this.token,
    required this.trackId,
    required this.context,
    required this.position,
    required this.length,
    required this.playing,
  });

  final EngineToken token;
  final TrackId trackId;
  final PlayContext? context;
  final Duration position;
  final Duration? length;
  final bool playing;
}

class _Listen {
  _Listen(this.observation, this.rule, this.ruleReadAt);

  ListenObservation observation;

  /// The rule this listen is judged by, and the clock of the last read.
  ListenRule rule;
  Duration ruleReadAt;
  final acc = ListenAccumulator();
  int? rowId;

  /// Listened ms at the last write that was queued (-1 = none yet), and at
  /// the last one that ran.
  int queuedMs = -1;
  int writtenMs = -1;
}

/// Records listens into `play_log`.
///
/// One accumulator per full [EngineToken] (entry, generation, handoff), so a
/// repeated entry is a new listen each time round and a gapless advance
/// attributes time to the right track. A row is inserted when the listen
/// qualifies and its `listened_ms` follows every [checkpoint] of listening,
/// on pause, on a load change and on [flush]. Writes go through the
/// recorder's own chain and are never awaited by the player's commands; a
/// failed write is logged.
///
/// The rule and the history switch are read from the settings, never held
/// past the next check: [rule] at most once a second while a listen is
/// open, [historyEnabled] when a row would be inserted. Switching history
/// off only stops new rows; a row already written keeps being updated.
class ListenRecorder {
  ListenRecorder({
    required this._writer,
    required this._deviceId,
    ListenRule Function()? rule,
    bool Function()? historyEnabled,
    int Function()? wallClock,
    Duration Function()? monotonic,
    this.checkpoint = const Duration(seconds: 10),
  }) : _rule = rule ?? (() => ListenRule.standard),
       _history = historyEnabled ?? (() => true),
       _wall = wallClock ?? (() => DateTime.now().millisecondsSinceEpoch),
       _mono = monotonic ?? _stopwatchClock();

  static Duration Function() _stopwatchClock() {
    final sw = Stopwatch()..start();
    return () => sw.elapsed;
  }

  final PlayLogWriter _writer;
  final String Function() _deviceId;
  final ListenRule Function() _rule;
  final bool Function() _history;
  final int Function() _wall;
  final Duration Function() _mono;
  final Duration checkpoint;
  final _chain = SerialChain();
  _Listen? _active;
  bool _closed = false;

  /// Follows the player. Null = nothing is loaded (ends the open listen).
  /// Cheap and synchronous; writes are queued.
  void observe(ListenObservation? o) {
    if (_closed) return;
    final active = _active;
    if (o == null) {
      if (active != null) _finish(active);
      return;
    }
    var current = active;
    if (current == null || current.observation.token != o.token) {
      if (current != null) _finish(current);
      final now = _mono();
      current = _active = _Listen(o, _rule(), now);
    }
    current.observation = o;
    final wasPlaying = current.acc.playing;
    current.acc
      ..lockLength(o.length)
      ..sample(
        position: o.position,
        clock: _mono(),
        playing: o.playing,
        wallMs: _wall(),
      );
    final acc = current.acc;
    final hasRow = current.queuedMs >= 0;
    if (!hasRow) {
      if (_wouldInsert(current, refresh: true)) _persist(current);
      return;
    }
    final due =
        acc.listened.inMilliseconds - current.queuedMs >=
        checkpoint.inMilliseconds;
    if (due || (wasPlaying && !o.playing)) _persist(current);
  }

  void _finish(_Listen listen) {
    _active = null;
    if (listen.queuedMs >= 0 || _wouldInsert(listen, refresh: true)) {
      _persist(listen);
    }
  }

  /// Whether a row has to be inserted for [listen] now: it qualifies under
  /// the current rule and history is on. [refresh] re-reads the rule when the
  /// last read is a second old or more; the clock is the recorder's own.
  bool _wouldInsert(_Listen listen, {required bool refresh}) {
    final now = _mono();
    if (refresh && now - listen.ruleReadAt >= const Duration(seconds: 1)) {
      listen.rule = _rule();
      listen.ruleReadAt = now;
    }
    return listen.acc.qualifiesUnder(listen.rule) && _history();
  }

  /// Queues the insert (first time) or the update of the listen's row with
  /// the value it has when the write runs.
  void _persist(_Listen listen) {
    listen.queuedMs = listen.acc.listened.inMilliseconds;
    _chain
        .run(() async {
          final ms = listen.acc.listened.inMilliseconds;
          final now = _wall();
          final id = listen.rowId;
          if (id == null) {
            final o = listen.observation;
            listen.rowId = await _writer.insertListen(
              trackId: o.trackId,
              playedAt: listen.acc.playedAt ?? now,
              listenedMs: ms,
              deviceId: _deviceId(),
              context: o.context,
              now: now,
            );
            listen.writtenMs = ms;
          } else if (ms != listen.writtenMs) {
            await _writer.updateListened(id, ms, now);
            listen.writtenMs = ms;
          }
        })
        .then<void>(
          (_) {},
          onError: (Object e) => _log.warning('could not save a listen: $e'),
        );
  }

  /// Writes the in-flight listen now and waits for the recorder's own queue.
  /// Never waits on the player's commands.
  Future<void> flush() async {
    final active = _active;
    if (active != null &&
        (active.queuedMs >= 0 || _wouldInsert(active, refresh: true))) {
      _persist(active);
    }
    await _chain.whenIdle();
  }

  /// Ends the open listen, writes it and refuses further observations.
  Future<void> close() async {
    final active = _active;
    if (active != null) _finish(active);
    _closed = true;
    await _chain.close();
  }
}
