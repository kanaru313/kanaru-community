import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../domain/playlists/playlist_models.dart';
import '../../library_locations.dart';
import '../../menus/menu_items.dart';
import '../../menus/menu_model.dart';
import '../../menus/menu_origin.dart';
import '../dialogs/playlist_confirm_flows.dart';
import 'playlist_menu_actions.dart';
import 'playlist_menu_rows.dart';

/// Menu of Favorites, from a snapshot read when it opened. No edit, delete,
/// cover button or "Ask AI"; "Advanced" saves a copy, exports, drops missing
/// songs and clears the list. [onOwnPage] hides "Go to", Play and Shuffle.
/// [today] dates the name of the copy.
MenuSpec buildFavoritesMenu(
  PlaylistDetail detail,
  MenuEnv env, {
  required bool onOwnPage,
  required bool desktop,
  required DateTime today,
}) {
  final l10n = env.l10n;
  final summary = detail.summary;
  final playable = detail.playableIds;
  final count = detail.entries.length;
  final copyName = l10n.playlistFavoritesCopyName(
    playlistMenuDate(l10n, today),
  );

  final advanced = [
    [
      MenuItemSpec(
        MenuItemId.playlistSaveAs,
        icon: KIcons.duplicate,
        title: l10n.playlistMenuSaveAs,
        subtitle: copyName,
        action: MenuAction.run(
          (ctx) => saveFavoritesAsPlaylist(ctx, summary.uid, copyName),
        ),
      ),
      ...playlistExportRows(detail, l10n, withRelative: false),
    ],
    [
      if (detail.unavailableCount > 0) playlistRemoveMissingRow(detail, l10n),
      MenuItemSpec(
        MenuItemId.playlistClearFavorites,
        icon: KIcons.heartOff,
        title: l10n.playlistMenuClearFavorites,
        subtitle: l10n.playlistMenuClearFavoritesHint(count),
        danger: true,
        enabled: count > 0,
        action: MenuAction.run((ctx) => clearFavoritesFlow(ctx, detail)),
      ),
    ],
  ];

  return MenuSpec(
    header: playlistMenuHeader(summary, l10n, desktop: desktop),
    groups: withAdvanced(
      [
        [
          if (!onOwnPage)
            // No dedicated id exists for this row; `link` is the id of the
            // "go to" rows.
            MenuItemSpec(
              MenuItemId.link,
              icon: KIcons.favorites,
              title: l10n.playlistMenuGoToFavorites,
              action: MenuAction.go(LibraryLocations.playlist(summary.uid)),
            ),
        ],
        [
          ...playRows(
            l10n,
            playable,
            playlistPlayContext(l10n, summary),
            own: onOwnPage,
          ),
          playlistCopyToRow(detail, l10n),
        ],
      ],
      advanced,
      l10n.libraryMenuAdvanced,
    ),
    advanced: advanced,
    queueIds: playable,
    origin: MenuOrigin.playlist(summary.uid),
  );
}
