import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/database/tombstone_upsert.dart';

import 'support/pro_like_database.dart';
import 'support/pro_like_database.drift.dart';
import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDb());
  tearDown(() => db.close());

  group('constraints', () {
    late int sourceId;
    setUp(() async => sourceId = await addSource(db));

    test('status accepts all four values', () async {
      for (final s in TrackStatus.values) {
        await addTrack(db, sourceId, locator: 'a-$s.flac', status: s);
      }
      expect(await db.select(db.tracks).get(), hasLength(4));
    });

    test('a missing row needs missing_since', () async {
      final id = await addTrack(db, sourceId, locator: 'a.flac');
      expect(
        db.customStatement(
          "UPDATE tracks SET status = 'missing' WHERE id = ?",
          [id],
        ),
        throwsConstraint('tracks_missing_since'),
      );
      await db.customStatement(
        "UPDATE tracks SET status = 'missing', missing_since = 5 WHERE id = ?",
        [id],
      );
    });

    test('language_detected accepts 0 and 1, rejects 2', () async {
      final id = await addTrack(db, sourceId, locator: 'a.flac');
      for (final v in [0, 1]) {
        await db.customStatement(
          'UPDATE tracks SET language_detected = ? WHERE id = ?',
          [v, id],
        );
      }
      expect(
        db.customStatement(
          'UPDATE tracks SET language_detected = 2 WHERE id = ?',
          [id],
        ),
        throwsConstraint('CHECK constraint failed'),
      );
    });

    test('status rejects an unknown value', () async {
      expect(
        addTrack(db, sourceId, locator: 'a.flac', status: 'gone'),
        throwsConstraint('CHECK constraint failed'),
      );
    });

    test('rating accepts 0 and 100, rejects 101', () async {
      await addTrack(db, sourceId, locator: 'a.flac', rating: 0);
      await addTrack(db, sourceId, locator: 'b.flac', rating: 100);
      expect(
        addTrack(db, sourceId, locator: 'c.flac', rating: 101),
        throwsConstraint('CHECK constraint failed'),
      );
    });

    test('(source_id, locator) is unique', () async {
      await addTrack(db, sourceId, locator: 'a.flac');
      expect(
        addTrack(db, sourceId, locator: 'a.flac', uid: 'other-uid'),
        throwsConstraint('tracks.source_id, tracks.locator'),
      );
    });

    test('a second mount with the same root is rejected', () async {
      await addMount(db, sourceId, root: '/music');
      final other = await addSource(db, name: 'Other');
      expect(
        addMount(db, other, root: '/music'),
        throwsConstraint('source_mounts.root'),
      );
    });

    test('mounts without a root may repeat', () async {
      await db
          .into(db.sourceMounts)
          .insert(
            SourceMountsCompanion.insert(sourceId: Value(sourceId), addedAt: 1),
          );
      final other = await addSource(db, name: 'Other');
      await db
          .into(db.sourceMounts)
          .insert(
            SourceMountsCompanion.insert(sourceId: Value(other), addedAt: 1),
          );
    });

    test('a source with tracks cannot be deleted', () async {
      await addTrack(db, sourceId, locator: 'a.flac');
      expect(db.delete(db.sources).go(), throwsConstraint('FOREIGN KEY'));
    });

    test('deleting a source removes its mount', () async {
      final solo = await addSource(db, name: 'Solo');
      await addMount(db, solo, root: '/solo');
      await (db.delete(db.sources)..where((s) => s.id.equals(solo))).go();
      expect(await db.select(db.sourceMounts).get(), isEmpty);
    });
  });

  test(
    'a Pro-like database joins tracks and RESTRICT blocks the delete',
    () async {
      final pro = ProLikeDatabase.connect(db.sharedConnection);
      addTearDown(pro.close);
      await db.customSelect('SELECT 1').get(); // public database opens first
      await pro.createOwnTables();

      final source = await addSource(db);
      final track = await addTrack(db, source, locator: 'a.flac');
      await pro
          .into(pro.proLikeNotes)
          .insert(ProLikeNotesCompanion.insert(trackId: track, body: 'note'));
      expect(
        (db.delete(db.tracks)..where((t) => t.id.equals(track))).go(),
        throwsConstraint('FOREIGN KEY'),
      );
      final joined = await (pro.select(
        pro.tracks,
      )..where((t) => t.id.equals(track))).getSingle();
      expect(joined.locator, 'a.flac');
    },
  );

  test('works inside a transaction of a Pro-like database', () async {
    final pro = ProLikeDatabase.connect(db.sharedConnection);
    addTearDown(pro.close);
    await db.customSelect('SELECT 1').get();
    SourcesCompanion src(int now) => SourcesCompanion.insert(
      uid: 'src:x',
      kind: 'webdav',
      name: 'S',
      addedAt: now,
      updatedAt: now,
    );
    final first = await insertOrRevive(pro, pro.sources, src(1), now: 1);
    await db.customStatement(
      'UPDATE sources SET deleted_at = 500 WHERE uid = ?',
      ['src:x'],
    );
    final revived = await pro.transaction(
      () => insertOrRevive(pro, pro.sources, src(9), now: 9),
    );
    expect(revived.id, first.id);
    expect(revived.deletedAt, isNull);

    await db.customStatement(
      'UPDATE sources SET deleted_at = 500 WHERE uid = ?',
      ['src:x'],
    );
    await expectLater(
      pro.transaction(() async {
        await insertOrRevive(pro, pro.sources, src(11), now: 11);
        throw StateError('abort');
      }),
      throwsStateError,
    );
    final after = await db.select(db.sources).getSingle();
    expect(after.deletedAt, 500);
    expect(after.updatedAt, 9);
  });
}
