import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../state/playlists/playlist_providers.dart';
import '../../browse/library_navigation.dart';
import '../../library_locations.dart';
import 'playlist_name_dialog.dart';

/// "Playlist mới": asks for a name (default "New playlist"), creates an empty
/// playlist and opens its page. Returns the new playlist's uid, null when the
/// user cancelled. The page is opened only while [context] is still mounted.
Future<String?> showCreatePlaylistDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final store = ProviderScope.containerOf(context).read(playlistStoreProvider);
  String? uid;
  await showKDialog<void>(
    context,
    builder: (_) => PlaylistNameDialog(
      title: l10n.playlistCreateTitle,
      confirmLabel: l10n.playlistCreateConfirm,
      initialName: l10n.playlistDefaultName,
      submit: (name) async => uid = await store.createPlaylist(name: name),
    ),
  );
  final created = uid;
  if (created != null && context.mounted) {
    // A push that completes when the page is popped: not awaited.
    unawaited(
      openLibraryPage<void>(context, LibraryLocations.playlist(created)),
    );
  }
  return created;
}
