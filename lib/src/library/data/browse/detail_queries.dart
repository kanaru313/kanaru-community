import '../../../database/database.dart';
import '../../../media/domain/library_keys.dart';
import '../../domain/browse/detail_data.dart';
import '../../domain/browse/menu_targets.dart';
import '../../domain/browse/song_scope.dart';
import 'album_artist_queries.dart';
import 'scope_sql.dart';

/// Albums of [artist]: [ArtistAlbums.own] (the artist is the album artist,
/// newest first) and [ArtistAlbums.appears] (another album artist's albums
/// with a track by the artist, newest first).
Future<ArtistAlbums> artistAlbums(AppDatabase db, ArtistKey artist) async {
  final own = await albumSummaries(db, ownedBy: artist.key, newestFirst: true);
  final appears = await albumSummaries(
    db,
    featuring: artist.key,
    notOwnedBy: artist.key,
    newestFirst: true,
  );
  return ArtistAlbums(own: own, appears: appears);
}

/// Artists and albums inside [scope] (a genre or a language).
Future<GroupShelves> groupShelves(AppDatabase db, SongScope scope) async {
  final artists = await artistSummaries(db, scope: scope);
  artists.sort((a, b) {
    final c = b.trackCount.compareTo(a.trackCount);
    return c != 0 ? c : a.name.compareTo(b.name);
  });
  final albums = await albumSummaries(db, scope: scope, newestFirst: true);
  return GroupShelves(artists: artists, albums: albums);
}

/// Track, artist and duration totals of [scope], and how many of its tracks
/// got their language by detection.
Future<GroupTotals> groupTotals(AppDatabase db, SongScope scope) async {
  final where = SqlWhere()..add(visibleTrackWhere('t'));
  addScope(where, scope);
  final row = await db
      .customSelect(
        'SELECT COUNT(*) AS tracks, '
        'SUM(coalesce(t.duration_ms, 0)) AS duration, '
        'SUM(t.language_detected) AS detected '
        'FROM tracks t WHERE ${where.sql}',
        variables: where.vars,
        readsFrom: {db.tracks},
      )
      .getSingle();
  final artists = await db
      .customSelect(
        'SELECT COUNT(DISTINCT ta.artist_key) AS n FROM track_artists ta '
        'JOIN tracks t ON t.id = ta.track_id WHERE ${where.sql}',
        variables: where.vars,
        readsFrom: {db.tracks, db.trackArtists},
      )
      .getSingle();
  return GroupTotals(
    tracks: row.read<int>('tracks'),
    artists: artists.read<int>('n'),
    durationMs: row.readNullable<int>('duration') ?? 0,
    detected: row.readNullable<int>('detected') ?? 0,
  );
}
