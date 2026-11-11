import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/play_context.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/song_scope.dart';
import '../../state/browse/list_prefs_providers.dart';
import '../../state/browse/song_list_providers.dart';
import '../browse/filter_debouncer.dart';
import '../browse/library_labels.dart';
import '../browse/library_list_scaffold.dart';
import '../browse/list_sort_popover.dart';
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
    this.showDetected = false,
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
  final bool showDetected;

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

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gutter = libraryGutter(context);
    final page = (list: widget.list, item: widget.item);
    final sort = ref.watch(detailSortProvider(page));
    final mobile = FormFactor.of(context) == FormFactor.mobile;
    final barHeight = MediaQuery.textScalerOf(context).scale(
      mobile
          ? KListSortFilterBar.heightMobile
          : KListSortFilterBar.heightDesktop,
    );
    final slivers = <Widget>[
      if (widget.hasSongs) ...[
        KStickyBarSliver(
          height: math.max(barHeight, KListSortFilterBar.heightMobile),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: KListSortFilterBar(
              leading: _CountText(
                scope: widget.scope,
                sort: sort,
                filter: _filter,
                durationMs: widget.durationMs,
              ),
              criterionLabel: sortCriterionLabel(l10n, sort.criterion),
              ascending: !sort.descending,
              onSortPressed: (anchor) => openListSort(
                context,
                list: widget.list,
                anchor: anchor,
                read: () => ref.read(detailSortProvider(page)),
                write: (sort) => ref
                    .read(detailSortOverridesProvider.notifier)
                    .set(page, sort),
              ),
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
          showDetected: widget.showDetected,
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

/// `N songs · length`, or `6 / 34 songs` while a filter narrows the list.
class _CountText extends ConsumerWidget {
  const _CountText({
    required this.scope,
    required this.sort,
    required this.filter,
    required this.durationMs,
  });

  final SongScope scope;
  final SortSpec sort;
  final String filter;
  final int? durationMs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final shown = ref
        .watch(songIdsProvider((scope: scope, sort: sort, filter: filter)))
        .value
        ?.length;
    final total = ref.watch(songCountProvider(scope)).value;
    final String text;
    if (shown == null) {
      text = '';
    } else if (filter.isNotEmpty && total != null) {
      text = l10n.libraryCountOf(shown, total, l10n.libraryUnitSongs);
    } else {
      final length = durationMs;
      text = length == null
          ? l10n.librarySongCount(shown)
          : '${l10n.librarySongCount(shown)} · '
                '${formatTotalDuration(l10n, length)}';
    }
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}
