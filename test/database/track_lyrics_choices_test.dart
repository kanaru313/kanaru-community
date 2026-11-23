import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/lyrics/data/lyrics_choice_store.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late TrackId track;

  setUp(() async {
    db = openTestDb();
    final source = await addSource(db);
    track = TrackId(await addTrack(db, source, locator: 'a.flac'));
  });
  tearDown(() => db.close());

  Future<List<Map<String, Object?>>> rows() async => [
    for (final r
        in await db.customSelect('SELECT * FROM track_lyrics_choices').get())
      r.data,
  ];

  test('no row means automatic', () async {
    expect(await rows(), isEmpty);
  });

  test('setLyricsOff inserts, a second call replaces the row', () async {
    await setLyricsOff(db, track, now: 10);
    expect(await rows(), [
      {'track_id': track.value, 'mode': 'off', 'updated_at': 10},
    ]);
    await setLyricsOff(db, track, now: 20);
    expect(await rows(), [
      {'track_id': track.value, 'mode': 'off', 'updated_at': 20},
    ]);
  });

  test(
    'clearLyricsChoice deletes the row and is harmless without one',
    () async {
      await clearLyricsChoice(db, track);
      await setLyricsOff(db, track, now: 1);
      await clearLyricsChoice(db, track);
      expect(await rows(), isEmpty);
    },
  );

  test('a stream on the table re-emits on both writes', () async {
    final seen = <int>[];
    final sub = db
        .select(db.trackLyricsChoices)
        .watch()
        .listen((r) => seen.add(r.length));
    await pumpEventQueue();
    await setLyricsOff(db, track, now: 1);
    await pumpEventQueue();
    await clearLyricsChoice(db, track);
    await pumpEventQueue();
    await sub.cancel();
    expect(seen, [0, 1, 0]);
  });

  test('setLyricsFile writes the file mode and replaces an off row', () async {
    await setLyricsOff(db, track, now: 1);
    await setLyricsFile(db, track, now: 2);
    expect(await rows(), [
      {'track_id': track.value, 'mode': 'file', 'updated_at': 2},
    ]);
    await setLyricsOff(db, track, now: 3);
    expect((await rows()).single['mode'], 'off');
  });

  test('the CHECK refuses a mode other than off and file', () async {
    await expectLater(
      db.customStatement(
        "INSERT INTO track_lyrics_choices (track_id, mode, updated_at) VALUES (?, 'kept', 1)",
        [track.value],
      ),
      throwsConstraint('CHECK'),
    );
  });

  test('the foreign key refuses an unknown track', () async {
    await expectLater(
      setLyricsOff(db, const TrackId(9999), now: 1),
      throwsConstraint('FOREIGN KEY'),
    );
  });

  test('a track with a choice cannot be deleted', () async {
    await setLyricsOff(db, track, now: 1);
    await expectLater(
      db.customStatement('DELETE FROM tracks WHERE id = ?', [track.value]),
      throwsConstraint('FOREIGN KEY'),
    );
    final left = await db
        .customSelect(
          'SELECT 1 FROM tracks WHERE id = ?',
          variables: [Variable.withInt(track.value)],
        )
        .get();
    expect(left, hasLength(1));
  });
}
