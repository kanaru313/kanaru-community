import 'package:flutter/widgets.dart';

/// [base] shrunk by [inset] above and below: the ink / hover / focus shape of
/// a dense row while the widget itself keeps the full hit area. Not exported.
class KInsetShape extends ShapeBorder {
  const KInsetShape(this.base, this.inset);

  final ShapeBorder base;
  final double inset;

  Rect _inset(Rect r) =>
      Rect.fromLTRB(r.left, r.top + inset, r.right, r.bottom - inset);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      base.getInnerPath(_inset(rect), textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      base.getOuterPath(_inset(rect), textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => KInsetShape(base.scale(t), inset * t);
}
