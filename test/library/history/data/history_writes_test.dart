import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/history/history_repository.dart';
import 'package:kanaru/src/library/data/history/history_writes.dart';
import 'package:kanaru/src/library/data/scan/track_gc_runner.dart';
import 'package:kanaru/src/library/domain/history/history_models.dart';

import '../../../database/support/test_db.dart';
import 'history_fixture.dart';

void main() {
  late AppDatabase db;
  late HistoryRepository repo;
  late List<int> t;
  var clock = 1000000;

  setUp(() async {
    clock = 1000000;
    db = openTestDb();
    repo = HistoryRepository(db, clock: () => clock);
    t = await addTracks(db, 3);
  });
  tearDown(() => db.close());

  Future<void> expectStatsRecomputed() async =>
      expect(await statsTable(db), await statsRecomputed(db));

  Future<int> rows({String where = '1 = 1'}) async =>
      (await db
              .customSelect('SELECT count(*) AS n FROM play_log WHERE $where')
              .getSingle())
          .read<int>('n');

  Future<void> seed() async {
    await addPlay(db, t[0], playedAt: 100, uid: 'a');
    await addPlay(db, t[0], playedAt: 200, uid: 'b');
    await addPlay(db, t[1], playedAt: 300, uid: 'c');
    await addPlay(db, t[1], playedAt: 400, uid: 'd');
    await addPlay(db, t[2], playedAt: 500, uid: 'e', skipped: true);
  }

  group('removePlays', () {
    test('tombstones live plays, stats follow, returns the batch', () async {
      await seed();
      final batch = (await repo.removePlays(['a', 'c']))!;
      expect(batch.uids, unorderedEquals(['a', 'c']));
      expect(batch.stamp, clock);
      expect(await rows(where: 'deleted_at IS NOT NULL'), 2);
      await expectStatsRecomputed();
      expect((await statsTable(db))[t[0]], [1, 0, 200, 200]);
    });

    test('plays already removed or unknown are not in the batch', () async {
      await seed();
      await repo.removePlays(['a']);
      clock += 10;
      final again = (await repo.removePlays(['a', 'nope', 'b']))!;
      expect(again.uids, ['b']);
      expect(again.stamp, clock);
      expect(await repo.removePlays(['a', 'nope']), isNull);
      expect(await repo.removePlays([]), isNull);
    });

    test('more than 500 plays in one removal', () async {
      final uids = <String>[];
      for (var i = 0; i < 1203; i++) {
        uids.add('m$i');
        await addPlay(db, t[i % 3], playedAt: 1000 + i, uid: 'm$i');
      }
      final batch = (await repo.removePlays(uids))!;
      expect(batch.uids.length, 1203);
      expect(await rows(where: 'deleted_at IS NULL'), 0);
      await expectStatsRecomputed();
      expect(await repo.undoBatches([batch]), 1203);
      await expectStatsRecomputed();
    });

    test(
      'a failure mid-way over several chunks leaves nothing removed',
      () async {
        final uids = <String>[];
        for (var i = 0; i < 1203; i++) {
          uids.add('m$i');
          await addPlay(db, t[i % 3], playedAt: 1000 + i, uid: 'm$i');
        }
        final before = await statsTable(db);
        await db.customStatement(
          'CREATE TEMP TRIGGER fail_removal BEFORE UPDATE ON play_log '
          "WHEN new.uid = 'm700' "
          "BEGIN SELECT RAISE(ABORT, 'boom'); END",
        );
        await expectLater(repo.removePlays(uids), throwsA(anything));
        await db.customStatement('DROP TRIGGER fail_removal');
        expect(await rows(where: 'deleted_at IS NOT NULL'), 0);
        expect(await statsTable(db), before);
        await expectStatsRecomputed();
      },
    );
  });

  group('undo', () {
    test(
      'two batches (t, t+5ms): one undo revives both, stats recompute',
      () async {
        await seed();
        final one = (await repo.removePlays(['a', 'c']))!;
        clock += 5;
        final two = (await repo.removePlays(['b', 'd']))!;
        expect(await statsTable(db), {
          t[2]: [0, 1, null, null],
        });
        expect(await repo.undoBatches([one, two]), 4);
        expect(await rows(where: 'deleted_at IS NOT NULL'), 0);
        await expectStatsRecomputed();
        expect((await statsTable(db))[t[0]], [2, 0, 100, 200]);
      },
    );

    test("an older stamp is not revived by a newer batch's undo", () async {
      await seed();
      await repo.removePlays(['a', 'c']);
      clock += 5;
      final two = (await repo.removePlays(['b', 'd']))!;
      expect(await repo.undoBatches([two]), 2);
      expect(
        await rows(where: "uid IN ('a','c') AND deleted_at IS NOT NULL"),
        2,
      );
      await expectStatsRecomputed();
    });

    test(
      'a play removed again keeps the newer stamp against the old batch',
      () async {
        await seed();
        final first = (await repo.removePlays(['a']))!;
        clock += 1;
        await repo.undoBatches([first]);
        clock += 1;
        await repo.removePlays(['a']);
        expect(await repo.undoBatches([first]), 0);
        await expectStatsRecomputed();
      },
    );

    test('after commit an undo revives nothing', () async {
      await seed();
      final batch = (await repo.removePlays(['a', 'b']))!;
      await repo.commitBatches([batch]);
      expect(await repo.undoBatches([batch]), 0);
      expect(await rows(), 3);
      await expectStatsRecomputed();
    });
  });

  group('commit', () {
    test('deletes the tombstones for good and is idempotent', () async {
      await seed();
      final one = (await repo.removePlays(['a']))!;
      clock += 1;
      final two = (await repo.removePlays(['c']))!;
      await repo.commitBatches([one, two]);
      expect(await rows(), 3);
      await repo.commitBatches([one, two]);
      expect(await rows(), 3);
      await expectStatsRecomputed();
    });

    test('commit leaves a play that was undone alone', () async {
      await seed();
      final batch = (await repo.removePlays(['a']))!;
      await repo.undoBatches([batch]);
      await repo.commitBatches([batch]);
      expect(await rows(where: "uid = 'a'"), 1);
    });

    test(
      'a batch with the right uids but a foreign stamp deletes nothing',
      () async {
        await seed();
        await repo.removePlays(['a']);
        await repo.commitBatches([
          const HistoryBatch(uids: ['a'], stamp: 1),
        ]);
        expect(await rows(where: "uid = 'a'"), 1);
      },
    );
  });

  group('purge', () {
    test('removes tombstones older than the grace only', () async {
      await seed();
      await repo.removePlays(['a']);
      clock += removedPlayGraceMs + 10;
      await repo.removePlays(['b']);
      final purged = await purgeRemovedPlays(
        db,
        before: clock - removedPlayGraceMs,
      );
      expect(purged, 1);
      expect(await rows(where: "uid = 'a'"), 0);
      expect(await rows(where: "uid = 'b'"), 1);
      await expectStatsRecomputed();
    });

    test('live plays are never purged', () async {
      await seed();
      expect(await purgeRemovedPlays(db, before: 1 << 50), 0);
      expect(await rows(), 5);
    });

    test('the GC runner purges old tombstones so the track can go', () async {
      final solo = (await addTracks(db, 1)).single;
      await addPlay(db, solo, playedAt: 100, uid: 'solo');
      await repo.removePlays(['solo']);
      // The tombstone still references the track (FK RESTRICT) until purged.
      await db.customUpdate(
        "UPDATE tracks SET status = 'missing', missing_since = 1 "
        'WHERE id = $solo',
      );
      final now = clock + missingGraceMs + removedPlayGraceMs + 1;
      expect(await runTrackGc(db, now: now), 1);
      expect(await rows(where: "uid = 'solo'"), 0);
      final left = await db
          .customSelect('SELECT count(*) AS n FROM tracks WHERE id = $solo')
          .getSingle();
      expect(left.read<int>('n'), 0);
    });
  });
}
