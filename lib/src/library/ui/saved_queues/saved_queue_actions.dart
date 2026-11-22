import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/track_id.dart';
import '../../../playback/state/playback_providers.dart';
import '../../domain/playlists/playlist_models.dart';
import '../../state/favorites_providers.dart';
import '../../state/saved_queues/saved_queue_providers.dart';
import '../add_to_playlist/add_to_playlist.dart';
import 'saved_queue_labels.dart';
import 'saved_queue_read.dart';

final _log = Logger('library.saved_queues');

/// The songs of saved queue [uid] that can play now, read at the moment of the
/// call. Null after saying why on [root]: the queue is gone, or has nothing
/// playable.
Future<List<TrackId>?> _playableOrSay(
  BuildContext root,
  AppLocalizations l10n,
  ProviderContainer container,
  String uid,
) async {
  final detail = await readSavedQueue(
    container.read(savedQueueStoreProvider),
    uid,
  );
  if (!root.mounted) return null;
  if (detail == null) {
    showAppSnackBar(root, l10n.savedQueueNotFoundTitle);
    return null;
  }
  final ids = savedQueuePlayableIds(detail);
  if (ids.isEmpty) {
    showAppSnackBar(root, l10n.libraryNothingToPlay);
    return null;
  }
  return ids;
}

/// Runs [body] for saved queue [uid] with the root context, the container and
/// the words taken before any await; a failure is logged and shown as
/// [failure].
Future<void> _guarded(
  BuildContext context,
  String what,
  String Function(AppLocalizations l10n) failure,
  Future<void> Function(
    BuildContext root,
    AppLocalizations l10n,
    ProviderContainer container,
  )
  body,
) async {
  final l10n = AppLocalizations.of(context);
  final container = ProviderScope.containerOf(context, listen: false);
  final root = Navigator.of(context, rootNavigator: true).context;
  try {
    await body(root, l10n, container);
  } on Object catch (e, s) {
    _log.warning('$what failed', e, s);
    if (root.mounted) showAppSnackBar(root, failure(l10n));
  }
}

/// Adds the songs of saved queue [uid] to the end of the current queue.
Future<void> appendSavedQueue(BuildContext context, String uid) => _guarded(
  context,
  'adding saved queue $uid to the queue',
  (l10n) => l10n.libraryMenuQueueFailed,
  (root, l10n, container) async {
    final commands = container.read(playbackCommandsProvider);
    final ids = await _playableOrSay(root, l10n, container, uid);
    if (ids == null) return;
    await commands.enqueue(ids);
    if (root.mounted) showAppSnackBar(root, l10n.libraryMenuQueued);
  },
);

/// Opens the "add to playlist" picker with the songs of saved queue [uid];
/// [sourceLabel] names the queue in it.
Future<void> saveSavedQueueAsPlaylist(
  BuildContext context,
  String uid,
  String sourceLabel,
) => _guarded(
  context,
  'saving saved queue $uid as a playlist',
  (l10n) => l10n.playlistAddFailed,
  (root, l10n, container) async {
    final ids = await _playableOrSay(root, l10n, container, uid);
    if (ids == null || !root.mounted) return;
    await showAddToPlaylist(
      root,
      AddToPlaylistRequest(tracks: ids, sourceLabel: sourceLabel),
    );
  },
);

/// Adds the songs of saved queue [uid] to Favorites and says how many were
/// added and how many were there already.
Future<void> favoriteSavedQueue(BuildContext context, String uid) => _guarded(
  context,
  'adding saved queue $uid to Favorites',
  (l10n) => l10n.libraryFavoriteFailed,
  (root, l10n, container) async {
    final ids = await _playableOrSay(root, l10n, container, uid);
    if (ids == null) return;
    final distinct = ids.toSet();
    // A provider nobody listens to is paused and never answers: hold it open
    // for the read (the page may have no heart on screen to do it).
    final Set<TrackId> already;
    final hold = container.listen(favoriteTrackIdsProvider, (_, _) {});
    try {
      already = await container.read(favoriteTrackIdsProvider.future);
    } finally {
      hold.close();
    }
    final skipped = distinct.where(already.contains).length;
    await container
        .read(favoritesControllerProvider)
        .setFavorite(distinct.toList(), true);
    if (root.mounted) {
      showAppSnackBar(
        root,
        l10n.playlistFavoritedAll(distinct.length - skipped, skipped),
      );
    }
  },
);

/// Removes the entries of saved queue [uid] whose song is missing now (read at
/// the moment of the call, not from the count the menu drew) and says how
/// many went. Nothing to remove stays quiet.
Future<void> removeMissingFromSavedQueue(BuildContext context, String uid) =>
    _guarded(
      context,
      'removing the missing songs of saved queue $uid',
      (l10n) => l10n.savedQueueRemoveFailed,
      (root, l10n, container) async {
        final removed = await container
            .read(savedQueueStoreProvider)
            .removeMissingFromSavedQueue(uid);
        if (removed > 0 && root.mounted) {
          showAppSnackBar(root, l10n.savedQueueRemovedMissing(removed));
        }
      },
    );
