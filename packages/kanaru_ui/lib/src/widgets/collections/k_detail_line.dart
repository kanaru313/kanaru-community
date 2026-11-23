import 'package:material_ui/material_ui.dart';

import '../k_text_link.dart';

export '../k_vertical_hit_extension.dart';

/// Second line of a detail hero: [text] (a link when [onTap] is set) and an
/// optional plain [trailing] after ` · ` (an album's year).
///
/// Each part is one line with its own ellipsis, so a long name is cut before
/// the year. The link is a [KTextLink] (the one link look of the app) with a
/// touch area at least 48 dp tall that overlaps the lines around it without
/// making the row taller.
///
/// [trailing] is meant to be short (a year). Not usable inside
/// `IntrinsicHeight` / `IntrinsicWidth`: it uses a `LayoutBuilder`.
class KDetailLine extends StatelessWidget {
  const KDetailLine({super.key, required this.text, this.onTap, this.trailing});

  final String text;

  /// Makes [text] a link.
  final VoidCallback? onTap;

  /// Plain text after the link, e.g. the year.
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodyLarge
        ?.copyWith(fontWeight: FontWeight.w500, color: scheme.onSurface);
    final tap = onTap;
    final line = LayoutBuilder(
      builder: (context, c) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: tap == null
                ? Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style,
                  )
                : KTextLink(text: text, style: style, onTap: tap),
          ),
          if (trailing != null)
            // Keeps its natural width (a year is never cut); only text wider
            // than the whole line is ellipsized.
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: c.hasBoundedWidth ? c.maxWidth : double.infinity,
              ),
              child: Text(
                ' · $trailing',
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
        ],
      ),
    );
    // The row rejects touches outside its box, so the reach is added around the
    // whole line, by the same rule as the link's own.
    return tap == null
        ? line
        : KVerticalHitExtension(
            minHeight: KTextLink.targetHeight(context),
            child: line,
          );
  }
}
