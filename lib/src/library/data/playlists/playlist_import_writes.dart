import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../../../media/domain/library_keys.dart';
import '../../domain/playlists/playlist_import.dart';
import '../../domain/playlists/playlist_text_rules.dart';
import 'playlist_sql.dart';

/// Creates the imported playlist in the caller's transaction: entries in file
/// order (repeats kept); an [ImportedMissing] line reuses the track row of
/// its `(source, locator)` or gets a `missing` placeholder (`hidden` under a
/// live exclusion) that the next scan adopts. Throws [ArgumentError], with
/// nothing written, for a bad name, an unknown track or a source that is not
/// a live local source.
Future<ImportedPlaylist> createImportedPlaylistWrite(
  AppDatabase db, {
  required String name,
  required List<ImportedEntry> entries,
  required int now,
}) async {
  // A name made from a file name is cut to fit, never rejected for length.
  final clean = capPlaylistName(cleanPlaylistName(name));
  if (clean.isEmpty) throw ArgumentError.value(name, 'name', 'empty');
  final sourceUids = <int, String>{};
  for (final e in entries) {
    if (e is ImportedMissing && !sourceUids.containsKey(e.sourceId)) {
      final rows = await db
          .customSelect(
            'SELECT uid FROM sources WHERE id = ? AND deleted_at IS NULL '
            'AND kind = ?',
            variables: [
              Variable.withInt(e.sourceId),
              Variable.withString(SourceKind.local),
            ],
          )
          .get();
      if (rows.isEmpty) {
        throw ArgumentError.value(
          e.sourceId,
          'sourceId',
          'not a live local source',
        );
      }
      sourceUids[e.sourceId] = rows.single.read<String>('uid');
    }
  }
  await requireTracksExist(db, [
    for (final e in entries)
      if (e is ImportedTrack) e.id.value,
  ]);

  final trackIds = <int>[];
  var created = 0;
  for (final e in entries) {
    switch (e) {
      case ImportedTrack():
        trackIds.add(e.id.value);
      case ImportedMissing():
        final existing = await _trackIdOf(db, e.sourceId, e.locator);
        if (existing != null) {
          trackIds.add(existing);
          break;
        }
        final id = await upsertTrackSnapshot(
          db,
          db.tracks,
          TracksCompanion(
            sourceId: Value(e.sourceId),
            locator: Value(e.locator),
            uid: Value(trackUid(sourceUids[e.sourceId]!, e.locator)),
            title: Value(e.title),
            titleSearch: Value(searchForm(e.title)),
            titleSort: Value(sortForm(e.title)),
            artist: Value.absentIfNull(e.artist),
            artistSearch: e.artist == null
                ? const Value.absent()
                : Value(searchForm(e.artist!)),
            durationMs: Value.absentIfNull(e.durationMs),
            relPath: Value(e.locator),
            addedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
        await markTracksMissing(db, [id], now);
        created++;
        trackIds.add(id);
    }
  }
  final playlistId = await insertPlaylistRow(db, name: clean, now: now);
  await appendEntries(db, playlistId, trackIds, now);
  return ImportedPlaylist(
    uid: await playlistUidOf(db, playlistId),
    entryCount: trackIds.length,
    missingCreated: created,
  );
}

Future<int?> _trackIdOf(AppDatabase db, int sourceId, String locator) async {
  final rows = await db
      .customSelect(
        'SELECT id FROM tracks WHERE source_id = ? AND locator = ?',
        variables: [Variable.withInt(sourceId), Variable.withString(locator)],
      )
      .get();
  return rows.isEmpty ? null : rows.single.read<int>('id');
}
