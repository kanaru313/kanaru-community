import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/list_view_prefs.dart';
import '../../state/browse/list_prefs_providers.dart';
import 'library_labels.dart';
import 'library_list_scaffold.dart';
import 'list_sort_popover.dart';

/// What a list page shows right now: remembered sort and layout, the text
/// typed in the filter field (empty when it is closed) and whether the field
/// is open (a page with a Back rule of its own yields while it is).
typedef LibraryListInput = ({
  SortSpec sort,
  CollectionView view,
  String filter,
  bool filterOpen,
});

/// The two halves a page puts into [LibraryListFrame]: the left group of the
/// bar (counts, play buttons, view switch, breadcrumb) and the list.
typedef LibraryListContent = ({Widget leading, Widget body});

/// Bar above a list (sort chip, filter toggle), the filter field under it and
/// the page [builder]'s list below. Owns the filter state of the page, which
/// is never persisted: closing the field clears it.
///
/// Back on the mobile shell first closes the filter field (a sort popover is
/// its own route and closes before that).
class LibraryListFrame extends ConsumerStatefulWidget {
  const LibraryListFrame({
    super.key,
    required this.list,
    required this.filterHint,
    required this.builder,
  });

  final BrowseList list;
  final String filterHint;
  final LibraryListContent Function(
    BuildContext context,
    LibraryListInput input,
  )
  builder;

  @override
  ConsumerState<LibraryListFrame> createState() => _LibraryListFrameState();
}

class _LibraryListFrameState extends ConsumerState<LibraryListFrame> {
  final TextEditingController _controller = TextEditingController();
  bool _filterOpen = false;
  String _filter = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleFilter() {
    setState(() {
      if (_filterOpen) _controller.clear();
      _filterOpen = !_filterOpen;
      if (!_filterOpen) _filter = '';
    });
  }

  void _closeFilter() => setState(() {
    _controller.clear();
    _filter = '';
    _filterOpen = false;
  });

  Future<void> _openSort(GlobalKey anchor) {
    final notifier = ref.read(libraryListViewsProvider.notifier);
    final list = widget.list;
    return openListSort(
      context,
      list: list,
      anchor: anchor,
      read: () => ref.read(libraryListViewsProvider).of(list).sort,
      write: (sort) => notifier.setSort(list, sort),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gutter = libraryGutter(context);
    final prefs = ref.watch(
      libraryListViewsProvider.select((v) => v.of(widget.list)),
    );
    final content = widget.builder(context, (
      sort: prefs.sort,
      view: prefs.view,
      filter: _filter,
      filterOpen: _filterOpen,
    ));
    return PopScope(
      canPop: !_filterOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _filterOpen) _closeFilter();
      },
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: KListSortFilterBar(
              leading: content.leading,
              criterionLabel: sortCriterionLabel(l10n, prefs.sort.criterion),
              ascending: !prefs.sort.descending,
              onSortPressed: _openSort,
              filterOpen: _filterOpen,
              onFilterToggle: _toggleFilter,
              sortTooltip: l10n.libraryOrderTooltip,
              filterTooltip: l10n.libraryFilter,
            ),
          ),
          if (_filterOpen)
            Padding(
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, KSpace.x2),
              child: KFilterField(
                controller: _controller,
                hint: widget.filterHint,
                closeTooltip: l10n.libraryFilterClose,
                onChanged: (text) => setState(() => _filter = text),
                onClose: _closeFilter,
              ),
            ),
          Expanded(child: content.body),
        ],
      ),
    );
  }
}
