import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

/// Draws an underline under every laid-out line of the text in [child], [gap]
/// below the baseline (Flutter's own decoration cannot set that distance).
/// A wrapped text is underlined line by line. The child's text, wrapping and
/// semantics are untouched; the underline is painted over it, so a fade
/// around this widget fades both.
class KLinkUnderline extends SingleChildRenderObjectWidget {
  const KLinkUnderline({
    super.key,
    required this.color,
    required this.thickness,
    required this.gap,
    super.child,
  });

  final Color color;
  final double thickness;

  /// Distance from the baseline to the top of the line.
  final double gap;

  @override
  RenderLinkUnderline createRenderObject(BuildContext context) =>
      RenderLinkUnderline(color, thickness, gap);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderLinkUnderline renderObject,
  ) {
    renderObject
      ..color = color
      ..thickness = thickness
      ..gap = gap;
  }
}

class RenderLinkUnderline extends RenderProxyBox {
  RenderLinkUnderline(this._color, this._thickness, this._gap);

  Color _color;
  double _thickness;
  double _gap;

  set color(Color v) {
    if (v == _color) return;
    _color = v;
    markNeedsPaint();
  }

  set thickness(double v) {
    if (v == _thickness) return;
    _thickness = v;
    markNeedsLayout();
  }

  set gap(double v) {
    if (v == _gap) return;
    _gap = v;
    markNeedsLayout();
  }

  /// The paragraph of the child's text: the first one down the single-child
  /// chain (`Text` is only proxies above its `RenderParagraph`).
  RenderParagraph? get _paragraph {
    RenderObject? r = child;
    while (r != null) {
      if (r is RenderParagraph) return r;
      RenderObject? next;
      r.visitChildren((c) => next ??= c);
      r = next;
    }
    return null;
  }

  List<Rect> _segments = const [];

  /// One rectangle per text line, in this box's coordinates (set by layout).
  @visibleForTesting
  List<Rect> get segments => _segments;

  @override
  void performLayout() {
    super.performLayout();
    _segments = _measure();
  }

  /// Lays the paragraph's text out again with the same settings in a
  /// `TextPainter` (a `RenderParagraph` does not expose its line metrics) and
  /// turns each line into its underline rectangle.
  List<Rect> _measure() {
    final p = _paragraph;
    if (p == null || !p.hasSize) return const [];
    final painter = TextPainter(
      text: p.text,
      textAlign: p.textAlign,
      textDirection: p.textDirection,
      textScaler: p.textScaler,
      maxLines: p.maxLines,
      ellipsis: p.overflow == TextOverflow.ellipsis ? '\u2026' : null,
      strutStyle: p.strutStyle,
      textWidthBasis: p.textWidthBasis,
      textHeightBehavior: p.textHeightBehavior,
      locale: p.locale,
    )..layout(maxWidth: p.size.width);
    try {
      final origin = MatrixUtils.transformPoint(
        p.getTransformTo(this),
        Offset.zero,
      );
      return [
        for (final m in painter.computeLineMetrics())
          Rect.fromLTWH(
            origin.dx + m.left,
            origin.dy + m.baseline + _gap,
            m.width,
            _thickness,
          ),
      ];
    } finally {
      painter.dispose();
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    final paint = Paint()..color = _color;
    for (final s in segments) {
      context.canvas.drawRect(s.shift(offset), paint);
    }
  }
}
