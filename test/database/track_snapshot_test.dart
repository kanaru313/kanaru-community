import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';

import 'support/pro_like_database.dart';
import 'support/pro_like_database.drift.dart';
import 'support/test_db.dart';

TracksCompanion _row(
  int sourceId,
  String locator, {
  String title = 'Title',
  int at = 1000,
  String? uid,
}) => TracksCompanion.insert(
  uid: uid ?? trackUid('source-$sourceId', locator),
  sourceId: sourceId,
  locator: locator,
  relPath: locator,
  title: title,
  titleSearch: Value(title.toLowerCase()),
  addedAt: at,
  updatedAt: at,
);

void main() {
  late AppDatabase db;
  late int local;
  setUp(() async {
    db = openTestDb();
    local = await addSource(db);
  });
  tearDown(() => db.close());

  Future<Track> read(int id) =>
      (db.select(db.tracks)..where((t) => t.id.equals(id))).getSingle();

  Future<int> upsert(TracksCompanion row) =>
      upsertTrackSnapshot(db, db.tracks, row);

  test('classification covers every column exactly once', () {
    final all = [
      ...trackIdentityColumns,
      ...trackSnapshotColumns,
      ...trackScanColumns,
      ...trackUserColumns,
      ...trackLifecycleColumns,
    ];
    final actual = db.tracks.$columns.map((c) => c.name).toList();
    expect(all.toSet(), hasLength(all.length));
    expect(all.toSet(), actual.toSet());
  });

  test('title without title_search and genre without genre_key throw', () {
    final noTitleSearch = TracksCompanion(
      uid: const Value('u'),
      sourceId: Value(local),
      locator: const Value('a'),
      relPath: const Value('a'),
      title: const Value('T'),
      addedAt: const Value(1),
      updatedAt: const Value(1),
    );
    expect(upsert(noTitleSearch), throwsArgumentError);
    expect(
      upsert(
        noTitleSearch.copyWith(
          titleSearch: const Value('t'),
          genre: const Value('Pop'),
        ),
      ),
      throwsArgumentError,
    );
  });

  test('title_search without title and genre_key without genre throw', () {
    final base = TracksCompanion(
      uid: const Value('u2'),
      sourceId: Value(local),
      locator: const Value('b'),
      relPath: const Value('b'),
      addedAt: const Value(1),
      updatedAt: const Value(1),
    );
    expect(
      upsert(base.copyWith(titleSearch: const Value('t'))),
      throwsArgumentError,
    );
    expect(
      upsert(
        base.copyWith(
          title: const Value('T'),
          titleSearch: const Value('t'),
          genreKey: const Value('pop'),
        ),
      ),
      throwsArgumentError,
    );
  });

  test('scan columns are written and rewritten', () async {
    final id = await upsert(
      _row(
        local,
        'a.flac',
      ).copyWith(tagsVersion: const Value(2), scanError: const Value('io')),
    );
    expect((await read(id)).tagsVersion, 2);
    await upsert(
      _row(local, 'a.flac', at: 2000).copyWith(scanError: const Value(null)),
    );
    final r = await read(id);
    expect((r.tagsVersion, r.scanError), (2, null));
  });

  test('a new file inside a live exclusion is inserted hidden', () async {
    await addMount(db, local, root: '/m');
    await applyFolderExclusion(
      db,
      sourceId: local,
      folderKey: 'A',
      displayPath: 'A',
      now: 1,
    );
    final inside = await upsert(_row(local, 'A/x.flac'));
    final outside = await upsert(_row(local, 'A B/x.flac'));
    expect((await read(inside)).status, TrackStatus.hidden);
    expect((await read(outside)).status, TrackStatus.present);
    await removeFolderExclusion(db, sourceId: local, folderKey: 'A', now: 2);
    expect((await read(inside)).status, TrackStatus.missing);
    await upsert(_row(local, 'A/x.flac', at: 3000));
    expect((await read(inside)).status, TrackStatus.present);
  });

  test('scan cycle keeps user data and clears missing_since', () async {
    final id = await upsert(_row(local, 'a.flac'));
    await (db.update(db.tracks)..where((t) => t.id.equals(id))).write(
      const TracksCompanion(rating: Value(80), lyricsOffsetMs: Value(250)),
    );
    await (db.update(db.tracks)..where((t) => t.id.equals(id))).write(
      const TracksCompanion(
        status: Value(TrackStatus.missing),
        missingSince: Value(500),
      ),
    );
    final before = await read(id);

    final again = await upsert(_row(local, 'a.flac', title: 'New', at: 2000));
    final after = await read(id);
    expect(again, id);
    expect(after.status, TrackStatus.present);
    expect(after.missingSince, isNull);
    expect(after.title, 'New');
    expect(after.updatedAt, 2000);
    expect(after.rating, 80);
    expect(after.lyricsOffsetMs, 250);
    expect(after.uid, before.uid);
    expect(after.addedAt, before.addedAt);
  });

  test('a hidden row stays hidden on rescan', () async {
    final id = await upsert(_row(local, 'a.flac'));
    await (db.update(db.tracks)..where((t) => t.id.equals(id))).write(
      const TracksCompanion(
        status: Value(TrackStatus.hidden),
        missingSince: Value(7),
      ),
    );
    await upsert(_row(local, 'a.flac', title: 'New', at: 2000));
    final row = await read(id);
    expect(row.status, TrackStatus.hidden);
    expect(row.title, 'New');
    expect(row.missingSince, 7);
  });

  group('plugin source', () {
    late int plugin;
    setUp(() async => plugin = await addSource(db, kind: SourceKind.plugin));

    test('rows are remote on insert and on conflict', () async {
      final id = await upsert(_row(plugin, 'x1'));
      expect((await read(id)).status, TrackStatus.remote);
      await upsert(_row(plugin, 'x1', title: 'Changed', at: 3000));
      final row = await read(id);
      expect(row.status, TrackStatus.remote);
      expect(row.title, 'Changed');
      expect(row.updatedAt, 3000);
    });

    test('a present plugin row becomes remote', () async {
      final id = await addTrack(db, plugin, locator: 'x1');
      await upsert(_row(plugin, 'x1'));
      expect((await read(id)).status, TrackStatus.remote);
    });
  });

  test('a caller-set status is rejected', () {
    expect(
      upsert(_row(local, 'a.flac').copyWith(status: const Value('present'))),
      throwsArgumentError,
    );
  });

  test('user and lifecycle columns are rejected', () {
    expect(
      upsert(_row(local, 'a.flac').copyWith(rating: const Value(5))),
      throwsArgumentError,
    );
    expect(
      upsert(_row(local, 'a.flac').copyWith(missingSince: const Value(5))),
      throwsArgumentError,
    );
  });

  test('a partial companion keeps other snapshot fields', () async {
    final id = await upsert(
      _row(
        local,
        'a.flac',
      ).copyWith(artist: const Value('Artist'), year: const Value(1999)),
    );
    // Only the required insert fields: other snapshot fields stay stored.
    await upsert(
      _row(local, 'a.flac', title: 'Only title', at: 5, uid: 'ignored'),
    );
    final row = await read(id);
    expect(row.title, 'Only title');
    expect(row.artist, 'Artist');
    expect(row.year, 1999);
    expect(row.uid, trackUid('source-$local', 'a.flac'));
  });

  test('an explicit null writes null', () async {
    final id = await upsert(
      _row(local, 'a.flac').copyWith(artist: const Value('A')),
    );
    await upsert(_row(local, 'a.flac').copyWith(artist: const Value(null)));
    expect((await read(id)).artist, isNull);
  });

  test('locators differing only by normalization form coexist', () async {
    final nfc = await upsert(_row(local, 'café.flac'));
    final nfd = await upsert(_row(local, 'café.flac'));
    expect(nfc, isNot(nfd));
    expect(await db.select(db.tracks).get(), hasLength(2));
  });

  group('inside a Pro-like transaction', () {
    late ProLikeDatabase pro;
    setUp(() async {
      pro = ProLikeDatabase.connect(db.sharedConnection);
      addTearDown(pro.close);
      await db.customSelect('SELECT 1').get();
      await pro.createOwnTables();
    });

    test('upsert and a Pro insert commit together', () async {
      await pro.transaction(() async {
        final id = await upsertTrackSnapshot(
          pro,
          pro.tracks,
          _row(local, 'a.flac'),
        );
        await pro
            .into(pro.proLikeNotes)
            .insert(ProLikeNotesCompanion.insert(trackId: id, body: 'n'));
      });
      expect(await db.select(db.tracks).get(), hasLength(1));
      expect(await pro.select(pro.proLikeNotes).get(), hasLength(1));
    });

    test('a throw rolls both back', () async {
      await expectLater(
        pro.transaction(() async {
          final id = await upsertTrackSnapshot(
            pro,
            pro.tracks,
            _row(local, 'a.flac'),
          );
          await pro
              .into(pro.proLikeNotes)
              .insert(ProLikeNotesCompanion.insert(trackId: id, body: 'n'));
          throw StateError('boom');
        }),
        throwsStateError,
      );
      expect(await db.select(db.tracks).get(), isEmpty);
      expect(await pro.select(pro.proLikeNotes).get(), isEmpty);
    });
  });
}
