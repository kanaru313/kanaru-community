import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/history/history_repository.dart';
import 'package:kanaru/src/library/domain/history/history_days.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

import '../../../database/support/test_db.dart';
import 'history_fixture.dart';

void main() {
  late AppDatabase db;
  late HistoryRepository repo;
  late List<int> t;

  setUp(() async {
    db = openTestDb();
    repo = HistoryRepository(db);
    t = await addTracks(db, 4);
  });
  tearDown(() => db.close());

  Future<void> expectOrdinalsMatchSql(int year) async {
    final w = yearWindow(year);
    final slow = await slowOrdinals(db, w.start, w.end);
    final plays = await repo.yearPlays(year);
    expect(plays, isNotEmpty);
    expect({for (final p in plays) p.id: p.ordinal}, slow);
  }

  group('years and range', () {
    test(
      'lists years with plays, skipping a year with none, newest first',
      () async {
        await addPlay(db, t[0], playedAt: ms(2024, 5, 1));
        await addPlay(db, t[0], playedAt: ms(2026, 2, 1));
        await addPlay(db, t[1], playedAt: ms(2026, 12, 31, 23, 59));
        expect(await repo.years(), [2026, 2024]);
        final range = (await repo.playedRange())!;
        expect(range.first, ms(2024, 5, 1));
        expect(range.last, ms(2026, 12, 31, 23, 59));
      },
    );

    test(
      'a year whose only plays are skipped or removed is not listed',
      () async {
        await addPlay(db, t[0], playedAt: ms(2024, 5, 1));
        await addPlay(db, t[0], playedAt: ms(2025, 5, 1), skipped: true);
        await addPlay(db, t[0], playedAt: ms(2026, 5, 1));
        final uid = 'gone';
        await addPlay(db, t[1], playedAt: ms(2025, 6, 1), uid: uid);
        await repo.removePlays([uid]);
        expect(await repo.years(), [2026, 2024]);
      },
    );

    test('empty history', () async {
      expect(await repo.years(), isEmpty);
      expect(await repo.playedRange(), isNull);
      expect(await repo.yearPlays(2026), isEmpty);
      final o = await repo.overview();
      expect((o.plays, o.songs, o.since), (0, 0, null));
    });
  });

  group('year plays and ordinal', () {
    test('A, B, A: ordinals equal the correlated-count SQL', () async {
      await addPlay(db, t[0], playedAt: ms(2026, 1, 1));
      await addPlay(db, t[1], playedAt: ms(2026, 1, 2));
      await addPlay(db, t[0], playedAt: ms(2026, 1, 3));
      final plays = await repo.yearPlays(2026);
      expect([for (final p in plays) p.ordinal], [2, 1, 1]);
      expect([for (final p in plays) p.track.id.value], [t[0], t[1], t[0]]);
      await expectOrdinalsMatchSql(2026);
    });

    test('same-millisecond plays order by row id and match the SQL', () async {
      final at = ms(2026, 3, 3);
      final a = await addPlay(db, t[0], playedAt: at);
      final b = await addPlay(db, t[0], playedAt: at);
      final c = await addPlay(db, t[0], playedAt: at);
      final plays = await repo.yearPlays(2026);
      expect([for (final p in plays) p.id], [c, b, a]);
      expect([for (final p in plays) p.ordinal], [3, 2, 1]);
      await expectOrdinalsMatchSql(2026);
    });

    test('plays after the year and in earlier years are counted', () async {
      await addPlay(db, t[0], playedAt: ms(2024, 1, 1));
      await addPlay(db, t[0], playedAt: ms(2025, 1, 1));
      await addPlay(db, t[0], playedAt: ms(2025, 6, 1));
      await addPlay(db, t[0], playedAt: ms(2026, 1, 1));
      await addPlay(db, t[1], playedAt: ms(2025, 7, 1));
      final y2025 = await repo.yearPlays(2025);
      expect([for (final p in y2025) p.ordinal], [1, 3, 2]);
      await expectOrdinalsMatchSql(2025);
      await expectOrdinalsMatchSql(2026);
    });

    test('still equal after a removal and after its undo', () async {
      final uids = <String>[];
      for (var i = 0; i < 6; i++) {
        final uid = 'p$i';
        uids.add(uid);
        await addPlay(db, t[i % 2], playedAt: ms(2026, 1, 1 + i), uid: uid);
      }
      await addPlay(db, t[0], playedAt: ms(2027, 1, 1));
      final batch = (await repo.removePlays(['p0', 'p3']))!;
      await expectOrdinalsMatchSql(2026);
      final after = await repo.yearPlays(2026);
      expect(after.length, 4);
      expect(await repo.undoBatches([batch]), 2);
      await expectOrdinalsMatchSql(2026);
      expect((await repo.yearPlays(2026)).length, 6);
    });

    test('skipped and removed plays are left out', () async {
      await addPlay(db, t[0], playedAt: ms(2026, 1, 1));
      await addPlay(db, t[0], playedAt: ms(2026, 1, 2), skipped: true);
      await addPlay(db, t[0], playedAt: ms(2026, 1, 3), deletedAt: 5);
      final plays = await repo.yearPlays(2026);
      expect(plays.length, 1);
      expect(plays.single.ordinal, 1);
    });

    test('window is half open at both year edges', () async {
      await addPlay(db, t[0], playedAt: yearWindow(2026).start);
      await addPlay(db, t[0], playedAt: yearWindow(2026).end - 1);
      await addPlay(db, t[0], playedAt: yearWindow(2026).end);
      expect((await repo.yearPlays(2026)).length, 2);
      expect((await repo.yearPlays(2027)).length, 1);
      await expectOrdinalsMatchSql(2026);
    });

    test('refreshTracks keeps ordinals and picks up new metadata', () async {
      await addPlay(db, t[0], playedAt: ms(2026, 1, 1));
      final before = await repo.yearPlays(2026);
      await (db.update(db.tracks)..where((x) => x.id.equals(t[0]))).write(
        const TracksCompanion(title: Value('Renamed')),
      );
      final after = await repo.refreshTracks(before);
      expect(after.single.track.title, 'Renamed');
      expect(after.single.ordinal, before.single.ordinal);
    });
  });

  group('overview and track history', () {
    test('overview counts live plays of played songs', () async {
      await addPlay(db, t[0], playedAt: ms(2025, 1, 1));
      await addPlay(db, t[0], playedAt: ms(2026, 1, 1));
      await addPlay(db, t[1], playedAt: ms(2026, 2, 1));
      await addPlay(db, t[2], playedAt: ms(2026, 2, 1), skipped: true);
      final o = await repo.overview();
      expect((o.plays, o.songs, o.since), (3, 2, ms(2025, 1, 1)));
    });

    test('track history lists plays newest first with ordinals', () async {
      await addPlay(db, t[0], playedAt: ms(2025, 1, 1));
      await addPlay(db, t[0], playedAt: ms(2026, 1, 1));
      await addPlay(db, t[0], playedAt: ms(2026, 2, 1), skipped: true);
      await addPlay(db, t[1], playedAt: ms(2026, 3, 1));
      final h = (await repo.trackHistory(TrackId(t[0])))!;
      expect(h.plays, 2);
      expect([for (final p in h.list) p.ordinal], [2, 1]);
      expect((h.first, h.last), (ms(2025, 1, 1), ms(2026, 1, 1)));
    });

    test(
      'a track with no plays has an empty history, a gone one is null',
      () async {
        final h = (await repo.trackHistory(TrackId(t[3])))!;
        expect((h.plays, h.first, h.last), (0, null, null));
        expect(h.list, isEmpty);
        expect(await repo.trackHistory(const TrackId(9999)), isNull);
      },
    );
  });

  group('top', () {
    Future<Map<int, int>> groupBy(int? start, int? end) async {
      final where = start == null
          ? ''
          : 'AND played_at >= $start AND played_at < $end';
      final rows = await db
          .customSelect(
            'SELECT track_id, count(*) AS n FROM play_log '
            'WHERE deleted_at IS NULL AND skipped = 0 $where GROUP BY track_id',
          )
          .get();
      return {for (final r in rows) r.read<int>('track_id'): r.read<int>('n')};
    }

    Future<void> seed() async {
      for (var i = 0; i < 5; i++) {
        await addPlay(db, t[0], playedAt: ms(2026, 1, 1 + i));
      }
      for (var i = 0; i < 3; i++) {
        await addPlay(db, t[1], playedAt: ms(2026, 2, 1 + i));
      }
      await addPlay(db, t[2], playedAt: ms(2025, 12, 31));
      await addPlay(db, t[2], playedAt: ms(2026, 2, 20), skipped: true);
    }

    test('all time equals GROUP BY over play_log', () async {
      await seed();
      final top = await repo.top(limit: 10);
      expect({
        for (final e in top.entries) e.track.id.value: e.count,
      }, await groupBy(null, null));
      expect([for (final e in top.entries) e.rank], [1, 2, 3]);
      expect((top.songs, top.plays), (3, 9));
    });

    test(
      'a window equals GROUP BY and totals cover the whole window',
      () async {
        await seed();
        final w = (start: ms(2026, 1, 1, 0), end: ms(2027, 1, 1, 0));
        final top = await repo.top(window: w, limit: 1);
        expect(top.entries.single.track.id.value, t[0]);
        expect((top.songs, top.plays), (2, 8));
        final all = await repo.top(window: w, limit: 10);
        expect({
          for (final e in all.entries) e.track.id.value: e.count,
        }, await groupBy(w.start, w.end));
      },
    );

    test('ties: earlier last play first, then lower track id', () async {
      await addPlay(db, t[1], playedAt: ms(2026, 1, 5));
      await addPlay(db, t[0], playedAt: ms(2026, 1, 9));
      await addPlay(db, t[2], playedAt: ms(2026, 1, 5));
      for (final w in <({int start, int end})?>[
        null,
        (start: 0, end: ms(2030, 1, 1)),
      ]) {
        final top = await repo.top(window: w, limit: 10);
        expect(
          [for (final e in top.entries) e.track.id.value],
          [t[1], t[2], t[0]],
        );
        expect(top.entries.first.lastPlayedAt, ms(2026, 1, 5));
      }
    });

    test('limit cuts the list, not the totals', () async {
      await seed();
      final top = await repo.top(limit: 2);
      expect(top.entries.length, 2);
      expect(top.songs, 3);
    });

    test('a limit below 1 is clamped, never "no limit"', () async {
      await seed();
      expect((await repo.top(limit: -1)).entries.length, 1);
      expect((await repo.top(limit: 0)).entries.length, 1);
    });
  });

  group('days and counts', () {
    test('play days are local days with a counted play', () async {
      await addPlay(db, t[0], playedAt: ms(2026, 5, 1, 0, 30));
      await addPlay(db, t[0], playedAt: ms(2026, 5, 1, 23, 30));
      await addPlay(db, t[1], playedAt: ms(2026, 5, 3));
      await addPlay(db, t[1], playedAt: ms(2026, 5, 4), skipped: true);
      await addPlay(db, t[1], playedAt: ms(2026, 5, 5), deletedAt: 3);
      final days = await repo.playDays(ms(2026, 5, 1, 0), ms(2026, 6, 1, 0));
      expect(days, {DateTime(2026, 5, 1), DateTime(2026, 5, 3)});
    });

    test('count is half open and ignores skipped and removed', () async {
      await addPlay(db, t[0], playedAt: 100);
      await addPlay(db, t[0], playedAt: 200);
      await addPlay(db, t[0], playedAt: 300);
      await addPlay(db, t[0], playedAt: 150, skipped: true);
      await addPlay(db, t[0], playedAt: 160, deletedAt: 1);
      expect(await repo.countPlays(100, 300), 2);
      expect(await repo.countPlays(0, 1000), 3);
    });

    test('played tracks come last played first', () async {
      await addPlay(db, t[0], playedAt: 300);
      await addPlay(db, t[1], playedAt: 500);
      await addPlay(db, t[2], playedAt: 100);
      await addPlay(db, t[3], playedAt: 900, skipped: true);
      expect(await repo.playedTracksNewestFirst(), [
        TrackId(t[1]),
        TrackId(t[0]),
        TrackId(t[2]),
      ]);
    });
  });
}
