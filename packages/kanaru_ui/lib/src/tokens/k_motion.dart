import 'package:flutter/widgets.dart';
import 'package:flutter/physics.dart' show SpringDescription, SpringSimulation;

/// Animation durations.
abstract final class KMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  /// A detail / sub-page (`KDetailPage`) coming in and going out.
  static const Duration pageIn = Duration(milliseconds: 280);
  static const Duration pageOut = Duration(milliseconds: 240);

  /// Wait after a page opens before it scrolls to a block it was asked to
  /// show (layout and the route transition have settled).
  static const Duration focusSettle = Duration(milliseconds: 300);

  /// One pulse of a block's border after a deep link: held for the first
  /// 60 % of this time, then fades out.
  static const Duration focusPulse = Duration(milliseconds: 2000);

  /// Delay between consecutive items of a staggered entrance (`KFabMenu`).
  static const Duration stagger = Duration(milliseconds: 50);

  /// A modal dialog scaling in (96 -> 100 %); none with reduced motion.
  static const Duration dialogIn = Duration(milliseconds: 160);

  /// Curve of [dialogIn] (fade and scale).
  static const Curve dialogCurve = Curves.easeOutCubic;

  /// Curve of colour and opacity changes (04 §3.5: colour = emphasized,
  /// position = spring).
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  /// Fade back of an icon button after a press. `KPressable` keeps its scale
  /// for cards and rows; icon buttons only change opacity.
  static const Duration press = Duration(milliseconds: 200);

  /// How long a row stays tinted after a long-press copy (`KInfoRow`); it
  /// fades in and out over [fast].
  static const Duration flash = Duration(milliseconds: 600);

  /// `KCheckMark` off -> on: disc pops in, tick draws, one pulse ring.
  static const Duration checkOn = Duration(milliseconds: 480);

  /// `KCheckMark` on -> off: tick retracts, disc shrinks. Quicker than on.
  static const Duration checkOff = Duration(milliseconds: 220);

  /// Waveform seek bar: bars growing from dots to their height, or collapsing
  /// back, in place.
  static const Duration waveformGrow = Duration(milliseconds: 600);

  /// Least time after a track change before its bars start to grow, even when
  /// the waveform is cached, so the old bars have collapsed and the change reads.
  static const Duration waveformGrowGate = Duration(milliseconds: 800);

  /// The dotted row cross-fading into the fallback seek bar (and back).
  static const Duration waveformFallbackFade = Duration(milliseconds: 200);

  /// Curve of [waveformGrow] (easeInOutQuart, as the mockup).
  static const Curve waveformGrowCurve = Curves.easeInOutQuart;

  /// Animation style for a route a helper opens (dialog, sheet, popover):
  /// none when the platform or the app turns animations off, else null (the
  /// route's own default). Flutter routes do not read `disableAnimations`.
  static AnimationStyle? routeAnimationStyle(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context)
      ? AnimationStyle.noAnimation
      : null;
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
      // Snap to the exact target when settled: a spring ends within its
      // tolerance (~0.001), and a check like `t > 0` would then stay true.
      SpringSimulation(
        spring,
        controller.value,
        target,
        velocity,
        snapToEnd: true,
      ),
    );
  }
}
