import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

/// Gives [child] an empty strip of [extent] dp after it whose taps go to the
/// child: the strip is part of the layout (it replaces the space a row would
/// leave there) and part of the child's hit area, so a tap beside the last
/// button of a row reaches the button, not the row.
class KEndHitExtension extends SingleChildRenderObjectWidget {
  const KEndHitExtension({super.key, required this.extent, super.child});

  /// Width of the strip, after the child in the reading direction.
  final double extent;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderEndHitExtension(extent, Directionality.of(context));

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderEndHitExtension)
      ..extent = extent
      ..textDirection = Directionality.of(context);
  }
}

class _RenderEndHitExtension extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  _RenderEndHitExtension(this._extent, this._direction);

  double _extent;
  TextDirection _direction;

  set textDirection(TextDirection v) {
    if (v == _direction) return;
    _direction = v;
    markNeedsLayout();
  }

  Offset get _childOffset =>
      _direction == TextDirection.rtl ? Offset(_extent, 0) : Offset.zero;

  set extent(double v) {
    if (v == _extent) return;
    _extent = v;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      (child?.getMinIntrinsicWidth(height) ?? 0) + _extent;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      (child?.getMaxIntrinsicWidth(height) ?? 0) + _extent;

  @override
  double computeMinIntrinsicHeight(double width) =>
      child?.getMinIntrinsicHeight(width) ?? 0;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      child?.getMaxIntrinsicHeight(width) ?? 0;

  Size _sizeFor(Size childSize, BoxConstraints constraints) =>
      constraints.constrain(Size(childSize.width + _extent, childSize.height));

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final c = child;
    if (c == null) return constraints.constrain(Size(_extent, 0));
    return _sizeFor(c.getDryLayout(constraints.loosen()), constraints);
  }

  @override
  void performLayout() {
    final c = child;
    if (c == null) {
      size = constraints.constrain(Size(_extent, 0));
      return;
    }
    c.layout(constraints.loosen(), parentUsesSize: true);
    (c.parentData! as BoxParentData).offset = _childOffset;
    size = _sizeFor(c.size, constraints);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final c = child;
    if (c != null) context.paintChild(c, offset + _childOffset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final c = child;
    if (c == null) return false;
    // A tap in the strip is a tap on the child's end edge: the position the
    // child sees is local to it, clamped inside its width.
    return result.addWithPaintOffset(
      offset: _childOffset,
      position: position,
      hitTest: (result, local) {
        final maxX = math.max(0.0, c.size.width - 0.01);
        final x = local.dx.clamp(0.0, maxX).toDouble();
        return c.hitTest(result, position: Offset(x, local.dy));
      },
    );
  }
}
