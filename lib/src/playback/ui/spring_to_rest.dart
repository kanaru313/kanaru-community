import 'package:flutter/widgets.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

/// [KSpring.animateTo] that ends exactly on [target].
///
/// A spring simulation is done once it is within about 1e-3 of the target
/// and the controller keeps that value, so a test such as `value != 0` or
/// `t > 0` stays true for good (a scrim that never leaves, an icon that
/// stays). The returned future completes after the value was set to [target];
/// when a newer animation (or dispose) cancels this one it does not complete,
/// so the newer one decides where the value ends.
Future<void> animateSpringTo(
  BuildContext context,
  AnimationController controller,
  double target,
  SpringDescription spring, {
  double velocity = 0,
  @visibleForTesting
  TickerFuture Function(
        BuildContext,
        AnimationController,
        double,
        SpringDescription, {
        double velocity,
      })
      animate =
      KSpring.animateTo,
}) async {
  await animate(context, controller, target, spring, velocity: velocity);
  controller.value = target;
}
