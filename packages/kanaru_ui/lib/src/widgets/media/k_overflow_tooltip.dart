import 'package:material_ui/material_ui.dart';

/// One-line [text] that ellipsizes when it does not fit. Its tooltip shows
/// [message] always, and puts the full [text] above it only when the line is
/// cut, so a short line is not repeated.
class KOverflowTooltip extends StatelessWidget {
  const KOverflowTooltip({
    super.key,
    required this.text,
    required this.message,
    this.style,
  });

  final String text;

  /// Always in the tooltip (after the full text when the line is cut).
  final String message;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final resolved = DefaultTextStyle.of(context).style.merge(style);
    return LayoutBuilder(
      builder: (context, box) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: resolved),
          maxLines: 1,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        final cut = painter.width > box.maxWidth;
        painter.dispose();
        return Tooltip(
          message: cut ? '$text\n$message' : message,
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        );
      },
    );
  }
}
