import 'dart:math';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/data/history/history_repository.dart';
import 'package:kanaru/src/library/data/history/history_sql.dart';
import 'package:kanaru/src/library/domain/history/history_days.dart';
import 'package:kanaru/src/playback/data/track_info_rows.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

import '../../../database/support/test_db.dart';
import 'history_fixture.dart';

/// Median of three timed runs of [body], in microseconds.
Future<int> _median3(Future<void> Function() body) async {
  final times = <int>[];
  for (var i = 0; i < 3; i++) {
    final sw = Stopwatch()..start();
    await body();
    times.add(sw.elapsedMicroseconds);
  }
  times.sort();
  return times[1];
}

void main() {
  test(
    'year read with ordinals costs at most 3x the plain plays read',
    () async {
      final db = openTestDb();
      addTearDown(db.close);
      final repo = HistoryRepository(db);
      final tracks = await addTracks(db, 2000);
      // 40 % of the plays go to 20 tracks: the skew of a heavy listener, which
      // is where a per-row recount would blow up.
      final rng = Random(7);
      final w = yearWindow(2026);
      await db.batch((b) {
        for (var i = 0; i < 14000; i++) {
          final track = rng.nextDouble() < 0.4
              ? tracks[rng.nextInt(20)]
              : tracks[20 + rng.nextInt(1980)];
          b.customStatement(
            'INSERT INTO play_log (uid, track_id, played_at, listened_ms, '
            'device_id, skipped, updated_at) VALUES (?, ?, ?, 1000, ?, 0, 0)',
            ['p$i', track, w.start + i * 2000, 'd'],
          );
        }
      });

      // A third of a year of plays after 2026, so the after-year count of the
      // 2026 read runs at size.
      final next = yearWindow(2027);
      await db.batch((b) {
        for (var i = 0; i < 4700; i++) {
          b.customStatement(
            'INSERT INTO play_log (uid, track_id, played_at, listened_ms, '
            'device_id, skipped, updated_at) VALUES (?, ?, ?, 1000, ?, 0, 0)',
            ['n$i', tracks[rng.nextInt(2000)], next.start + i * 2000, 'd'],
          );
        }
      });

      Future<void> plain() async {
        final rows = await db
            .customSelect(
              historyYearPlaysSql,
              variables: [Variable.withInt(w.start), Variable.withInt(w.end)],
            )
            .get();
        await loadTrackInfos(db, [
          for (final r in rows) TrackId(r.read<int>('track_id')),
        ]);
      }

      // Warm the page cache and the planner before timing either side.
      await plain();
      await repo.yearPlays(2026);
      final base = await _median3(plain);
      final full = await _median3(() async => repo.yearPlays(2026));

      expect((await repo.yearPlays(2026)).length, 14000);
      expect(
        full,
        lessThanOrEqualTo(base * 3),
        reason: 'year read ${full}us vs plain plays read ${base}us',
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
