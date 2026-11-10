import 'package:drift/drift.dart';

import 'library_track_tables.dart';

/// One row per play (or early skip). Synced by `uid`; the stats triggers keep
/// `play_stats` in step with it.
@DataClassName('Play')
@TableIndex(
  name: 'play_log_track_played',
  columns: {#trackId, #deletedAt, #playedAt, #skipped},
)
@TableIndex.sql(
  'CREATE INDEX play_log_played_at ON play_log '
  '(played_at, track_id, skipped, deleted_at) WHERE deleted_at IS NULL',
)
class PlayLog extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// ULID.
  TextColumn get uid => text().unique()();
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.restrict)();
  IntColumn get playedAt => integer()();
  IntColumn get listenedMs => integer().nullable()();

  /// Device that played; read from a file outside the database.
  TextColumn get deviceId => text()();

  /// Where playback started (open text): album, artist, playlist, search...
  TextColumn get contextKind => text().nullable()();

  /// Context identifier: playlist uid, album key...
  TextColumn get contextRef => text().nullable()();

  /// True = skipped early; such a play does not count as played.
  BoolColumn get skipped => boolean().withDefault(const Constant(false))();
  IntColumn get updatedAt => integer()();

  /// Tombstone for sync. Clearing history uses a hard delete.
  IntColumn get deletedAt => integer().nullable()();
}

/// Per-device aggregate of the live rows of `play_log`, kept by triggers and
/// by `runPlayStatsBulk`. A track that was only skipped has a row with
/// `play_count` 0 and NULL first/last, so "was played" queries filter
/// `last_played_at IS NOT NULL`. Owned child of `tracks`: deleted by the
/// track GC before the track.
@DataClassName('PlayStat')
@TableIndex.sql(
  'CREATE INDEX play_stats_last ON play_stats (last_played_at) '
  'WHERE last_played_at IS NOT NULL',
)
class PlayStats extends Table {
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.restrict)();

  /// Live plays with `skipped = 0`.
  IntColumn get playCount => integer()();

  /// Live plays with `skipped = 1`.
  IntColumn get skipCount => integer().withDefault(const Constant(0))();

  /// Earliest non-skipped play.
  IntColumn get firstPlayedAt => integer().nullable()();

  /// Latest non-skipped play; NULL while the track was only skipped.
  IntColumn get lastPlayedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {trackId};
}

/// The play queue of this device (not synced). A track may appear several
/// times. The current entry, position, shuffle and repeat live in settings.
@DataClassName('QueueEntryRow')
@TableIndex(name: 'queue_entries_track', columns: {#trackId})
@TableIndex(name: 'queue_entries_order', columns: {#sortKey, #id})
@TableIndex.sql(
  'CREATE INDEX queue_entries_shuffle ON queue_entries (shuffle_key, id) '
  'WHERE shuffle_key IS NOT NULL',
)
class QueueEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.restrict)();

  /// Fractional key: the order the user sees.
  TextColumn get sortKey => text()();

  /// Order while shuffle is on; NULL when it is off.
  TextColumn get shuffleKey => text().nullable()();
  IntColumn get addedAt => integer()();
}
