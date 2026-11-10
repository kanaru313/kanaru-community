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

/// Counts the visible library: present tracks, distinct albums (album artist
/// key and album title key both set) and distinct artists of those tracks.
Future<LibraryCounts> countsForFinished(AppDatabase db) async {
  final visible = visibleTrackWhere('t');
  final row = await db
      .customSelect(
        'SELECT '
        '(SELECT COUNT(*) FROM tracks t WHERE $visible) AS tracks, '
        '(SELECT COUNT(*) FROM (SELECT DISTINCT t.album_artist_key, '
        't.album_title_key FROM tracks t WHERE $visible '
        'AND t.album_artist_key IS NOT NULL '
        'AND t.album_title_key IS NOT NULL)) AS albums, '
        '(SELECT COUNT(DISTINCT a.artist_key) FROM track_artists a '
        'JOIN tracks t ON t.id = a.track_id WHERE $visible) AS artists',
        readsFrom: {db.tracks, db.trackArtists},
      )
      .getSingle();
  return LibraryCounts(
    tracks: row.read<int>('tracks'),
    albums: row.read<int>('albums'),
    artists: row.read<int>('artists'),
  );
}
