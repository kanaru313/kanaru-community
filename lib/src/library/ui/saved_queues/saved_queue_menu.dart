import 'package:flutter/widgets.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/history/history_days.dart';
import '../../domain/playlists/playlist_models.dart';
import '../../state/history/local_day_provider.dart';
import '../../state/saved_queues/saved_queue_providers.dart';
import '../m3u/m3u_entry_points.dart';
import '../menus/menu_loaders.dart' show ItemGoneException;
import '../menus/menu_model.dart';
import '../menus/open_menu.dart';
import 'saved_queue_actions.dart';
import 'saved_queue_delete.dart';
import 'saved_queue_labels.dart';
import 'saved_queue_play.dart';
import 'saved_queue_read.dart';

/// Opens the menu of saved queue [uid] (a sheet on the mobile shell, a
/// dropdown on desktop), built from the queue as it is when it opens. A queue
/// that is gone says so and opens no menu.
///
/// [pageRoute]: the route of the queue's own page (`ModalRoute.of` of the
/// page), handed to the delete flow so the page leaves before the queue goes.
/// Null from the list.
Future<void> openSavedQueueMenu(
  BuildContext context,
  String uid, {
  ModalRoute<Object?>? pageRoute,
  bool viaKeyboard = false,
}) => openMenu(context, (container, env) async {
  final detail = await readSavedQueue(
    container.read(savedQueueStoreProvider),
    uid,
  );
  if (detail == null) throw ItemGoneException('saved queue $uid');
  return buildSavedQueueMenu(
    detail,
    env.l10n,
    today: localDay(container.read(historyClockProvider)()),
    pageRoute: pageRoute,
  );
}, viaKeyboard: viaKeyboard);

/// The menu of a saved queue, as drawn: play (replacing the current queue),
/// shuffle, add to the end of the queue, save as a playlist, add all to
/// Favorites, export as M3U, drop the missing songs (only when there are
/// some), then a group of its own with the red delete row.
///
/// Rows that need a playable song are dim when none can play now; the action
/// reads the queue again when chosen and says so if it changed.
MenuSpec buildSavedQueueMenu(
  PlaylistDetail detail,
  AppLocalizations l10n, {
  required DateTime today,
  ModalRoute<Object?>? pageRoute,
}) {
  final summary = detail.summary;
  final info = summary.savedQueue;
  if (info == null) throw ArgumentError('not a saved queue: ${summary.uid}');
  final uid = summary.uid;
  final name = savedQueueName(l10n, info.savedAt, today);
  final missing = detail.unavailableCount;
  final canPlay = savedQueuePlayableIds(detail).isNotEmpty;
  return MenuSpec(
    header: MenuHeader(
      image: MenuImage.playlist,
      itemKey: uid,
      autoCoverKeys: summary.autoCoverKeys,
      title: name,
      subtitle: savedQueueStatsLine(l10n, summary, missing: missing),
    ),
    groups: [
      [
        MenuItemSpec(
          MenuItemId.play,
          icon: KIcons.play,
          title: l10n.savedQueueMenuPlay,
          enabled: canPlay,
          action: MenuAction.run((ctx) => playSavedQueue(ctx, uid)),
        ),
        MenuItemSpec(
          MenuItemId.shuffle,
          icon: KIcons.shuffle,
          title: l10n.libraryShuffle,
          enabled: canPlay,
          action: MenuAction.run(
            (ctx) => playSavedQueue(ctx, uid, shuffle: true),
          ),
        ),
        MenuItemSpec(
          MenuItemId.queueAppend,
          icon: KIcons.queue,
          title: l10n.savedQueueMenuAppend,
          enabled: canPlay,
          action: MenuAction.run((ctx) => appendSavedQueue(ctx, uid)),
        ),
        MenuItemSpec(
          MenuItemId.playlist,
          icon: KIcons.playlistAdd,
          title: l10n.savedQueueMenuSaveAsPlaylist,
          enabled: canPlay,
          action: MenuAction.run(
            (ctx) => saveSavedQueueAsPlaylist(ctx, uid, name),
          ),
        ),
        MenuItemSpec(
          MenuItemId.playlistFavoriteAll,
          icon: KIcons.heart,
          title: l10n.libraryMenuFavoriteAll,
          enabled: canPlay,
          action: MenuAction.run((ctx) => favoriteSavedQueue(ctx, uid)),
        ),
        MenuItemSpec(
          MenuItemId.playlistExportM3u,
          icon: KIcons.fileExport,
          title: l10n.historyMenuExportM3u,
          enabled: detail.entries.isNotEmpty,
          soon: !m3uAvailable,
          action: MenuAction.run((ctx) => exportM3u(ctx, uid, relative: false)),
        ),
        if (missing > 0)
          MenuItemSpec(
            MenuItemId.playlistRemoveMissing,
            icon: KIcons.musicOff,
            title: l10n.savedQueueMenuRemoveMissing,
            action: MenuAction.run(
              (ctx) => removeMissingFromSavedQueue(ctx, uid),
            ),
          ),
      ],
      [
        MenuItemSpec(
          MenuItemId.playlistDelete,
          icon: KIcons.delete,
          title: l10n.savedQueueMenuDelete,
          danger: true,
          action: MenuAction.run(
            (ctx) => deleteSavedQueueFlow(ctx, uid, pageRoute: pageRoute),
          ),
        ),
      ],
    ],
  );
}
