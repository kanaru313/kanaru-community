import 'package:drift/drift.dart';

import '../../../database/app_database.dart';
import '../../../database/track_visibility.dart';
import '../../../media/domain/track_id.dart';
import '../../domain/search/track_hit.dart';
import '../../domain/search/track_lookup.dart';

/// Ids per statement, under SQLite's 999 variable limit.
const int _chunk = 900;

/// [TrackLookup] over the app database, with the library lists' visibility.
class TrackLookupQuery implements TrackLookup {
  TrackLookupQuery(this._db);

  final AppDatabase _db;

  @override
  Future<({List<TrackHit> visible, List<int> absent})> visibleOf(
    List<int> ids,
  ) async {
    final unique = ids.toSet().toList();
    final found = <int, TrackHit>{};
    for (var i = 0; i < unique.length; i += _chunk) {
      final end = i + _chunk > unique.length ? unique.length : i + _chunk;
      final chunk = unique.sublist(i, end);
      final rows = await _db
          .customSelect(
            'SELECT t.id, t.title, t.artist, t.album, t.year FROM tracks t '
            'WHERE ${visibleTrackWhere('t')} '
            'AND t.id IN (${List.filled(chunk.length, '?').join(',')})',
            variables: [for (final id in chunk) Variable.withInt(id)],
            readsFrom: {_db.tracks},
          )
          .get();
      for (final r in rows) {
        final id = r.read<int>('id');
        found[id] = trackHitFromRow(r);
      }
    }
    return (
      visible: [
        for (final id in unique)
          if (found[id] != null) found[id]!,
      ],
      absent: [
        for (final id in unique)
          if (found[id] == null) id,
      ],
    );
  }
}

/// Reads a `TrackHit` from a row with `id, title, artist, album, year`.
TrackHit trackHitFromRow(QueryRow r) => TrackHit(
  id: TrackId(r.read<int>('id')),
  title: r.read<String>('title'),
  artist: r.readNullable<String>('artist'),
  album: r.readNullable<String>('album'),
  year: r.readNullable<int>('year'),
);
