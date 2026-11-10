import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';

import 'support/test_db.dart';

void main() {
  late AppDatabase db;
  late int src;

  setUp(() async {
    db = openTestDb();
    src = await addSource(db, uid: 'src-1', root: null);
    await addMount(db, src, root: '/m');
  });
  tearDown(() => db.close());

  Future<int> track(String locator, {String status = TrackStatus.present}) =>
      addTrack(db, src, locator: locator, status: status);

  Future<String> status(int id) async => (await (db.select(
    db.tracks,
  )..where((t) => t.id.equals(id))).getSingle()).status;

  Future<int> exclude(String key, {int now = 2000}) => applyFolderExclusion(
    db,
    sourceId: src,
    folderKey: key,
    displayPath: '/m/$key',
    now: now,
  );

  Future<void> unexclude(String key, {int now = 3000}) =>
      removeFolderExclusion(db, sourceId: src, folderKey: key, now: now);

  test('apply hides present and missing rows in the range only', () async {
    final inA = await track('A/x.flac');
    final deep = await track('A/B/y.flac');
    final gone = await track('A/z.flac', status: TrackStatus.missing);
    final sibling = await track('A B/x.flac');
    final dot = await track('A.b/x.flac');
    final zero = await track('A0');
    await exclude('A');
    expect(await status(inA), TrackStatus.hidden);
    expect(await status(deep), TrackStatus.hidden);
    expect(await status(gone), TrackStatus.hidden);
    expect(await status(sibling), TrackStatus.present);
    expect(await status(dot), TrackStatus.present);
    expect(await status(zero), TrackStatus.present);
    expect(await excludedFolderKeys(db, src), ['A']);
  });

  test(
    'remove turns the range into missing and a later upsert restores it',
    () async {
      final id = await track('A/x.flac');
      await exclude('A');
      await unexclude('A');
      final row = await (db.select(
        db.tracks,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(row.status, TrackStatus.missing);
      expect(row.missingSince, 3000);
      expect(await excludedFolderKeys(db, src), isEmpty);

      await upsertTrackSnapshot(
        db,
        db.tracks,
        TracksCompanion.insert(
          uid: row.uid,
          sourceId: src,
          locator: 'A/x.flac',
          relPath: 'A/x.flac',
          title: 'T',
          titleSearch: const Value('t'),
          addedAt: 1,
          updatedAt: 4000,
        ),
      );
      expect(await status(id), TrackStatus.present);
    },
  );

  test(
    'apply twice returns the same id; revive after remove keeps it',
    () async {
      final a = await exclude('A');
      expect(await exclude('A'), a);
      await unexclude('A');
      expect(await exclude('A'), a);
      expect(await excludedFolderKeys(db, src), ['A']);
    },
  );

  test('removing the outer folder keeps an inner exclusion hidden', () async {
    final inner = await track('A/B/x.flac');
    final outerOnly = await track('A/y.flac');
    await exclude('A/B');
    await exclude('A');
    await unexclude('A');
    expect(await status(inner), TrackStatus.hidden);
    expect(await status(outerOnly), TrackStatus.missing);
  });

  test(
    'removing the inner folder under a live outer unhides nothing',
    () async {
      final inner = await track('A/B/x.flac');
      await exclude('A');
      await exclude('A/B');
      await unexclude('A/B');
      expect(await status(inner), TrackStatus.hidden);
    },
  );

  test('a root exclusion covers everything', () async {
    final inner = await track('A/x.flac');
    await exclude('A');
    await exclude('');
    await unexclude('A');
    expect(await status(inner), TrackStatus.hidden);
    await unexclude('');
    expect(await status(inner), TrackStatus.missing);
  });

  test('nothing is unhidden while the mount is disabled', () async {
    final id = await track('A/x.flac');
    await exclude('A');
    await setMountEnabled(db, src, false, 2500);
    await unexclude('A');
    expect(await status(id), TrackStatus.hidden);
  });

  test('nothing is unhidden for a removed source', () async {
    final id = await track('A/x.flac');
    await exclude('A');
    await removeSource(db, src, 2500);
    await unexclude('A');
    expect(await status(id), TrackStatus.hidden);
  });

  test('apply on a removed source throws and changes nothing', () async {
    final id = await track('A/x.flac');
    await removeSource(db, src, 2500);
    await expectLater(exclude('A'), throwsStateError);
    expect(await excludedFolderKeys(db, src), isEmpty);
    expect(await status(id), TrackStatus.hidden);
  });

  test('remove with no live exclusion is a no-op', () async {
    final id = await track('A/x.flac', status: TrackStatus.present);
    await unexclude('A');
    expect(await status(id), TrackStatus.present);
  });

  test('hidden rows of other sources and remote rows are untouched', () async {
    final other = await addSource(db, name: 'Other');
    final foreign = await addTrack(db, other, locator: 'A/x.flac');
    final remote = await track('A/r.flac', status: TrackStatus.remote);
    await exclude('A');
    expect(await status(foreign), TrackStatus.present);
    expect(await status(remote), TrackStatus.remote);
  });

  test('a tombstoned exclusion does not count as covering', () async {
    final id = await track('A/B/x.flac');
    await exclude('A');
    await exclude('A/B');
    await unexclude('A/B');
    await unexclude('A');
    expect(await status(id), TrackStatus.missing);
  });

  test('remove resets the scan cursor of an enabled mount', () async {
    await track('A/x.flac');
    await db.customStatement(
      "UPDATE source_mounts SET scan_cursor = 'c', last_scan_at = 5",
    );
    await exclude('A');
    await unexclude('A');
    final m = await db.select(db.sourceMounts).getSingle();
    expect((m.scanCursor, m.lastScanAt), (null, null));
  });

  test('remove notifies tracks and excluded_folders streams', () async {
    await track('A/x.flac');
    await exclude('A');
    var t = 0, f = 0;
    final s1 = db.select(db.tracks).watch().listen((_) => t++);
    final s2 = db.select(db.excludedFolders).watch().listen((_) => f++);
    addTearDown(() async {
      await s1.cancel();
      await s2.cancel();
    });
    await pumpEventQueue();
    final t0 = t, f0 = f;
    await unexclude('A');
    await pumpEventQueue();
    expect(t, greaterThan(t0));
    expect(f, greaterThan(f0));
  });

  test('an exclusion survives disabling and enabling the mount', () async {
    final inA = await track('A/x.flac');
    final other = await track('B/x.flac');
    await exclude('A');
    await setMountEnabled(db, src, false, 2500);
    await setMountEnabled(db, src, true, 2600);
    expect(await status(inA), TrackStatus.hidden);
    expect(await status(other), TrackStatus.missing);
  });

  test('an exclusion survives removing and reviving the source', () async {
    final inA = await track('A/x.flac');
    final other = await track('B/x.flac');
    await exclude('A');
    await removeSource(db, src, 2500);
    await reviveSource(
      db,
      src,
      2600,
      name: 'Music',
      account: null,
      configJson: '{}',
      credentialRef: null,
    );
    expect(await status(inA), TrackStatus.hidden);
    expect(await status(other), TrackStatus.missing);
  });

  test('streams on tracks and excluded_folders re-emit', () async {
    await track('A/x.flac');
    final tracks = db.select(db.tracks).watch();
    final folders = db.select(db.excludedFolders).watch();
    var t = 0, f = 0;
    final s1 = tracks.listen((_) => t++);
    final s2 = folders.listen((_) => f++);
    addTearDown(() async {
      await s1.cancel();
      await s2.cancel();
    });
    await pumpEventQueue();
    final t0 = t, f0 = f;
    await exclude('A');
    await pumpEventQueue();
    expect(t, greaterThan(t0));
    expect(f, greaterThan(f0));
  });
}
