import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../tokens/k_icon_size.dart';

const double _kRing = KIconSize.md;
const double _kStroke = 2.5;
const double _kInnerIcon = 14;
const double _kDot = 7;
const double _kHeldAlpha = 0.70;

/// Icon wrapped in a progress ring (the sleep timer button of the mobile
/// header).
///
/// [progress] 0..1 (clamped, NaN = 0) draws the ring (track `onSurfaceVariant`
/// 28 %, arc `primary`) around a 14 dp icon. `null` means nothing measurable:
/// a 24 dp icon with a 7 dp dot at its top right. [held] turns ring and icon
/// to `onSurfaceVariant` at 70 %. Decorative: it adds no semantics.
class KProgressRingIcon extends StatelessWidget {
  const KProgressRingIcon({
    super.key,
    required this.icon,
    this.progress,
    this.held = false,
  });

  final IconData icon;
  final double? progress;
  final bool held;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = held
        ? scheme.onSurfaceVariant.withValues(alpha: _kHeldAlpha)
        : scheme.primary;
    final p = progress;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: _kRing,
        child: p == null
            ? Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Icon(icon, size: _kRing, color: accent),
                  ),
                  PositionedDirectional(
                    top: -1,
                    end: -1,
                    child: Container(
                      key: const ValueKey('progress-ring-dot'),
                      width: _kDot,
                      height: _kDot,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              )
            : CustomPaint(
                painter: RingPainter(
                  progress: p.isNaN ? 0 : p.clamp(0.0, 1.0),
                  track: scheme.onSurfaceVariant.withValues(alpha: 0.28),
                  arc: accent,
                ),
                child: Center(
                  child: Icon(icon, size: _kInnerIcon, color: accent),
                ),
              ),
      ),
    );
  }
}

/// Paints the ring track and the arc from 12 o'clock. Package-internal; not
/// exported from the barrel.
class RingPainter extends CustomPainter {
  RingPainter({required this.progress, required this.track, required this.arc});

  final double progress;
  final Color track;
  final Color arc;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_kStroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _kStroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, base..color = track);
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        base..color = arc,
      );
    }
  }

  @override
  bool shouldRepaint(RingPainter old) =>
      old.progress != progress || old.track != track || old.arc != arc;
}
