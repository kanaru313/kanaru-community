import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../tokens/k_space.dart';

/// A bar cut into [count] segments: the first [done] are played (empty), the
/// one at [done] drains with [currentFraction] (0..1 left), the rest are full.
typedef KClockSegments = ({int count, int done, double currentFraction});

const double _kHeldNumberAlpha = 0.55;
const double _kSegmentGap = 4;

/// Big thin number with a small label above, a progress bar under it and a
/// start / end text row (the sleep timer's running screen).
///
/// The bar shows [fraction] (0..1, clamped, NaN = 0) or, when [segments] is
/// set, one segment per track. [held] dims the number to 55 % and draws the
/// bar in `outline` (the count is paused). The big number is excluded from
/// semantics; [statusLabel] is a hidden node with the spoken state (minute
/// precision from the caller). It is not a live region: announcing changes is
/// the caller's job.
class KClockProgress extends StatelessWidget {
  const KClockProgress({
    super.key,
    required this.label,
    required this.bigText,
    required this.statusLabel,
    this.fraction = 0,
    this.segments,
    this.startText,
    this.endText,
    this.held = false,
  });

  final String label;
  final String bigText;
  final String statusLabel;
  final double fraction;
  final KClockSegments? segments;
  final String? startText;
  final String? endText;
  final bool held;

  /// Number size by shell and text length: 57 / 45 / 36 on touch shells,
  /// 45 / 36 / 28 on desktop (up to 5, up to 7, longer).
  static double numberSize({required bool desktop, required int length}) {
    final tier = length <= 5 ? 0 : (length <= 7 ? 1 : 2);
    return (desktop
        ? const [45.0, 36.0, 28.0]
        : const [57.0, 45.0, 36.0])[tier];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    final numberStyle = theme.textTheme.displayLarge?.copyWith(
      fontSize: numberSize(desktop: desktop, length: bigText.length),
      fontWeight: FontWeight.w400,
      height: 1.1,
      color: held
          ? scheme.onSurface.withValues(alpha: _kHeldNumberAlpha)
          : scheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final small = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        ExcludeSemantics(
          child: Text(
            bigText,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: numberStyle,
          ),
        ),
        Semantics(
          container: true,
          liveRegion: false,
          label: statusLabel,
          child: const SizedBox.shrink(),
        ),
        const SizedBox(height: KSpace.x3),
        ExcludeSemantics(
          child: SizedBox(
            height: desktop ? 6 : 8,
            child: CustomPaint(
              painter: ClockBarPainter(
                fraction: fraction,
                segments: segments,
                fill: held ? scheme.outline : scheme.primary,
                track: scheme.primary.withValues(alpha: 0.24),
              ),
            ),
          ),
        ),
        if (startText != null || endText != null) ...[
          const SizedBox(height: KSpace.x2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(startText ?? '', style: small)),
              const SizedBox(width: KSpace.x3),
              Flexible(
                child: Text(
                  endText ?? '',
                  textAlign: TextAlign.end,
                  style: small,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

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
    return [
      for (var i = 0; i < s.count; i++)
        i < s.done
            ? 0.0
            : (i == s.done
                  ? (s.currentFraction.isNaN
                        ? 0.0
                        : s.currentFraction.clamp(0.0, 1.0))
                  : 1.0),
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
