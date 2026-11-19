part of 'player_controller.dart';

/// The stop policy and the track-end events. Runs inside the chain.
extension _SleepStop on PlayerController {
  /// Whether the installed policy stops after the current entry of [queue].
  /// A policy that throws counts as "stop": one stop too many is safer than
  /// one too few.
  bool _sleepStopNow(QueueState queue) {
    final policy = _policy;
    if (policy == null) return false;
    try {
      return policy.stopsAfterCurrent(queue, _repeatTimes);
    } catch (e, st) {
      _log.warning('sleep stop policy failed: ${e.runtimeType}', null, st);
      return true;
    }
  }

  /// Whether the entry [endedId], which the engine ended by itself, is the
  /// one the policy stops after. The decision made when the next was withheld
  /// counts, and so does the policy's answer now (the reconcile may not have
  /// run since it was installed). No policy: never.
  bool _sleepEndsNow(int? endedId) =>
      _policy != null &&
      ((endedId != null && _withheldFor == endedId) || _sleepStopNow(_queue));

  /// Bookkeeping of an entry that ended by itself: the policy is consumed by
  /// a stop and told about any other end; the event waits for the handler's
  /// publish. Failures are not natural ends.
  void _naturalEnd(
    int? entryId, {
    required bool sleep,
    required bool queueEnded,
  }) {
    final consumed = sleep ? _policy : null;
    if (sleep) {
      _policy = null;
      _withheldFor = null;
    } else if (_failuresInRow == 0) {
      try {
        _policy?.trackEnded();
      } catch (e, st) {
        _log.warning('sleep stop policy failed: ${e.runtimeType}', null, st);
      }
    }
    if (entryId == null || _failuresInRow > 0) return;
    _pendingEnds.add(
      TrackEnd(
        entryId: entryId,
        sleepStop: sleep,
        queueEnded: queueEnded,
        policy: consumed,
      ),
    );
  }

  /// Emits what [_naturalEnd] collected; called after the publish.
  void _flushTrackEnds() {
    if (_pendingEnds.isEmpty) return;
    final ends = List<TrackEnd>.of(_pendingEnds);
    _pendingEnds.clear();
    if (_disposed || _trackEndsCtrl.isClosed) return;
    ends.forEach(_trackEndsCtrl.add);
  }

  /// Pauses at the start of the entry that is playing: the sleep stop of an
  /// advance the engine already made.
  Future<void> _restAtStart() async {
    _intent = PlayIntent.paused;
    _position = Duration.zero;
    _startAt = Duration.zero;
    _enginePlaying = false;
    _thaw();
    _seekTarget = Duration.zero;
    _seekFile = _loaded;
    _seekDeadlineMs = _nowMs() + PlayerController._seekGuard.inMilliseconds;
    await _engine?.pause();
    await _engine?.seek(Duration.zero);
  }
}
