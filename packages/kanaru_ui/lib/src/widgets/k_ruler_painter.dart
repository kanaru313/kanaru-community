import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Ticks and numbers of a `KRuler` around the centre [position].
class KRulerPainter extends CustomPainter {
  const KRulerPainter({
    required this.min,
    required this.max,
    required this.position,
    required this.tick,
    required this.majorEvery,
    required this.labelEvery,
    required this.minorColor,
    required this.majorColor,
    required this.labelStyle,
    required this.textScaler,
  });

  final int min;
  final int max;
  final double position;

  /// Width of one unit.
  final double tick;
  final int majorEvery;
  final int labelEvery;
  final Color minorColor;
  final Color majorColor;
  final TextStyle labelStyle;
  final TextScaler textScaler;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final half = (cx / tick).ceil() + 2;
    final from = (position - half).floor().clamp(min, max);
    final to = (position + half).ceil().clamp(min, max);
    final paint = Paint()..strokeWidth = 2;
    for (var i = from; i <= to; i++) {
      final x = cx + (i - position) * tick;
      final major = i % majorEvery == 0;
      paint.color = major ? majorColor : minorColor;
      final h = major ? 26.0 : 14.0;
      canvas.drawLine(
        Offset(x, size.height - 10),
        Offset(x, size.height - 10 - h),
        paint,
      );
      if (i % labelEvery == 0 || (labelEvery == 1 && i == min)) {
        final tp = TextPainter(
          text: TextSpan(text: '$i', style: labelStyle),
          textDirection: TextDirection.ltr,
          textScaler: textScaler,
          maxLines: 1,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, 2));
        tp.dispose();
      }
    }
  }

  @override
  bool shouldRepaint(KRulerPainter old) =>
      old.position != position ||
      old.min != min ||
      old.max != max ||
      old.tick != tick ||
      old.majorEvery != majorEvery ||
      old.labelEvery != labelEvery ||
      old.minorColor != minorColor ||
      old.majorColor != majorColor ||
      old.labelStyle != labelStyle ||
      old.textScaler != textScaler;
}
