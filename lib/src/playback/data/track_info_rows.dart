import 'package:drift/drift.dart';

import '../../database/database.dart';
import '../../media/domain/library_keys.dart';
import '../../media/domain/track_id.dart';
import '../../media/domain/track_info.dart';

/// Ids per `IN (...)` query: far below SQLite's variable limit. Chunks are
/// separated by an event-loop turn so a 20k-track queue does not freeze the
/// UI isolate.
const int trackInfoChunkSize = 500;

/// The only row to [TrackInfo] mapping. [artists] come from `track_artists`
/// in tag order. The album key is built from the stored keys (null for a track
/// without an album).
TrackInfo trackInfoFromRow(
  Track row, {
  List<String> artists = const [],
  int playCount = 0,
}) {
  final titleKey = row.albumTitleKey;
  final artistKey = row.albumArtistKey;
  // Only the stored keys: the scanner writes them with `albumKeyFor`.
  final albumKey = titleKey != null && artistKey != null
      ? AlbumKey(artistKey, titleKey)
      : null;
  return TrackInfo(
    id: TrackId(row.id),
    title: row.title,
    status: _availability(row.status),
    relPath: row.relPath,
    artist: row.artist,
    album: row.album,
    albumArtist: row.albumArtist,
    artists: artists,
    year: row.year,
    trackNo: row.trackNo,
    discNo: row.discNo,
    durationMs: row.durationMs,
    coverKey: row.coverKey,
    albumKey: albumKey,
    genre: row.genre,
    language: row.language,
    languageDetected: row.languageDetected == 1,
    format: row.codec ?? formatFromLocator(row.relPath),
    sampleRate: row.sampleRate,
    bitrate: row.bitrate,
    bitDepth: row.bitDepth,
    playCount: playCount,
  );
}

TrackAvailability _availability(String status) => switch (status) {
  TrackStatus.present => TrackAvailability.present,
  TrackStatus.missing => TrackAvailability.missing,
  TrackStatus.hidden => TrackAvailability.hidden,
  TrackStatus.remote => TrackAvailability.remote,
  _ => throw StateError('unknown track status: $status'),
};

/// Loads [ids] in chunks of at most [trackInfoChunkSize]. Keeps the input
/// order (a repeated id appears repeatedly) and drops ids with no row. Any
/// status is returned; [TrackInfo.status] tells the caller what it got.
Future<List<TrackInfo>> loadTrackInfos(
  AppDatabase db,
  List<TrackId> ids,
) async {
  if (ids.isEmpty) return const [];
  final byId = <int, TrackInfo>{};
  final unique = {for (final id in ids) id.value}.toList();
  for (var i = 0; i < unique.length; i += trackInfoChunkSize) {
    // Let the UI isolate draw between chunks of a very long queue.
    if (i > 0) await Future<void>.delayed(Duration.zero);
    final chunk = unique.sublist(
      i,
      i + trackInfoChunkSize > unique.length
          ? unique.length
          : i + trackInfoChunkSize,
    );
    byId.addAll(await _loadChunk(db, chunk));
  }
  return [for (final id in ids) ?byId[id.value]];
}

Future<Map<int, TrackInfo>> _loadChunk(AppDatabase db, List<int> chunk) async {
  final marks = List.filled(chunk.length, '?').join(',');
  final vars = [for (final id in chunk) Variable.withInt(id)];
  final trackRows = await (db.select(
    db.tracks,
  )..where((t) => t.id.isIn(chunk))).get();
  if (trackRows.isEmpty) return const {};
  final artistRows = await db
      .customSelect(
        'SELECT track_id, artist_name FROM track_artists '
        'WHERE track_id IN ($marks) ORDER BY track_id, position',
        variables: vars,
      )
      .get();
  final statRows = await db
      .customSelect(
        'SELECT track_id, play_count FROM play_stats '
        'WHERE track_id IN ($marks)',
        variables: vars,
      )
      .get();
  final artists = <int, List<String>>{};
  for (final r in artistRows) {
    artists
        .putIfAbsent(r.read<int>('track_id'), () => [])
        .add(r.read<String>('artist_name'));
  }
  final plays = {
    for (final r in statRows)
      r.read<int>('track_id'): r.read<int>('play_count'),
  };
  return {
    for (final r in trackRows)
      r.id: trackInfoFromRow(
        r,
        artists: artists[r.id] ?? const [],
        playCount: plays[r.id] ?? 0,
      ),
  };
}

/// Live [TrackInfo] of one track; null when the row is gone. Re-emits only
/// when the mapped value changes. For single-item screens: lists get their
/// infos from their own list query.
Stream<TrackInfo?> watchTrackInfo(AppDatabase db, TrackId id) {
  return db
      .customSelect(
        'SELECT 1',
        readsFrom: {db.tracks, db.trackArtists, db.playStats},
      )
      .watch()
      .asyncMap((_) async => (await loadTrackInfos(db, [id])).firstOrNull)
      .distinct();
}
