import 'package:flutter/widgets.dart';
import 'package:flutter/physics.dart' show SpringDescription, SpringSimulation;

/// Animation durations.
abstract final class KMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
}

/// Spring tokens (04 §3.5): snappy = select/press, gentle = sheets/pages,
/// bouncy = mini player to Now Playing.
abstract final class KSpring {
  static final SpringDescription snappy = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 700,
    ratio: 0.9,
  );
  static final SpringDescription gentle = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 300,
    ratio: 1.0,
  );
  static final SpringDescription bouncy = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 450,
    ratio: 0.72,
  );

  /// Animates [controller] to [target] with [spring] from [velocity]; jumps
  /// to [target] when the platform asks for reduced motion.
  ///
  /// Underdamped springs ([bouncy], [snappy]) overshoot [target]: the
  /// controller must be `AnimationController.unbounded` (or have bounds wider
  /// than the overshoot), or the value is clamped and the future completes
  /// early.
  static TickerFuture animateTo(
    BuildContext context,
    AnimationController controller,
    double target,
    SpringDescription spring, {
    double velocity = 0,
  }) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return controller.animateTo(target, duration: Duration.zero);
    }
    return controller.animateWith(
      SpringSimulation(spring, controller.value, target, velocity),
    );
  }
}
