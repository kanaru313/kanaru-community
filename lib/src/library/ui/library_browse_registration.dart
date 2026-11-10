import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../extension/state/extension_registry.dart';
import '../../extension/state/registry_entries.dart';
import '../domain/library_tabs.dart';
import 'browse/library_labels.dart';
import 'browse/library_routes.dart';
import 'library_locations.dart';
import 'playlists_page.dart';

const _tabIcons = {
  LibraryTab.songs: KIcons.songs,
  LibraryTab.albums: KIcons.albums,
  LibraryTab.artists: KIcons.artists,
  LibraryTab.genres: KIcons.genres,
  LibraryTab.languages: KIcons.languages,
  LibraryTab.folders: KIcons.folders,
};

/// Library tab with its six lists, Playlists tab, the placeholder items that
/// follow Playlists in the sidebar, and the pages of the library lists.
void registerLibraryBrowse(ExtensionRegistry registry) {
  registry.addNavItem(
    NavItem(
      id: 'library',
      path: '/library',
      icon: KIcons.library,
      selectedIcon: KIcons.librarySelected,
      label: (c) => AppLocalizations.of(c).navLibrary,
      order: 105,
      mobileOrder: 20,
      // The six lists below replace it in the sidebar; mobile keeps the tab.
      sidebar: false,
    ),
  );
  // Children after their parent (the registry requires it). They are always
  // all in the sidebar, in the default order; the settings of tab order and
  // visibility steer the mobile sub-tabs only.
  for (final tab in LibraryTab.values) {
    registry.addNavItem(
      NavItem(
        id: 'library_${tab.name}',
        path: LibraryLocations.list(tab),
        icon: _tabIcons[tab]!,
        selectedIcon: _tabIcons[tab]!,
        label: (c) => libraryTabLabel(AppLocalizations.of(c), tab),
        order: 110 + tab.index * 10,
        mobileTab: false,
        parentId: 'library',
      ),
    );
  }
  registry
    ..addNavItem(
      NavItem(
        id: 'playlists',
        path: '/playlists',
        icon: KIcons.playlists,
        selectedIcon: KIcons.playlistsSelected,
        label: (c) => AppLocalizations.of(c).navPlaylists,
        order: 210,
        mobileOrder: 30,
      ),
    )
    ..addNavItem(
      NavItem(
        id: 'favorites',
        path: '/playlists/favorites',
        icon: KIcons.favorites,
        selectedIcon: KIcons.favoritesSelected,
        label: (c) => AppLocalizations.of(c).libraryNavFavorites,
        order: 220,
        mobileTab: false,
        comingSoon: true,
      ),
    )
    ..addNavItem(
      NavItem(
        id: 'history',
        path: '/playlists/history',
        icon: KIcons.history,
        selectedIcon: KIcons.history,
        label: (c) => AppLocalizations.of(c).libraryNavHistory,
        order: 240,
        mobileTab: false,
        comingSoon: true,
      ),
    )
    ..addNavItem(
      NavItem(
        id: 'most_played',
        path: '/playlists/most-played',
        icon: KIcons.mostPlayed,
        selectedIcon: KIcons.mostPlayed,
        label: (c) => AppLocalizations.of(c).libraryNavMostPlayed,
        order: 250,
        mobileTab: false,
        comingSoon: true,
      ),
    )
    ..addRoute(libraryRoute())
    ..addRoute(
      GoRoute(path: '/playlists', builder: (_, _) => const PlaylistsPage()),
    );
}
