import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../extension/state/extension_registry.dart';
import '../../extension/state/registry_entries.dart';
import 'library_page.dart';
import 'playlists_page.dart';

/// Library and Playlists tabs, the placeholder items that follow Playlists in
/// the sidebar, and the pages of the library lists.
void registerLibraryBrowse(ExtensionRegistry registry) {
  registry
    ..addNavItem(
      NavItem(
        id: 'library',
        path: '/library',
        icon: KIcons.library,
        selectedIcon: KIcons.librarySelected,
        label: (c) => AppLocalizations.of(c).navLibrary,
        order: 105,
        mobileOrder: 20,
      ),
    )
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
    ..addRoute(
      GoRoute(path: '/library', builder: (_, _) => const LibraryPage()),
    )
    ..addRoute(
      GoRoute(path: '/playlists', builder: (_, _) => const PlaylistsPage()),
    );
}
