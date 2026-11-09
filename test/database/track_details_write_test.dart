import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late int track;
  setUp(() async {
    db = openTestDb();
    track = await addTrack(db, await addSource(db), locator: 'a');
  });
  tearDown(() => db.close());

  Future<TrackDetail> row() => db.select(db.trackDetails).getSingle();

  test('insert, then rewrite only the columns present', () async {
    await upsertTrackDetails(
      db,
      TrackDetailsCompanion.insert(
        trackId: Value(track),
        comment: const Value('c'),
        lrcLocator: const Value('a.lrc'),
      ),
    );
    await upsertTrackDetails(
      db,
      TrackDetailsCompanion(
        trackId: Value(track),
        lrcLocator: const Value(null),
        coverSrc: const Value('cover.jpg'),
      ),
    );
    final r = await row();
    expect(r.comment, 'c');
    expect(r.lrcLocator, isNull);
    expect(r.coverSrc, 'cover.jpg');
  });

  test('only the track id is a no-op on an existing row', () async {
    await upsertTrackDetails(
      db,
      TrackDetailsCompanion(trackId: Value(track), comment: const Value('c')),
    );
    await upsertTrackDetails(db, TrackDetailsCompanion(trackId: Value(track)));
    expect((await row()).comment, 'c');
  });

  test('missing track id throws', () async {
    await expectLater(
      upsertTrackDetails(db, const TrackDetailsCompanion(comment: Value('c'))),
      throwsArgumentError,
    );
  });
}
