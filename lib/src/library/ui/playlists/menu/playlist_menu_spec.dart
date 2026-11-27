import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../domain/ask_ai_target.dart';
import '../../../domain/playlists/playlist_models.dart';
import '../../../domain/playlists/playlist_text_rules.dart';
import '../../library_locations.dart';
import '../../menus/menu_items.dart';
import '../../menus/menu_model.dart';
import '../../menus/menu_origin.dart';
import '../../playlist_common/playlist_labels.dart';
import '../dialogs/duplicate_playlist_dialog.dart';
import '../dialogs/edit_playlist_dialog.dart';
import '../dialogs/playlist_confirm_flows.dart';
import 'playlist_menu_actions.dart';
import 'playlist_menu_rows.dart';

/// Menu of a playlist (not Favorites), from a snapshot read when it opened.
/// [onOwnPage] hides "Go to", Play and Shuffle (the page has them);
/// [pageRoute] is the route of that page, handed to the delete flow so the
/// page leaves before the playlist goes.
MenuSpec buildPlaylistMenu(
  PlaylistDetail detail,
  MenuEnv env, {
  required bool onOwnPage,
  required bool desktop,
  ModalRoute<Object?>? pageRoute,
}) {
  final l10n = env.l10n;
  final summary = detail.summary;
  final name = playlistDisplayName(l10n, summary);
  final playable = detail.playableIds;
  final duplicates = detail.duplicateCount;
  final missing = detail.unavailableCount;

  final advanced = [
    [
      MenuItemSpec(
        MenuItemId.playlistDuplicate,
        icon: KIcons.duplicate,
        title: l10n.playlistMenuDuplicate,
        subtitle: capPlaylistName(l10n.playlistCopyName(name)),
        action: MenuAction.run(
          (ctx) => showDuplicatePlaylistDialog(ctx, summary),
        ),
      ),
    ],
    playlistExportRows(detail, l10n, withRelative: true),
    [
      if (duplicates > 0)
        MenuItemSpec(
          MenuItemId.playlistRemoveDuplicates,
          icon: KIcons.removeDuplicates,
          title: l10n.playlistMenuRemoveDuplicates,
          subtitle: l10n.playlistMenuRemoveDuplicatesHint(duplicates),
          action: MenuAction.run(
            (ctx) => removeDuplicateEntries(ctx, summary.uid),
          ),
        ),
      if (missing > 0) playlistRemoveMissingRow(detail, l10n),
    ],
    [
      MenuItemSpec(
        MenuItemId.playlistDelete,
        icon: KIcons.delete,
        title: l10n.playlistMenuDelete,
        subtitle: l10n.playlistMenuDeleteHint,
        danger: true,
        action: MenuAction.run(
          (ctx) => deletePlaylistFlow(
            ctx,
            summary,
            pageRoute: onOwnPage ? pageRoute : null,
          ),
        ),
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
              icon: KIcons.playlists,
              title: l10n.playlistMenuGoTo,
              subtitle: name,
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
          MenuItemSpec(
            MenuItemId.playlistFavoriteAll,
            icon: KIcons.heart,
            title: l10n.libraryMenuFavoriteAll,
            enabled: playable.isNotEmpty,
            action: MenuAction.run((ctx) => favoriteAllOf(ctx, summary.uid)),
          ),
          MenuItemSpec(
            MenuItemId.playlistEdit,
            icon: KIcons.edit,
            title: l10n.playlistMenuEdit,
            hint: l10n.playlistMenuEditHint,
            action: MenuAction.run(
              (ctx) => showEditPlaylistDialog(ctx, summary),
            ),
          ),
          askAiRow(
            env,
            l10n.playlistMenuAskAi,
            AskAiTarget.playlist(summary.uid, name),
            id: MenuItemId.playlistAskAi,
          ),
        ],
      ],
      [
        for (final g in advanced)
          if (g.isNotEmpty) g,
      ],
      l10n.libraryMenuAdvanced,
    ),
    advanced: [
      for (final g in advanced)
        if (g.isNotEmpty) g,
    ],
    queueIds: playable,
    origin: MenuOrigin.playlist(summary.uid),
  );
}
