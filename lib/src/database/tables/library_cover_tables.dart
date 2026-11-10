import 'package:drift/drift.dart';

/// Colours taken from a cover, keyed by the cover's content key. A cache:
/// it may be dropped at any time and is rebuilt from the cover. No foreign
/// key: the key is a content hash shared by many tracks.
@DataClassName('CoverColorsRow')
class CoverColors extends Table {
  /// Same value as `tracks.cover_key`.
  TextColumn get coverKey => text()();

  /// ARGB seed colour (input of `ColorScheme.fromSeed`).
  IntColumn get seed => integer()();

  /// JSON array of ARGB ints, most dominant first.
  TextColumn get colors => text()();

  /// Version of the algorithm that produced the row.
  IntColumn get version => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {coverKey};
}

/// Values of `custom_covers.kind`: the item types that can carry a cover
/// chosen by the user. Songs are not included. The typed version for callers
/// is `CustomCoverKind` in `library/domain/`; a test keeps the two equal.
abstract final class CustomCoverKinds {
  /// `item_key` = playlist uid.
  static const playlist = 'playlist';

  /// `item_key` = `AlbumKey.encode()`.
  static const album = 'album';

  /// `item_key` = `ArtistKey.encode()`.
  static const artist = 'artist';

  static const Set<String> values = {playlist, album, artist};
}

/// A cover image the user chose for a playlist, album or artist. Albums and
/// artists have no table, so `item_key` is not a foreign key; a playlist's row
/// is removed by the `custom_covers_playlist_delete` trigger. The image file
/// lives in the data dir under `custom_covers/<cover_key>.<ext>`.
@DataClassName('CustomCoverRow')
@TableIndex(name: 'custom_covers_cover_key', columns: {#coverKey})
class CustomCovers extends Table {
  TextColumn get kind => text()
      // A drift column check refers to its own column.
      // ignore: recursive_getters
      .check(kind.isIn(CustomCoverKinds.values))();

  /// Playlist uid, or the encoded `AlbumKey` / `ArtistKey`.
  TextColumn get itemKey => text()();

  /// Content hash of the stored image (SHA-256, lower-case hex).
  TextColumn get coverKey => text()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {kind, itemKey};
}
