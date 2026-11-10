import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late int src;
  setUp(() async {
    db = openTestDb();
    src = await addSource(db);
  });
  tearDown(() => db.close());

  Future<Track> row(int id) =>
      (db.select(db.tracks)..where((t) => t.id.equals(id))).getSingle();

  test('present rows become missing with missing_since', () async {
    final a = await addTrack(db, src, locator: 'a');
    expect(await markTracksMissing(db, [a, a], 5000), 1);
    final r = await row(a);
    expect(r.status, TrackStatus.missing);
    expect(r.missingSince, 5000);
  });

  test('hidden, remote and already missing rows are not touched', () async {
    final hidden = await addTrack(
      db,
      src,
      locator: 'h',
      status: TrackStatus.hidden,
    );
    final remote = await addTrack(
      db,
      src,
      locator: 'r',
      status: TrackStatus.remote,
    );
    final missing = await addTrack(
      db,
      src,
      locator: 'm',
      status: TrackStatus.missing,
      now: 100,
    );
    expect(await markTracksMissing(db, [hidden, remote, missing], 5000), 0);
    expect((await row(hidden)).status, TrackStatus.hidden);
    expect((await row(remote)).status, TrackStatus.remote);
    expect((await row(missing)).missingSince, 100);
  });

  test('empty input does nothing', () async {
    expect(await markTracksMissing(db, const [], 1), 0);
  });

  test('1 200 ids are all marked, across chunk boundaries', () async {
    final ids = <int>[];
    await db.batch((b) {
      for (var i = 0; i < 1200; i++) {
        b.insert(
          db.tracks,
          TracksCompanion.insert(
            uid: 'u$i',
            sourceId: src,
            locator: 'l$i',
            relPath: 'l$i',
            title: 't',
            addedAt: 1,
            updatedAt: 1,
          ),
        );
      }
    });
    ids.addAll([for (final r in await db.select(db.tracks).get()) r.id]);
    expect(ids, hasLength(1200));
    expect(await markTracksMissing(db, ids, 9), 1200);
    final left = await (db.select(
      db.tracks,
    )..where((t) => t.status.equals(TrackStatus.present))).get();
    expect(left, isEmpty);
  });

  test('a stream on tracks re-emits', () async {
    final a = await addTrack(db, src, locator: 'a');
    final emitted = <int>[];
    final sub =
        (db.select(db.tracks)
              ..where((t) => t.status.equals(TrackStatus.present)))
            .watch()
            .listen((r) => emitted.add(r.length));
    addTearDown(sub.cancel);
    await pumpEventQueue();
    await markTracksMissing(db, [a], 1);
    await pumpEventQueue();
    expect(emitted.last, 0);
  });
}
