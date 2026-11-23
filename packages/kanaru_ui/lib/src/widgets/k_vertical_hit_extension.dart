import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

import '../tokens/k_layout.dart';

/// Lets taps in the space around [child] reach it, up to a total touch
/// height of [minHeight] (default [KLayout.minTarget]), without changing its
/// size: the touch area overlaps the neighbours, the row stays as tall as its
/// content. Only the child's own width takes part.
///
/// The extra reach is split above and below, or all above when
/// [upwardOnly]: for a last child, whose parents end where it ends and
/// reject touches below.
class KVerticalHitExtension extends SingleChildRenderObjectWidget {
  const KVerticalHitExtension({
    super.key,
    this.upwardOnly = false,
    this.minHeight = KLayout.minTarget,
    this.horizontalExtra = 0,
    super.child,
  });

  final bool upwardOnly;
  final double minHeight;

  /// Hit-only reach on the left and right of the child (no layout change).
  final double horizontalExtra;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderVerticalHitExtension(upwardOnly, minHeight, horizontalExtra);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderVerticalHitExtension)
      ..upwardOnly = upwardOnly
      ..minHeight = minHeight
      ..horizontalExtra = horizontalExtra;
  }
}

class _RenderVerticalHitExtension extends RenderProxyBox {
  _RenderVerticalHitExtension(
    this.upwardOnly,
    this.minHeight,
    this.horizontalExtra,
  );

  bool upwardOnly;
  double minHeight;
  double horizontalExtra;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final c = child;
    if (c == null) return false;
    final extra = math.max(0.0, minHeight - size.height);
    final above = upwardOnly ? extra : extra / 2;
    final below = upwardOnly ? 0.0 : extra / 2;
    if (position.dx < -horizontalExtra ||
        position.dx >= size.width + horizontalExtra ||
        position.dy < -above ||
        position.dy >= size.height + below) {
      return false;
    }
    // A tap in the extra strip is a tap on the child's nearest edge.
    final y = position.dy.clamp(0.0, math.max(0.0, size.height - 0.01));
    final x = position.dx.clamp(0.0, math.max(0.0, size.width - 0.01));
    if (!c.hitTest(result, position: Offset(x.toDouble(), y.toDouble()))) {
      return false;
    }
    result.add(BoxHitTestEntry(this, position));
    return true;
  }
}
