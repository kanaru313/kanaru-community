import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../../../media/domain/library_keys.dart';
import '../../domain/browse/browse_items.dart';
import '../../domain/browse/song_scope.dart';
import 'scope_sql.dart';

/// Albums of visible tracks that have an album tag, ordered by the stored
/// album sort key (then key), so a title sort needs no folding.
///
/// Display artist: `album_display_artist`, else `album_artist`, else the
/// first `track_artists` entry of the group's lowest track id.
///
/// [scope] counts only its tracks (a genre's albums count the genre's
/// tracks). [ownedBy] keeps albums whose album artist key is that key,
/// [notOwnedBy] the others. [featuring] keeps albums that hold a track by
/// that artist key and counts the whole album, not only that artist's share.
/// [newestFirst] orders by year, newest first (no year last), instead of by
/// name.
Future<List<AlbumSummary>> albumSummaries(
  AppDatabase db, {
  SongScope scope = const SongScope.all(),
  String? ownedBy,
  String? notOwnedBy,
  String? featuring,
  bool newestFirst = false,
}) async {
  final where = SqlWhere()
    ..add(visibleTrackWhere('t'))
    ..add('t.album_artist_key IS NOT NULL AND t.album_title_key IS NOT NULL');
  addScope(where, scope);
  if (ownedBy != null) {
    where.add('t.album_artist_key = ?', [Variable.withString(ownedBy)]);
  }
  if (notOwnedBy != null) {
    where.add('t.album_artist_key <> ?', [Variable.withString(notOwnedBy)]);
  }
  if (featuring != null) {
    // Not correlated: SQLite builds the album key list once, from the
    // (artist_key, track_id) primary key.
    where.add(
      '(t.album_artist_key, t.album_title_key) IN ('
      'SELECT x.album_artist_key, x.album_title_key FROM track_artists fa '
      'JOIN tracks x ON x.id = fa.track_id WHERE fa.artist_key = ? '
      "AND ${visibleTrackWhere('x')})",
      [Variable.withString(featuring)],
    );
  }
  final order = newestFirst
      ? '(MAX(t.year) IS NULL), MAX(t.year) DESC, MIN(t.album_search)'
      : 'MIN(t.album_search)';
  final rows = await db
      .customSelect(
        'SELECT t.album_artist_key AS artist_key, t.album_title_key AS title_key, '
        'MIN(t.album) AS title, '
        'coalesce(MIN(t.album_display_artist), MIN(t.album_artist), '
        '(SELECT ta.artist_name FROM track_artists ta WHERE ta.position = 0 '
        'AND ta.track_id = (SELECT MIN(t2.id) FROM tracks t2 '
        'WHERE t2.album_artist_key = t.album_artist_key '
        'AND t2.album_title_key = t.album_title_key '
        "AND ${visibleTrackWhere('t2')}))) AS artist, "
        'MAX(t.year) AS year, COUNT(*) AS tracks, '
        'SUM(coalesce(t.duration_ms, 0)) AS duration, '
        'MIN(t.cover_key) AS cover, MAX(t.added_at) AS added '
        'FROM tracks t WHERE ${where.sql} '
        'GROUP BY t.album_artist_key, t.album_title_key '
        'ORDER BY $order, t.album_artist_key, t.album_title_key',
        variables: where.vars,
        readsFrom: {db.tracks, db.trackArtists},
      )
      .get();
  return [
    for (final r in rows)
      AlbumSummary(
        key: AlbumKey(
          r.read<String>('artist_key'),
          r.read<String>('title_key'),
        ).encode(),
        title: r.read<String>('title'),
        artist: r.readNullable<String>('artist'),
        year: r.readNullable<int>('year'),
        trackCount: r.read<int>('tracks'),
        durationMs: r.read<int>('duration'),
        coverKey: r.readNullable<String>('cover'),
        addedAt: r.read<int>('added'),
      ),
  ];
}

/// Artists of visible tracks (one row per `track_artists` key) in no
/// particular order: the caller orders. [scope] counts only its tracks
/// (track count, duration). Album count = own albums
/// (album artist key = artist key). Photo = cover of the newest own album
/// that has one; the artist page uses the same rule.
Future<List<ArtistSummary>> artistSummaries(
  AppDatabase db, {
  SongScope scope = const SongScope.all(),
}) async {
  final where = SqlWhere()..add(visibleTrackWhere('t'));
  addScope(where, scope);
  final rows = await db
      .customSelect(
        'SELECT ta.artist_key AS key, MIN(ta.artist_name) AS name, '
        'COUNT(*) AS tracks, SUM(coalesce(t.duration_ms, 0)) AS duration, '
        '(SELECT COUNT(DISTINCT o.album_title_key) FROM tracks o '
        'WHERE o.album_artist_key = ta.artist_key '
        "AND o.album_title_key IS NOT NULL AND ${visibleTrackWhere('o')}) "
        'AS albums, '
        '(SELECT c.cover_key FROM tracks c '
        'WHERE c.album_artist_key = ta.artist_key '
        'AND c.album_title_key IS NOT NULL AND c.cover_key IS NOT NULL '
        "AND ${visibleTrackWhere('c')} "
        'ORDER BY (c.year IS NULL), c.year DESC, c.album_title_key, c.id '
        'LIMIT 1) AS cover '
        'FROM track_artists ta JOIN tracks t ON t.id = ta.track_id '
        'WHERE ${where.sql} GROUP BY ta.artist_key',
        variables: where.vars,
        readsFrom: {db.tracks, db.trackArtists},
      )
      .get();
  return [
    for (final r in rows)
      ArtistSummary(
        key: ArtistKey(r.read<String>('key')).encode(),
        name: r.read<String>('name'),
        trackCount: r.read<int>('tracks'),
        albumCount: r.read<int>('albums'),
        durationMs: r.read<int>('duration'),
        coverKey: r.readNullable<String>('cover'),
      ),
  ];
}
