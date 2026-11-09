import 'package:drift/drift.dart';

import 'library_source_tables.dart';
import 'library_track_tables.dart';

/// Values of `playlists.kind`. The column has no CHECK; NULL means a normal
/// or imported playlist.
abstract final class PlaylistKind {
  /// The one Favorites playlist (uid `favorites`).
  static const favorites = 'favorites';

  /// A mood playlist, unique by `name_key`.
  static const mood = 'mood';

  static const Set<String> values = {favorites, mood};
}

/// Values of `saved_items.kind`. The column has no CHECK.
abstract final class SavedItemKind {
  static const album = 'album';
  static const artist = 'artist';

  /// A playlist that lives on the remote source, saved by reference.
  static const playlistRemote = 'playlist_remote';

  static const Set<String> values = {album, artist, playlistRemote};
}

/// A user playlist: Favorites, a mood, a normal one or one imported from a
/// file. Deleting one is a hard `DELETE`; its entries cascade. `uid` is the
/// only unconditional unique key; the partial unique indexes cover live rows
/// only, so a tombstone never blocks a new playlist.
@DataClassName('Playlist')
@TableIndex.sql(
  'CREATE UNIQUE INDEX playlists_favorites_unique ON playlists (kind) '
  "WHERE kind = 'favorites' AND deleted_at IS NULL",
)
@TableIndex.sql(
  'CREATE UNIQUE INDEX playlists_mood_name_unique ON playlists (name_key) '
  "WHERE kind = 'mood' AND deleted_at IS NULL",
)
@TableIndex.sql(
  'CREATE UNIQUE INDEX playlists_origin_unique ON playlists '
  '(origin_source_id, origin_locator) '
  'WHERE origin_source_id IS NOT NULL AND deleted_at IS NULL',
)
@TableIndex(name: 'playlists_origin_source', columns: {#originSourceId})
class Playlists extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// `favorites` for Favorites, a ULID otherwise.
  TextColumn get uid => text().unique()();
  TextColumn get name => text()();

  /// Mood playlists: lower case, collapsed spaces, NFC, accents kept. Mood
  /// rows must always set it: NULLs are distinct, so a NULL would bypass
  /// `playlists_mood_name_unique`.
  TextColumn get nameKey => text().nullable()();

  /// A [PlaylistKind] value; null = normal or imported.
  TextColumn get kind => text().nullable()();
  TextColumn get description => text().withDefault(const Constant(''))();

  /// Source of an imported playlist.
  IntColumn get originSourceId => integer()
      .nullable()
      .references(Sources, #id, onDelete: KeyAction.restrict)();
  TextColumn get originLocator => text().nullable()();

  /// Revision at the last import.
  TextColumn get originRevision => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
}

/// One track in a playlist. Favorites entries have a deterministic uid; all
/// others use a ULID so a track can repeat. Read with
/// `deleted_at IS NULL ORDER BY sort_key, uid`.
@DataClassName('PlaylistEntry')
@TableIndex(
  name: 'playlist_entries_order',
  columns: {#playlistId, #deletedAt, #sortKey, #uid, #trackId},
)
@TableIndex(
  name: 'playlist_entries_track',
  columns: {#trackId, #deletedAt, #playlistId},
)
class PlaylistEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uid => text().unique()();
  IntColumn get playlistId =>
      integer().references(Playlists, #id, onDelete: KeyAction.cascade)();
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.restrict)();

  /// Fractional key in base62; SQLite compares text in binary order, the
  /// same as Dart's `String.compareTo` for these ASCII keys.
  TextColumn get sortKey => text()();
  IntColumn get addedAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
}

/// An album, artist or playlist of a remote source that the user saved. The
/// uid is derived from the remote id, so saving it again revives the row.
@DataClassName('SavedItem')
@TableIndex(
  name: 'saved_items_lookup',
  columns: {#sourceId, #kind, #remoteId},
)
class SavedItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uid => text().unique()();

  /// A [SavedItemKind] value.
  TextColumn get kind => text()();
  IntColumn get sourceId =>
      integer().references(Sources, #id, onDelete: KeyAction.restrict)();

  /// Identifier on the source.
  TextColumn get remoteId => text()();

  /// Last seen remote data.
  TextColumn get snapshotJson => text()();
  IntColumn get savedAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
}
