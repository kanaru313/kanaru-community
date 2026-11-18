import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/sort_order.dart';
import '../../domain/playlists/playlist_sort.dart';
import '../../state/browse/list_prefs_providers.dart';
import '../../state/playlists/playlist_providers.dart';
import '../browse/filter_debouncer.dart';
import '../browse/library_list_scaffold.dart';
import '../browse/list_sort_dialog.dart';
import '../browse/list_sort_popover.dart';
import '../collections/collection_parts.dart';
import '../m3u/m3u_entry_points.dart';
import '../selection/selection_back.dart' show rootModalOpen;
import '../selection/selection_inset.dart';
import 'dialogs/create_playlist_dialog.dart';
import 'list/new_playlist_shortcut.dart';
import 'list/playlists_hub.dart';
import 'list/playlists_list_bar.dart';
import 'list/playlists_list_slivers.dart';

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

  final TextEditingController _filterController = TextEditingController();
  final FilterDebouncer _debounce = FilterDebouncer();
  final ListSortGuard _sortGuard = ListSortGuard();
  final KFabMenuController _fab = KFabMenuController();
  late final NewPlaylistShortcut _shortcut = NewPlaylistShortcut(
    context,
    _newPlaylist,
  );
  bool _filterOpen = false;
  String _filter = '';

  /// Set the first time the page is on screen. A tab built but never shown
  /// (a deep link into a playlist builds the tab root under it) starts no
  /// query; once shown, the page keeps its data while another page covers it.
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    _shortcut.attach();
  }

  @override
  void dispose() {
    _shortcut.detach();
    _sortGuard.close();
    _debounce.cancel();
    _filterController.dispose();
    _fab.dispose();
    super.dispose();
  }

  /// Opens the create dialog; the FAB menu closes first.
  void _newPlaylist() {
    _fab.close();
    unawaited(showCreatePlaylistDialog(context));
  }

  void _importM3u() => unawaited(importM3u(context));

  void _onFilterChanged(String text) => _debounce(text, (text) {
    if (mounted) setState(() => _filter = text);
  });

  void _toggleFilter() => _filterOpen ? _closeFilter() : _openFilter();

  void _openFilter() => setState(() => _filterOpen = true);

  void _closeFilter() {
    _debounce.cancel();
    setState(() {
      _filterController.clear();
      _filter = '';
      _filterOpen = false;
    });
  }

  /// The container is taken now: the sort box is on the root navigator and
  /// can outlive this page, whose `ref` is dead by then.
  Future<void> _openSort(GlobalKey anchor) {
    final container = ProviderScope.containerOf(context);
    Future<void> write(SortOrder sort) =>
        container.read(libraryListViewsProvider.notifier).setSort(_list, sort);
    return openListSort(
      context,
      list: _list,
      anchor: anchor,
      guard: _sortGuard,
      read: () => container.read(libraryListViewsProvider).of(_list).sort,
      write: write,
      reset: () => write(defaultSortOf(_list)),
    );
  }

  void _reverseSort() {
    final current = ref.read(libraryListViewsProvider).of(_list).sort;
    unawaited(
      ref
          .read(libraryListViewsProvider.notifier)
          .setSort(_list, current.reversed()),
    );
  }

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
    final shown = all == null ? null : filterPlaylists(all, _filter);
    // A refresh error leaves the last value, but the body shows the error:
    // no bar then either.
    final hasAny = all != null && all.isNotEmpty && !async.hasError;
    final filterOpen = _filterOpen && hasAny;
    if (all != null && all.isEmpty && (_filterOpen || _filter.isNotEmpty)) {
      // The last playlist is gone: the filter goes with it.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _closeFilter();
      });
    }
    // On the mobile shell Back first reaches the shell's own listener (it
    // would go Home), so the filter answers Back itself, like the FAB menu;
    // the PopScope covers a page pushed above other routes.
    return BackButtonListener(
      onBackButtonPressed: () async {
        if (!filterOpen || rootModalOpen(context)) return false;
        _closeFilter();
        return true;
      },
      child: PopScope(
        canPop: !filterOpen,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && filterOpen) _closeFilter();
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
                      if (mobile && hasAny)
                        SliverToBoxAdapter(
                          child: Semantics(
                            header: true,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                gutter,
                                KSpace.x2,
                                gutter,
                                KSpace.x1,
                              ),
                              child: Text(
                                l10n.playlistYours,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
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
                              filtering: _filter.isNotEmpty,
                              plain: l10n.playlistCount,
                              unit: l10n.plScreensUnitPlaylists,
                              l10n: l10n,
                            ),
                            view: prefs.view,
                            sort: prefs.sort,
                            onSortPressed: _openSort,
                            onReverse: _reverseSort,
                            filterOpen: filterOpen,
                            onFilterToggle: _toggleFilter,
                            filterController: _filterController,
                            onFilterChanged: _onFilterChanged,
                            onFilterClose: _closeFilter,
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
