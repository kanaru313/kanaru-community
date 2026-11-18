import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../playback/state/playback_providers.dart';
import '../../../domain/playlists/playlist_models.dart';
import '../../../state/playlists/playlist_page_controller.dart';
import '../../../state/playlists/playlist_providers.dart';
import '../../browse/play_actions.dart';
import '../menu/playlist_menu_rows.dart';
import '../page/playlist_play_gate.dart' show playlistWriteWait;

final _log = Logger('library.playlist_play');

/// Plays the available songs of [summary]'s playlist in the order saved in it
/// (never the sort of the list on screen).
///
/// Takes a play request number first: the playlist is read from the store
/// afterwards, so a read that finishes after the user started something newer
/// is dropped. Everything the toasts need is taken before the read; the tile
/// may be gone by then.
Future<void> playPlaylist(
  WidgetRef ref,
  BuildContext context,
  PlaylistSummary summary,
) async {
  final requests = ref.read(playRequestsProvider.notifier);
  final request = requests.begin();
  final store = ref.read(playlistStoreProvider);
  final commands = ref.read(playbackCommandsProvider);
  final l10n = AppLocalizations.of(context);
  final playContext = playlistPlayContext(l10n, summary);
  // The root navigator outlives the tile, so a toast can still be shown.
  final root = Navigator.of(context, rootNavigator: true).context;
  try {
    // The open page's queued writes land first, as for the menu's Play.
    final container = ProviderScope.containerOf(context, listen: false);
    final page = playlistPageProvider(summary.uid);
    if (container.read(page.exists)) {
      try {
        await container
            .read(page.notifier)
            .afterWrites()
            .timeout(playlistWriteWait);
      } on TimeoutException {
        if (root.mounted) showAppSnackBar(root, l10n.playlistSaveFailed);
        return;
      }
    }
    final detail = await store.loadPlaylist(summary.uid);
    if (!requests.isNewest(request)) {
      _log.fine('play request $request dropped: a newer one started');
      return;
    }
    if (detail == null) {
      if (root.mounted) showAppSnackBar(root, l10n.libraryNotFoundMessage);
      return;
    }
    final ids = detail.playableIds;
    if (ids.isEmpty) {
      if (root.mounted) showAppSnackBar(root, l10n.libraryNothingToPlay);
      return;
    }
    await playIds(commands, ids, playContext);
  } on Object catch (e, s) {
    _log.warning('playing playlist ${summary.uid} failed', e, s);
    if (root.mounted) showAppSnackBar(root, l10n.libraryPlayFailed);
  }
}
