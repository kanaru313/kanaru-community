import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/track_id.dart';
import '../../domain/history/history_models.dart';
import '../../domain/history/history_ranges.dart';
import '../../domain/history/top_queue.dart';
import '../../domain/playlists/playlist_models.dart';
import '../../state/favorites_providers.dart';
import '../../state/history/history_actions.dart';
import '../add_to_playlist/add_to_playlist.dart';
import '../history/history_export_rows.dart';
import '../menus/menu_model.dart';
import '../menus/open_menu.dart';
import 'most_played_labels.dart';

final _log = Logger('library.history');

/// Plays [entries] in rank order (shuffled when [shuffle]), songs that cannot
/// play left out, and says so when nothing played. [context] belongs to a
/// page or the root navigator (a menu action's), so the toast outlives the
/// menu.
Future<void> playMostPlayedOrToast(
  BuildContext context,
  List<TopEntry> entries, {
  bool shuffle = false,
}) async {
  final l10n = AppLocalizations.of(context);
  final actions = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(historyActionsProvider);
  final ok = await actions.playTop(
    entries,
    shuffle: shuffle,
    label: l10n.libraryNavMostPlayed,
  );
  if (!ok && context.mounted) {
    showAppSnackBar(context, l10n.historyMostPlayedPlayFailed);
  }
}

/// Opens the ⋮ menu of the Most played page (sheet on mobile, dropdown on
/// desktop) for the list as it is now: [entries] in rank order, [range] and
/// [today] to name it. [stale] (the list is reloading) dims every row.
Future<void> openMostPlayedMenu(
  BuildContext context, {
  required MostPlayed data,
  required MostPlayedRange range,
  required DateTime today,
  required bool stale,
  bool viaKeyboard = false,
}) => openMenu(
  context,
  (container, env) async => buildMostPlayedMenu(
    env.l10n,
    data: data,
    range: range,
    today: today,
    stale: stale,
  ),
  viaKeyboard: viaKeyboard,
);

/// The page menu: play by rank, shuffle, add to a playlist (named after the
/// range), add all to Favorites, export as M3U. Every row waits while the list
/// reloads ([stale]) and stays dim for an empty one.
MenuSpec buildMostPlayedMenu(
  AppLocalizations l10n, {
  required MostPlayed data,
  required MostPlayedRange range,
  required DateTime today,
  required bool stale,
}) {
  final queue = TopQueue(data.entries);
  final enabled = !stale && queue.ids.isNotEmpty;
  final name = mostPlayedListName(l10n, range, today);
  return MenuSpec(
    header: MenuHeader(
      image: MenuImage.tile,
      tileIcon: KIcons.mostPlayed,
      seed: 'most-played',
      title: l10n.libraryNavMostPlayed,
      subtitle: mostPlayedRangeLine(l10n, range, today),
    ),
    groups: [
      [
        MenuItemSpec(
          MenuItemId.play,
          icon: KIcons.play,
          title: l10n.historyMostPlayedMenuPlay,
          enabled: enabled,
          action: MenuAction.run(
            (ctx) => playMostPlayedOrToast(ctx, data.entries),
          ),
        ),
        MenuItemSpec(
          MenuItemId.shuffle,
          icon: KIcons.shuffle,
          title: l10n.libraryShuffle,
          enabled: enabled,
          action: MenuAction.run(
            (ctx) => playMostPlayedOrToast(ctx, data.entries, shuffle: true),
          ),
        ),
      ],
      [
        MenuItemSpec(
          MenuItemId.playlist,
          icon: KIcons.playlistAdd,
          title: l10n.libraryMenuAddToPlaylist,
          enabled: enabled,
          action: MenuAction.run(
            (ctx) => showAddToPlaylist(
              ctx,
              AddToPlaylistRequest(tracks: queue.ids, sourceLabel: name),
            ),
          ),
        ),
        MenuItemSpec(
          MenuItemId.favorite,
          icon: KIcons.heart,
          title: l10n.libraryMenuFavoriteAll,
          enabled: enabled,
          action: MenuAction.run((ctx) => favoriteAll(ctx, queue.ids)),
        ),
        ...trackListExportRows(
          l10n,
          name: name,
          enabled: enabled,
          tracks: () async => [for (final e in data.entries) e.track.id],
        ),
      ],
    ],
  );
}

/// Adds [ids] to Favorites and says how many were added and how many were
/// there already.
Future<void> favoriteAll(BuildContext context, List<TrackId> ids) async {
  final l10n = AppLocalizations.of(context);
  final container = ProviderScope.containerOf(context, listen: false);
  final messenger = ScaffoldMessenger.of(context);
  try {
    final already = await container.read(favoriteTrackIdsProvider.future);
    final skipped = ids.where(already.contains).length;
    await container.read(favoritesControllerProvider).setFavorite(ids, true);
    if (messenger.mounted) {
      showAppSnackBarOn(
        messenger,
        l10n.playlistFavoritedAll(ids.length - skipped, skipped),
      );
    }
  } on Object catch (e) {
    _log.warning(
      'Adding the most played to Favorites failed: ${e.runtimeType}',
    );
    if (messenger.mounted) {
      showAppSnackBarOn(messenger, l10n.historyMostPlayedFavoriteFailed);
    }
  }
}
