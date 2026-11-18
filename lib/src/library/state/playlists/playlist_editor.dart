import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../domain/playlists/playlist_models.dart';
import '../../domain/playlists/playlist_store.dart';
import '../custom_cover_providers.dart';
import 'playlist_providers.dart';

final _log = Logger('library.playlists');

/// What the Edit dialog does with the cover.
sealed class PlaylistCoverEdit {
  /// Leave the cover as it is.
  const factory PlaylistCoverEdit.keep() = _Keep;

  /// Drop the custom cover; the automatic one shows again.
  const factory PlaylistCoverEdit.automatic() = _Automatic;

  /// Use [image] (a readable local JPEG, PNG or WebP) as the cover.
  const factory PlaylistCoverEdit.file(File image) = _FileCover;
}

final class _Keep implements PlaylistCoverEdit {
  const _Keep();
}

final class _Automatic implements PlaylistCoverEdit {
  const _Automatic();
}

final class _FileCover implements PlaylistCoverEdit {
  const _FileCover(this.image);
  final File image;
}

/// [text] is the outcome of the name and description write; [coverFailed]
/// means the text is saved but the cover change was not.
class PlaylistEditResult {
  const PlaylistEditResult({required this.text, this.coverFailed = false});

  final PlaylistUpdate text;
  final bool coverFailed;

  @override
  bool operator ==(Object other) =>
      other is PlaylistEditResult &&
      other.text == text &&
      other.coverFailed == coverFailed;

  @override
  int get hashCode => Object.hash(text, coverFailed);
}

/// Saves the Edit dialog with one call.
class PlaylistEditor {
  PlaylistEditor(this._store, this._covers);

  final PlaylistStore _store;
  final CustomCoverController _covers;

  /// Name and description go in one database transaction (`ArgumentError` for
  /// an invalid value, nothing written). The cover follows: a copied file
  /// cannot share that transaction, so a cover failure is reported in the
  /// result and the text stays saved. A playlist that is gone skips the cover.
  Future<PlaylistEditResult> save(
    String uid, {
    required String name,
    required String description,
    PlaylistCoverEdit cover = const PlaylistCoverEdit.keep(),
  }) async {
    final text = await _store.updatePlaylist(
      uid,
      name: name,
      description: description,
    );
    if (text == PlaylistUpdate.gone || cover is _Keep) {
      return PlaylistEditResult(text: text);
    }
    try {
      switch (cover) {
        case _Automatic():
          await _covers.removeCover(CustomCoverKind.playlist, uid);
        case _FileCover(:final image):
          await _covers.importCover(CustomCoverKind.playlist, uid, image);
        case _Keep():
          break;
      }
      return PlaylistEditResult(text: text);
    } on Object catch (error, stack) {
      _log.warning('Playlist cover change failed', error, stack);
      return PlaylistEditResult(text: text, coverFailed: true);
    }
  }
}

final playlistEditorProvider = Provider<PlaylistEditor>(
  (ref) => PlaylistEditor(
    ref.watch(playlistStoreProvider),
    ref.watch(customCoverControllerProvider),
  ),
);
