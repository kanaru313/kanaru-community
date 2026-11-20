import 'package:drift/drift.dart' show Variable;
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/database/play_stats_bulk.dart';

import '../../../database/support/test_db.dart';

/// The correlated-count SQL the year read replaces: the ordinal of every live
/// counted play of `[?1, ?2)` straight from `play_log`. Tests only; too slow
/// for the app (it recounts the log for every row).
const slowOrdinalSql = '''
SELECT p.id AS id,
  (SELECT count(*) FROM play_log q
   WHERE q.track_id = p.track_id AND q.deleted_at IS NULL AND q.skipped = 0
     AND (q.played_at < p.played_at
          OR (q.played_at = p.played_at AND q.id <= p.id))) AS ord
FROM play_log p
WHERE p.deleted_at IS NULL AND p.skipped = 0
  AND p.played_at >= ?1 AND p.played_at < ?2''';

/// `{play id: ordinal}` by the slow SQL for the plays of `[start, end)`.
Future<Map<int, int>> slowOrdinals(AppDatabase db, int start, int end) async {
  final rows = await db
      .customSelect(
        slowOrdinalSql,
        variables: [Variable.withInt(start), Variable.withInt(end)],
      )
      .get();
  return {for (final r in rows) r.read<int>('id'): r.read<int>('ord')};
}

/// `play_stats` as `{track id: [plays, skips, first, last]}`.
Future<Map<int, List<int?>>> statsTable(AppDatabase db) async => {
  for (final r in await db.customSelect('SELECT * FROM play_stats').get())
    r.read<int>('track_id'): [
      r.read<int>('play_count'),
      r.read<int>('skip_count'),
      r.readNullable<int>('first_played_at'),
      r.readNullable<int>('last_played_at'),
    ],
};

/// The stats a full recompute of the live rows gives, same shape.
Future<Map<int, List<int?>>> statsRecomputed(AppDatabase db) async => {
  for (final r in await db.customSelect(playStatsAggregateSql()).get())
    r.read<int>('track_id'): [
      r.read<int>('play_count'),
      r.read<int>('skip_count'),
      r.readNullable<int>('first_played_at'),
      r.readNullable<int>('last_played_at'),
    ],
};

/// Local epoch ms of a date, so fixtures read the same in every zone.
int ms(int y, int m, int d, [int h = 12, int min = 0]) =>
    DateTime(y, m, d, h, min).millisecondsSinceEpoch;

/// A source and [n] tracks `t0..`; returns their ids.
Future<List<int>> addTracks(AppDatabase db, int n) async {
  final source = await addSource(db);
  return [
    for (var i = 0; i < n; i++)
      await addTrack(db, source, locator: 't$i.flac', title: 'T$i'),
  ];
}
