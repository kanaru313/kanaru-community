import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/widgets.dart';

/// Progress of every moving part of a `KSwitch`, each 0..1 (the thumb may
/// overshoot 1).
class KSwitchProgress {
  const KSwitchProgress({
    required this.fill,
    required this.thumb,
    required this.tick,
    required this.stretch,
  });

  /// Primary fill width, 0 = nothing, 1 = full track.
  final double fill;

  /// Thumb travel, 0 = off position, 1 = on position (overshoots).
  final double thumb;

  /// Tick draw progress.
  final double tick;

  /// Stretch pulse, 0 at rest, 1 at its peak.
  final double stretch;
}

/// Paints the 52 x 32 switch: track, fill, thumb and tick.
class KSwitchPainter extends CustomPainter {
  KSwitchPainter({
    required this.progress,
    required this.pressed,
    required this.focused,
    required this.track,
    required this.outline,
    required this.primary,
    required this.onPrimary,
    required this.surface,
  });

  final KSwitchProgress progress;
  final bool pressed;
  final bool focused;
  final Color track;
  final Color outline;
  final Color primary;
  final Color onPrimary;
  final Color surface;

  static const double _border = 2;

  // Reused every frame; style and colour are set before each draw.
  final Paint _fill = Paint();
  final Paint _stroke = Paint()..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final box = RRect.fromRectAndRadius(rect, Radius.circular(size.height / 2));
    canvas.drawRRect(box, (_fill..color = track));

    final fill = progress.fill.clamp(0.0, 1.0);
    // The outline border fades out as the fill covers the track.
    final borderColor = Color.lerp(outline, primary, fill)!;
    if (fill < 1) {
      canvas.drawRRect(
        box.deflate(_border / 2),
        _stroke
          ..strokeWidth = _border
          ..color = borderColor.withValues(alpha: 1 - fill),
      );
    }
    if (fill > 0) {
      canvas.save();
      canvas.clipRRect(box);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width * fill, size.height),
        (_fill..color = primary),
      );
      canvas.restore();
    }

    final p = progress.thumb;
    final grow = p.clamp(0.0, 1.0);
    var diameter = 16 + 8 * grow;
    var cx = 16 + 20 * p;
    if (pressed) {
      diameter = 28;
      // Off: anchored to the left edge, on: to the right edge.
      cx = 18 + 16 * p;
    }
    final stretch = math.sin(math.pi * progress.stretch.clamp(0.0, 1.0));
    final thumbColor = Color.lerp(outline, onPrimary, grow)!;
    canvas.save();
    canvas.translate(cx, size.height / 2);
    canvas.scale(1 + 0.35 * stretch, 1 - 0.15 * stretch);
    canvas.drawCircle(Offset.zero, diameter / 2, (_fill..color = thumbColor));
    if (progress.tick > 0) _paintTick(canvas);
    canvas.restore();

    if (focused) {
      canvas.drawRRect(
        box.inflate(3),
        _stroke
          ..strokeWidth = 2
          ..color = primary,
      );
      // 2 px gap in the surface colour between the track and the ring.
      canvas.drawRRect(
        box.inflate(1),
        _stroke
          ..strokeWidth = 2
          ..color = surface,
      );
    }
  }

  /// Tick on a 16 grid centred on the thumb.
  void _paintTick(Canvas canvas) {
    final path = Path()
      ..moveTo(4.2 - 8, 8.3 - 8)
      ..lineTo(6.9 - 8, 10.9 - 8)
      ..lineTo(11.8 - 8, 5.6 - 8);
    final drawn = Path();
    for (final PathMetric m in path.computeMetrics()) {
      drawn.addPath(m.extractPath(0, m.length * progress.tick), Offset.zero);
    }
    canvas.drawPath(
      drawn,
      _stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = primary,
    );
  }

  @override
  bool shouldRepaint(KSwitchPainter old) =>
      old.progress.fill != progress.fill ||
      old.progress.thumb != progress.thumb ||
      old.progress.tick != progress.tick ||
      old.progress.stretch != progress.stretch ||
      old.pressed != pressed ||
      old.focused != focused ||
      old.track != track ||
      old.outline != outline ||
      old.primary != primary ||
      old.onPrimary != onPrimary ||
      old.surface != surface;
}
