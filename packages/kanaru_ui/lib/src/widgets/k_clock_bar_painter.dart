import 'package:material_ui/material_ui.dart';

/// A bar cut into [count] segments read like the minutes bar: filled = what is
/// left, shrinking toward the left. The first `count - done` segments are the
/// tracks left; the last of them is the playing one and drains from its right
/// end with [currentFraction] (0..1 left); the [done] played tracks are empty
/// segments on the right.
typedef KClockSegments = ({int count, int done, double currentFraction});

const double _kSegmentGap = 4;

/// Paints the rounded track and its fill. Public inside the package so tests
/// can read what is drawn; not exported from the barrel.
class ClockBarPainter extends CustomPainter {
  ClockBarPainter({
    required double fraction,
    required this.segments,
    required this.fill,
    required this.track,
  }) : fraction = fraction.isNaN ? 0.0 : fraction.clamp(0.0, 1.0);

  final double fraction;
  final KClockSegments? segments;
  final Color fill;
  final Color track;

  /// Filled share (0..1) of each drawn segment, left to right.
  List<double> get fills {
    final s = segments;
    if (s == null) return [fraction];
    final current = s.count - s.done - 1;
    return [
      for (var i = 0; i < s.count; i++)
        i < current
            ? 1.0
            : (i == current
                  ? (s.currentFraction.isNaN
                        ? 0.0
                        : s.currentFraction.clamp(0.0, 1.0))
                  : 0.0),
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final parts = fills;
    final gaps = (parts.length - 1) * _kSegmentGap;
    final w = (size.width - gaps) / parts.length;
    final r = Radius.circular(size.height / 2);
    for (var i = 0; i < parts.length; i++) {
      final x = i * (w + _kSegmentGap);
      final rect = Rect.fromLTWH(x, 0, w, size.height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, r),
        Paint()..color = track,
      );
      if (parts[i] > 0) {
        final part = Rect.fromLTWH(x, 0, w * parts[i], size.height);
        canvas.drawRRect(
          RRect.fromRectAndRadius(part, r),
          Paint()..color = fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(ClockBarPainter old) =>
      old.fraction != fraction ||
      old.segments != segments ||
      old.fill != fill ||
      old.track != track;
}
