part of 'player_controller.dart';

/// How often the ramp sends a new level.
const _fadeTick = Duration(milliseconds: 50);

/// The sleep fade-out: a ramp of the engine volume to silence that leaves the
/// play state alone. The ramp is the controller's `_gain` (1 = the user's
/// volume, 0 = silent); the engine gets `_volume * _gain`, and the user's
/// volume setting is never written by it.
///
/// Every step runs as a task of the command chain, so it stays in order with
/// the commands. Any other command ends the fade (see `_cmd`) by bumping
/// `_fadeGen`, which makes every step still queued drop itself.
extension _SleepFade on PlayerController {
  /// A ramp is running, or it ended and left the engine silent.
  bool get _fadeActive => _fadeTimer != null || _gain < 1;

  /// What the engine gets: the user's volume under the ramp.
  double get _outVolume => _volume * _gain;

  /// Runs a sleep command: a no-op after [dispose], and a failure is logged
  /// and swallowed, so the sleep timer never sees an error.
  Future<void> _sleepCmd(
    Future<void> Function() body, {
    bool keepsFade = true,
    bool reconcile = false,
  }) async {
    if (_disposed) return;
    try {
      await _cmd(body, reconcile: reconcile, keepsSleepFade: keepsFade);
    } on Object catch (e, st) {
      _log.warning('sleep command failed: ${e.runtimeType}', null, st);
    }
  }

  void _cancelRamp() {
    _fadeGen++;
    _fadeTimer?.cancel();
    _fadeTimer = null;
  }

  /// Starts (or restarts, from the current level) the ramp to silence.
  Future<void> _startFade(Duration length) async {
    if (_intent != PlayIntent.playing) return;
    _cancelRamp();
    _fadeStartGain = _gain;
    _fadeFromMs = nowMs;
    _fadeLengthMs = max(1, length.inMilliseconds);
    final gen = _fadeGen;
    // The timer is made in the controller's own zone: made inside the chain
    // task it would run its callbacks in the chain's zone.
    _fadeTimer = _homeZone.run(
      () => _periodic(_fadeTick, () => _onFadeTick(gen)),
    );
  }

  void _onFadeTick(int gen) {
    if (_disposed || gen != _fadeGen) return;
    _chain
        .run(() => _fadeStep(gen))
        .then<void>((_) {}, onError: (Object e) => _log.fine('fade step: $e'));
  }

  /// One ramp step. The level comes from the clock, so a step that waited
  /// behind a slow task jumps to the right place.
  Future<void> _fadeStep(int gen) async {
    if (_disposed || gen != _fadeGen) return;
    final t = ((nowMs - _fadeFromMs) / _fadeLengthMs).clamp(0.0, 1.0);
    _gain = _fadeStartGain * (1 - t);
    if (t >= 1) {
      _fadeTimer?.cancel();
      _fadeTimer = null;
    }
    try {
      await _engine?.setVolume(_outVolume);
    } on Object catch (e, st) {
      _log.warning('fade volume failed: ${e.runtimeType}', null, st);
    }
  }

  /// Ends the fade for a command that is not a sleep command: the ramp stops
  /// and the gain is 1, but the engine keeps its level until [_restoreVolume]
  /// runs, which is after the command's own engine work (a pause).
  void _endFadeDeferred() {
    if (!_fadeActive) return;
    _cancelRamp();
    _gain = 1;
    _restoreVolumePending = true;
  }

  /// Ends the fade at once and gives the user's volume back.
  Future<void> _endFadeNow() async {
    if (!_fadeActive) return;
    _cancelRamp();
    _gain = 1;
    _restoreVolumePending = true;
    await _restoreVolume();
  }

  /// Sends the user's volume to the engine when a fade ended and nobody has
  /// yet. A failure is logged; the restore stays pending and the next
  /// reconcile tries again (the engine stays silent meanwhile).
  Future<void> _restoreVolume() async {
    if (!_restoreVolumePending) return;
    final engine = _engine;
    if (engine != null) {
      try {
        await engine.setVolume(_outVolume);
      } on Object catch (e, st) {
        _log.warning('volume restore failed: ${e.runtimeType}', null, st);
        _dirty = true;
        return;
      }
    }
    _restoreVolumePending = false;
  }

  /// [_restoreVolume] for a command that has no reconcile after it. While a
  /// reconcile is still due (the burst holds a pause), that reconcile
  /// restores after its engine work instead.
  Future<void> _restoreVolumeUnlessDirty() async {
    if (_dirty) return;
    await _restoreVolume();
  }
}
