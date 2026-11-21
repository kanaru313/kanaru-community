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
import '../menus/menu_model.dart';
import '../menus/open_menu.dart';
import 'history_clear_dialog.dart';
import 'history_export_rows.dart';
import 'history_locations.dart';
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
    playedTracks: () =>
        container.read(historyStoreProvider).playedTracksNewestFirst(),
  );
}, viaKeyboard: viaKeyboard);

/// The page menu from the overview's play count ([plays]) and whether a clear
/// is running ([clearing]: clearing again waits). [playedTracks] reads every
/// song ever played, last played first, when the M3U export is chosen.
MenuSpec buildHistoryPageMenu(
  AppLocalizations l10n, {
  required int plays,
  required bool clearing,
  required Future<List<TrackId>> Function() playedTracks,
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
        MenuItemSpec(
          MenuItemId.playlist,
          icon: KIcons.playlistAdd,
          title: l10n.libraryMenuAddToPlaylist,
          enabled: any,
          action: MenuAction.run(_addAllToPlaylist),
        ),
      ],
      [
        MenuItemSpec(
          // The id of the "go to" rows: no dedicated id exists for this one.
          MenuItemId.link,
          icon: KIcons.mostPlayed,
          title: l10n.historyMenuMostPlayed,
          action: MenuAction.go(HistoryLocations.mostPlayed),
        ),
        trackListExportRow(
          l10n,
          name: l10n.historyTitle,
          fallback: l10n.historyTitle,
          tracks: playedTracks,
          enabled: any,
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
