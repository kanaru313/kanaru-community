import 'package:material_ui/material_ui.dart';

import 'k_detail_line.dart';

/// Description under a detail hero: plain text, clamped to [maxLines] lines
/// with a "more" button only when the text really overflows; the button
/// opens it in place and turns into "less".
///
/// Controlled: the caller keeps [expanded] (so a page can remember it) and
/// passes the labels (the design system has no localization).
class KDetailDescription extends StatelessWidget {
  const KDetailDescription({
    super.key,
    required this.text,
    required this.expanded,
    required this.onExpandedChanged,
    required this.moreLabel,
    required this.lessLabel,
  });

  final String text;
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;
  final String moreLabel;
  final String lessLabel;

  /// Lines shown while collapsed.
  static const int maxLines = 3;

  /// Widest the text grows (about 75 characters per line).
  static const double maxWidth = 640;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: scheme.onSurface);
    // Collapsed text reads as one paragraph: breaks become spaces.
    final flat = text.replaceAll(RegExp(r'\s*\n+\s*'), ' ');
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final painter = TextPainter(
              text: TextSpan(text: flat, style: style),
              textDirection: direction,
              textScaler: scaler,
              maxLines: maxLines,
            )..layout(maxWidth: constraints.maxWidth);
            final overflows = painter.didExceedMaxLines;
            painter.dispose();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (expanded)
                  Text(text, style: style)
                else
                  Text(
                    flat,
                    style: style,
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (overflows)
                  // Last in its parents: the touch area grows upward only.
                  KVerticalHitExtension(
                    upwardOnly: true,
                    child: TextButton(
                      onPressed: () => onExpandedChanged(!expanded),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: scheme.primary,
                        textStyle: style?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      child: Text(expanded ? lessLabel : moreLabel),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
