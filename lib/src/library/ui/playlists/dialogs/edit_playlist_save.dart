import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/playlists/playlist_models.dart';
import '../../../state/playlists/playlist_editor.dart';
import 'playlist_form_model.dart';

final _log = Logger('library.playlists');

/// Saves the form; shared by both shells.
class PlaylistEditSave {
  const PlaylistEditSave(
    this.container,
    this.messenger,
    this.l10n,
    this.summary,
  );

  final ProviderContainer container;
  final ScaffoldMessengerState messenger;
  final AppLocalizations l10n;
  final PlaylistSummary summary;

  void _toast(String message) {
    if (messenger.mounted) showAppSnackBarOn(messenger, message);
  }

  /// Writes the changes; true when the dialog should close.
  Future<bool> run(PlaylistFormModel form) async {
    final name = form.cleanName;
    final description = form.cleanDescription;
    final coverChanged = form.automaticCover.value;
    if (!coverChanged &&
        name == summary.name &&
        description == summary.description) {
      return true; // nothing changed: nothing to write
    }
    final PlaylistEditResult result;
    form.saving.value = true;
    try {
      result = await container
          .read(playlistEditorProvider)
          .save(
            summary.uid,
            name: name,
            description: description,
            cover: form.cover,
          );
    } on Object catch (error, stack) {
      _log.warning('Saving playlist ${summary.uid} failed', error, stack);
      _toast(l10n.playlistSaveFailed);
      form.saving.value = false;
      return false;
    }
    // Before the caller closes the dialog: the model dies with its route.
    form.saving.value = false;
    switch (result.text) {
      case PlaylistUpdate.gone:
        _toast(l10n.playlistNotFoundTitle);
      case _ when result.coverFailed:
        _toast(l10n.plScreensCoverFailed);
      case PlaylistUpdate.saved:
        _toast(l10n.playlistSaved);
      case PlaylistUpdate.unchanged:
        if (coverChanged) _toast(l10n.playlistSaved);
    }
    return true;
  }
}
