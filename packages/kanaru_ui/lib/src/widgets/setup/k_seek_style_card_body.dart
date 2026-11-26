import 'package:material_ui/material_ui.dart';

import '../../tokens/k_motion.dart';
import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import '../k_check_mark.dart';
import '../k_gap.dart';
import 'k_seek_style_card_parts.dart';

/// Gap under the preview well (the mockup's 6 px; the scale has no 6).
const double _wellGap = 6;

/// What a [KSeekStyleCard] shows inside its frame: the preview well, the title
/// line with the optional ★, the caption line and, on the chosen card, the
/// tick badge in the top-right corner and the action row. Excludes the text from semantics: the card
/// node carries the label.
class SeekStyleCardBody extends StatelessWidget {
  const SeekStyleCardBody({
    super.key,
    required this.preview,
    required this.title,
    required this.caption,
    required this.selected,
    required this.fallback,
    required this.action,
  });

  final Widget preview;
  final String title;
  final String caption;
  final bool selected;
  final KFallbackMark? fallback;
  final KCardAction? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final animate = !MediaQuery.disableAnimationsOf(context);
    final fallback = this.fallback;
    final action = this.action;
    final column = Padding(
      padding: const EdgeInsets.all(KSpace.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The well: a lighter inset box the picture sits in.
          ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: KRadius.md,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: KSpace.x1),
                child: Center(child: preview),
              ),
            ),
          ),
          const KGap(_wellGap),
          // Every title line is as tall as the ★ box, so cards with and
          // without a ★ stay the same height.
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: fallbackStarBox),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ExcludeSemantics(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: KSpace.x1),
                      child: Text(
                        title,
                        style: text.bodyLarge?.copyWith(
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                if (fallback != null) FallbackStarButton(mark: fallback),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: ExcludeSemantics(
                  child: Text(
                    caption,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (selected && action != null) ...[
            const KGap(KSpace.x2),
            SizedBox(
              width: double.infinity,
              child: CardActionButton(action: action),
            ),
          ],
        ],
      ),
    );
    // The tick badge sits in the card's top-right corner, as drawn.
    return Stack(
      children: [
        column,
        PositionedDirectional(
          top: KSpace.x2,
          end: KSpace.x2,
          child: AnimatedScale(
            scale: selected ? 1 : 0,
            duration: animate ? KMotion.fast : Duration.zero,
            curve: KMotion.emphasized,
            child: const KCheckMark(
              state: KCheckState.on,
              size: 22,
              style: KCheckMarkStyle.cover,
            ),
          ),
        ),
      ],
    );
  }
}
