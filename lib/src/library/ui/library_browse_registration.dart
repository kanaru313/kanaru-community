import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../extension/state/extension_registry.dart';
import '../../extension/state/registry_entries.dart';
import '../domain/library_tabs.dart';
import 'browse/library_labels.dart';
import 'browse/library_routes.dart';
import 'library_locations.dart';

const _tabIcons = {
  LibraryTab.songs: KIcons.songs,
  LibraryTab.albums: KIcons.albums,
  LibraryTab.artists: KIcons.artists,
  LibraryTab.genres: KIcons.genres,
  LibraryTab.languages: KIcons.languages,
  LibraryTab.folders: KIcons.folders,
};

/// Library tab with its six lists, the placeholder items that follow
/// Playlists in the sidebar (History, Most played), and the pages of the library lists.
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
      // `/library` only redirects; the list pages are the tab's roots.
      isRootPath: (path) =>
          LibraryTab.values.any((t) => path == LibraryLocations.list(t)),
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
    ..addRoute(libraryRoute());
}
