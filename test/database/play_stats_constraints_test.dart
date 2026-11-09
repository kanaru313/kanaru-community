import 'dart:io';

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

  group('foreign keys', () {
    test('a track with plays cannot be deleted', () async {
      await addPlay(db, t1, playedAt: 10);
      expect(db.delete(db.tracks).go(), throwsConstraint('FOREIGN KEY'));
    });

    test('a track with only a stats row cannot be deleted', () async {
      await db.into(db.playStats).insert(
          PlayStatsCompanion.insert(trackId: Value(t2), playCount: 0));
      expect(
        (db.delete(db.tracks)..where((t) => t.id.equals(t2))).go(),
        throwsConstraint('FOREIGN KEY'),
      );
    });
  });

  test('replacing a play by uid fires the delete trigger', () async {
    await addPlay(db, t1, playedAt: 10, uid: 'same');
    await addPlay(db, t1, playedAt: 15);
    await db.into(db.playLog).insert(
          PlayLogCompanion.insert(
              uid: 'same', trackId: t2, playedAt: 30,
              deviceId: 'd', updatedAt: 30),
          mode: InsertMode.insertOrReplace,
        );
    final actual = await db.customSelect(
        'SELECT track_id, play_count, skip_count, first_played_at, '
        'last_played_at FROM play_stats ORDER BY track_id').get();
    final expected = await db
        .customSelect('${playStatsAggregateSql()} ORDER BY track_id')
        .get();
    expect([for (final r in actual) r.data.values.toList()],
        [for (final r in expected) r.data.values.toList()]);
    expect(actual, hasLength(2));
  });

  test('the barrels do not export the play_stats_ctl type', () {
    for (final f in [
      'lib/kanaru.dart',
      'lib/src/database/database.dart',
      'lib/src/database/tables.dart',
    ]) {
      expect(File(f).readAsStringSync(), isNot(contains('playback_stats')));
    }
    expect(
      File('lib/src/database/tables/playback_tables.drift.dart')
          .readAsStringSync(),
      isNot(contains('PlayStatsCtl')),
    );
  });
}
