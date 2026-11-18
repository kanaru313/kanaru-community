import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../extension/state/extension_registry.dart';
import '../../../extension/state/registry_entries.dart';
import '../../domain/playlists/playlist_ids.dart';
import '../browse/library_routes.dart';
import '../library_locations.dart';
import '../playlists/playlist_page.dart';
import '../playlists/playlists_page.dart';

/// Playlists tab, the Favorites sidebar item under it, and the playlist
/// routes. Static children go before `:uid`, so a fixed name is never taken
/// for a playlist id: `favorites` now, and History (`history`) and Most played
/// (`most-played`) when they become real pages. Until then their paths match
/// `:uid`, and a page asked for an unknown uid shows "not found".
void registerPlaylists(ExtensionRegistry registry) {
  registry
    ..addNavItem(
      NavItem(
        id: 'playlists',
        path: LibraryLocations.playlists,
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
        path: LibraryLocations.playlist(PlaylistUids.favorites),
        icon: KIcons.favorites,
        selectedIcon: KIcons.favoritesSelected,
        label: (c) => AppLocalizations.of(c).libraryNavFavorites,
        order: 220,
        mobileTab: false,
        parentId: 'playlists',
      ),
    )
    ..addRoute(
      GoRoute(
        path: LibraryLocations.playlists,
        builder: (_, _) => const PlaylistsPage(),
        routes: [
          GoRoute(
            path: PlaylistUids.favorites,
            pageBuilder: (context, state) => libraryDetailPage(
              state,
              const PlaylistPage(uid: PlaylistUids.favorites),
            ),
          ),
          GoRoute(
            path: ':uid',
            pageBuilder: (context, state) => libraryDetailPage(
              state,
              PlaylistPage(uid: state.pathParameters['uid']!),
            ),
          ),
        ],
      ),
    );
}
