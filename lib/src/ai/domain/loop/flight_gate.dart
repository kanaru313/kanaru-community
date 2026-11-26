import 'dart:async';

/// The single in-flight future of a driver: at most one turn step runs, and
/// a trigger that arrives while it runs either wakes it (an answer to a card)
/// or is dropped.
class FlightGate {
  Completer<void>? _current;
  bool _wake = false;
  final _wakeCalls = <String>{};
  bool _deferred = false;

  /// How many switches (`runExclusive`) wait for the gate.
  int exclusiveWaiting = 0;

  /// The stop branch left cards open and parked the turn: an answer that
  /// landed meanwhile still needs a flight. Any other stop ends the turn and
  /// drops such an answer (Stop is never followed by a model round).
  bool stopParked = false;

  /// The user pressed Stop while the gate was taken. Unlike the driver's
  /// stop flag, [reserve] does not clear it: whoever releases the gate acts
  /// on it first (drops answers, ends the turn), so a switch that holds or
  /// takes the gate never swallows the Stop.
  bool userStopPending = false;

  /// Forgets a recorded user Stop.
  void clearUserStop() => userStopPending = false;

  /// Consumes the user Stop and drops every answer waiting for a flight
  /// (Stop is never followed by a model round).
  void consumeUserStop() {
    userStopPending = false;
    _wake = false;
    _wakeCalls.clear();
    _deferred = false;
  }

  /// The running flight; null when nothing runs.
  Completer<void>? get current => _current;

  bool get busy => _current != null;

  /// Claims the flight, or null when one is running. [onClaim] runs first
  /// (the driver clears its stop flag there).
  Completer<void>? reserve({void Function()? onClaim}) {
    if (_current != null) return null;
    onClaim?.call();
    _wake = false;
    _wakeCalls.clear();
    stopParked = false;
    return _current = Completer<void>();
  }

  /// Lets go of [flight] and completes it.
  void release(Completer<void> flight) {
    if (identical(_current, flight)) _current = null;
    if (!flight.isCompleted) flight.complete();
  }

  /// Tells the running flight to look again before it parks.
  void wakeRunning(String callId) {
    _wake = true;
    _wakeCalls.add(callId);
  }

  /// Forgets the answers to [callIds] (their cards were skipped). The wake
  /// stays when an answer to another call is recorded.
  void dropWakesFor(Set<String> callIds) {
    _wakeCalls.removeAll(callIds);
    if (_wakeCalls.isEmpty) _wake = false;
  }

  /// Whether an answer is recorded, without clearing it.
  bool get hasWake => _wake;

  /// Whether an answer came in while the flight ran; reading it clears it.
  bool takeWake() {
    final woke = _wake;
    _wake = false;
    _wakeCalls.clear();
    return woke;
  }

  /// An answer is due a flight: true to start it now. With a switch waiting
  /// it is kept for the last one, so an earlier switch does not skip it.
  bool startNow() {
    if (exclusiveWaiting > 0) {
      _deferred = true;
      return false;
    }
    return true;
  }

  /// Whether an answer was kept for the last switch; reading it clears it.
  bool takeDeferred() {
    final kept = _deferred;
    _deferred = false;
    return kept;
  }
}
