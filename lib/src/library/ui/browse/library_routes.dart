import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/library_tabs.dart';
import '../../state/library_tabs_providers.dart';
import '../collections/albums_page.dart';
import '../collections/artists_page.dart';
import '../collections/genres_page.dart';
import '../collections/languages_page.dart';
import '../detail/album_page.dart';
import '../detail/artist_page.dart';
import '../detail/group_page.dart';
import '../detail/see_all_page.dart';
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
    ..._detailRoutes(),
  ],
);

/// Detail and see-all pages. Flat siblings of the list routes (no nesting),
/// so each location shows exactly one page and a push stacks one page.
List<GoRoute> _detailRoutes() => [
  GoRoute(
    path: 'albums/:album',
    pageBuilder: (context, state) =>
        _detailPage(state, AlbumPage(albumId: state.pathParameters['album']!)),
  ),
  GoRoute(
    path: 'artists/:artist',
    pageBuilder: (context, state) => _detailPage(
      state,
      ArtistPage(artistId: state.pathParameters['artist']!),
    ),
  ),
  for (final appears in [false, true])
    GoRoute(
      path: 'artists/:artist/${appears ? 'appears' : 'albums'}',
      pageBuilder: (context, state) => _detailPage(
        state,
        ArtistAlbumsPage(
          artistId: state.pathParameters['artist']!,
          appears: appears,
        ),
      ),
    ),
  for (final kind in GroupKind.values) ...[
    GoRoute(
      path: '${kind.name == 'genre' ? 'genres' : 'languages'}/:${kind.name}',
      pageBuilder: (context, state) => _detailPage(
        state,
        GroupPage(kind: kind, id: state.pathParameters[kind.name]!),
      ),
    ),
    for (final artists in [true, false])
      GoRoute(
        path:
            '${kind.name == 'genre' ? 'genres' : 'languages'}/:${kind.name}/'
            '${artists ? 'artists' : 'albums'}',
        pageBuilder: (context, state) => _detailPage(
          state,
          GroupSeeAllPage(
            kind: kind,
            id: state.pathParameters[kind.name]!,
            artists: artists,
          ),
        ),
      ),
  ],
];

/// A detail page slides in from the right and out again on one smooth curve.
/// The platform default (Cupertino) eases fast-to-slow, so the last part of
/// the slide crawls and the page below stays on screen as a trailing image.
Page<void> _detailPage(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      transitionsBuilder: (context, animation, secondary, child) =>
          SlideTransition(
            position: Tween(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                    reverseCurve: Curves.easeInCubic,
                  ),
                ),
            child: child,
          ),
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
