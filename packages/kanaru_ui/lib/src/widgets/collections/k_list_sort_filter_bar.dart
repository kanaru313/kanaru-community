import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../layout/form_factor.dart';
import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import '../k_gap.dart';

/// Bar above every list: [leading] group on the left (count, play buttons,
/// view switch, breadcrumb), the sort chip and the filter toggle on the
/// right. No scrolling of its own; the page makes it sticky if it wants.
class KListSortFilterBar extends StatefulWidget {
  const KListSortFilterBar({
    super.key,
    required this.leading,
    required this.criterionLabel,
    required this.ascending,
    required this.onSortPressed,
    required this.filterOpen,
    required this.onFilterToggle,
    this.sortTooltip,
    this.filterTooltip,
  });

  /// Left group; takes the room the right group leaves.
  final Widget leading;

  /// Name of the criterion in use.
  final String criterionLabel;

  /// Direction shown as a small arrow next to [criterionLabel].
  final bool ascending;

  /// Opens the sort popover; [anchor] is the chip to attach it to
  /// (`showKSortPopover(anchor: anchor, ...)`).
  final void Function(GlobalKey anchor) onSortPressed;
  final bool filterOpen;
  final VoidCallback onFilterToggle;
  final String? sortTooltip;
  final String? filterTooltip;

  static const double heightMobile = 52;
  static const double heightDesktop = 48;

  @override
  State<KListSortFilterBar> createState() => _KListSortFilterBarState();
}

class _KListSortFilterBarState extends State<KListSortFilterBar> {
  final GlobalKey _chipKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mobile = FormFactor.of(context) == FormFactor.mobile;
    final height = mobile
        ? KListSortFilterBar.heightMobile
        : KListSortFilterBar.heightDesktop;
    final filterButton = widget.filterOpen
        ? IconButton.filledTonal
        : IconButton.new;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: LayoutBuilder(
        // The chip is at most half of the bar (and leaves room for leading actions
        // such as the mobile play/shuffle buttons): a long label is ellipsized.
        builder: (context, bar) {
          final leadingMin = mobile ? 96.0 : 0.0;
          final filterWidth = mobile ? 48.0 : 40.0;
          final gaps = KSpace.x3 + KSpace.x2;
          final maxChipWidth = math.max(
            48.0,
            math.min(
              bar.maxWidth / 2,
              bar.maxWidth - leadingMin - filterWidth - gaps,
            ),
          );
          return Row(
            children: [
              Expanded(child: widget.leading),
              const KGap(KSpace.x3),
              Semantics(
                button: true,
                label: widget.sortTooltip == null
                    ? widget.criterionLabel
                    : '${widget.sortTooltip}: ${widget.criterionLabel}',
                excludeSemantics: true,
                child: Tooltip(
                  message: widget.sortTooltip ?? '',
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxChipWidth),
                    child: InkWell(
                      key: _chipKey,
                      borderRadius: KRadius.full,
                      onTap: () => widget.onSortPressed(_chipKey),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: mobile ? 48 : 40),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: KSpace.x3,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  widget.criterionLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(color: scheme.onSurface),
                                ),
                              ),
                              const KGap(KSpace.x1),
                              Icon(
                                widget.ascending
                                    ? KIcons.sortAsc
                                    : KIcons.sortDesc,
                                size: 14,
                                color: scheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const KGap(KSpace.x2),
              filterButton(
                tooltip: widget.filterTooltip,
                isSelected: widget.filterOpen,
                onPressed: widget.onFilterToggle,
                icon: const Icon(KIcons.filter),
              ),
            ],
          );
        },
      ),
    );
  }
}
