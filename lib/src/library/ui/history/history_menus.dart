import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/track_id.dart';
import '../../domain/history/history_models.dart';
import '../../domain/playlists/playlist_models.dart';
import '../../state/browse/song_list_providers.dart'
    show trackRowLoaderProvider;
import '../../state/history/history_providers.dart';
import '../add_to_playlist/add_to_playlist.dart';
import '../menus/menu_items.dart' show soonRow;
import '../menus/menu_model.dart';
import '../menus/open_menu.dart';
import 'history_clear_dialog.dart';
import 'history_toasts.dart';

final _log = Logger('library.history');

/// Opens the ⋮ menu of the History page (sheet on mobile, dropdown on
/// desktop): play and shuffle every song ever played, add them to a playlist,
/// Most played, export, and the clear dialog.
Future<void> openHistoryPageMenu(
  BuildContext context, {
  bool viaKeyboard = false,
}) => openMenu(context, (container, env) async {
  final overview = await container.read(historyOverviewProvider.future);
  return buildHistoryPageMenu(
    env.l10n,
    plays: overview.plays,
    clearing: container.read(historyClearingProvider),
  );
}, viaKeyboard: viaKeyboard);

/// The page menu from the overview's play count ([plays]) and whether a clear
/// is running ([clearing]: clearing again waits).
///
/// Most played and the M3U export are built later, so they show dimmed with
/// the "coming soon" label, as every unbuilt row of the app does.
MenuSpec buildHistoryPageMenu(
  AppLocalizations l10n, {
  required int plays,
  required bool clearing,
}) {
  final any = plays > 0;
  return MenuSpec(
    header: MenuHeader(
      image: MenuImage.tile,
      tileIcon: KIcons.history,
      seed: 'history',
      title: l10n.historyTitle,
      subtitle: l10n.historyHeroPlays(plays),
    ),
    groups: [
      [
        MenuItemSpec(
          MenuItemId.play,
          icon: KIcons.play,
          title: l10n.libraryPlayAll,
          enabled: any,
          action: MenuAction.run(
            (ctx) => playHistoryOrToast(
              ctx,
              (a) => a.playAllHistory(label: l10n.historyTitle),
            ),
          ),
        ),
        MenuItemSpec(
          MenuItemId.shuffle,
          icon: KIcons.shuffle,
          title: l10n.libraryShuffle,
          enabled: any,
          action: MenuAction.run(
            (ctx) => playHistoryOrToast(
              ctx,
              (a) => a.playAllHistory(shuffle: true, label: l10n.historyTitle),
            ),
          ),
        ),
      ],
      [
        MenuItemSpec(
          MenuItemId.playlist,
          icon: KIcons.playlistAdd,
          title: l10n.libraryMenuAddToPlaylist,
          enabled: any,
          action: MenuAction.run(_addAllToPlaylist),
        ),
        soonRow(MenuItemId.link, KIcons.mostPlayed, l10n.historyMenuMostPlayed),
        soonRow(
          MenuItemId.playlistExportM3u,
          KIcons.fileExport,
          l10n.playlistMenuExportM3u,
        ),
      ],
      [
        MenuItemSpec(
          MenuItemId.delete,
          icon: KIcons.delete,
          title: l10n.historyMenuClear,
          enabled: any && !clearing,
          danger: true,
          action: MenuAction.run(showHistoryClearDialog),
        ),
      ],
    ],
  );
}

/// Every song ever played that can still play, last played first, read when
/// the row is chosen (the list can be long; the menu opens without it).
Future<void> _addAllToPlaylist(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final l10n = AppLocalizations.of(context);
  final List<TrackId> ids;
  try {
    final all = await container
        .read(historyStoreProvider)
        .playedTracksNewestFirst();
    final infos = await container.read(trackRowLoaderProvider)(all);
    final seen = <int>{};
    ids = [
      for (final t in infos)
        if (canPlayTrack(t) && seen.add(t.id.value)) t.id,
    ];
  } on Object catch (e) {
    _log.warning('Reading the played songs failed: ${e.runtimeType}');
    if (context.mounted) showAppSnackBar(context, l10n.playlistAddFailed);
    return;
  }
  if (!context.mounted) return;
  if (ids.isEmpty) {
    showAppSnackBar(context, l10n.historyNothingToAdd);
    return;
  }
  await showAddToPlaylist(
    context,
    AddToPlaylistRequest(tracks: ids, sourceLabel: l10n.historyTitle),
  );
}
