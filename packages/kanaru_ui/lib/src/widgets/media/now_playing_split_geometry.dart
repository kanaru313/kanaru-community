import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Share of the body that the track column takes, and its limits.
const double splitColumnShare = 0.42;
const double splitColumnMinWidth = 300;
const double splitColumnMaxWidth = 600;

/// Air left and right of the track column's content, and above and below it.
const EdgeInsets splitColumnPadding = EdgeInsets.symmetric(
  horizontal: 24,
  vertical: 16,
);

/// The cover is never larger than this, however much room there is, nor
/// smaller than [splitCoverMinSide].
const double splitCoverMaxSide = 500;
const double splitCoverMinSide = 96;

/// Gaps between the cover, the text, the seek slot and the transport row.
const double splitCoverGap = 24;
const double splitSeekGap = 16;
const double splitTransportGap = 8;

/// Gap above the artist line and above the album line.
const double splitLineGap = 8;

/// A line of the artist or album: text, or the 20 dp icon beside it.
const double splitLineIconSize = 20;

/// Height of the transport row: the 36 dp play icon in 8 dp of padding.
const double splitTransportHeight = 52;

/// Title lines reserved under the cover whether or not the title wraps.
const int splitTitleLines = 2;

/// Width of the track column in a body [bodyWidth] wide: 42 %, clamped to
/// 300..600.
double splitColumnWidth(double bodyWidth) => (bodyWidth * splitColumnShare)
    .clamp(splitColumnMinWidth, splitColumnMaxWidth);

/// Height of [lines] lines of [style] under [scaler]. Flutter's default line
/// height (1.2) when the style sets none; the text engine rounds each line up
/// to a whole dp, so the estimate does too.
double splitTextHeight(
  TextScaler scaler,
  TextStyle? style,
  int lines, {
  double fallbackSize = 14,
}) {
  final size = style?.fontSize ?? fallbackSize;
  final line = (scaler.scale(size) * (style?.height ?? 1.2)).ceilToDouble();
  return line * lines;
}

/// Height the text under the cover always takes: two title lines, an artist
/// line and an album line, whether or not the song has them. Reserved, so the
/// cover and the controls stay where they are when a title wraps or the album
/// arrives late.
double splitTextReserve(
  TextScaler scaler, {
  required TextStyle? titleStyle,
  required TextStyle? lineStyle,
}) {
  final line = math.max(
    splitLineIconSize,
    splitTextHeight(scaler, lineStyle, 1, fallbackSize: 16),
  );
  return splitTextHeight(
        scaler,
        titleStyle,
        splitTitleLines,
        fallbackSize: 26,
      ) +
      splitLineGap +
      line +
      splitLineGap +
      line;
}

/// Everything under the cover that has a fixed height; [seekHeight] is the
/// seek slot's.
double splitReserve(
  TextScaler scaler, {
  required TextStyle? titleStyle,
  required TextStyle? lineStyle,
  required double seekHeight,
}) =>
    splitCoverGap +
    splitTextReserve(scaler, titleStyle: titleStyle, lineStyle: lineStyle) +
    splitSeekGap +
    seekHeight +
    splitTransportGap +
    splitTransportHeight;

/// Side of the cover for a column [innerWidth] wide in a body [bodyHeight]
/// high: the narrowest of the width, 500 and what the fixed reserve leaves,
/// never under 96.
double splitCoverSide({
  required double innerWidth,
  required double bodyHeight,
  required double reserve,
}) {
  final byHeight = bodyHeight - reserve - splitColumnPadding.vertical;
  return math
      .min(math.min(innerWidth, splitCoverMaxSide), byHeight)
      .clamp(splitCoverMinSide, double.infinity);
}
