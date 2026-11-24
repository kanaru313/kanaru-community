import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/lyrics/data/translation/translation_prefs_store.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

import '../../../database/support/test_db.dart';

void main() {
  late AppDatabase db;
  late TranslationPrefsStore store;
  late TrackId track;

  setUp(() async {
    db = openTestDb();
    store = TranslationPrefsStore(db);
    final source = await addSource(db);
    track = TrackId(await addTrack(db, source, locator: 'a.flac'));
  });
  tearDown(() => db.close());

  Future<int> rowCount() async =>
      (await db.customSelect('SELECT 1 FROM track_translation_prefs').get())
          .length;

  test('no row reads as null', () async {
    expect(await store.watch(track).first, isNull);
  });

  test('setTarget writes, replaces and the stream follows', () async {
    final seen = <String?>[];
    final sub = store.watch(track).listen(seen.add);
    await pumpEventQueue();
    expect(await store.setTarget(track, 'vi', now: 1), isTrue);
    await pumpEventQueue();
    expect(await store.setTarget(track, 'en', now: 2), isTrue);
    await pumpEventQueue();
    expect(await rowCount(), 1);
    expect(seen, [null, 'vi', 'en']);
    await sub.cancel();
  });

  test('setTarget(null) deletes the row', () async {
    await store.setTarget(track, 'vi', now: 1);
    expect(await store.setTarget(track, null, now: 2), isTrue);
    expect(await rowCount(), 0);
    expect(await store.setTarget(track, null, now: 3), isTrue);
  });

  test('a code outside the language list is refused', () async {
    expect(() => store.setTarget(track, 'xx', now: 1), throwsArgumentError);
    expect(() => store.setTarget(track, 'zh-TW', now: 1), throwsArgumentError);
    expect(await rowCount(), 0);
  });

  test('an unknown track is reported, never thrown', () async {
    expect(await store.setTarget(const TrackId(9999), 'vi', now: 1), isFalse);
  });
}
