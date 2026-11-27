import 'package:material_ui/material_ui.dart';

/// Space between two rows of a capped song list in the chat.
const double chatListGap = 2;

/// Height of one compact song row (cover, title, artist) at the current text
/// size: the cover plus [vertical] padding on both sides, or, when the two
/// text lines grow past it (large text), the lines plus the padding. A capped
/// list is exactly eight of these tall.
double chatSongRowExtent(
  BuildContext context, {
  required double cover,
  required double vertical,
}) {
  final text = Theme.of(context).textTheme;
  final scaler = MediaQuery.textScalerOf(context);
  double line(TextStyle? s) {
    final size = s?.fontSize ?? 14;
    // The font size is scaled, then the line height multiplies it: a
    // nonlinear scaler does not give the same as scaling the product.
    return scaler.scale(size) * (s?.height ?? 1.4);
  }

  final lines = line(text.bodyMedium) + line(text.bodySmall);
  return (lines > cover ? lines : cover) + 2 * vertical;
}

/// Height of one text line of a capped result list in a tool card.
double chatTextRowExtent(BuildContext context, TextStyle? style) {
  final scaler = MediaQuery.textScalerOf(context);
  final size = style?.fontSize ?? 12;
  return scaler.scale(size) * (style?.height ?? 1.4) + 8;
}
