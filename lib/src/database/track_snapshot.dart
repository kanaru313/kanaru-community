import 'package:drift/drift.dart';

import 'tables.dart';

/// Columns that identify a row; never rewritten by an upsert.
const trackIdentityColumns = {'id', 'uid', 'source_id', 'locator'};

/// Columns the scanner and the online resolver own; an upsert rewrites the
/// ones its companion carries.
const trackSnapshotColumns = {
  'rel_path',
  'revision',
  'mtime_ms',
  'size_bytes',
  'start_ms',
  'end_ms',
  'song_key',
  'title',
  'title_sort',
  'artist',
  'album',
  'album_artist',
  'genre',
  'composer',
  'language',
  'album_display_artist',
  'artist_sort',
  'album_sort',
  'artist_search',
  'album_search',
  'album_artist_search',
  'genre_search',
  'album_artist_key',
  'album_title_key',
  'cover_key',
  'cover_url',
  'track_no',
  'track_total',
  'disc_no',
  'disc_total',
  'year',
  'duration_ms',
  'bitrate',
  'sample_rate',
  'bit_depth',
  'channels',
};

/// Columns the user owns; survive every snapshot upsert.
const trackUserColumns = {
  'rating',
  'rating_updated_at',
  'lyrics_offset_ms',
  'lyrics_offset_updated_at',
};

/// Columns derived from the source kind and the stored row, never passed by
/// callers (`added_at` is set once on insert, `updated_at` on every write).
const trackLifecycleColumns = {
  'status',
  'missing_since',
  'added_at',
  'updated_at',
};

final _writable = {
  ...trackIdentityColumns.difference({'id'}),
  ...trackSnapshotColumns,
  'added_at',
  'updated_at',
};

/// Inserts or refreshes the snapshot of one track in a single statement and
/// returns `tracks.id`. [tracks] is the table instance of [db] (any database
/// on the shared connection, also inside its transaction).
///
/// [row] needs `sourceId`, `locator`, `uid`, `title`, `relPath`, `addedAt`
/// and `updatedAt`. Any other column (`id`, user columns, `status`,
/// `missing_since`) throws [ArgumentError]; the status comes from the
/// source kind (`plugin` gives `remote`; otherwise a new row is `present`
/// and a conflict keeps `hidden` and turns everything else `present`).
/// `missing_since` clears unless the row stays `hidden`. On conflict on
/// `(source_id, locator)` only the snapshot fields present in [row] are
/// rewritten (absent keeps the stored value, an explicit null writes null),
/// plus `updated_at`. Identity, user columns and `added_at` are untouched.
Future<int> upsertTrackSnapshot(
  DatabaseConnectionUser db,
  $TracksTable tracks,
  TracksCompanion row,
) async {
  final cols = row.toColumns(false);
  final bad = cols.keys.where((n) => !_writable.contains(n)).toList();
  if (bad.isNotEmpty) {
    throw ArgumentError.value(
      bad.join(', '),
      'row',
      'not writable by a snapshot upsert (status is derived, user and '
          'lifecycle columns are never passed)',
    );
  }
  if (!row.sourceId.present || !row.locator.present) {
    throw ArgumentError('sourceId and locator are required');
  }
  final names = cols.keys.toList();
  final sourceId = cols['source_id']!;

  // Reads the source kind inside the statement; one `?` per use.
  const isPlugin =
      "(SELECT kind FROM sources WHERE id = ?) = '${SourceKind.plugin}'";
  const stays = "tracks.status = '${TrackStatus.hidden}'";
  final updates = [
    for (final n in names)
      if (trackSnapshotColumns.contains(n)) '$n = excluded.$n',
    'updated_at = excluded.updated_at',
    "status = CASE WHEN $isPlugin THEN '${TrackStatus.remote}' "
        "WHEN $stays THEN '${TrackStatus.hidden}' "
        "ELSE '${TrackStatus.present}' END",
    'missing_since = CASE WHEN NOT ($isPlugin) AND $stays '
        'THEN tracks.missing_since ELSE NULL END',
  ];
  final sql =
      'INSERT INTO tracks (${names.join(', ')}, status) '
      "VALUES (${List.filled(names.length, '?').join(', ')}, "
      "CASE WHEN $isPlugin THEN '${TrackStatus.remote}' "
      "ELSE '${TrackStatus.present}' END) "
      'ON CONFLICT (source_id, locator) DO UPDATE SET ${updates.join(', ')} '
      'RETURNING id';
  // Placeholders appear in this order: values, insert status, conflict
  // status, conflict missing_since.
  final rows = await db.customWriteReturning(
    sql,
    variables: [
      for (final n in names) cols[n]! as Variable,
      sourceId as Variable,
      sourceId,
      sourceId,
    ],
    updates: {tracks},
  );
  // The indexed columns may have changed through the insert trigger.
  db.notifyUpdates({const TableUpdate('track_search')});
  return rows.single.read<int>('id');
}
