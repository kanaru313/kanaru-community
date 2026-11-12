import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

/// The two slots of [KMediaCardRightColumn].
enum KMediaCardRightSlot { top, bottom }

/// Right column of a [KMediaCard]: a short [top] text (duration) over a
/// [bottom] icon button (favourite), drawn as one tight pair on a shared
/// horizontal centre.
///
/// The pair is laid out from the *measured* [bottom] box, so it works for a
/// 48 dp mobile button, a 40 dp desktop one and a bare 24 dp icon alike: the
/// visible icon (at most [iconSize] tall, centred in its box) sits [pairGap]
/// under the text, and the pair is centred in [height] as far as the [bottom]
/// box allows (it must stay inside the column or taps on its edge would miss).
/// The [top] text is painted into the empty padding of the [bottom] box and
/// must ignore the pointer, so the box keeps its whole hit area. The [bottom]
/// is placed with the same maths whether or not [top] is set, so hearts line
/// up down a list.
class KMediaCardRightColumn
    extends
        SlottedMultiChildRenderObjectWidget<KMediaCardRightSlot, RenderBox> {
  const KMediaCardRightColumn({
    super.key,
    required this.height,
    required this.topLine,
    this.top,
    this.bottom,
  });

  /// Visible icon size the pair is laid out for (`SongFavoriteButton`: 20).
  static const double iconSize = 20;

  /// Space between the text bottom and the icon top.
  static const double pairGap = 2;

  /// Height of the column (the card's content height).
  final double height;

  /// Height of one [top] text line, used to centre the pair.
  final double topLine;
  final Widget? top;
  final Widget? bottom;

  @override
  Iterable<KMediaCardRightSlot> get slots => KMediaCardRightSlot.values;

  @override
  Widget? childForSlot(KMediaCardRightSlot slot) =>
      slot == KMediaCardRightSlot.top ? top : bottom;

  @override
  SlottedContainerRenderObjectMixin<KMediaCardRightSlot, RenderBox>
  createRenderObject(BuildContext context) =>
      RenderKMediaCardRightColumn(height, topLine);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderKMediaCardRightColumn renderObject,
  ) {
    renderObject
      ..height = height
      ..topLine = topLine;
  }
}

/// Render object of [KMediaCardRightColumn].
class RenderKMediaCardRightColumn extends RenderBox
    with SlottedContainerRenderObjectMixin<KMediaCardRightSlot, RenderBox> {
  RenderKMediaCardRightColumn(this._height, this._topLine);

  double _height;
  double _topLine;

  set height(double v) {
    if (v == _height) return;
    _height = v;
    markNeedsLayout();
  }

  set topLine(double v) {
    if (v == _topLine) return;
    _topLine = v;
    markNeedsLayout();
  }

  RenderBox? get _top => childForSlot(KMediaCardRightSlot.top);
  RenderBox? get _bottom => childForSlot(KMediaCardRightSlot.bottom);

  static const _loose = BoxConstraints();

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final tw = _top?.getDryLayout(_loose).width ?? 0;
    final bw = _bottom?.getDryLayout(_loose).width ?? 0;
    return constraints.constrain(Size(math.max(tw, bw), _height));
  }

  @override
  void performLayout() {
    final top = _top;
    final bottom = _bottom;
    top?.layout(_loose, parentUsesSize: true);
    bottom?.layout(_loose, parentUsesSize: true);
    final width = math.max(top?.size.width ?? 0, bottom?.size.width ?? 0);
    size = constraints.constrain(Size(width, _height));

    final bh = bottom?.size.height ?? 0;
    // Where the visible icon starts inside the bottom box.
    final inset = (bh - math.min(bh, KMediaCardRightColumn.iconSize)) / 2;
    final visible = bh - 2 * inset;
    final pair = _topLine + KMediaCardRightColumn.pairGap + visible;
    final boxTop = math.min(
      math.max(
        (size.height - pair) / 2 +
            _topLine +
            KMediaCardRightColumn.pairGap -
            inset,
        0.0,
      ),
      math.max(size.height - bh, 0.0),
    );
    if (bottom != null) {
      (bottom.parentData! as BoxParentData).offset = Offset(
        (size.width - bottom.size.width) / 2,
        boxTop,
      );
    }
    if (top != null) {
      final textBottom = bottom == null
          ? top.size.height
          : boxTop + inset - KMediaCardRightColumn.pairGap;
      (top.parentData! as BoxParentData).offset = Offset(
        (size.width - top.size.width) / 2,
        textBottom - top.size.height,
      );
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in [_bottom, _top]) {
      if (child == null) continue;
      context.paintChild(
        child,
        offset + (child.parentData! as BoxParentData).offset,
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in [_top, _bottom]) {
      if (child == null) continue;
      final offset = (child.parentData! as BoxParentData).offset;
      final hit = result.addWithPaintOffset(
        offset: offset,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      );
      if (hit) return true;
    }
    return false;
  }
}
