import 'dart:math';

import 'package:drift/drift.dart' show InsertMode, Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/play_stats_bulk.dart';
import 'package:kanaru/src/database/tables.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late List<int> tracks;

  setUp(() async {
    db = openTestDb();
    final source = await addSource(db);
    tracks = [
      for (var i = 0; i < 5; i++) await addTrack(db, source, locator: 't$i.flac'),
    ];
  });
  tearDown(() => db.close());

  Future<List<List<Object?>>> table(String sql) async => [
        for (final r in await db.customSelect(sql).get())
          [for (final k in r.data.keys) r.data[k]]
      ];

  Future<void> expectMatchesRecompute() async {
    final actual = await table(
        'SELECT track_id, play_count, skip_count, first_played_at, '
        'last_played_at FROM play_stats ORDER BY track_id');
    final expected = await table(
        '${playStatsAggregateSql()} ORDER BY track_id');
    expect(actual, expected);
  }

  for (final seed in [7, 2024]) {
    test('incremental stats equal the recompute (seed $seed)', () async {
      final rnd = Random(seed);
      final ids = <int>[];

      Future<void> step() async {
        final live = ids.isNotEmpty;
        Future<void> upd(PlayLogCompanion c) => (db.update(db.playLog)
              ..where((p) => p.id.equals(ids[rnd.nextInt(ids.length)])))
            .write(c);
        switch (rnd.nextInt(live ? 10 : 1)) {
          case 0:
            ids.add(await addPlay(db, tracks[rnd.nextInt(5)],
                playedAt: rnd.nextInt(100), skipped: rnd.nextBool()));
          case 1:
            await upd(PlayLogCompanion(deletedAt: Value(rnd.nextInt(100))));
          case 2:
            await upd(const PlayLogCompanion(deletedAt: Value(null)));
          case 3:
            await upd(PlayLogCompanion(playedAt: Value(rnd.nextInt(100))));
          case 4:
            await upd(PlayLogCompanion(skipped: Value(rnd.nextBool())));
          case 5:
            await upd(PlayLogCompanion(trackId: Value(tracks[rnd.nextInt(5)])));
          case 6:
            final i = rnd.nextInt(ids.length);
            await (db.delete(db.playLog)..where((p) => p.id.equals(ids[i]))).go();
            ids.removeAt(i);
          case 7:
            await runPlayStatsBulk(db, () async {
              ids.add(await addPlay(db, tracks[rnd.nextInt(5)],
                  playedAt: rnd.nextInt(100)));
              await runPlayStatsBulk(db, () => upd(
                  PlayLogCompanion(trackId: Value(tracks[rnd.nextInt(5)]))));
            });
          case 9:
            final i = rnd.nextInt(ids.length);
            final old = await (db.select(db.playLog)
                  ..where((p) => p.id.equals(ids[i])))
                .getSingle();
            await db.into(db.playLog).insert(
                  PlayLogCompanion.insert(
                      uid: old.uid, trackId: tracks[rnd.nextInt(5)],
                      playedAt: rnd.nextInt(100), deviceId: 'd',
                      updatedAt: 1, skipped: Value(rnd.nextBool())),
                  mode: InsertMode.insertOrReplace,
                );
            ids[i] = (await (db.select(db.playLog)
                      ..where((p) => p.uid.equals(old.uid)))
                    .getSingle())
                .id;
          case 8:
            await runPlayStatsBulk(db, () => upd(
                PlayLogCompanion(playedAt: Value(rnd.nextInt(100)))));
        }
      }

      for (var i = 0; i < 500; i++) {
        await step();
        await expectMatchesRecompute();
      }
    });
  }
}
