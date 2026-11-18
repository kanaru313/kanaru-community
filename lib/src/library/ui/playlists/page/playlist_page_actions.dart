import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/playlists/playlist_ids.dart';
import '../../../domain/playlists/playlist_models.dart';
import '../../../state/playlists/playlist_page_controller.dart';
import '../playlist_removal_toasts.dart';

final _log = Logger('library.playlists');

/// Removes every missing entry of playlist [uid] through its open page, with
/// an Undo toast.
Future<void> removeUnavailableOnPage(BuildContext context, String uid) =>
    _removeOnPage(
      context,
      (page) => page(uid).removeUnavailable(),
      (l10n, removal) =>
          l10n.playlistRemovedUnavailable(removal.entryUids.length),
    );

/// Removes one entry of playlist [uid] through its open page, with an Undo
/// toast.
Future<void> removeEntryOnPage(
  BuildContext context,
  String uid,
  PlaylistEntryView entry,
) => _removeOnPage(
  context,
  (page) => page(uid).remove([entry.uid]),
  (l10n, _) => uid == PlaylistUids.favorites
      ? l10n.playlistRemovedFavorite(entry.info.title)
      : l10n.playlistRemovedEntry(entry.info.title),
);

typedef _PageOf = PlaylistPageController Function(String uid);

/// Runs [remove] on the page's controller and announces the result. A write
/// that failed says so once; the writes queued behind it were cancelled and
/// stay silent. Everything the toast needs is taken before the write, as the
/// row may be gone when it ends.
Future<void> _removeOnPage(
  BuildContext context,
  Future<PlaylistRemoval?> Function(_PageOf page) remove,
  String Function(AppLocalizations l10n, PlaylistRemoval removal) message,
) async {
  final container = ProviderScope.containerOf(context);
  final l10n = AppLocalizations.of(context);
  final root = Navigator.of(context, rootNavigator: true).context;
  try {
    final removal = await remove(
      (uid) => container.read(playlistPageProvider(uid).notifier),
    );
    if (removal == null || !root.mounted) return;
    showRemovalToast(root, container, removal, message(l10n, removal));
  } on PlaylistWriteFailure catch (failure) {
    if (failure.cancelled) return;
    _log.warning('A playlist removal failed', failure.cause);
    if (root.mounted) showAppSnackBar(root, l10n.playlistSaveFailed);
  } on Object catch (error, stack) {
    _log.warning('A playlist removal failed', error, stack);
    if (root.mounted) showAppSnackBar(root, l10n.playlistSaveFailed);
  }
}
