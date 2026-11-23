import 'package:drift/drift.dart' show Value, Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/lyrics/data/lyrics_choice_store.dart';
import 'package:kanaru/src/lyrics/data/lyrics_facts_query.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_facts.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

import '../../database/support/test_db.dart';

void main() {
  late AppDatabase db;
  late TrackId track;

  setUp(() async {
    db = openTestDb();
    final source = await addSource(db);
    track = TrackId(await addTrack(db, source, locator: 'a.flac'));
  });
  tearDown(() => db.close());

  /// Collects the emissions of the stream for [id].
  (List<LyricsFacts?>, Future<void> Function()) collect(TrackId id) {
    final seen = <LyricsFacts?>[];
    final sub = watchLyricsFacts(db, id).listen(seen.add);
    return (seen, sub.cancel);
  }

  test('emits the facts of a track without details', () async {
    final (seen, stop) = collect(track);
    await pumpEventQueue();
    await stop();
    expect(seen, [
      LyricsFacts(
        trackId: track,
        trackRevision: null,
        lrcLocator: null,
        lrcRevision: null,
        off: false,
        title: 'Title',
      ),
    ]);
  });

  test('is null for an unknown track', () async {
    final (seen, stop) = collect(const TrackId(4242));
    await pumpEventQueue();
    await stop();
    expect(seen, [null]);
  });

  test(
    'emits again on a details write, a choice write and a revision change',
    () async {
      final (seen, stop) = collect(track);
      await pumpEventQueue();

      await db
          .into(db.trackDetails)
          .insert(
            TrackDetailsCompanion.insert(
              trackId: Value(track.value),
              lrcLocator: const Value('a.lrc'),
              lrcRevision: const Value('1:10'),
            ),
          );
      await pumpEventQueue();
      expect(seen.last!.lrcLocator, 'a.lrc');
      expect(seen.last!.lrcRevision, '1:10');

      await setLyricsOff(db, track, now: 5);
      await pumpEventQueue();
      expect(seen.last!.off, isTrue);

      await db.customUpdate(
        "UPDATE tracks SET revision = '9:9' WHERE id = ?",
        variables: [Variable.withInt(track.value)],
        updates: {db.tracks},
      );
      await pumpEventQueue();
      expect(seen.last!.trackRevision, '9:9');

      await clearLyricsChoice(db, track);
      await pumpEventQueue();
      await stop();
      expect(seen.last!.off, isFalse);
      expect(seen, hasLength(5));
    },
  );

  test('an unrelated write does not emit twice (distinct)', () async {
    final (seen, stop) = collect(track);
    await pumpEventQueue();
    // Another track's details: this stream re-runs on the table but the
    // value is equal.
    final other = await addTrack(db, 1, locator: 'b.flac');
    await db
        .into(db.trackDetails)
        .insert(TrackDetailsCompanion.insert(trackId: Value(other)));
    await pumpEventQueue();
    await stop();
    expect(seen, hasLength(1));
  });

  test('read key ignores the choice', () async {
    final (seen, stop) = collect(track);
    await pumpEventQueue();
    await setLyricsOff(db, track, now: 1);
    await pumpEventQueue();
    await stop();
    expect(seen.first!.readKey, seen.last!.readKey);
    expect(seen.first, isNot(seen.last));
  });
}
