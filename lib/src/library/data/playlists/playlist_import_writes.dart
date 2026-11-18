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

  // One lookup for every (source, locator) of the file, then one upsert per
  // new row and one `missing` mark for all of them.
  final missing = <String, ImportedMissing>{};
  for (final e in entries) {
    if (e is ImportedMissing) {
      missing.putIfAbsent(_pairKey(e.sourceId, e.locator), () => e);
    }
  }
  final known = await _existingTrackIds(db, missing.values);
  final fresh = <int>[];
  for (final entry in missing.entries) {
    if (known.containsKey(entry.key)) continue;
    final e = entry.value;
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
    known[entry.key] = id;
    fresh.add(id);
  }
  await markTracksMissing(db, fresh, now);
  final trackIds = [
    for (final e in entries)
      switch (e) {
        ImportedTrack() => e.id.value,
        ImportedMissing() => known[_pairKey(e.sourceId, e.locator)]!,
      },
  ];
  final created = fresh.length;
  final playlistId = await insertPlaylistRow(db, name: clean, now: now);
  await appendEntries(db, playlistId, trackIds, now);
  return ImportedPlaylist(
    uid: await playlistUidOf(db, playlistId),
    entryCount: trackIds.length,
    missingCreated: created,
  );
}

String _pairKey(int sourceId, String locator) => '$sourceId\u0000$locator';

/// Ids of the existing rows (any status) for [lines], by pair key.
Future<Map<String, int>> _existingTrackIds(
  AppDatabase db,
  Iterable<ImportedMissing> lines,
) async {
  if (lines.isEmpty) return {};
  final rows = await db
      .customSelect(
        'SELECT id, source_id, locator FROM tracks '
        '''WHERE (source_id, locator) IN (SELECT json_extract(value, '\$.s'), '''
        '''json_extract(value, '\$.l') FROM json_each(?))''',
        variables: [
          jsonList([
            for (final e in lines) {'s': e.sourceId, 'l': e.locator},
          ]),
        ],
      )
      .get();
  return {
    for (final r in rows)
      _pairKey(r.read<int>('source_id'), r.read<String>('locator')): r
          .read<int>('id'),
  };
}
