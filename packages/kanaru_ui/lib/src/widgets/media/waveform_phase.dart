import '../../tokens/k_motion.dart';

/// What the app knows about the waveform of the playing track. A mirror of the
/// app's own status: `kanaru_ui` does not import the app.
enum KWaveformStatus {
  /// No decision yet (the waveform is loading, or it is another track's).
  unknown,

  /// Being computed; no bars yet.
  computing,

  /// The levels are there.
  ready,

  /// There are no levels and none are coming.
  none,
}

/// What the band shows.
enum WaveformPhaseKind {
  /// No decision yet: the dotted row, no animation.
  unknown,

  /// Computing: the dotted row.
  dots,

  /// The bars grow from dots to their height.
  growing,

  /// The bars at their height.
  shown,

  /// The old track's bars shrink to dots.
  collapsing,

  /// The fallback seek bar (fading in, or there).
  fallback,
}

/// The state machine of the waveform band, in pure Dart.
///
/// Events take the elapsed time of one clock (the widget's ticker; tests pass
/// their own), so nothing here reads the wall clock. Every event first
/// advances the clock to its time, then applies itself. See the transition
/// table in the plan and in `docs/system-architecture-playback.md`.
///
/// - The first decision after mount (no track change yet) is applied at once.
/// - After a track change the old bars collapse over [growDuration], and the
///   new bars start to grow only once [gate] has passed since the change.
/// - `none` fades the dotted row into the fallback over [fadeDuration].
/// - With reduced motion every transition is instant and the gate is skipped.
class WaveformPhase {
  WaveformPhase({
    this.growDuration = KMotion.waveformGrow,
    this.gate = KMotion.waveformGrowGate,
    this.fadeDuration = KMotion.waveformFallbackFade,
  });

  final Duration growDuration;
  final Duration gate;
  final Duration fadeDuration;

  WaveformPhaseKind _kind = WaveformPhaseKind.unknown;
  KWaveformStatus _held = KWaveformStatus.unknown;
  Duration _now = Duration.zero;
  Duration? _gateAt;
  double _growT = 0;
  double _fallbackT = 0;
  List<double>? _snapshot;
  bool _changed = false;
  bool _reduceMotion = false;
  int _revision = 0;

  WaveformPhaseKind get kind => _kind;

  /// The latest status the owner reported (unknown again after a track
  /// change, until it reports the new track's).
  KWaveformStatus get held => _held;

  /// The clock as of the last event.
  Duration get now => _now;

  /// When the pending gate passes; null when none is pending.
  Duration? get gateAt => _gateAt;

  /// Linear 0..1 progress of the bars from dots to full height (the owner
  /// eases it).
  double get growT => _growT;

  /// 0..1 share of the fallback shown over the bars.
  double get fallbackT => _fallbackT;

  /// Bar heights the collapse starts from; non-null while [kind] is
  /// collapsing, or fading to the fallback during a collapse.
  List<double>? get snapshot => _snapshot;

  /// A track changed since mount.
  bool get changed => _changed;

  /// Grows when [growT] or [fallbackT] or [kind] change (what the band draws).
  int get revision => _revision;

  /// Something is pending: the owner must keep sending ticks.
  bool get needsTicks =>
      _gateAt != null || _growT != _growTarget || _fallbackT != _fallbackTarget;

  double get _growTarget =>
      _kind == WaveformPhaseKind.growing || _kind == WaveformPhaseKind.shown
      ? 1
      : 0;

  double get _fallbackTarget => _kind == WaveformPhaseKind.fallback ? 1 : 0;

  /// The owner reports the status of the current track.
  void onStatus(KWaveformStatus status, Duration now) => _event(now, () {
    _held = status;
    switch (status) {
      case KWaveformStatus.unknown:
        break;
      case KWaveformStatus.computing:
        if (_kind == WaveformPhaseKind.unknown ||
            _kind == WaveformPhaseKind.fallback) {
          _kind = WaveformPhaseKind.dots;
        }
      case KWaveformStatus.ready:
        // The first decision after mount is applied at once: opening the
        // screen on a cached track never animates.
        if (_kind == WaveformPhaseKind.unknown && !_changed) {
          _kind = WaveformPhaseKind.shown;
          _growT = 1;
        }
      case KWaveformStatus.none:
        if (_kind == WaveformPhaseKind.unknown && !_changed) _fallbackT = 1;
        _kind = WaveformPhaseKind.fallback;
    }
  });

  /// The playing track changed. [snapshot] is what the band draws now (bar
  /// heights); without it nothing collapses.
  void onTrackChange(Duration now, {List<double>? snapshot}) => _event(now, () {
    _changed = true;
    _held = KWaveformStatus.unknown;
    _gateAt = now + gate;
    switch (_kind) {
      case WaveformPhaseKind.unknown:
      case WaveformPhaseKind.dots:
        break;
      case WaveformPhaseKind.growing:
      case WaveformPhaseKind.shown:
      case WaveformPhaseKind.collapsing:
        if (snapshot != null && snapshot.isNotEmpty) {
          _snapshot = snapshot;
          _kind = WaveformPhaseKind.collapsing;
          _growT = 1;
        } else {
          _kind = WaveformPhaseKind.dots;
          _growT = 0;
          _snapshot = null;
        }
      case WaveformPhaseKind.fallback:
        _kind = WaveformPhaseKind.dots;
    }
  });

  /// Time passes.
  void onTick(Duration now) => _event(now, () {});

  /// The platform asks for reduced motion (or stops asking).
  void onReduceMotion(bool on, Duration now) =>
      _event(now, () => _reduceMotion = on);

  /// Advance the clock, apply [apply], settle, and count a visible change.
  void _event(Duration now, void Function() apply) {
    final before = (_kind, _growT, _fallbackT);
    _advance(now);
    apply();
    _finish();
    if (before != (_kind, _growT, _fallbackT)) _revision++;
  }

  void _advance(Duration now) {
    final dt = now > _now ? now - _now : Duration.zero;
    _now = now;
    _growT = _approach(_growT, _growTarget, dt, growDuration);
    _fallbackT = _approach(_fallbackT, _fallbackTarget, dt, fadeDuration);
    if (_kind == WaveformPhaseKind.growing && _growT >= 1) {
      _kind = WaveformPhaseKind.shown;
    }
    if (_kind == WaveformPhaseKind.fallback && _fallbackT >= 1) _growT = 0;
    if (_growT <= 0) _snapshot = null;
    if (_kind == WaveformPhaseKind.collapsing && _growT <= 0) {
      _kind = WaveformPhaseKind.dots;
    }
    final gateAt = _gateAt;
    if (gateAt != null && now >= gateAt) _gateAt = null;
  }

  static double _approach(
    double value,
    double target,
    Duration dt,
    Duration full,
  ) {
    final step = dt.inMicroseconds / full.inMicroseconds;
    if (target > value) return (value + step).clamp(0.0, target);
    return (value - step).clamp(target, 1.0);
  }

  /// After every event: start the growth when everything it waited for is
  /// there, then apply reduced motion.
  void _finish() {
    if (_held == KWaveformStatus.ready &&
        _gateAt == null &&
        (_kind == WaveformPhaseKind.unknown ||
            _kind == WaveformPhaseKind.dots ||
            _kind == WaveformPhaseKind.fallback)) {
      _kind = WaveformPhaseKind.growing;
      _snapshot = null;
    }
    if (_reduceMotion) _jumpToTarget();
  }

  void _jumpToTarget() {
    _gateAt = null;
    _snapshot = null;
    switch (_held) {
      case KWaveformStatus.ready:
        _kind = WaveformPhaseKind.shown;
      case KWaveformStatus.none:
        _kind = WaveformPhaseKind.fallback;
      case KWaveformStatus.computing:
        _kind = WaveformPhaseKind.dots;
      case KWaveformStatus.unknown:
        if (_kind != WaveformPhaseKind.unknown) _kind = WaveformPhaseKind.dots;
    }
    _growT = _growTarget;
    _fallbackT = _fallbackTarget;
  }
}
