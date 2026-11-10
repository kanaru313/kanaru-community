import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/domain/custom_cover_controller.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDb());
  tearDown(() => db.close());

  Future<int> rows() async =>
      (await db
              .customSelect('SELECT count(*) AS n FROM custom_covers')
              .getSingle())
          .read<int>('n');

  test('the domain enum names equal the CHECK set', () {
    expect(
      CustomCoverKind.values.map((k) => k.name).toSet(),
      CustomCoverKinds.values,
    );
  });

  group('table', () {
    test('CHECK rejects a kind outside playlist/album/artist', () {
      expect(
        db.customStatement(
          "INSERT INTO custom_covers VALUES ('track', 'x', 'k', 1)",
        ),
        throwsConstraint('CHECK'),
      );
    });

    test('primary key is (kind, item_key)', () async {
      await db.customStatement(
        "INSERT INTO custom_covers VALUES ('album', 'x', 'k', 1)",
      );
      // Same key under another kind is a different item.
      await db.customStatement(
        "INSERT INTO custom_covers VALUES ('artist', 'x', 'k', 1)",
      );
      expect(
        db.customStatement(
          "INSERT INTO custom_covers VALUES ('album', 'x', 'k2', 2)",
        ),
        throwsConstraint('UNIQUE'),
      );
    });

    test('NOT NULL columns', () {
      expect(
        db.customStatement(
          "INSERT INTO custom_covers VALUES ('album', 'x', NULL, 1)",
        ),
        throwsConstraint('NOT NULL'),
      );
    });
  });

  group('helpers', () {
    test('set returns the replaced key, get and clear round trip', () async {
      expect(await customCoverKey(db, 'album', 'a'), isNull);
      expect(await setCustomCover(db, 'album', 'a', 'k1'), isNull);
      expect(await customCoverKey(db, 'album', 'a'), 'k1');
      expect(await setCustomCover(db, 'album', 'a', 'k2', now: 5), 'k1');
      expect(await customCoverKey(db, 'album', 'a'), 'k2');
      expect(await rows(), 1);
      expect(await clearCustomCover(db, 'album', 'a'), 'k2');
      expect(await clearCustomCover(db, 'album', 'a'), isNull);
      expect(await customCoverKey(db, 'album', 'a'), isNull);
    });

    test('bad input is a failed future, not a synchronous throw', () async {
      final futures = [
        setCustomCover(db, 'song', 'a', 'k'),
        setCustomCover(db, 'album', '', 'k'),
        setCustomCover(db, 'album', 'a', ''),
        clearCustomCover(db, 'song', 'a'),
      ];
      for (final f in futures) {
        await expectLater(f, throwsArgumentError);
      }
    });

    test('a playlist cover needs an existing playlist', () async {
      await expectLater(
        setCustomCover(db, 'playlist', 'ghost', 'k'),
        throwsConstraint('no such playlist'),
      );
      await addPlaylist(db, uid: 'pl-a');
      await setCustomCover(db, 'playlist', 'pl-a', 'k');
      await expectLater(
        db.customStatement(
          "UPDATE custom_covers SET item_key = 'ghost' WHERE kind = 'playlist'",
        ),
        throwsConstraint('no such playlist'),
      );
      // Album and artist keys are not checked against a table.
      await setCustomCover(db, 'album', 'no-table', 'k');
      expect(await rows(), 2);
    });

    test('referenced keys are distinct; reference check', () async {
      await setCustomCover(db, 'album', 'a', 'k1');
      await setCustomCover(db, 'artist', 'a', 'k1');
      await addPlaylist(db, uid: 'p');
      await setCustomCover(db, 'playlist', 'p', 'k2');
      expect(await referencedCustomCoverKeys(db), {'k1', 'k2'});
      expect(await isCustomCoverKeyReferenced(db, 'k1'), isTrue);
      expect(await isCustomCoverKeyReferenced(db, 'k3'), isFalse);
    });

    test('watch emits on set, change and clear', () async {
      final seen = <String?>[];
      final sub = watchCustomCoverKey(db, 'album', 'a').listen(seen.add);
      addTearDown(sub.cancel);
      await pumpEventQueue();
      await setCustomCover(db, 'album', 'a', 'k1');
      await pumpEventQueue();
      await setCustomCover(db, 'album', 'a', 'k2');
      await pumpEventQueue();
      await setCustomCover(db, 'album', 'b', 'other'); // other item: no emit
      await pumpEventQueue();
      await clearCustomCover(db, 'album', 'a');
      await pumpEventQueue();
      expect(seen, [null, 'k1', 'k2', null]);
    });
  });

  group('playlist delete', () {
    test('hard delete removes only that playlist cover', () async {
      await addPlaylist(db, uid: 'pl-a');
      await addPlaylist(db, uid: 'pl-b');
      await setCustomCover(db, 'playlist', 'pl-a', 'k1');
      await setCustomCover(db, 'playlist', 'pl-b', 'k2');
      // Same text under another kind must survive.
      await setCustomCover(db, 'album', 'pl-a', 'k3');

      await db.customStatement("DELETE FROM playlists WHERE uid = 'pl-a'");

      expect(await customCoverKey(db, 'playlist', 'pl-a'), isNull);
      expect(await customCoverKey(db, 'playlist', 'pl-b'), 'k2');
      expect(await customCoverKey(db, 'album', 'pl-a'), 'k3');
    });

    test('a tombstoned playlist keeps its cover', () async {
      await addPlaylist(db, uid: 'pl-a');
      await setCustomCover(db, 'playlist', 'pl-a', 'k1');
      await db.customStatement(
        "UPDATE playlists SET deleted_at = 5 WHERE uid = 'pl-a'",
      );
      expect(await customCoverKey(db, 'playlist', 'pl-a'), 'k1');
    });

    test('the watch stream sees the trigger delete', () async {
      await addPlaylist(db, uid: 'pl-a');
      await setCustomCover(db, 'playlist', 'pl-a', 'k1');
      final seen = <String?>[];
      final sub = watchCustomCoverKey(db, 'playlist', 'pl-a').listen(seen.add);
      addTearDown(sub.cancel);
      await pumpEventQueue();
      await db.delete(db.playlists).go();
      await pumpEventQueue();
      expect(seen, ['k1', null]);
    });
  });

  test('works on the file database (background isolate)', () async {
    final dir = Directory.systemTemp.createTempSync('kanaru_cc_');
    final file = AppDatabase.file(File('${dir.path}/kanaru.db'));
    addTearDown(() async {
      await file.close();
      dir.deleteSync(recursive: true);
    });
    await addPlaylist(file, uid: 'pl-a');
    final seen = <String?>[];
    final sub = watchCustomCoverKey(file, 'playlist', 'pl-a').listen(seen.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();
    expect(await setCustomCover(file, 'playlist', 'pl-a', 'k1'), isNull);
    await pumpEventQueue();
    await file.delete(file.playlists).go();
    await pumpEventQueue();
    expect(await referencedCustomCoverKeys(file), isEmpty);
    expect(seen, [null, 'k1', null]);
    await expectLater(
      file.customStatement(
        "INSERT INTO custom_covers VALUES ('bad', 'x', 'k', 1)",
      ),
      throwsConstraint('CHECK'),
    );
  });
}
