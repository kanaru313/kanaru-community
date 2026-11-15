import 'package:flutter/widgets.dart';

/// Overshoot curve shared by the disc pop and the tick <-> dash morph.
const Curve kCheckOvershoot = Cubic(0.34, 1.56, 0.64, 1);

const _tick = [Offset(6.7, 12.4), Offset(10.4, 16.0), Offset(17.4, 8.7)];
const _dash = [Offset(7.5, 12), Offset(12, 12), Offset(16.5, 12)];

double _interval(double t, double begin, double end) =>
    ((t - begin) / (end - begin)).clamp(0.0, 1.0);

/// Paints a `KCheckMark` frame from the controller [progress] (0 = off,
/// 1 = on) and [morph] (0 = tick, 1 = dash). All geometry is on a 24 grid
/// scaled to the paint size. Repaints through the two animations, never
/// through `setState`.
class KCheckMarkPainter extends CustomPainter {
  KCheckMarkPainter({
    required this.progress,
    required this.morph,
    required this.reversing,
    this.tickOnly = false,
    required this.pulse,
    required this.ringColor,
    required this.discColor,
    required this.tickColor,
  }) : super(repaint: Listenable.merge([progress, morph]));

  final Animation<double> progress;
  final Animation<double> morph;

  /// True while animating on -> off (different timing from off -> on).
  final bool reversing;

  /// Draw only the tick: no ring, disc or pulse.
  final bool tickOnly;

  /// Draw the pulse ring (only for a change after the first build).
  final bool pulse;
  final Color ringColor;
  final Color discColor;
  final Color tickColor;

  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final c = size.center(Offset.zero);
    final t = progress.value;
    final double disc;
    final double tick;
    if (reversing) {
      final r = 1 - t;
      tick = 1 - _interval(r, 0, 0.4);
      disc = 1 - Curves.easeIn.transform(_interval(r, 0.27, 1));
    } else {
      disc = kCheckOvershoot.transform(_interval(t, 0, 0.62));
      tick = Curves.easeInOutCubic.transform(_interval(t, 0.23, 0.77));
    }

    // Ring fades out as the disc grows over it.
    if (!tickOnly) _paintDisc(canvas, size, k, c, t, disc);
    if (tick > 0) _paintTick(canvas, k, tick);
  }

  void _paintDisc(
    Canvas canvas,
    Size size,
    double k,
    Offset c,
    double t,
    double disc,
  ) {
    final ringAlpha = (1 - disc).clamp(0.0, 1.0);
    if (ringAlpha > 0) {
      _paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.75 * k
        ..color = ringColor.withValues(alpha: ringColor.a * ringAlpha);
      canvas.drawCircle(c, size.width / 2 - 0.875 * k, _paint);
    }
    if (disc > 0) {
      _paint
        ..style = PaintingStyle.fill
        ..color = discColor;
      canvas.drawCircle(c, size.width / 2 * disc, _paint);
    }
    if (pulse && !reversing) {
      final p = const Cubic(0.2, 0.7, 0.3, 1).transform(_interval(t, 0, 0.875));
      if (p > 0 && p < 1) {
        _paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6 * k
          ..color = discColor.withValues(alpha: 0.55 * (1 - p));
        canvas.drawCircle(c, size.width / 2 * (1 + 0.55 * p), _paint);
      }
    }
  }

  void _paintTick(Canvas canvas, double k, double drawn) {
    final m = morph.value;
    final pts = [
      for (var i = 0; i < 3; i++)
        Offset.lerp(_tick[i], _dash[i], kCheckOvershoot.transform(m))! * k,
    ];
    final path = Path()
      ..moveTo(pts[0].dx, pts[0].dy)
      ..lineTo(pts[1].dx, pts[1].dy)
      ..lineTo(pts[2].dx, pts[2].dy);
    final metric = path.computeMetrics().first;
    _paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = tickColor;
    canvas.drawPath(metric.extractPath(0, metric.length * drawn), _paint);
  }

  @override
  bool shouldRepaint(KCheckMarkPainter old) =>
      old.progress != progress ||
      old.morph != morph ||
      old.reversing != reversing ||
      old.tickOnly != tickOnly ||
      old.pulse != pulse ||
      old.ringColor != ringColor ||
      old.discColor != discColor ||
      old.tickColor != tickColor;
}
