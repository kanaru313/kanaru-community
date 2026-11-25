import 'package:material_ui/material_ui.dart';

import '../tokens/k_shape.dart';

/// One placeholder line drawn while its text is not known yet (a list row
/// still loading, the Now Playing info card before the track's info): a
/// rounded bar in a box exactly one text line high, so the text that replaces
/// it moves nothing.
///
/// The box is [fontSize] scaled by the ambient `TextScaler` times
/// [lineHeight]; the bar is [widthFactor] of the available width and 0.8 of
/// the scaled font size high, centred vertically at the start. It is
/// decorative and carries no semantics of its own.
class KSkeletonLine extends StatelessWidget {
  const KSkeletonLine({
    super.key,
    required this.fontSize,
    required this.widthFactor,
    this.lineHeight = defaultLineHeight,
    this.color,
  }) : assert(fontSize > 0),
       assert(widthFactor > 0 && widthFactor <= 1),
       assert(lineHeight > 0);

  /// Line height used when none is given: the media card's text lines.
  static const double defaultLineHeight = 1.35;

  /// Unscaled font size of the text this line stands for.
  final double fontSize;

  /// Share of the available width the bar covers (0, 1].
  final double widthFactor;

  /// Line height multiplier of the text this line stands for.
  final double lineHeight;

  /// Bar colour; defaults to `onSurface` at 12 % opacity.
  final Color? color;

  /// Height of the box for [fontSize] and [lineHeight] under [scaler].
  static double extentOf(
    TextScaler scaler,
    double fontSize, {
    double lineHeight = defaultLineHeight,
  }) => scaler.scale(fontSize) * lineHeight;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final scaled = scaler.scale(fontSize);
    return SizedBox(
      height: scaled * lineHeight,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: widthFactor,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color:
                  color ??
                  Theme.of(context).colorScheme.onSurface
                      .withValues(alpha: 0.12),
              borderRadius: KRadius.sm,
            ),
            child: SizedBox(height: scaled * 0.8),
          ),
        ),
      ),
    );
  }
}
