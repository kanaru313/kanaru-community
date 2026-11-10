import 'dart:io';

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
  /// Copies [source] into the app data folder and makes it the cover of the
  /// item. The source path is not kept. [source] must be a readable regular
  /// local file: on Android copy a `content://` picker result to a temp file
  /// first.
  ///
  /// Failed futures: [FormatException] when the file is not a supported image
  /// (JPEG, PNG, WebP, GIF, BMP), is not a regular file, is empty or larger
  /// than 8 MiB; `TimeoutException` when reading stalls; [ArgumentError] for an
  /// empty or malformed [itemKey] (album and artist keys must decode) or for
  /// the Favorites playlist (a missing source is also a [FormatException]);
  /// [FileSystemException] when the source exists but cannot be read
  /// (permissions). Database failures (for example a playlist that was deleted
  /// meanwhile) arrive as `SqliteException`, wrapped in `DriftRemoteException`
  /// on the file database. Nothing is left behind on failure.
  Future<void> importCover(CustomCoverKind kind, String itemKey, File source);

  /// Back to the automatic cover. No-op when the item has no custom cover.
  Future<void> removeCover(CustomCoverKind kind, String itemKey);

  /// Deletes image files that no row references and leftover temp files, when
  /// they are older than one hour. Returns the number of files deleted.
  Future<int> collectUnreferencedFiles();
}
