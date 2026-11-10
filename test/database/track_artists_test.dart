import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late int src;
  late int track;
  setUp(() async {
    db = openTestDb();
    src = await addSource(db);
    track = await addTrack(db, src, locator: 'a');
  });
  tearDown(() => db.close());

  Future<List<TrackArtist>> rows() =>
      (db.select(db.trackArtists)
            ..where((t) => t.trackId.equals(track))
            ..orderBy([(t) => OrderingTerm.asc(t.position)]))
          .get();

  test('rows keep the tag order', () async {
    await replaceTrackArtists(db, track, [
      (key: 'b', name: 'B'),
      (key: 'a', name: 'A'),
    ]);
    final r = await rows();
    expect(r.map((e) => e.artistKey), ['b', 'a']);
    expect(r.map((e) => e.position), [0, 1]);
  });

  test('a repeated key keeps the first occurrence', () async {
    await replaceTrackArtists(db, track, [
      (key: 'x', name: 'First'),
      (key: 'y', name: 'Y'),
      (key: 'x', name: 'first'),
    ]);
    final r = await rows();
    expect(r.map((e) => e.artistName), ['First', 'Y']);
    expect(r.map((e) => e.position), [0, 1]);
  });

  test('replacing drops the old rows; empty list clears', () async {
    await replaceTrackArtists(db, track, [(key: 'a', name: 'A')]);
    await replaceTrackArtists(db, track, [(key: 'b', name: 'B')]);
    expect((await rows()).map((e) => e.artistKey), ['b']);
    await replaceTrackArtists(db, track, const []);
    expect(await rows(), isEmpty);
  });

  test('other tracks are untouched', () async {
    final other = await addTrack(db, src, locator: 'b');
    await replaceTrackArtists(db, other, [(key: 'a', name: 'A')]);
    await replaceTrackArtists(db, track, [(key: 'a', name: 'A')]);
    await replaceTrackArtists(db, track, const []);
    expect(await db.select(db.trackArtists).get(), hasLength(1));
  });

  test('an empty key throws and keeps the old rows', () async {
    await replaceTrackArtists(db, track, [(key: 'a', name: 'A')]);
    await expectLater(
      replaceTrackArtists(db, track, [(key: '', name: 'N')]),
      throwsArgumentError,
    );
    expect(await rows(), hasLength(1));
  });

  test('an unknown track fails the foreign key', () async {
    await expectLater(
      replaceTrackArtists(db, 9999, [(key: 'a', name: 'A')]),
      throwsConstraint('FOREIGN KEY'),
    );
  });

  test('a stream on track_artists re-emits', () async {
    final sizes = <int>[];
    final sub = db
        .select(db.trackArtists)
        .watch()
        .listen((r) => sizes.add(r.length));
    addTearDown(sub.cancel);
    await pumpEventQueue();
    await replaceTrackArtists(db, track, [(key: 'a', name: 'A')]);
    await pumpEventQueue();
    expect(sizes.last, 1);
  });

  test('track_artists rows go before the track in the GC', () async {
    await db.customStatement(
      "UPDATE tracks SET status = 'missing', missing_since = 1 WHERE id = ?",
      [track],
    );
    await replaceTrackArtists(db, track, [(key: 'a', name: 'A')]);
    expect(await collectOrphanTracks(db, now: 1 + missingGraceMs), 1);
    expect(await db.select(db.trackArtists).get(), isEmpty);
    expect(await db.select(db.tracks).get(), isEmpty);
  });
}
