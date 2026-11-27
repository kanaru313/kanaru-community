import '../../../database/database.dart';

/// What the library holds, for the scan summary.
class LibraryCounts {
  const LibraryCounts({
    required this.tracks,
    required this.albums,
    required this.artists,
  });

  final int tracks;
  final int albums;
  final int artists;
}

/// SQL select list (no `SELECT`, no trailing comma) of the visible library
/// counts `tracks`, `albums` and `artists`: present tracks, distinct albums
/// (album artist key and album title key both set; the Albums tab groups the
/// same way) and distinct artists of those tracks (the Artists tab's rows).
/// Shared by the scan summary and the library overview so both count alike.
String visibleCountsSelect() {
  final visible = visibleTrackWhere('t');
  return '(SELECT COUNT(*) FROM tracks t WHERE $visible) AS tracks, '
      '(SELECT COUNT(*) FROM (SELECT DISTINCT t.album_artist_key, '
      't.album_title_key FROM tracks t WHERE $visible '
      'AND t.album_artist_key IS NOT NULL '
      'AND t.album_title_key IS NOT NULL)) AS albums, '
      '(SELECT COUNT(DISTINCT a.artist_key) FROM track_artists a '
      'JOIN tracks t ON t.id = a.track_id WHERE $visible) AS artists';
}

/// Counts the visible library.
Future<LibraryCounts> countsForFinished(AppDatabase db) async {
  final row = await db
      .customSelect(
        'SELECT ${visibleCountsSelect()}',
        readsFrom: {db.tracks, db.trackArtists},
      )
      .getSingle();
  return LibraryCounts(
    tracks: row.read<int>('tracks'),
    albums: row.read<int>('albums'),
    artists: row.read<int>('artists'),
  );
}
