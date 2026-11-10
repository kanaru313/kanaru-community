import '../../../database/database.dart';
import '../../domain/browse/browse_items.dart';

/// Genres of visible tracks, ordered by the stored genre sort key. [key] is
/// the stored `genre_key` (what `SongScope.genre` takes).
Future<List<GenreSummary>> genreSummaries(AppDatabase db) async {
  final rows = await db
      .customSelect(
        'SELECT t.genre_key AS key, MIN(t.genre) AS name, COUNT(*) AS tracks '
        "FROM tracks t WHERE ${visibleTrackWhere('t')} "
        "AND t.genre_key IS NOT NULL AND t.genre_key <> '' "
        'GROUP BY t.genre_key ORDER BY MIN(t.genre_search), t.genre_key',
        readsFrom: {db.tracks},
      )
      .get();
  return [
    for (final r in rows)
      GenreSummary(
        key: r.read<String>('key'),
        name: r.read<String>('name'),
        trackCount: r.read<int>('tracks'),
      ),
  ];
}

/// Languages of visible tracks; the group of tracks without a language has a
/// null code. Unordered: the caller orders (unknown last).
Future<List<LanguageSummary>> languageSummaries(AppDatabase db) async {
  final rows = await db
      .customSelect(
        'SELECT t.language AS code, COUNT(*) AS tracks, '
        'SUM(t.language_detected) AS detected '
        "FROM tracks t WHERE ${visibleTrackWhere('t')} GROUP BY t.language",
        readsFrom: {db.tracks},
      )
      .get();
  return [
    for (final r in rows)
      LanguageSummary(
        code: r.readNullable<String>('code'),
        trackCount: r.read<int>('tracks'),
        detectedCount: r.read<int>('detected'),
      ),
  ];
}
