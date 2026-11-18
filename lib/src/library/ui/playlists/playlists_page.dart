import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/playlists/playlist_sort.dart';
import '../../state/browse/list_prefs_providers.dart';
import '../../state/playlists/playlist_providers.dart';
import '../browse/library_list_scaffold.dart';
import '../browse/list_sort_dialog.dart';
import '../collections/collection_parts.dart';
import '../m3u/m3u_entry_points.dart';
import '../selection/selection_back.dart' show rootModalOpen;
import '../selection/selection_inset.dart';
import 'dialogs/create_playlist_dialog.dart';
import 'list/new_playlist_shortcut.dart';
import 'list/playlists_hub.dart';
import 'list/playlists_list_bar.dart';
import 'list/playlists_list_slivers.dart';
import 'list/playlists_sort_actions.dart';
import 'list/playlists_yours_header.dart';
import 'page/playlist_back_chain.dart';
import 'page/playlist_filter_state.dart';

/// Root page of the Playlists tab. Desktop: the page "Playlist". Mobile: the
/// tab root, with the hub of shortcuts above "Playlist của bạn".
///
/// Owns what is not stored: the filter text, the open sort box (closed with
/// the page), the FAB menu and Ctrl+N. Sort and layout are remembered in
/// `libraryListViewsProvider`.
class PlaylistsPage extends ConsumerStatefulWidget {
  const PlaylistsPage({super.key});

  @override
  ConsumerState<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends ConsumerState<PlaylistsPage> {
  static const BrowseList _list = BrowseList.playlists;

  final PlaylistFilterState _filterState = PlaylistFilterState();
  final ListSortGuard _sortGuard = ListSortGuard();
  final KFabMenuController _fab = KFabMenuController();

  /// Owns Esc while the filter is open (see `PlaylistBackScope`).
  final FocusNode _focus = FocusNode(
    debugLabel: 'PlaylistsPage',
    skipTraversal: true,
  );
  late final NewPlaylistShortcut _shortcut = NewPlaylistShortcut(
    context,
    _newPlaylist,
  );

  /// Set the first time the page is on screen. A tab built but never shown
  /// (a deep link into a playlist builds the tab root under it) starts no
  /// query; once shown, the page keeps its data while another page covers it.
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    _shortcut.attach();
    _filterState.addListener(_onFilterChanged);
  }

  @override
  void dispose() {
    _shortcut.detach();
    _sortGuard.close();
    _filterState
      ..removeListener(_onFilterChanged)
      ..dispose();
    _fab.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Opens the create dialog; the FAB menu closes first.
  void _newPlaylist() {
    _fab.close();
    unawaited(showCreatePlaylistDialog(context));
  }

  void _importM3u() => unawaited(importM3u(context));

  void _onFilterChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openSort(GlobalKey anchor) =>
      openPlaylistsSort(context, anchor, _sortGuard);

  void _reverseSort() => reversePlaylistsSort(ref);

  @override
  Widget build(BuildContext context) {
    _shown = _shown || TickerMode.valuesOf(context).enabled;
    if (!_shown) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final mobile = FormFactor.of(context) == FormFactor.mobile;
    final gutter = libraryGutter(context);
    final scaler = MediaQuery.textScalerOf(context);
    final prefs = ref.watch(
      libraryListViewsProvider.select((v) => v.of(_list)),
    );
    final async = ref.watch(sortedPlaylistsProvider);
    final all = async.value;
    final shown = all == null ? null : filterPlaylists(all, _filterState.text);
    // A refresh error leaves the last value, but the body shows the error:
    // no bar then either.
    final hasAny = all != null && all.isNotEmpty && !async.hasError;
    final filterOpen = _filterState.open && hasAny;
    // The last playlist is gone: the filter goes with it.
    _filterState.closeWhenEmpty(
      empty: all != null && all.isEmpty,
      alive: () => mounted,
    );
    // Back and Esc, outermost last: a dialog or sheet (root routes), the FAB
    // menu (its own listener and key handler, nearer than this one), the
    // filter, then the page. On the mobile shell Back first reaches the
    // shell's own listener (it would go Home), so the filter answers Back
    // itself, like the FAB menu; the scope's PopScope covers a page pushed
    // above other routes, and its Focus owns Esc on desktop.
    return BackButtonListener(
      onBackButtonPressed: () async {
        if (!filterOpen ||
            rootModalOpen(context) ||
            !(ModalRoute.isCurrentOf(context) ?? true) ||
            !TickerMode.valuesOf(context).enabled) {
          // Covered by a page or hidden behind another tab: not ours.
          return false;
        }
        _filterState.close();
        return true;
      },
      child: PlaylistBackScope(
        active: filterOpen,
        focusNode: _focus,
        outerMenu: _fab,
        closeTop: () {
          if (!filterOpen) return false;
          _filterState.close();
          return true;
        },
        child: KFabMenu(
          controller: _fab,
          openTooltip: l10n.playlistFabOpen,
          closeTooltip: l10n.playlistFabClose,
          items: [
            KFabMenuItem(
              icon: KIcons.add,
              label: l10n.playlistFabNew,
              onPressed: _newPlaylist,
            ),
            KFabMenuItem(
              icon: KIcons.fileImport,
              label: l10n.playlistFabImport,
              enabled: m3uAvailable,
              onPressed: _importM3u,
            ),
            KFabMenuItem(
              icon: KIcons.smartPlaylist,
              label: l10n.playlistFabSmart,
              enabled: false,
              trailing: const ProBadge(),
            ),
          ],
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                child: PageHeader(title: l10n.navPlaylists),
              ),
              Expanded(
                child: KScrollInkSurface(
                  child: CustomScrollView(
                    slivers: [
                      const M3uImportProgressSliver(),
                      if (mobile) const PlaylistsHub(),
                      if (mobile && hasAny) const PlaylistsYoursHeader(),
                      if (hasAny)
                        KStickyBarSliver(
                          height: playlistsBarHeight(
                            scaler,
                            filterOpen: filterOpen,
                          ),
                          child: PlaylistsListBar(
                            countText: collectionCountText(
                              shown: shown?.length,
                              total: all.length,
                              filtering: _filterState.text.isNotEmpty,
                              plain: l10n.playlistCount,
                              unit: l10n.plScreensUnitPlaylists,
                              l10n: l10n,
                            ),
                            view: prefs.view,
                            sort: prefs.sort,
                            onSortPressed: _openSort,
                            onReverse: _reverseSort,
                            filterOpen: filterOpen,
                            onFilterToggle: _filterState.toggle,
                            filterController: _filterState.controller,
                            onFilterChanged: (text) =>
                                _filterState.typed(text, () => mounted),
                            onFilterClose: _filterState.close,
                          ),
                        ),
                      PlaylistsListSlivers(
                        async: async,
                        shown: shown,
                        view: prefs.view,
                        onCreate: _newPlaylist,
                        onImport: m3uAvailable ? _importM3u : null,
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: KFabMenu.listEndPadding),
                      ),
                      const SelectionInsetSliver(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
