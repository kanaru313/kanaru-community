import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../../../media/domain/library_keys.dart';
import '../../../media/domain/track_id.dart';
import '../../domain/browse/list_sort.dart';
import '../../domain/browse/song_scope.dart';
import '../../domain/browse/sort_order.dart';
import 'scope_sql.dart';

/// Ids of the visible tracks of [scope], ordered by [sort], narrowed by the
/// text [filter] (every whitespace-separated token, accents ignored, must
/// occur in the title, artist or album; an empty filter keeps everything).
///
/// Ties end with `title_sort, id` (`id` only when title is itself a key), so
/// the order is total. A nullable sort key
/// puts its NULL rows last in both directions. All user text is bound, never
/// part of the SQL string.
Future<List<TrackId>> songIds(
  AppDatabase db,
  SongScope scope,
  SortOrder sort,
  String filter,
) async {
  final where = SqlWhere()..add(visibleTrackWhere('t'));
  addScope(where, scope);
  _filter(where, filter);
  final joinPlays = sort.contains(SortCriterion.playCount);
  final rows = await db
      .customSelect(
        'SELECT t.id FROM tracks t '
        '${joinPlays ? 'LEFT JOIN play_stats ps ON ps.track_id = t.id ' : ''}'
        'WHERE ${where.sql} ORDER BY ${_orderBy(sort)}',
        variables: where.vars,
        readsFrom: {db.tracks, db.trackArtists, if (joinPlays) db.playStats},
      )
      .get();
  return [for (final r in rows) TrackId(r.read<int>('id'))];
}

/// Number of visible tracks of [scope] (no filter).
Future<int> songCount(AppDatabase db, SongScope scope) async {
  final where = SqlWhere()..add(visibleTrackWhere('t'));
  addScope(where, scope);
  final row = await db
      .customSelect(
        'SELECT COUNT(*) AS n FROM tracks t WHERE ${where.sql}',
        variables: where.vars,
        readsFrom: {db.tracks, db.trackArtists},
      )
      .getSingle();
  return row.read<int>('n');
}

final _blank = RegExp(r'\s+');

void _filter(SqlWhere w, String filter) {
  final tokens = searchForm(filter).split(_blank).where((t) => t.isNotEmpty);
  for (final token in tokens) {
    // char(31) keeps a token from matching across two fields.
    w.add(
      "instr(t.title_search || char(31) || coalesce(t.artist_search, '') "
      "|| char(31) || coalesce(t.album_search, ''), ?) > 0",
      [Variable.withString(token)],
    );
  }
}

/// `col` with NULLs last in either direction.
String _nullsLast(String col, bool desc) =>
    '($col IS NULL), $col${desc ? ' DESC' : ''}';

String _orderBy(SortOrder sort) {
  final terms = [
    for (final spec in sort.specs) _term(spec.criterion, spec.descending),
  ];
  final titled = sort.contains(SortCriterion.title);
  return [...terms, if (!titled) 't.title_sort', 't.id'].join(', ');
}

String _term(SortCriterion criterion, bool d) {
  return switch (criterion) {
    SortCriterion.title => 't.title_sort${d ? ' DESC' : ''}',
    SortCriterion.artist => _nullsLast('t.artist_search', d),
    SortCriterion.album => _nullsLast('t.album_search', d),
    SortCriterion.year => _nullsLast('t.year', d),
    SortCriterion.dateAdded => 't.added_at${d ? ' DESC' : ''}',
    SortCriterion.playCount => 'coalesce(ps.play_count, 0)${d ? ' DESC' : ''}',
    SortCriterion.duration => _nullsLast('t.duration_ms', d),
    SortCriterion.trackNumber =>
      '${_nullsLast('t.disc_no', d)}, ${_nullsLast('t.track_no', d)}',
    SortCriterion.trackCount ||
    SortCriterion.albumCount ||
    SortCriterion.name ||
    SortCriterion.dateModified ||
    SortCriterion.playlistOrder => throw ArgumentError.value(
      criterion,
      'sort',
      'not a song criterion',
    ),
  };
}
