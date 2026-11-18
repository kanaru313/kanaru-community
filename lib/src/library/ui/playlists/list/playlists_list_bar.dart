import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/browse/list_sort.dart';
import '../../../domain/browse/list_view_prefs.dart';
import '../../../domain/browse/sort_order.dart';
import '../../browse/library_labels.dart';
import '../../browse/library_list_scaffold.dart';
import '../../collections/collection_parts.dart';

/// Height of the pinned bar: the bar at the current text scale, plus the
/// filter field and its gap while the field is open.
double playlistsBarHeight(TextScaler scaler, {required bool filterOpen}) =>
    scaler.scale(KListSortFilterBar.height) +
    (filterOpen ? KFilterField.height + KSpace.x2 : 0);

/// Bar above the playlists: count, grid / list switch, sort chip, reverse,
/// filter toggle, and the filter field under it while it is open.
class PlaylistsListBar extends StatelessWidget {
  const PlaylistsListBar({
    super.key,
    required this.countText,
    required this.view,
    required this.sort,
    required this.onSortPressed,
    required this.onReverse,
    required this.filterOpen,
    required this.onFilterToggle,
    required this.filterController,
    required this.onFilterChanged,
    required this.onFilterClose,
  });

  /// Already worded: `5 playlists` or `2 / 5 playlists`.
  final String countText;
  final CollectionView view;
  final SortOrder sort;
  final void Function(GlobalKey anchor) onSortPressed;
  final VoidCallback onReverse;
  final bool filterOpen;
  final VoidCallback onFilterToggle;
  final TextEditingController filterController;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onFilterClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Rows have the bar's gutter plus their own padding; the grid its gutter.
    final gutter = view == CollectionView.list
        ? libraryBarGutter(context)
        : libraryGutter(context);
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: KListSortFilterBar(
            leading: CollectionBarLeading(text: countText),
            view: CollectionViewSwitch(list: BrowseList.playlists, view: view),
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
        if (filterOpen)
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, 0, gutter, KSpace.x2),
            child: KFilterField(
              controller: filterController,
              hint: l10n.playlistFilterHint,
              closeTooltip: l10n.libraryFilterClose,
              onChanged: onFilterChanged,
              onClose: onFilterClose,
            ),
          ),
      ],
    );
  }
}
