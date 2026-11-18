import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../playback/state/playback_providers.dart';
import '../../../domain/playlists/playlist_sort.dart';
import '../../../state/playlists/playlist_page_controller.dart';
import '../../../state/playlists/playlist_prefs_providers.dart';
import '../../browse/play_actions.dart';
import '../menu/playlist_menu_rows.dart';

final _log = Logger('library.playlists');

/// How long Play waits for the page's queued writes before it gives up.
const Duration playlistWriteWait = Duration(seconds: 5);

/// Plays playlist [uid] as the page shows it: the available entries in the
/// page's sort (the filter is ignored), after the writes the page has queued.
///
/// The request number is taken before anything is awaited, so a newer play
/// (anywhere in the library) wins over this one. Returns once playback was
/// asked for, dropped or failed; the caller ignores a second press until then.
/// [mounted] says whether the button's page is still there after the wait.
Future<void> playPlaylistPage(
  WidgetRef ref,
  BuildContext context,
  String uid, {
  required bool shuffle,
  required bool Function() mounted,
}) async {
  final requests = ref.read(playRequestsProvider.notifier);
  final request = requests.begin();
  final container = ProviderScope.containerOf(context, listen: false);
  final controller = container.read(playlistPageProvider(uid).notifier);
  final commands = ref.read(playbackCommandsProvider);
  final l10n = AppLocalizations.of(context);
  // The root navigator outlives the page, so a toast can still be shown.
  final root = Navigator.of(context, rootNavigator: true).context;
  try {
    try {
      await controller.afterWrites().timeout(playlistWriteWait);
    } on TimeoutException {
      if (root.mounted) showAppSnackBar(root, l10n.playlistSaveFailed);
      return;
    }
    if (!mounted() || !requests.isNewest(request)) return;
    final detail = container.read(playlistPageProvider(uid)).detail.value;
    if (detail == null) return;
    final sort = container.read(playlistTrackSortProvider(uid));
    final ids = [
      for (final e in sortPlaylistEntries(detail.entries, sort))
        if (e.available) e.info.id,
    ];
    if (ids.isEmpty) {
      if (root.mounted) showAppSnackBar(root, l10n.libraryNothingToPlay);
      return;
    }
    await playIds(
      commands,
      ids,
      playlistPlayContext(l10n, detail.summary),
      shuffle: shuffle,
    );
  } on Object catch (error, stack) {
    _log.warning('Playing playlist $uid failed', error, stack);
    if (root.mounted) showAppSnackBar(root, l10n.libraryPlayFailed);
  }
}
