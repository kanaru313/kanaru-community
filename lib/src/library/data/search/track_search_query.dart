import 'package:drift/drift.dart';

import '../../../database/app_database.dart';
import '../../../database/fts_query.dart';
import '../../../database/track_visibility.dart';
import '../../../media/domain/library_keys.dart';
import '../../domain/search/track_hit.dart';
import '../../domain/search/track_search.dart';
import 'track_lookup_query.dart';

/// [TrackSearch] over the `track_search` FTS5 table.
class TrackSearchQuery implements TrackSearch {
  TrackSearchQuery(this._db);

  final AppDatabase _db;

  @override
  Future<({List<TrackHit> rows, int total})> searchTracks(
    String query, {
    int offset = 0,
    int limit = trackSearchMaxLimit,
  }) async {
    final match = ftsPrefixQuery(_capped(searchForm(query)));
    if (match == null) return (rows: <TrackHit>[], total: 0);
    final from =
        'FROM track_search JOIN tracks t ON t.id = track_search.rowid '
        'WHERE track_search MATCH ? AND ${visibleTrackWhere('t')}';
    // One transaction: a scan commit between the two reads cannot make the
    // total disagree with the page.
    return _db.transaction(() async {
      final totalRow = await _db
          .customSelect(
            'SELECT COUNT(*) AS n $from',
            variables: [Variable.withString(match)],
            readsFrom: {_db.tracks},
          )
          .getSingle();
      final rows = await _db
          .customSelect(
            'SELECT t.id, t.title, t.artist, t.album, t.year $from '
            'ORDER BY track_search.rank, t.title_sort, t.id LIMIT ? OFFSET ?',
            variables: [
              Variable.withString(match),
              Variable.withInt(limit.clamp(1, trackSearchMaxLimit)),
              Variable.withInt(offset < 0 ? 0 : offset),
            ],
            readsFrom: {_db.tracks},
          )
          .get();
      return (
        rows: [for (final r in rows) trackHitFromRow(r)],
        total: totalRow.read<int>('n'),
      );
    });
  }

  /// The first [trackSearchMaxWords] words of [folded], at most
  /// [trackSearchMaxChars] characters: an AND of thousands of prefix terms
  /// would hold the single database connection for seconds.
  static String _capped(String folded) {
    final head = folded.length > trackSearchMaxChars
        ? folded.substring(0, trackSearchMaxChars)
        : folded;
    final words = head.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return words.take(trackSearchMaxWords).join(' ');
  }
}
