import 'dart:io';

import 'covers/cover_choice.dart';
import 'covers/cover_preview.dart';

/// What can carry a user-chosen cover. The names are stored in
/// `custom_covers.kind`; a test keeps them equal to the table's CHECK set.
/// Songs and Favorites (a fixed heart tile) have no custom cover.
enum CustomCoverKind {
  /// `itemKey` = playlist uid.
  playlist,

  /// `itemKey` = `AlbumKey.encode()`.
  album,

  /// `itemKey` = `ArtistKey.encode()`.
  artist,
}

/// Covers the user chose for playlists, albums and artists.
abstract interface class CustomCoverController {
  /// Makes [choice] the cover of the item and returns a handle to take it back.
  /// The previous cover's files are kept until the handle is released (see
  /// [CoverChange]); the caller must release it. Errors and the failure
  /// guarantees (a [choice] file): [FormatException] when the image cannot be
  /// used for good (undecodable, another format, too large, a native panic);
  /// [FileSystemException] when it may work later or the file cannot be read
  /// (I/O error, missing file, permission denied, an import over 60 s);
  /// [ArgumentError] for a malformed [itemKey] or the Favorites playlist;
  /// database failures arrive as `SqliteException`. Choosing the automatic
  /// cover only fails with [ArgumentError] or a database error. The old cover
  /// stays when it fails.
  Future<CoverChange> changeCover(
    CustomCoverKind kind,
    String itemKey,
    CoverChoice choice,
  );

  /// Decodes [source] once, upright, for the crop dialog. The caller deletes
  /// the preview file. Failures: [FormatException] for an
  /// image that cannot be used, [FileSystemException] for a read or write
  /// problem or a preview taking longer than 60 s.
  Future<CoverPreview> previewCover(File source);

  /// Back to the automatic cover. No-op when the item has no custom cover.
  /// Fails with [ArgumentError] for a malformed [itemKey].
  Future<void> removeCover(CustomCoverKind kind, String itemKey);

  /// Deletes cover files (thumb and full) that no row references, and temp
  /// files of the native writer, when older than one hour. Returns the number of files deleted.
  Future<int> collectUnreferencedFiles();
}
