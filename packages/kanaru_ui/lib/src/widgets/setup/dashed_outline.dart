import 'dart:ui' show PathMetric;

import 'package:material_ui/material_ui.dart';

/// Draws a dashed outline over [child]: a pill by default (the suggestion
/// chips), or a rounded rectangle when [radius] is given.
class DashedOutline extends StatelessWidget {
  const DashedOutline({
    super.key,
    required this.color,
    required this.child,
    this.radius,
  });

  final Color color;
  final Widget child;

  /// Corner radius; null = half the height (pill).
  final double? radius;

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: _DashedPainter(color, radius),
    child: child,
  );
}

class _DashedPainter extends CustomPainter {
  _DashedPainter(this.color, this.radius);

  final Color color;
  final double? radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius ?? size.height / 2),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final PathMetric m in (Path()..addRRect(rrect)).computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 8) {
        canvas.drawPath(m.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter old) =>
      old.color != color || old.radius != radius;
}
