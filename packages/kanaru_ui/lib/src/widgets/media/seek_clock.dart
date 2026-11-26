import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// How long a seek bar animation takes to fade in or out when playback
/// starts or stops.
const Duration seekEnergyFade = Duration(milliseconds: 300);

/// Longest step of one frame, in seconds.
const double seekMaxFrameTime = 0.05;

/// The clock of the moving looks (squiggle drift, flat effects).
///
/// [energy] eases to 1 while playing and to 0 on pause over
/// [seekEnergyFade]; [time] (seconds) advances while the energy is above 0.
/// Its ticker runs only while one of them still changes, so a paused bar that
/// has settled schedules no frames. The ticker comes from the owner's
/// [TickerProvider], so `TickerMode` mutes it. Painters listen to the clock
/// (no widget rebuild per frame).
class SeekClock extends ChangeNotifier {
  SeekClock(TickerProvider vsync) {
    _ticker = vsync.createTicker(_onTick);
  }

  late final Ticker _ticker;
  Duration _last = Duration.zero;
  double _target = 0;
  bool _usesTime = false;
  bool _configured = false;

  /// 0..1.
  double energy = 0;

  /// Seconds of animation, only moving while [energy] is above 0.
  double time = 0;

  /// Whether the ticker is scheduled (not necessarily delivering: a ticker
  /// muted by `TickerMode` stays active without frames).
  bool get running => _ticker.isActive;

  /// Sets the goal. [target] is the energy to reach; [usesTime] says that
  /// [time] matters while energy is above 0 (drift, shine, sparks). [instant]
  /// jumps to the target (first configuration, or no fade wanted).
  void configure({
    required double target,
    required bool usesTime,
    bool instant = false,
  }) {
    _target = target;
    _usesTime = usesTime;
    if (instant || !_configured) {
      final changed = energy != target;
      energy = target;
      if (changed) notifyListeners();
    }
    _configured = true;
    _sync();
  }

  void _sync() {
    final needed = energy != _target || (_usesTime && energy > 0);
    if (needed && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!needed && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) {
    // A frame never moves more than this: a muted ticker keeps its start, so
    // the first frame after unmuting would bring the whole muted span.
    final dt = math.min(
      seekMaxFrameTime,
      (elapsed - _last).inMicroseconds / 1e6,
    );
    _last = elapsed;
    if (energy != _target) {
      final step = dt / (seekEnergyFade.inMicroseconds / 1e6);
      energy = _target > energy
          ? (energy + step).clamp(0.0, _target)
          : (energy - step).clamp(_target, 1.0);
    }
    if (_usesTime && energy > 0) time += dt;
    notifyListeners();
    _sync();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}
