import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/play_context.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/song_scope.dart';
import '../../state/browse/list_prefs_providers.dart';
import '../browse/filter_debouncer.dart';
import '../browse/library_labels.dart';
import '../browse/library_list_scaffold.dart';
import '../browse/list_sort_dialog.dart';
import '../browse/list_sort_popover.dart';
import 'detail_songs_count.dart';
import '../selection/selection_inset.dart';
import '../songs/song_list.dart';

/// The songs part of a detail page: a sticky list bar (`N songs · length`,
/// sort chip, filter toggle), the filter field and the rows, as slivers for
/// the page's own scroll view. Owns the filter of the page, which is never
/// stored; on the mobile shell Back closes the field first.
///
/// The sort is remembered per [list] (`albumTracks` or `detailSongs`).
/// [durationMs] is the length of the whole scope, shown while no filter is
/// typed.
class DetailSongsHost extends ConsumerStatefulWidget {
  const DetailSongsHost({
    super.key,
    required this.list,
    required this.item,
    required this.scope,
    required this.playContext,
    required this.builder,
    this.hasSongs = true,
    this.durationMs,
    this.showNumber = false,
  });

  final BrowseList list;

  /// Id of the page's item: its sort is remembered for the session.
  final String item;
  final SongScope scope;

  /// False leaves the songs part out (an artist with no song of its own). The
  /// host stays in the tree either way, so the filter and scroll of the page
  /// survive the first song arriving.
  final bool hasSongs;
  final PlayContext playContext;
  final int? durationMs;
  final bool showNumber;

  /// Builds the page around the song [slivers].
  final Widget Function(BuildContext context, List<Widget> slivers) builder;

  @override
  ConsumerState<DetailSongsHost> createState() => _DetailSongsHostState();
}

class _DetailSongsHostState extends ConsumerState<DetailSongsHost> {
  final TextEditingController _controller = TextEditingController();
  bool _filterOpen = false;
  String _filter = '';
  final FilterDebouncer _debounce = FilterDebouncer();
  final ListSortGuard _sortGuard = ListSortGuard();

  @override
  void dispose() {
    _sortGuard.close();
    _debounce.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _toggleFilter() {
    if (_filterOpen) {
      _closeFilter();
    } else {
      setState(() => _filterOpen = true);
    }
  }

  void _closeFilter() {
    _debounce.cancel();
    setState(() {
      _controller.clear();
      _filter = '';
      _filterOpen = false;
    });
  }

  /// The container is taken now: the sort box is on the root navigator and
  /// can outlive this page, whose `ref` is dead by then.
  Future<void> _openSort(GlobalKey anchor) {
    final container = ProviderScope.containerOf(context);
    final page = (list: widget.list, item: widget.item);
    return openListSort(
      context,
      list: widget.list,
      anchor: anchor,
      guard: _sortGuard,
      read: () => container.read(detailSortProvider(page)),
      write: (sort) =>
          container.read(detailSortOverridesProvider.notifier).set(page, sort),
      reset: () async =>
          container.read(detailSortOverridesProvider.notifier).clear(page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gutter = libraryBarGutter(context);
    final page = (list: widget.list, item: widget.item);
    final sort = ref.watch(detailSortProvider(page));
    final barHeight = MediaQuery.textScalerOf(context)
        .scale(KListSortFilterBar.height);
    final slivers = <Widget>[
      if (widget.hasSongs) ...[
        KStickyBarSliver(
          height: barHeight,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: KListSortFilterBar(
              leading: DetailSongsCount(
                scope: widget.scope,
                sort: sort,
                filter: _filter,
                durationMs: widget.durationMs,
              ),
              sortLabel: sortOrderLabel(l10n, sort),
              ascending: !sort.primary.descending,
              onSortPressed: _openSort,
              // The order at press time, not this build's: two taps in one frame
              // must flip twice.
              onReverse: () => unawaited(
                ref
                    .read(detailSortOverridesProvider.notifier)
                    .set(page, ref.read(detailSortProvider(page)).reversed()),
              ),
              reverseTooltip: l10n.libraryOrderReverse,
              filterOpen: _filterOpen,
              onFilterToggle: _toggleFilter,
              sortTooltip: l10n.libraryOrderTooltip,
              filterTooltip: l10n.libraryFilter,
            ),
          ),
        ),
        if (_filterOpen)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, KSpace.x2),
              child: KFilterField(
                controller: _controller,
                hint: l10n.libraryFilterSongsHint,
                closeTooltip: l10n.libraryFilterClose,
                onChanged: (text) => _debounce(text, (text) {
                  if (mounted) setState(() => _filter = text);
                }),
                onClose: _closeFilter,
              ),
            ),
          ),
        SongSlivers(
          scope: widget.scope,
          sort: sort,
          filter: _filter,
          playContext: widget.playContext,
          showNumber: widget.showNumber,
        ),
      ],
      const SelectionInsetSliver(),
    ];
    return PopScope(
      canPop: !_filterOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _filterOpen) _closeFilter();
      },
      child: widget.builder(context, slivers),
    );
  }
}
