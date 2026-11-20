import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart';

/// Scroll physics that always come to rest on a multiple of [tick]: a fling
/// keeps its momentum and settles on a tick, a slow release springs to the
/// nearest one. No overscroll (the ruler has two hard ends).
class KRulerPhysics extends ClampingScrollPhysics {
  const KRulerPhysics({required this.tick, super.parent});

  final double tick;

  @override
  KRulerPhysics applyTo(ScrollPhysics? ancestor) =>
      KRulerPhysics(tick: tick, parent: buildParent(ancestor));

  double _snap(ScrollMetrics m, double pixels) =>
      ((pixels / tick).round() * tick).clamp(
        m.minScrollExtent,
        m.maxScrollExtent,
      );

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final tolerance = toleranceFor(position);
    var rest = position.pixels;
    if (velocity.abs() >= tolerance.velocity) {
      rest = ClampingScrollSimulation(
        position: position.pixels,
        velocity: velocity,
        tolerance: tolerance,
      ).x(60);
    }
    final target = _snap(position, rest);
    if ((target - position.pixels).abs() < tolerance.distance) return null;
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }
}

/// The ruler is dragged with a mouse too, and shows no scrollbar or glow.
ScrollBehavior kRulerScrollBehavior(BuildContext context) =>
    ScrollConfiguration.of(context).copyWith(
      dragDevices: PointerDeviceKind.values.toSet(),
      scrollbars: false,
      overscroll: false,
    );

/// An empty horizontal scroll view over the ruler: it carries the touch, its
/// content is [span] plus one viewport wide so the offset is the value.
class KRulerScrollLayer extends StatelessWidget {
  const KRulerScrollLayer({
    super.key,
    required this.controller,
    required this.tick,
    required this.span,
  });

  final ScrollController controller;
  final double tick;
  final double span;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: kRulerScrollBehavior(context),
      child: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          controller: controller,
          scrollDirection: Axis.horizontal,
          physics: KRulerPhysics(tick: tick),
          child: ColoredBox(
            color: const Color(0x00000000),
            child: SizedBox(width: span + box.maxWidth, height: box.maxHeight),
          ),
        ),
      ),
    );
  }
}
