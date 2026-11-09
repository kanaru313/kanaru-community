import 'package:drift/drift.dart';

import 'library_source_tables.dart';

/// Values of `tracks.status`; a CHECK on the column enforces the set.
abstract final class TrackStatus {
  /// In the library. Set by the scanner only.
  static const present = 'present';

  /// File of a scanned source that was not seen in a complete scan.
  static const missing = 'missing';

  /// The user took it out of the library (source removed, mount disabled,
  /// folder excluded).
  static const hidden = 'hidden';

  /// Row of a reference-only (plugin) source; never in the library.
  static const remote = 'remote';

  static const Set<String> values = {present, missing, hidden, remote};
}

/// One row per track of every source (local, remote, plugin). Foreign keys
/// into this table are always `ON DELETE RESTRICT`.
@DataClassName('Track')
@TableIndex.sql(
  'CREATE INDEX tracks_present_title ON tracks (title_sort, id) '
  "WHERE status = 'present'",
)
@TableIndex(name: 'tracks_status', columns: {#status, #sourceId})
@TableIndex(name: 'tracks_added_at', columns: {#addedAt})
@TableIndex(name: 'tracks_album_key', columns: {#albumArtistKey, #albumTitleKey})
@TableIndex(name: 'tracks_song_key', columns: {#songKey})
@TableIndex(name: 'tracks_rel_path', columns: {#sourceId, #relPath})
@TableIndex(name: 'tracks_language', columns: {#language})
class Tracks extends Table {
  // Identity
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uid => text().unique()();
  IntColumn get sourceId =>
      integer().references(Sources, #id, onDelete: KeyAction.restrict)();

  /// Path relative to the mount root, or the provider file id.
  TextColumn get locator => text()();

  // Snapshot (written by the scanner and the snapshot upsert)
  TextColumn get relPath => text()();
  TextColumn get revision => text().nullable()();
  IntColumn get mtimeMs => integer().nullable()();
  IntColumn get sizeBytes => integer().nullable()();
  IntColumn get startMs => integer().nullable()();
  IntColumn get endMs => integer().nullable()();
  TextColumn get songKey => text().nullable()();
  TextColumn get title => text()();
  TextColumn get titleSort => text().withDefault(const Constant(''))();
  TextColumn get artist => text().nullable()();
  TextColumn get album => text().nullable()();
  TextColumn get albumArtist => text().nullable()();
  TextColumn get genre => text().nullable()();
  TextColumn get composer => text().nullable()();
  TextColumn get language => text().nullable()();
  TextColumn get albumDisplayArtist => text().nullable()();
  TextColumn get artistSort => text().nullable()();
  TextColumn get albumSort => text().nullable()();
  TextColumn get artistSearch => text().nullable()();
  TextColumn get albumSearch => text().nullable()();
  TextColumn get albumArtistSearch => text().nullable()();
  TextColumn get genreSearch => text().nullable()();
  TextColumn get albumArtistKey => text().nullable()();
  TextColumn get albumTitleKey => text().nullable()();
  TextColumn get coverKey => text().nullable()();
  TextColumn get coverUrl => text().nullable()();
  IntColumn get trackNo => integer().nullable()();
  IntColumn get trackTotal => integer().nullable()();
  IntColumn get discNo => integer().nullable()();
  IntColumn get discTotal => integer().nullable()();
  IntColumn get year => integer().nullable()();
  IntColumn get durationMs => integer().nullable()();
  IntColumn get bitrate => integer().nullable()();
  IntColumn get sampleRate => integer().nullable()();
  IntColumn get bitDepth => integer().nullable()();
  IntColumn get channels => integer().nullable()();

  // User (last write wins per field; survive every snapshot upsert)
  IntColumn get rating => integer()
      .nullable()
      // A drift column check refers to its own column.
      // ignore: recursive_getters
      .check(rating.isBetween(const Constant(0), const Constant(100)))();
  IntColumn get ratingUpdatedAt => integer().nullable()();
  IntColumn get lyricsOffsetMs => integer().withDefault(const Constant(0))();
  IntColumn get lyricsOffsetUpdatedAt => integer().nullable()();

  // Lifecycle
  TextColumn get status => text()
      .withDefault(const Constant(TrackStatus.present))
      // A drift column check refers to its own column.
      // ignore: recursive_getters
      .check(status.isIn(TrackStatus.values))();

  /// Set when a row becomes `missing`.
  IntColumn get missingSince => integer().nullable()();
  IntColumn get addedAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {sourceId, locator},
      ];
}

/// Rarely read per-track data, split off the hot `tracks` rows. Owned
/// one-to-one child of `tracks`; the track GC deletes it first.
@DataClassName('TrackDetail')
class TrackDetails extends Table {
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.restrict)();
  TextColumn get comment => text().nullable()();

  /// JSON of tags without a column.
  TextColumn get extraTags => text().nullable()();

  /// Sidecar `.lrc` locator (path or file id).
  TextColumn get lrcLocator => text().nullable()();
  TextColumn get lrcRevision => text().nullable()();

  /// External cover image (locator or server image id).
  TextColumn get coverSrc => text().nullable()();

  @override
  Set<Column> get primaryKey => {trackId};
}
