import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/scan/track_gc_runner.dart';

import '../../database/support/test_db.dart';

void main() {
  late AppDatabase db;
  late int sourceId;
  setUp(() async {
    db = openTestDb();
    sourceId = await addSource(db);
  });
  tearDown(() => db.close());

  final late = 1000 + missingGraceMs + 1;

  Future<int> count() async => (await db.select(db.tracks).get()).length;

  test('deletes an old missing orphan and keeps a recent one', () async {
    await addAgedTrack(db, sourceId, 'old.mp3', TrackStatus.missing);
    await addAgedTrack(db, sourceId, 'new.mp3', TrackStatus.missing, at: late);
    expect(await runTrackGc(db, now: late), 1);
    expect((await db.select(db.tracks).get()).single.locator, 'new.mp3');
  });

  test('keeps a missing track that sits in the queue', () async {
    final id = await addAgedTrack(db, sourceId, 'q.mp3', TrackStatus.missing);
    await db
        .into(db.queueEntries)
        .insert(
          QueueEntriesCompanion.insert(
            trackId: id,
            sortKey: 'a',
            addedAt: 1000,
          ),
        );
    expect(await runTrackGc(db, now: late), 0);
    expect(await count(), 1);
  });

  test('swallows the fail-closed StateError and returns null', () async {
    await addAgedTrack(db, sourceId, 'old.mp3', TrackStatus.missing);
    await db.customStatement('PRAGMA foreign_keys = OFF');
    expect(await runTrackGc(db, now: late), isNull);
    expect(await count(), 1);
  });

  test('a database error is logged and returns null', () async {
    await addAgedTrack(db, sourceId, 'old.mp3', TrackStatus.missing);
    await db.customStatement(
      'CREATE TRIGGER boom BEFORE DELETE ON tracks '
      "BEGIN SELECT RAISE(ABORT, 'boom'); END",
    );
    expect(await runTrackGc(db, now: late), isNull);
    expect(await count(), 1);
  });
}
