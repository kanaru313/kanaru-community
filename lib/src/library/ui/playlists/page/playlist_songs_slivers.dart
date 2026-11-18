import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/browse/list_sort.dart';
import '../../../domain/playlists/playlist_models.dart';
import '../../../state/playlists/playlist_prefs_providers.dart';
import '../../browse/filter_debouncer.dart';
import '../../browse/library_labels.dart';
import '../../browse/library_list_scaffold.dart';
import '../../browse/list_sort_dialog.dart';
import '../../browse/list_sort_popover.dart';
import '../../selection/selection_inset.dart';
import '../menu/playlist_menu_rows.dart';
import 'playlist_list_bar.dart';
import 'playlist_missing_note.dart';
import 'playlist_page_actions.dart';
import 'playlist_page_states.dart';
import 'playlist_play_gate.dart';
import 'playlist_rows_sliver.dart';
import 'playlist_select_all_claim.dart';
import 'playlist_shown_entries.dart';

/// The songs part of a playlist page: the sticky list bar, the filter field,
/// the missing-songs note and the rows, as slivers for the page's own scroll
/// view; or the empty state. Owns what is never stored: the filter, and the
/// sort box (closed with the page). On the mobile shell Back closes the
/// filter field first.
///
/// The sort is remembered per playlist (`playlistTrackSortsProvider`).
class PlaylistSongsHost extends ConsumerStatefulWidget {
  const PlaylistSongsHost({
    super.key,
    required this.detail,
    required this.builder,
  });

  final PlaylistDetail detail;

  /// Builds the page around the song [slivers]. [serving] and [play] are the
  /// Play / shuffle gate, kept here because this host outlives the layout
  /// switch between the wide and the narrow page.
  final Widget Function(
    BuildContext context,
    List<Widget> slivers,
    bool serving,
    void Function({required bool shuffle}) play,
  )
  builder;

  @override
  ConsumerState<PlaylistSongsHost> createState() => _PlaylistSongsHostState();
}

class _PlaylistSongsHostState extends ConsumerState<PlaylistSongsHost> {
  final TextEditingController _controller = TextEditingController();
  final FilterDebouncer _debounce = FilterDebouncer();
  final ListSortGuard _sortGuard = ListSortGuard();
  final ShownEntriesMemo _memo = ShownEntriesMemo();
  bool _filterOpen = false;
  String _filter = '';

  /// A Play or shuffle press is being served: further presses are ignored.
  bool _serving = false;

  late final SelectAllClaim _claim;

  @override
  void initState() {
    super.initState();
    _claim = SelectAllClaim(context, ref);
  }

  Future<void> _play({required bool shuffle}) async {
    if (_serving) return;
    setState(() => _serving = true);
    try {
      await playPlaylistPage(
        ref,
        context,
        _uid,
        shuffle: shuffle,
        mounted: () => mounted,
      );
    } finally {
      if (mounted) setState(() => _serving = false);
    }
  }

  String get _uid => widget.detail.summary.uid;

  @override
  void dispose() {
    _claim.dispose();
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
    final uid = _uid;
    final sorts = container.read(playlistTrackSortsProvider.notifier);
    return openListSort(
      context,
      list: BrowseList.playlistTracks,
      anchor: anchor,
      guard: _sortGuard,
      read: () => container.read(playlistTrackSortProvider(uid)),
      write: (sort) => sorts.set(uid, sort),
      reset: () => sorts.reset(uid),
    );
  }

  /// The order at press time, not this build's: two taps in one frame must
  /// flip twice.
  void _reverse() => unawaited(
    ref
        .read(playlistTrackSortsProvider.notifier)
        .set(_uid, ref.read(playlistTrackSortProvider(_uid)).reversed()),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detail = widget.detail;
    final empty = detail.entries.isEmpty;
    if (empty && (_filterOpen || _filter.isNotEmpty)) {
      // The list emptied under an open filter: it has nothing to narrow.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _closeFilter();
      });
    }
    final sort = ref.watch(playlistTrackSortProvider(_uid));
    final filter = empty ? '' : _filter;
    final shown = _memo.of(detail, sort, filter);
    _claim.sync(
      (ModalRoute.isCurrentOf(context) ?? true) &&
          TickerMode.valuesOf(context).enabled,
      shown.playable,
      () => mounted,
    );
    final gutter = libraryBarGutter(context);
    final unavailable = detail.unavailableCount;
    final totals = playlistTotals(detail);
    final countText = filter.isNotEmpty
        ? l10n.libraryCountOf(
            shown.distinctCount,
            totals.count,
            l10n.libraryUnitSongs,
          )
        : '${l10n.librarySongCount(totals.count)} · '
              '${formatTotalDuration(l10n, totals.durationMs)}';
    final playContext = playlistPlayContext(l10n, detail.summary);
    final slivers = <Widget>[
      if (empty)
        PlaylistEmptyState(uid: _uid)
      else ...[
        PlaylistListBar(
          countText: countText,
          sort: sort,
          onSortPressed: _openSort,
          onReverse: _reverse,
          filterOpen: _filterOpen,
          onFilterToggle: _toggleFilter,
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
        if (unavailable > 0)
          SliverToBoxAdapter(
            child: PlaylistMissingNote(
              count: unavailable,
              onRemove: () => unawaited(removeUnavailableOnPage(context, _uid)),
            ),
          ),
        if (shown.rows.isEmpty)
          const PlaylistNoMatchState()
        else
          PlaylistRowsSliver(
            uid: _uid,
            shown: shown,
            playContext: playContext,
            onRemoveMissing: (entry) =>
                unawaited(removeEntryOnPage(context, _uid, entry)),
          ),
      ],
      const SelectionInsetSliver(),
    ];
    return PopScope(
      canPop: !_filterOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _filterOpen) _closeFilter();
      },
      child: widget.builder(context, slivers, _serving, _play),
    );
  }
}
