import 'package:drift/drift.dart';

import '../../database/database.dart';
import '../domain/overview/library_overview.dart';
import '../domain/playlists/playlist_ids.dart';
import 'playlists/playlist_sql.dart';
import 'scan/library_counts.dart';

/// [LibraryOverviewReader] on the app database: one round trip.
class LibraryOverviewQuery implements LibraryOverviewReader {
  LibraryOverviewQuery(this._db);

  final AppDatabase _db;

  @override
  Future<LibraryOverview> read() async {
    final row = await _db
        .customSelect(
          'SELECT ${visibleCountsSelect()}, '
          '(SELECT COALESCE(SUM(t.duration_ms), 0) FROM tracks t '
          "WHERE ${visibleTrackWhere('t')}) AS duration, "
          // Same set `list_playlists` offers, without Favorites.
          '(SELECT COUNT(*) FROM playlists WHERE uid != ? '
          'AND $writablePlaylistPredicate) AS playlists',
          variables: [Variable.withString(PlaylistUids.favorites)],
          readsFrom: {_db.tracks, _db.trackArtists, _db.playlists},
        )
        .getSingle();
    return LibraryOverview(
      songs: row.read<int>('tracks'),
      albums: row.read<int>('albums'),
      artists: row.read<int>('artists'),
      playlists: row.read<int>('playlists'),
      totalDurationMs: row.read<int>('duration'),
    );
  }
}
