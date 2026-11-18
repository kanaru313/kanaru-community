import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/playlists/playlist_models.dart';
import '../../../domain/playlists/playlist_text_rules.dart';
import '../../../state/playlists/playlist_page_controller.dart';
import '../../../state/playlists/playlist_providers.dart';
import '../playlist_removal_toasts.dart';

final _log = Logger('library.playlists');

/// Adds every available song of playlist [uid] to Favorites and says how many
/// were added and skipped (already there). A playlist deleted meanwhile says
/// so, nothing is written.
Future<void> favoriteAllOf(BuildContext context, String uid) async {
  final l10n = AppLocalizations.of(context);
  final store = ProviderScope.containerOf(context).read(playlistStoreProvider);
  final messenger = ScaffoldMessenger.of(context);
  try {
    final result = await store.addAllToFavorites(uid);
    if (!messenger.mounted) return;
    showAppSnackBarOn(
      messenger,
      result.goneUids.isNotEmpty
          ? l10n.libraryNotFoundMessage
          : l10n.playlistFavoritedAll(
              result.addedTrackCount,
              result.skippedTrackCount,
            ),
    );
  } on Object catch (error, stack) {
    _log.warning('Adding $uid to Favorites failed', error, stack);
    if (messenger.mounted) {
      showAppSnackBarOn(messenger, l10n.playlistSaveFailed);
    }
  }
}

/// Copies Favorites into a new playlist named [name] at once (no dialog).
Future<void> saveFavoritesAsPlaylist(
  BuildContext context,
  String favoritesUid,
  String name,
) async {
  final l10n = AppLocalizations.of(context);
  final store = ProviderScope.containerOf(context).read(playlistStoreProvider);
  final messenger = ScaffoldMessenger.of(context);
  final cappedName = capPlaylistName(name);
  try {
    final uid = await store.duplicatePlaylist(favoritesUid, name: cappedName);
    if (!messenger.mounted) return;
    showAppSnackBarOn(
      messenger,
      uid == null
          ? l10n.libraryNotFoundMessage
          : l10n.playlistDuplicated(cappedName),
    );
  } on Object catch (error, stack) {
    _log.warning('Saving Favorites as a playlist failed', error, stack);
    if (messenger.mounted) {
      showAppSnackBarOn(messenger, l10n.playlistSaveFailed);
    }
  }
}

/// Removes the repeated songs of playlist [uid], keeping the first of each,
/// with an Undo toast.
Future<void> removeDuplicateEntries(BuildContext context, String uid) =>
    _removeAndAnnounce(
      context,
      uid,
      (container, pageOpen) => pageOpen
          ? container
                .read(playlistPageProvider(uid).notifier)
                .removeDuplicates()
          : container.read(playlistStoreProvider).removeDuplicates(uid),
      (l10n, count) => l10n.playlistRemovedDuplicates(count),
    );

/// Removes the entries [entryUids] (read when the menu opened) of playlist
/// [uid], with an Undo toast. Entries that went missing after that stay.
Future<void> removeMissingEntries(
  BuildContext context,
  String uid,
  List<String> entryUids,
) => _removeAndAnnounce(context, uid, (container, pageOpen) {
  if (!pageOpen) {
    return container.read(playlistStoreProvider).removeEntries(uid, entryUids);
  }
  // Only the captured entries the page still shows.
  final shown = container.read(playlistPageProvider(uid)).detail.value;
  final present = {
    for (final e in shown?.entries ?? const <PlaylistEntryView>[]) e.uid,
  };
  final left = [
    for (final id in entryUids)
      if (present.contains(id)) id,
  ];
  if (shown != null && left.isEmpty) return Future.value();
  return container.read(playlistPageProvider(uid).notifier).remove(left);
}, (l10n, count) => l10n.playlistRemovedUnavailable(count));

/// Runs [remove] and shows the Undo toast. When the page of the playlist is
/// open the removal goes through its write gate (the list updates at once and
/// the write waits for the ones queued before it), else straight to the
/// store. Nothing removed: a playlist that is gone says so, one that is not
/// has nothing left to remove and stays quiet.
Future<void> _removeAndAnnounce(
  BuildContext context,
  String uid,
  Future<PlaylistRemoval?> Function(ProviderContainer container, bool pageOpen)
  remove,
  String Function(AppLocalizations l10n, int count) message,
) async {
  final l10n = AppLocalizations.of(context);
  final container = ProviderScope.containerOf(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    final pageOpen = container.read(playlistPageProvider(uid).exists);
    final removal = await remove(container, pageOpen);
    if (!messenger.mounted || !context.mounted) return;
    if (removal != null) {
      showRemovalToast(
        context,
        container,
        removal,
        message(l10n, removal.entryUids.length),
      );
      return;
    }
    await _announceIfGone(container, messenger, l10n, uid);
  } on Object catch (error, stack) {
    _log.warning('Removing entries of $uid failed', error, stack);
    if (messenger.mounted) {
      showAppSnackBarOn(messenger, l10n.playlistSaveFailed);
    }
  }
}

/// Nothing was removed: a playlist that is gone says so, one that is not has
/// nothing left to remove and stays quiet.
Future<void> _announceIfGone(
  ProviderContainer container,
  ScaffoldMessengerState messenger,
  AppLocalizations l10n,
  String uid,
) async {
  final stillThere =
      await container.read(playlistStoreProvider).loadPlaylist(uid) != null;
  if (!stillThere && messenger.mounted) {
    showAppSnackBarOn(messenger, l10n.libraryNotFoundMessage);
  }
}
