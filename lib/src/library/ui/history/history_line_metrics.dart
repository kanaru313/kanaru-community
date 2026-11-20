import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Heights of the lines of the History timeline. Every line has a fixed
/// extent, so the list can place lines and jump to a day without measuring.
///
/// The extents follow the text scale: a song row is [row] tall, and the day
/// bar (the pinned one and the header line of every other day, which must be
/// exactly the same height for the swap to be invisible) is [dayBar] tall.
class HistoryLineMetrics {
  const HistoryLineMetrics({required this.row, required this.dayBar});

  /// Reads the extents for [theme] at [scaler].
  factory HistoryLineMetrics.of(TextTheme theme, TextScaler scaler) =>
      HistoryLineMetrics(
        row: KMediaCard.extentOf(scaler),
        dayBar:
            2 * dayBarPadding +
            _line(theme.titleSmall, scaler) +
            _line(theme.bodySmall, scaler),
      );

  /// A song row of the timeline, with the gap below it (also the extent of
  /// the older-year line).
  final double row;

  /// The day bar: padding, the label line and the figures line (each line
  /// rounded up to a whole pixel, as the text engine does).
  final double dayBar;

  /// Vertical padding of the day bar; 57 dp tall at the default text scale.
  static const double dayBarPadding = KSpace.x2 + KSpace.x1 / 2;

  /// Height of the older-year line at the end of the year.
  double get footer => row;

  /// Line height factor of both text lines of the bar; the bar's styles set
  /// it too, so the extent is what is drawn whatever the font.
  static const double lineHeight = 1.4;

  static double _line(TextStyle? style, TextScaler scaler) =>
      (scaler.scale(style?.fontSize ?? 14) * lineHeight).ceilToDouble();
}
