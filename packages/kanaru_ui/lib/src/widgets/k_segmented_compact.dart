import 'package:material_ui/material_ui.dart';

import '../tokens/k_motion.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';
import 'k_press_surface.dart';
import 'k_segmented.dart' show KSegment;

/// Visible height of a [KSegmentedCompact]; grows with the text scale.
const double kSegmentedCompactHeight = 24;

/// The small outlined sibling of `KSegmented`, for a caption row (the
/// [Dưới dòng | Thay dòng] choice beside "Xem trước"): 2 or 3 short values,
/// one chosen. A 1 dp `outline` stroke around the group and between the
/// segments, fully rounded ends; only the chosen segment is tinted
/// (`secondaryContainer`), no check mark. Same on every shell.
///
/// Tab walks the segments, Enter / Space choose the focused one. Semantics:
/// one node per segment, `selected` for the chosen, in one exclusive group.
/// The tap area is the visible 24 dp (a caption-row control, not a main
/// action); use `KSegmented` where touch is the main input.
class KSegmentedCompact<T> extends StatelessWidget {
  const KSegmentedCompact({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  }) : assert(
         segments.length >= 2 && segments.length <= 3,
         'a compact segmented control holds 2 or 3 segments',
       );

  final List<KSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;

  /// Spoken name of the whole group.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stroke = BorderSide(color: scheme.outline);
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Container(
        constraints: const BoxConstraints(minHeight: kSegmentedCompactHeight),
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            borderRadius: KRadius.full,
            side: stroke,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < segments.length; i++) ...[
                if (i > 0)
                  VerticalDivider(width: 1, thickness: 1, color: stroke.color),
                _CompactSegment(
                  label: segments[i].label,
                  selected: segments[i].value == value,
                  onTap: segments[i].enabled
                      ? () => onChanged(segments[i].value)
                      : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactSegment extends StatelessWidget {
  const _CompactSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;

  /// Null: the segment is disabled.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : KMotion.fast;
    return Flexible(
      child: KPressSurface(
        onPressed: onTap,
        radius: KRadius.full,
        semanticLabel: label,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        builder: (context, overlay, _) => AnimatedContainer(
          duration: duration,
          curve: KMotion.emphasized,
          color: Color.alphaBlend(
            scheme.onSurface.withValues(alpha: overlay),
            selected ? scheme.secondaryContainer : const Color(0x00000000),
          ),
          padding: const EdgeInsets.symmetric(horizontal: KSpace.x2 + 2),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
