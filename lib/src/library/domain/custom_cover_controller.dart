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
  /// Turns [source] into a cover (a 256 px thumb and a 1024 px full JPEG plus
  /// colours, like a song cover) in the app data folder and makes it the cover
  /// of the item. The source path is not kept. [source] must be a readable
  /// regular local file (JPEG, PNG or WebP, sniffed from the content): on
  /// Android copy a `content://` picker result to a temp file first.
  ///
  /// Failed futures: [FormatException] when the image cannot be used for good
  /// (undecodable, another format, too large for the native limits, a missing
  /// or special file, a native panic); [FileSystemException] when it may work
  /// later or the file cannot be read (I/O error, permission denied, failing
  /// to write under the data folder, the import taking longer than 60 s);
  /// [ArgumentError] for an empty or malformed [itemKey] (album and artist
  /// keys must decode) or for the Favorites playlist. Database failures (for
  /// example a playlist that was deleted meanwhile) arrive as `SqliteException`,
  /// wrapped in `DriftRemoteException` on the file database. Any other error
  /// means the native library is unavailable. The old cover stays on every
  /// failure, and cover files nothing references are removed (a colours row
  /// written before a failed row write is harmless and may stay).
  Future<void> importCover(CustomCoverKind kind, String itemKey, File source);

  /// Makes [choice] the cover of the item and returns a handle to take it back.
  /// The previous cover's files are kept until the handle is released (see
  /// [CoverChange]); the caller must release it. Errors and the failure
  /// guarantees are those of [importCover] ([choice] a file); choosing the
  /// automatic cover only fails with [ArgumentError] or a database error. The
  /// old cover stays when it fails.
  Future<CoverChange> changeCover(
    CustomCoverKind kind,
    String itemKey,
    CoverChoice choice,
  );

  /// Decodes [source] once, upright, for the crop dialog. The caller deletes
  /// the preview file. Failures like [importCover]: [FormatException] for an
  /// image that cannot be used, [FileSystemException] for a read or write
  /// problem or a preview taking longer than 60 s.
  Future<CoverPreview> previewCover(File source);

  /// Back to the automatic cover. No-op when the item has no custom cover.
  /// Fails with [ArgumentError] like [importCover] for a malformed [itemKey].
  Future<void> removeCover(CustomCoverKind kind, String itemKey);

  /// Deletes cover files (thumb and full) that no row references, and temp
  /// files of the native writer, when older than one hour. Returns the number of files deleted.
  Future<int> collectUnreferencedFiles();
}
