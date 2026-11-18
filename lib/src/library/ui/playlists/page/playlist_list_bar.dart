import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/browse/sort_order.dart';
import '../../browse/library_labels.dart';
import '../../browse/library_list_scaffold.dart';

/// The sticky bar above the rows: `N songs · length` (or `3 / 12 songs`
/// while filtering), the sort chip, reverse and the filter toggle. Only a
/// playlist with entries has one.
class PlaylistListBar extends StatelessWidget {
  const PlaylistListBar({
    super.key,
    required this.countText,
    required this.sort,
    required this.onSortPressed,
    required this.onReverse,
    required this.filterOpen,
    required this.onFilterToggle,
    this.editLead,
  });

  /// Already worded.
  final String countText;
  final SortOrder sort;
  final void Function(GlobalKey anchor) onSortPressed;
  final VoidCallback onReverse;
  final bool filterOpen;
  final VoidCallback onFilterToggle;

  /// Edit mode: the bar is only this text (the count and the fixed order),
  /// in the same box, with no sort or filter controls. Null: the usual bar.
  final String? editLead;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lead = editLead;
    final leading = Text(
      lead ?? countText,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
    return KStickyBarSliver(
      height: MediaQuery.textScalerOf(context).scale(KListSortFilterBar.height),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: libraryBarGutter(context)),
        child: lead != null
            ? Align(alignment: AlignmentDirectional.centerStart, child: leading)
            : KListSortFilterBar(
                leading: leading,
                sortLabel: sortOrderLabel(l10n, sort),
                ascending: !sort.primary.descending,
                onSortPressed: onSortPressed,
                onReverse: onReverse,
                reverseTooltip: l10n.libraryOrderReverse,
                filterOpen: filterOpen,
                onFilterToggle: onFilterToggle,
                sortTooltip: l10n.libraryOrderTooltip,
                filterTooltip: l10n.libraryFilter,
              ),
      ),
    );
  }
}
