import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../extension/state/extension_registry.dart';
import '../../../extension/state/registry_entries.dart';
import 'history_locations.dart';

/// History and Most played: sidebar children of Playlists and hub tiles.
/// Registered after the Playlists tab (the parent goes first). The routes are
/// nested under `/playlists` by `registerPlaylists`.
void registerHistory(ExtensionRegistry registry) {
  registry
    ..addNavItem(
      NavItem(
        id: 'history',
        path: HistoryLocations.history,
        icon: KIcons.history,
        selectedIcon: KIcons.history,
        label: (c) => AppLocalizations.of(c).libraryNavHistory,
        order: 240,
        mobileTab: false,
        parentId: 'playlists',
      ),
    )
    ..addNavItem(
      NavItem(
        id: 'most_played',
        path: HistoryLocations.mostPlayed,
        icon: KIcons.mostPlayed,
        selectedIcon: KIcons.mostPlayed,
        label: (c) => AppLocalizations.of(c).libraryNavMostPlayed,
        order: 250,
        mobileTab: false,
        parentId: 'playlists',
      ),
    );
}
