import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import '../extension/kanaru_extension.dart';
import '../extension/state/extension_registry.dart';
import '../extension/state/registry_entries.dart';
import 'ui/library_page.dart';
import 'ui/playlists_page.dart';

/// Library and Playlists: nav entries and root pages.
class LibraryExtension implements KanaruExtension {
  const LibraryExtension();

  @override
  String get id => 'library';

  @override
  void register(ExtensionRegistry registry) {
    registry
      ..addNavItem(NavItem(
        id: 'library',
        path: '/library',
        icon: KIcons.library,
        selectedIcon: KIcons.librarySelected,
        label: (c) => AppLocalizations.of(c).navLibrary,
        order: 20,
      ))
      ..addNavItem(NavItem(
        id: 'playlists',
        path: '/playlists',
        icon: KIcons.playlists,
        selectedIcon: KIcons.playlistsSelected,
        label: (c) => AppLocalizations.of(c).navPlaylists,
        order: 30,
      ))
      ..addRoute(GoRoute(path: '/library', builder: (_, _) => const LibraryPage()))
      ..addRoute(GoRoute(path: '/playlists', builder: (_, _) => const PlaylistsPage()));
  }
}
