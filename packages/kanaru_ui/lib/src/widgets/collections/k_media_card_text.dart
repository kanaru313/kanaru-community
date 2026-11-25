import 'package:material_ui/material_ui.dart';

import '../../tokens/k_space.dart';
import '../k_gap.dart';
import '../k_skeleton_line.dart';

/// Text sizes and line heights of a media card, shared by the text column and
/// the card's height maths ([KMediaCard.extentOf]).
abstract final class KMediaCardMetrics {
  static const double titleSize = 15;
  static const double lineSize = 13;
  static const double lineHeight = 1.35;

  /// Title style of a media card (also used by the mini player).
  static TextStyle? titleStyle(TextTheme t) => t.bodyLarge?.copyWith(
    fontWeight: FontWeight.w600,
    fontSize: titleSize,
    height: lineHeight,
  );

  /// Style of the lines under the title.
  static TextStyle? lineStyle(TextTheme t) =>
      t.bodySmall?.copyWith(fontSize: lineSize, height: lineHeight);

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
    this.line3Color,
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

  /// Colour of [line3] when it differs from [soft] (the missing-file error).
  final Color? line3Color;

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
            style: base?.copyWith(color: color),
          ),
        ),
      );
    }

    Widget bar(double size, double fraction) => KSkeletonLine(
      fontSize: size,
      widthFactor: fraction,
      lineHeight: KMediaCardMetrics.lineHeight,
      color: barColor ?? ink.withValues(alpha: 0.12),
    );

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

    final lineStyle = KMediaCardMetrics.lineStyle(textTheme);
    final titleStyle = KMediaCardMetrics.titleStyle(textTheme);
    // A two-line title takes the room of a title and a second line.
    final twoLineHeight =
        KMediaCardMetrics.line(scaler, KMediaCardMetrics.titleSize) +
        KMediaCardMetrics.line(scaler, KMediaCardMetrics.lineSize);

    final titleRow = Row(
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
    );
    // A row of one line only (no second or third line) centres its title on
    // the height of a full three-line block, like the cover beside it.
    if (titleLines != 2 && line2 == null && line3 == null) {
      return SizedBox(
        height:
            KMediaCardMetrics.line(scaler, KMediaCardMetrics.titleSize) +
            2 * KMediaCardMetrics.line(scaler, KMediaCardMetrics.lineSize),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: titleRow,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleRow,
        if (titleLines != 2)
          line(line2, KMediaCardMetrics.lineSize, lineStyle, soft),
        line(line3, KMediaCardMetrics.lineSize, lineStyle, line3Color ?? soft),
      ],
    );
  }
}
