import 'package:material_ui/material_ui.dart';

import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import '../k_gap.dart';

/// Text sizes and line heights of a media card, shared by the text column and
/// the card's height maths ([KMediaCard.extentOf]).
abstract final class KMediaCardMetrics {
  static const double titleSize = 15;
  static const double lineSize = 13;
  static const double lineHeight = 1.35;

  /// Height of one text line of [size] under [scaler].
  static double line(TextScaler scaler, double size) =>
      scaler.scale(size) * lineHeight;

  /// Height of the three reserved lines (title + two lines).
  static double textBlock(TextScaler scaler) =>
      line(scaler, titleSize) + 2 * line(scaler, lineSize);
}

/// Text column of a media card: title (with an optional tag), then two lines.
/// Always three lines high so every card of a list has the same height.
class KMediaCardText extends StatelessWidget {
  const KMediaCardText({
    super.key,
    required this.title,
    required this.ink,
    required this.soft,
    this.titleLabel,
    this.titleLines = 1,
    this.line2,
    this.line3,
    this.loading = false,
    this.barColor,
  });

  final String title;
  final String? titleLabel;
  final int titleLines;
  final String? line2;
  final String? line3;

  /// Draw placeholder bars instead of text (same line heights).
  final bool loading;

  /// Colour of the placeholder bars.
  final Color? barColor;

  /// Colour of the title.
  final Color ink;

  /// Colour of the tag and the lines under the title.
  final Color soft;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scaler = MediaQuery.textScalerOf(context);

    Widget line(String? text, double size, TextStyle? base, Color color) {
      return SizedBox(
        height: KMediaCardMetrics.line(scaler, size),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: 1,
          child: Text(
            text ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: base?.copyWith(
              fontSize: size,
              height: KMediaCardMetrics.lineHeight,
              color: color,
            ),
          ),
        ),
      );
    }

    Widget bar(double size, double fraction) {
      return SizedBox(
        height: KMediaCardMetrics.line(scaler, size),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: FractionallySizedBox(
            widthFactor: fraction,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: barColor ?? ink.withValues(alpha: 0.12),
                borderRadius: KRadius.sm,
              ),
              child: SizedBox(height: scaler.scale(size) * 0.8),
            ),
          ),
        ),
      );
    }

    if (loading) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(KMediaCardMetrics.titleSize, 0.6),
          bar(KMediaCardMetrics.lineSize, 0.4),
          SizedBox(
            height: KMediaCardMetrics.line(scaler, KMediaCardMetrics.lineSize),
          ),
        ],
      );
    }

    final titleStyle = textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w600,
    );
    // A two-line title takes the room of a title and a second line.
    final twoLineHeight =
        KMediaCardMetrics.line(scaler, KMediaCardMetrics.titleSize) +
        KMediaCardMetrics.line(scaler, KMediaCardMetrics.lineSize);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: titleLines == 2
                  ? SizedBox(
                      height: twoLineHeight,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle?.copyWith(
                            fontSize: KMediaCardMetrics.titleSize,
                            color: ink,
                            height:
                                twoLineHeight /
                                (2 * scaler.scale(KMediaCardMetrics.titleSize)),
                          ),
                        ),
                      ),
                    )
                  : line(title, KMediaCardMetrics.titleSize, titleStyle, ink),
            ),
            if (titleLabel != null) ...[
              const KGap(KSpace.x2),
              Text(
                titleLabel!,
                maxLines: 1,
                style: textTheme.labelSmall?.copyWith(color: soft),
              ),
            ],
          ],
        ),
        if (titleLines != 2)
          line(line2, KMediaCardMetrics.lineSize, textTheme.bodySmall, soft),
        line(line3, KMediaCardMetrics.lineSize, textTheme.bodySmall, soft),
      ],
    );
  }
}
