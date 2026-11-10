import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/library_tabs.dart';
import '../../state/library_tabs_providers.dart';
import '../collections/albums_page.dart';
import '../collections/artists_page.dart';
import '../collections/genres_page.dart';
import '../collections/languages_page.dart';
import '../folders/folder_locations.dart';
import '../folders/folders_page.dart';
import '../library_locations.dart';
import '../songs/songs_page.dart';
import 'library_navigation.dart';

/// The route tree of the library: `/library` and its six list pages.
///
/// `/library` has no page. It redirects to the list shown last (or the first
/// visible one) and only when the location is exactly `/library`: go_router
/// runs the redirect of every route in a matched chain, parents included, so
/// an unguarded redirect would also rewrite every `/library/...` location.
/// The list routes are siblings, so a list switch replaces the page, and
/// pages opened later (details, folder levels) are pushed on top.
GoRoute libraryRoute() => GoRoute(
  path: LibraryLocations.root,
  redirect: (context, state) {
    if (state.uri.path != LibraryLocations.root) return null;
    final container = ProviderScope.containerOf(context, listen: false);
    final visible = container.read(libraryTabsProvider).visible;
    final last = container.read(lastLibraryTabProvider);
    final tab = last != null && visible.contains(last) ? last : visible.first;
    return LibraryLocations.list(tab);
  },
  routes: [
    for (final tab in LibraryTab.values)
      GoRoute(
        path: tab.name,
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: _pageOf(tab, state),
        ),
      ),
  ],
);

Widget _pageOf(LibraryTab tab, GoRouterState state) => switch (tab) {
  LibraryTab.songs => const SongsPage(),
  LibraryTab.albums => const AlbumsPage(),
  LibraryTab.artists => const ArtistsPage(),
  LibraryTab.genres => const GenresPage(),
  LibraryTab.languages => const LanguagesPage(),
  LibraryTab.folders => _foldersPage(state),
};

/// The Folders page: its location is in the URL, and the level it was opened
/// at travels as `extra` through the replaces that move between levels.
Widget _foldersPage(GoRouterState state) {
  final location = FolderLocation.parse(state.uri);
  final extra = state.extra;
  return FoldersPage(
    location: location,
    entry: extra is FolderLocation ? extra : location,
  );
}
