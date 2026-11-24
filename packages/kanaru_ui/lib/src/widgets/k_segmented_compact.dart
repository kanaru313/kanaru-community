import 'package:material_ui/material_ui.dart';

import '../tokens/k_motion.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';
import 'k_press_surface.dart';
import 'k_segmented.dart' show KSegment;

/// Visible height of a [KSegmentedCompact]; grows with the text scale.
const double kSegmentedCompactHeight = 24;

/// Height of the tap area of each segment (the pill is centred in it).
const double kSegmentedCompactHit = 48;

/// M3 disabled content opacity.
const double _kDisabledOpacity = 0.38;

/// The small outlined sibling of `KSegmented`, for a caption row (the
/// [Dưới dòng | Thay dòng] choice beside "Xem trước"): 2 or 3 short values,
/// one chosen. A 1 dp `outline` stroke around the group and between the
/// segments, fully rounded ends; only the chosen segment is tinted
/// (`secondaryContainer`), no check mark, no weight change. Same on every
/// shell.
///
/// The pill is 24 dp high but each segment's tap area is 48 dp tall (and at
/// least 48 wide), so the widget lays out 48 dp tall with the pill centred.
/// Tab walks the segments, Enter / Space choose the focused one. Semantics:
/// one node per segment, `selected` for the chosen, in one exclusive group.
/// A null [onChanged] dims the whole control and makes it inert.
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

  /// Null: disabled (dimmed, not focusable, not tappable).
  final ValueChanged<T>? onChanged;

  /// Spoken name of the whole group.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stroke = BorderSide(color: scheme.outline);
    final last = segments.length - 1;
    final group = Semantics(
      container: true,
      label: semanticLabel,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < segments.length; i++)
                Flexible(
                  child: _CompactSegment(
                    label: segments[i].label,
                    selected: segments[i].value == value,
                    first: i == 0,
                    last: i == last,
                    divider: stroke,
                    onTap: onChanged != null && segments[i].enabled
                        ? () => onChanged!(segments[i].value)
                        : null,
                  ),
                ),
            ],
          ),
          // The group outline over the pills' fill, never in the way of taps.
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      borderRadius: KRadius.full,
                      side: stroke,
                    ),
                  ),
                  child: const SizedBox(
                    height: kSegmentedCompactHeight,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return onChanged == null
        ? Opacity(opacity: _kDisabledOpacity, child: group)
        : group;
  }
}

class _CompactSegment extends StatelessWidget {
  const _CompactSegment({
    required this.label,
    required this.selected,
    required this.first,
    required this.last,
    required this.divider,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool first;
  final bool last;
  final BorderSide divider;

  /// Null: the segment is disabled.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : KMotion.fast;
    const end = Radius.circular(999);
    return KPressSurface(
      onPressed: onTap,
      radius: KRadius.full,
      semanticLabel: label,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      builder: (context, overlay, _) => ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: kSegmentedCompactHit,
          minWidth: kSegmentedCompactHit,
        ),
        child: Center(
          heightFactor: 1,
          widthFactor: 1,
          child: AnimatedContainer(
            duration: duration,
            curve: KMotion.emphasized,
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                scheme.onSurface.withValues(alpha: overlay),
                selected ? scheme.secondaryContainer : const Color(0x00000000),
              ),
              borderRadius: BorderRadiusDirectional.horizontal(
                start: first ? end : Radius.zero,
                end: last ? end : Radius.zero,
              ),
              border: first ? null : BorderDirectional(start: divider),
            ),
            // 4 dp above and below the 16 dp label line: the 24 dp pill.
            padding: const EdgeInsets.symmetric(
              horizontal: KSpace.x2 + 2,
              vertical: KSpace.x1,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: fg, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}
