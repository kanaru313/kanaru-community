import 'package:material_ui/material_ui.dart';

import '../tokens/k_motion.dart';
import '../tokens/k_shape.dart';
import '../tokens/k_space.dart';
import 'k_press_surface.dart';
import 'k_segmented.dart' show KSegment;

/// Visible height of a compact [KSegmentedOutlined].
const double kSegmentedCompactHeight = 24;

/// Visible height of a regular [KSegmentedOutlined].
const double kSegmentedRegularHeight = 36;

/// Height of the tap area of each segment (the pill is centred in it).
const double kSegmentedCompactHit = 48;

/// How big a [KSegmentedOutlined] is.
enum KSegmentedOutlinedSize {
  /// 24 dp pill, `labelSmall`, as wide as its labels: a caption-row choice
  /// (the [Dưới dòng | Thay dòng] beside "Xem trước").
  compact,

  /// 36 dp pill, `labelLarge`, segments share the full width: a choice of
  /// its own under a section title ("Áp dụng cho").
  regular,
}

/// M3 disabled content opacity.
const double _kDisabledOpacity = 0.38;

/// The outlined sibling of `KSegmented`: 2 or 3 short values, one chosen, in
/// two [KSegmentedOutlinedSize]s. A 1 dp `outline` stroke around the group and between the
/// segments, fully rounded ends; only the chosen segment is tinted
/// (`secondaryContainer`), no check mark, no weight change. Same on every
/// shell.
///
/// The pill is 24 or 36 dp high but each segment's tap area is 48 dp tall (and
/// at least 48 wide), so the widget lays out 48 dp tall with the pill centred.
/// A segment with `enabled: false` is dimmed and inert.
/// Tab walks the segments, Enter / Space choose the focused one. Semantics:
/// one node per segment, `selected` for the chosen, in one exclusive group.
/// A null [onChanged] dims the whole control and makes it inert.
class KSegmentedOutlined<T> extends StatelessWidget {
  const KSegmentedOutlined({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    this.size = KSegmentedOutlinedSize.compact,
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

  final KSegmentedOutlinedSize size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stroke = BorderSide(color: scheme.outline);
    final last = segments.length - 1;
    final regular = size == KSegmentedOutlinedSize.regular;
    final group = Semantics(
      container: true,
      label: semanticLabel,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisSize: regular ? MainAxisSize.max : MainAxisSize.min,
            children: [
              for (var i = 0; i < segments.length; i++)
                Flexible(
                  fit: regular ? FlexFit.tight : FlexFit.loose,
                  child: _OutlinedSegment(
                    regular: regular,
                    enabled: segments[i].enabled,
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
                  child: SizedBox(
                    height: regular
                        ? kSegmentedRegularHeight
                        : kSegmentedCompactHeight,
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

class _OutlinedSegment extends StatelessWidget {
  const _OutlinedSegment({
    required this.regular,
    required this.enabled,
    required this.label,
    required this.selected,
    required this.first,
    required this.last,
    required this.divider,
    required this.onTap,
  });

  final bool regular;
  final bool enabled;
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
    final fg = selected
        ? scheme.onSecondaryContainer
        : regular
        ? scheme.onSurface
        : scheme.onSurfaceVariant;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : KMotion.fast;
    const end = Radius.circular(999);
    final labelText = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style:
          (regular
                  ? Theme.of(context).textTheme.labelLarge
                  : Theme.of(context).textTheme.labelSmall)
              ?.copyWith(color: fg, fontWeight: FontWeight.w500),
    );
    final segment = KPressSurface(
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
          widthFactor: regular ? null : 1,
          child: AnimatedContainer(
            duration: duration,
            curve: KMotion.emphasized,
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                scheme.onSurface.withValues(alpha: overlay),
                selected ? scheme.secondaryContainer : const Color(0x00000000),
              ),
              borderRadius: first || last
                  ? BorderRadiusDirectional.horizontal(
                      start: first ? end : Radius.zero,
                      end: last ? end : Radius.zero,
                    )
                  : null,
              border: first ? null : BorderDirectional(start: divider),
            ),
            // Compact: 4 dp above and below the 16 dp label line make the
            // 24 dp pill. Regular: at least the 36 dp pill, label centred.
            padding: EdgeInsets.symmetric(
              horizontal: regular ? KSpace.x2 : KSpace.x2 + 2,
              vertical: regular ? 0 : KSpace.x1,
            ),
            child: regular
                ? ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: kSegmentedRegularHeight,
                    ),
                    child: Center(heightFactor: 1, child: labelText),
                  )
                : labelText,
          ),
        ),
      ),
    );
    return enabled
        ? segment
        : Opacity(opacity: _kDisabledOpacity, child: segment);
  }
}
