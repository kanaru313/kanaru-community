import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../layout/form_factor.dart';
import '../../tokens/k_icon_size.dart';
import '../../tokens/k_space.dart';
import '../k_gap.dart';
import '../k_icon_button.dart';
import 'k_list_sort_chip.dart';

/// Bar above every list: [leading] group on the left (count, play buttons,
/// breadcrumb), then on the right the optional [view] switch, the sort chip
/// ([sortLabel] only), the reverse button and the filter toggle (small icon
/// buttons, the same on every shell). [height] tall on both shells. No
/// scrolling of its own; the page makes it sticky if it wants.
///
/// [criterionLabel] (with a direction arrow in the chip, 52 / 48 dp tall) is
/// the older layout, kept until the callers move to [sortLabel].
class KListSortFilterBar extends StatefulWidget {
  const KListSortFilterBar({
    super.key,
    required this.leading,
    this.sortLabel,
    this.criterionLabel,
    required this.ascending,
    required this.onSortPressed,
    this.onReverse,
    this.reverseTooltip,
    required this.filterOpen,
    required this.onFilterToggle,
    this.sortTooltip,
    required this.filterTooltip,
    this.view,
  }) : assert(
         (sortLabel == null) != (criterionLabel == null),
         'give exactly one of sortLabel and criterionLabel',
       ),
       assert(
         onReverse == null || reverseTooltip != null,
         'a reverse button needs its reverseTooltip',
       );

  /// Left group; takes the room the right group leaves.
  final Widget leading;

  /// Chip text: the first criterion's name, `"Nghệ sĩ +2"` when several.
  final String? sortLabel;

  /// Older chip text (name only, the arrow shows [ascending]).
  final String? criterionLabel;

  /// Direction of the first criterion: picks the reverse button's arrow.
  final bool ascending;

  /// Opens the sort popover; [anchor] is the chip to attach it to
  /// (`showKSortPopover(anchor: anchor, ...)`).
  final void Function(GlobalKey anchor) onSortPressed;

  /// Reverses the whole order; null hides the reverse button.
  final VoidCallback? onReverse;
  final String? reverseTooltip;
  final bool filterOpen;
  final VoidCallback onFilterToggle;
  final String? sortTooltip;
  final String filterTooltip;

  /// The grid / list switch, left of the sort chip.
  final Widget? view;

  /// Width of a small icon button: icon plus padding 8 each side.
  static const double buttonSize = KIconSize.sm + 2 * KSpace.x2;

  /// Bar height on both shells.
  static const double height = 40;

  /// Sort chip height.
  static const double chipHeight = 32;

  static const double heightMobile = 52;
  static const double heightDesktop = 48;

  @override
  State<KListSortFilterBar> createState() => _KListSortFilterBarState();
}

class _KListSortFilterBarState extends State<KListSortFilterBar> {
  final GlobalKey _chipKey = GlobalKey();

  /// Shared by the light and the tonal filter button: they are different
  /// widgets, and the node keeps keyboard focus on the button across the swap.
  final FocusNode _filterFocus = FocusNode(debugLabel: 'filter button');

  @override
  void dispose() {
    _filterFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = FormFactor.of(context) == FormFactor.mobile;
    final legacy = widget.criterionLabel != null;
    final height = legacy
        ? (mobile
              ? KListSortFilterBar.heightMobile
              : KListSortFilterBar.heightDesktop)
        : KListSortFilterBar.height;
    final label = widget.sortLabel ?? widget.criterionLabel!;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: LayoutBuilder(
        // The chip is at most half of the bar (and leaves room for leading actions
        // such as the mobile play/shuffle buttons): a long label is ellipsized.
        builder: (context, bar) {
          final leadingMin = mobile ? 96.0 : 0.0;
          final buttons =
              1 +
              (widget.view == null ? 0 : 1) +
              (widget.onReverse == null ? 0 : 1);
          final gaps = KSpace.x3 + (legacy ? KSpace.x2 : 0);
          final maxChipWidth = math.max(
            48.0,
            math.min(
              bar.maxWidth / 2,
              bar.maxWidth -
                  leadingMin -
                  KListSortFilterBar.buttonSize * buttons -
                  gaps,
            ),
          );
          return Row(
            children: [
              Expanded(child: widget.leading),
              const KGap(KSpace.x3),
              ?widget.view,
              ListSortChip(
                chipKey: _chipKey,
                label: label,
                semanticLabel: widget.sortTooltip == null
                    ? label
                    : '${widget.sortTooltip}: $label',
                tooltip: widget.sortTooltip ?? '',
                maxWidth: maxChipWidth,
                minHeight: legacy
                    ? (mobile ? 48 : 40)
                    : KListSortFilterBar.chipHeight,
                arrowAscending: legacy ? widget.ascending : null,
                onTap: () => widget.onSortPressed(_chipKey),
              ),
              if (legacy) const KGap(KSpace.x2),
              if (widget.onReverse != null)
                KIconButton(
                  tooltip: widget.reverseTooltip!,
                  onPressed: widget.onReverse,
                  icon: widget.ascending ? KIcons.sortAsc : KIcons.sortDesc,
                  size: KIconSize.sm,
                  padding: const EdgeInsets.all(KSpace.x2),
                ),
              // Open: the tonal disc of a selected button, as big as the light
              // button's box. Closed: the light icon.
              if (widget.filterOpen)
                KIconButton.yieldSpace(
                  child: IconButton.filledTonal(
                    focusNode: _filterFocus,
                    tooltip: widget.filterTooltip,
                    isSelected: true,
                    onPressed: widget.onFilterToggle,
                    iconSize: KIconSize.sm,
                    style: IconButton.styleFrom(
                      fixedSize: const Size.square(
                        KListSortFilterBar.buttonSize,
                      ),
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(KIcons.filter),
                  ),
                )
              else
                KIconButton(
                  focusNode: _filterFocus,
                  tooltip: widget.filterTooltip,
                  onPressed: widget.onFilterToggle,
                  icon: KIcons.filter,
                  size: KIconSize.sm,
                  padding: const EdgeInsets.all(KSpace.x2),
                ),
            ],
          );
        },
      ),
    );
  }
}
