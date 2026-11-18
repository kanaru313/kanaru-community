import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/playlists/playlist_models.dart';
import '../../../domain/playlists/playlist_sort.dart';
import '../../../state/playlists/playlist_prefs_providers.dart';
import '../../browse/library_labels.dart';
import '../../browse/library_list_scaffold.dart';
import '../../browse/list_sort_dialog.dart';
import '../../selection/selection_inset.dart';
import '../menu/playlist_menu_rows.dart';
import 'playlist_edit_host.dart';
import 'playlist_edit_mode.dart';
import 'playlist_filter_state.dart';
import 'playlist_list_bar.dart';
import 'playlist_missing_note.dart';
import 'playlist_page_actions.dart';
import 'playlist_page_states.dart';
import 'playlist_play_gate.dart';
import 'playlist_row_actions.dart';
import 'playlist_rows_sliver.dart';
import 'playlist_select_all_claim.dart';
import 'playlist_shown_entries.dart';
import 'playlist_sort_actions.dart';

/// The songs part of a playlist page: the sticky list bar, the filter field,
/// the missing-songs note and the rows, as slivers for the page's own scroll
/// view; or the empty state. Owns what is never stored: the filter, and the
/// sort box (closed with the page). On the mobile shell Back closes the
/// filter field first, then leaves edit mode.
///
/// The sort is remembered per playlist (`playlistTrackSortsProvider`). In
/// [edit] mode the page shows the playlist's own order with no filter, whatever
/// is stored; leaving it brings the stored sort and the filter back as they
/// were. While a row is dragged the rows are frozen (`ReorderFreeze`).
class PlaylistSongsHost extends ConsumerStatefulWidget {
  const PlaylistSongsHost({
    super.key,
    required this.detail,
    required this.edit,
    required this.builder,
  });

  final PlaylistDetail detail;
  final PlaylistEditMode edit;

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
  late final PlaylistFilterState _filter = PlaylistFilterState(
    onChanged: () => setState(() {}),
  );
  final ListSortGuard _sortGuard = ListSortGuard();
  final ShownEntriesMemo _memo = ShownEntriesMemo();

  /// A Play or shuffle press is being served: further presses are ignored.
  bool _serving = false;

  late final SelectAllClaim _claim;
  late final PlaylistEditHost _editHost;

  /// The rows as drawn by the last build (frozen ones while dragging).
  late ShownEntries _shown;

  @override
  void initState() {
    super.initState();
    _claim = SelectAllClaim(context, ref);
    _editHost = PlaylistEditHost(
      edit: widget.edit,
      filter: _filter,
      context: () => context,
      uid: () => _uid,
      shown: () => _shown,
      hasEntries: () => widget.detail.entries.isNotEmpty,
      refresh: () {
        if (mounted) setState(() {});
      },
    );
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
    _editHost.dispose();
    _claim.dispose();
    _sortGuard.close();
    _filter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detail = widget.detail;
    final editing = widget.edit.editing;
    final empty = detail.entries.isEmpty;
    if (empty && (_filter.open || _filter.text.isNotEmpty)) {
      // The list emptied under an open filter: it has nothing to narrow.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _filter.close();
      });
    }
    // This page is the one on screen: no page or modal above it and its
    // branch not hidden behind another tab.
    final onTop =
        (ModalRoute.isCurrentOf(context) ?? true) &&
        TickerMode.valuesOf(context).enabled;
    if (editing && (empty || !onTop) && !widget.edit.dragging) {
      // Nothing left to edit, or the page is covered (a drag in progress
      // ends first).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.edit.exit();
      });
    }
    final stored = ref.watch(playlistTrackSortProvider(_uid));
    final sort = editing ? editModeSort : stored;
    final filter = empty || editing ? '' : _filter.text;
    final shown = _shown =
        _editHost.freeze.frozen ?? _memo.of(detail, sort, filter);
    _claim.sync(onTop && !editing, shown.playable, () => mounted);
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
    final slivers = <Widget>[
      if (empty)
        PlaylistEmptyState(uid: _uid)
      else ...[
        PlaylistListBar(
          countText: countText,
          editLead: editing ? l10n.plScreensEditBarLead(totals.count) : null,
          sort: sort,
          onSortPressed: (anchor) =>
              unawaited(openPlaylistSort(context, _uid, anchor, _sortGuard)),
          onReverse: () => unawaited(reversePlaylistSort(ref, _uid)),
          filterOpen: _filter.open,
          onFilterToggle: _filter.toggle,
        ),
        if (_filter.open)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(gutter, 0, gutter, KSpace.x2),
              child: KFilterField(
                controller: _filter.controller,
                hint: l10n.libraryFilterSongsHint,
                closeTooltip: l10n.libraryFilterClose,
                onChanged: (text) => _filter.typed(text, () => mounted),
                onClose: _filter.close,
              ),
            ),
          ),
        if (unavailable > 0 && !editing)
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
            playContext: playlistPlayContext(l10n, detail.summary),
            editing: editing,
            actions: playlistRowActions(
              context,
              l10n,
              uid: _uid,
              isFavorites: _editHost.isFavorites,
              canStep: canReorder(stored, _filter.text),
              rowCount: () => _shown.rows.length,
              onStep: _editHost.step,
              onReorderStart: _editHost.dragStart,
              onReorderItem: _editHost.drop,
            ),
          ),
      ],
      const SelectionInsetSliver(),
    ];
    return PopScope(
      canPop: !_filter.open && !editing,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (editing) {
          // A drag in progress ends first.
          if (!widget.edit.dragging) widget.edit.exit();
        } else if (_filter.open) {
          _filter.close();
        }
      },
      child: Listener(
        onPointerDown: (e) => _editHost.pointerDown(e.pointer),
        onPointerUp: (e) => _editHost.pointerGone(e.pointer),
        onPointerCancel: (e) => _editHost.pointerGone(e.pointer),
        child: widget.builder(context, slivers, _serving, _play),
      ),
    );
  }
}
