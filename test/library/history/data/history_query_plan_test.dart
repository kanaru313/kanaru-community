import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/history/history_sql.dart';

import '../../../database/support/test_db.dart';
import 'history_fixture.dart';

/// Every read of the history and the plan its SQL may have. A read over
/// `play_log` must search one of its indexes; the per-track aggregate
/// `play_stats` (one row per played track) may be scanned. Nothing may scan
/// `play_log` (the log grows without bound).
final _reads = <String, ({String sql, int vars, RegExp plan})>{
  'bounds': (sql: historyBoundsSql, vars: 0, plan: _statsAny),
  'window has play': (sql: historyWindowHasPlaySql, vars: 2, plan: _playedAt),
  'year plays': (sql: historyYearPlaysSql, vars: 2, plan: _playedAt),
  'after counts': (sql: historyAfterCountsSql, vars: 1, plan: _playedAt),
  'play counts': (sql: historyPlayCountsSql, vars: -1, plan: _statsAny),
  'overview': (sql: historyOverviewSql, vars: 0, plan: _statsScan),
  'track plays': (sql: historyTrackPlaysSql, vars: 1, plan: _trackPlayed),
  'top window': (sql: historyTopWindowSql, vars: 3, plan: _playedAt),
  'window totals': (sql: historyWindowTotalsSql, vars: 2, plan: _playedAt),
  'top all': (sql: historyTopAllSql, vars: 1, plan: _statsScan),
  'play times': (sql: historyPlayTimesSql, vars: 2, plan: _playedAt),
  'count': (sql: historyCountSql, vars: 2, plan: _playedAt),
  'played tracks': (sql: historyPlayedTracksSql, vars: 0, plan: _statsAny),
};

final _playedAt = RegExp(
  r'^SEARCH play_log USING (COVERING )?INDEX play_log_played_at',
);
final _trackPlayed = RegExp(
  r'^SEARCH play_log USING INDEX play_log_track_played',
);
final _statsScan = RegExp(r'^SCAN play_stats');
final _statsAny = RegExp(r'^(SCAN|SEARCH) play_stats');

void main() {
  late AppDatabase db;
  setUp(() async {
    db = openTestDb();
    // The app never runs ANALYZE, so the default estimates used here are the
    // app's.
    final tracks = await addTracks(db, 3);
    for (var i = 0; i < 20; i++) {
      await addPlay(db, tracks[i % 3], playedAt: ms(2026, 1, 1 + i));
    }
  });
  tearDown(() => db.close());

  for (final entry in _reads.entries) {
    test('${entry.key}: planned as allowed, never a play_log scan', () async {
      final r = entry.value;
      final vars = r.vars < 0
          ? [Variable.withString('[1,2]')]
          : [for (var i = 0; i < r.vars; i++) Variable.withInt(1000 + i)];
      final rows = await db
          .customSelect('EXPLAIN QUERY PLAN ${r.sql}', variables: vars)
          .get();
      final details = [for (final row in rows) row.read<String>('detail')];
      expect(
        details.where((d) => d.contains('play_log')),
        isNot(contains(startsWith('SCAN play_log'))),
        reason: details.join('\n'),
      );
      expect(
        details.any(r.plan.hasMatch),
        isTrue,
        reason: 'expected ${r.plan.pattern} in:\n${details.join('\n')}',
      );
    });
  }
}
