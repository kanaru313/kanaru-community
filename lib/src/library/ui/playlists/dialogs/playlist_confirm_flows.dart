import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/playlists/playlist_ids.dart';
import '../../../domain/playlists/playlist_models.dart';
import '../../../state/playlists/playlist_page_controller.dart';
import '../../../state/playlists/playlist_prefs_providers.dart';
import '../../../state/playlists/playlist_providers.dart';
import '../../library_locations.dart';
import '../../playlist_common/playlist_labels.dart';
import '../playlist_removal_toasts.dart';

final _log = Logger('library.playlists');

/// The wait for the page route to finish leaving is bounded, so a route that
/// stays on screen cannot block the delete.
const _exitWait = Duration(seconds: 1);

/// Asks, then deletes playlist [summary] for good (the songs stay).
///
/// [pageRoute]: the route of the playlist's own page when the flow starts from
/// it (capture `ModalRoute.of(pageContext)` before calling), null otherwise.
/// With it the page is left first (pop, or go to the list when nothing is
/// below) and the delete waits for `pageRoute.completed`, which completes when
/// the exit animation ended and also when the route is disposed without one (a
/// `go`), at most 1 s. The page therefore never shows "not found" while it
/// slides away. If the page is no longer the current route after the
/// confirmation (the router moved meanwhile) nothing is popped: the delete just
/// runs. Everything used after an await was captured before it. A failure
/// shows a toast on the list page.
Future<void> deletePlaylistFlow(
  BuildContext context,
  PlaylistSummary summary, {
  ModalRoute<Object?>? pageRoute,
}) async {
  assert(!summary.isFavorites, 'Favorites cannot be deleted');
  final l10n = AppLocalizations.of(context);
  final container = ProviderScope.containerOf(context);
  final messenger = ScaffoldMessenger.of(
    Navigator.of(context, rootNavigator: true).context,
  );
  final router = pageRoute == null ? null : GoRouter.of(context);
  final name = playlistDisplayName(l10n, summary);

  final confirmed = await confirmAction(
    context,
    title: l10n.playlistDeleteTitle(name),
    message: l10n.playlistDeleteBody(summary.trackCount),
    confirmLabel: l10n.playlistDeleteConfirm,
    destructive: true,
  );
  if (!confirmed) return;

  if (router != null && pageRoute != null && pageRoute.isCurrent) {
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(LibraryLocations.playlists);
    }
    await pageRoute.completed.timeout(_exitWait, onTimeout: () => null);
  }
  final bool deleted;
  try {
    deleted = await container
        .read(playlistStoreProvider)
        .deletePlaylist(summary.uid);
  } on Object catch (error, stack) {
    _log.warning('Deleting playlist ${summary.uid} failed', error, stack);
    if (messenger.mounted) {
      showAppSnackBarOn(messenger, l10n.plScreensDeleteFailed);
    }
    return;
  }
  // The playlist is gone either way; a stale remembered sort is harmless.
  try {
    await container
        .read(playlistTrackSortsProvider.notifier)
        .forget(summary.uid);
  } on Object catch (error, stack) {
    _log.warning('Forgetting the sort of ${summary.uid} failed', error, stack);
  }
  // false: it was already gone, so there is nothing to announce.
  if (deleted && messenger.mounted) {
    showAppSnackBarOn(messenger, l10n.plScreensDeleted(name));
  }
}

/// Asks, then removes every song from Favorites with an Undo toast. On the
/// Favorites page the removal goes through the page's write gate (the list
/// updates at once); elsewhere straight to the store.
Future<void> clearFavoritesFlow(
  BuildContext context,
  PlaylistDetail favorites,
) async {
  assert(favorites.summary.isFavorites, 'Only Favorites is cleared');
  final l10n = AppLocalizations.of(context);
  final container = ProviderScope.containerOf(context);
  final rootContext = Navigator.of(context, rootNavigator: true).context;
  final messenger = ScaffoldMessenger.of(rootContext);
  // The entries the user saw in the confirmation: songs ♥'d meanwhile stay.
  final uids = [for (final e in favorites.entries) e.uid];
  if (uids.isEmpty) return;

  final confirmed = await confirmAction(
    context,
    title: l10n.playlistClearFavoritesTitle,
    message: l10n.playlistClearFavoritesBody(uids.length),
    confirmLabel: l10n.playlistClearFavoritesConfirm,
    destructive: true,
  );
  if (!confirmed) return;

  try {
    final page = playlistPageProvider(PlaylistUids.favorites);
    final removal = container.read(page.exists)
        ? await container.read(page.notifier).remove(uids)
        : await container
              .read(playlistStoreProvider)
              .removeEntries(PlaylistUids.favorites, uids);
    if (removal == null || !rootContext.mounted) return;
    showRemovalToast(
      rootContext,
      container,
      removal,
      l10n.playlistClearedFavorites,
    );
  } on Object catch (error, stack) {
    _log.warning('Clearing Favorites failed', error, stack);
    if (messenger.mounted) {
      showAppSnackBarOn(messenger, l10n.playlistSaveFailed);
    }
  }
}
