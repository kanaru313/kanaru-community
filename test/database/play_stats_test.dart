import 'package:drift/drift.dart' show InsertMode, Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/play_stats_bulk.dart';
import 'package:kanaru/src/database/tables.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late int t1;
  late int t2;

  setUp(() async {
    db = openTestDb();
    final source = await addSource(db);
    t1 = await addTrack(db, source, locator: 'a.flac');
    t2 = await addTrack(db, source, locator: 'b.flac');
  });
  tearDown(() => db.close());

  Future<PlayStat?> stat(int id) => (db.select(db.playStats)
        ..where((s) => s.trackId.equals(id)))
      .getSingleOrNull();

  Future<int> bulk() async => (await db
          .customSelect('SELECT bulk FROM play_stats_ctl WHERE id = 1')
          .getSingle())
      .read<int>('bulk');

  Future<void> update(int id, PlayLogCompanion c) =>
      (db.update(db.playLog)..where((p) => p.id.equals(id))).write(c);

  test('a fresh database has the control row with bulk 0', () async {
    expect(await bulk(), 0);
  });

  test('plays and skips update counts and first/last', () async {
    await addPlay(db, t1, playedAt: 50);
    await addPlay(db, t1, playedAt: 10);
    await addPlay(db, t1, playedAt: 90, skipped: true);
    final s = (await stat(t1))!;
    expect((s.playCount, s.skipCount, s.firstPlayedAt, s.lastPlayedAt),
        (2, 1, 10, 50));
  });

  test('a skip-only track has a row with NULL first and last', () async {
    await addPlay(db, t1, playedAt: 5, skipped: true);
    final s = (await stat(t1))!;
    expect((s.playCount, s.skipCount, s.firstPlayedAt, s.lastPlayedAt),
        (0, 1, null, null));
  });

  test('a play inserted already tombstoned is not counted', () async {
    await addPlay(db, t1, playedAt: 5, deletedAt: 6);
    expect(await stat(t1), isNull);
  });

  test('tombstoning the first and last play looks min/max up again', () async {
    final a = await addPlay(db, t1, playedAt: 10);
    await addPlay(db, t1, playedAt: 20);
    final c = await addPlay(db, t1, playedAt: 30);
    await update(a, const PlayLogCompanion(deletedAt: Value(99)));
    await update(c, const PlayLogCompanion(deletedAt: Value(99)));
    final s = (await stat(t1))!;
    expect((s.playCount, s.firstPlayedAt, s.lastPlayedAt), (1, 20, 20));
  });

  test('tombstoning every play removes the stats row', () async {
    final a = await addPlay(db, t1, playedAt: 10);
    final b = await addPlay(db, t1, playedAt: 20, skipped: true);
    await update(a, const PlayLogCompanion(deletedAt: Value(99)));
    expect(await stat(t1), isNotNull);
    await update(b, const PlayLogCompanion(deletedAt: Value(99)));
    expect(await stat(t1), isNull);
  });

  test('changing played_at, skipped or track_id adjusts the stats', () async {
    final a = await addPlay(db, t1, playedAt: 10);
    await addPlay(db, t1, playedAt: 20);
    await update(a, const PlayLogCompanion(playedAt: Value(40)));
    expect((await stat(t1))!.firstPlayedAt, 20);
    expect((await stat(t1))!.lastPlayedAt, 40);

    await update(a, const PlayLogCompanion(skipped: Value(true)));
    var s = (await stat(t1))!;
    expect((s.playCount, s.skipCount, s.lastPlayedAt), (1, 1, 20));

    await update(a, PlayLogCompanion(trackId: Value(t2)));
    s = (await stat(t1))!;
    expect((s.playCount, s.skipCount), (1, 0));
    final moved = (await stat(t2))!;
    expect((moved.playCount, moved.skipCount, moved.lastPlayedAt), (0, 1, null));
  });

  test('updating only listened_ms leaves the stats alone', () async {
    final a = await addPlay(db, t1, playedAt: 10);
    await update(a, const PlayLogCompanion(listenedMs: Value(1234)));
    expect((await stat(t1))!.playCount, 1);
  });

  test('a hard delete subtracts the play', () async {
    await addPlay(db, t1, playedAt: 10);
    final b = await addPlay(db, t1, playedAt: 20);
    await (db.delete(db.playLog)..where((p) => p.id.equals(b))).go();
    final s = (await stat(t1))!;
    expect((s.playCount, s.lastPlayedAt), (1, 10));
  });

  group('runPlayStatsBulk', () {
    test('clearing all history empties the stats and resets the switch', () async {
      await addPlay(db, t1, playedAt: 10);
      await addPlay(db, t2, playedAt: 20, skipped: true);
      await runPlayStatsBulk(db, () => db.delete(db.playLog).go());
      expect(await db.select(db.playStats).get(), isEmpty);
      expect(await bulk(), 0);
    });

    test('moving a play inside a bulk recomputes both tracks', () async {
      final a = await addPlay(db, t1, playedAt: 10);
      await addPlay(db, t1, playedAt: 20);
      await runPlayStatsBulk(db, () => update(a, PlayLogCompanion(trackId: Value(t2))));
      expect((await stat(t1))!.playCount, 1);
      expect((await stat(t2))!.firstPlayedAt, 10);
      expect(await bulk(), 0);
    });

    test('a nested call only runs its write; the outer one recomputes', () async {
      await runPlayStatsBulk(db, () async {
        await runPlayStatsBulk(db, () => addPlay(db, t1, playedAt: 7));
        expect(await bulk(), 1);
        expect(await stat(t1), isNull);
      });
      expect((await stat(t1))!.playCount, 1);
      expect(await bulk(), 0);
    });

    test('an exception rolls back writes and the switch', () async {
      await addPlay(db, t1, playedAt: 10);
      await expectLater(
        runPlayStatsBulk(db, () async {
          await db.delete(db.playLog).go();
          throw StateError('boom');
        }),
        throwsStateError,
      );
      expect(await bulk(), 0);
      expect(await db.select(db.playLog).get(), hasLength(1));
      expect((await stat(t1))!.playCount, 1);
      // Triggers work again after the rollback.
      await addPlay(db, t1, playedAt: 11);
      expect((await stat(t1))!.playCount, 2);
    });

    test('abort-mode writes of an already touched track succeed', () async {
      await runPlayStatsBulk(db, () async {
        for (final at in [10, 20]) {
          await db.into(db.playLog).insert(
                PlayLogCompanion.insert(
                    uid: 'u$at', trackId: t1, playedAt: at,
                    deviceId: 'd', updatedAt: at),
                mode: InsertMode.insertOrAbort,
              );
        }
        await db.customStatement(
            'UPDATE OR ABORT play_log SET played_at = played_at + 1');
      });
      final s = (await stat(t1))!;
      expect((s.playCount, s.firstPlayedAt, s.lastPlayedAt), (2, 11, 21));
    });

    test('the temp objects stay out of the main schema', () async {
      await runPlayStatsBulk(db, () async {});
      final rows = await db
          .customSelect("SELECT name FROM sqlite_master WHERE name LIKE 'play_stats_touch%'")
          .get();
      expect(rows, isEmpty);
    });
  });

  test('a play_stats stream emits after a plain play_log insert', () async {
    final emissions = <int>[];
    final sub = db.select(db.playStats).watch().listen((r) => emissions.add(r.length));
    addTearDown(sub.cancel);
    await pumpEventQueue();
    await addPlay(db, t1, playedAt: 10);
    await pumpEventQueue();
    expect(emissions.last, 1);
  });
}
