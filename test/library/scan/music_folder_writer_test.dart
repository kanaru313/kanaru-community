import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/library/data/scan/music_folder_writer.dart';

import '../../database/support/test_db.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = openTestDb();
    addTearDown(db.close);
  });

  Future<List<Map<String, Object?>>> sourceRows() async => [
    for (final r
        in await db
            .customSelect(
              'SELECT s.id, s.kind, s.name, s.deleted_at, m.root, m.enabled '
              'FROM sources s JOIN source_mounts m ON m.source_id = s.id '
              'ORDER BY s.id',
            )
            .get())
      r.data,
  ];

  test('adding writes a local source and an enabled mount', () async {
    final result = await addLocalSource(
      db,
      root: '/home/u/Music',
      name: 'Music',
      now: 100,
    );
    expect(result, SourceWrite.added);
    final rows = await sourceRows();
    expect(rows, hasLength(1));
    expect(rows.single['kind'], 'local');
    expect(rows.single['name'], 'Music');
    expect(rows.single['root'], '/home/u/Music');
    expect(rows.single['enabled'], 1);
    expect(rows.single['deleted_at'], isNull);
  });

  test('adding the same live root changes nothing', () async {
    await addLocalSource(db, root: '/m', name: 'm', now: 100);
    final again = await addLocalSource(db, root: '/m', name: 'm', now: 200);
    expect(again, SourceWrite.alreadyLive);
    expect(await sourceRows(), hasLength(1));
  });

  test(
    'removing tombstones the source, its exclusions and hides tracks',
    () async {
      await addLocalSource(db, root: '/m', name: 'm', now: 100);
      final id = (await sourceRows()).single['id']! as int;
      await addTrack(db, id, locator: 'a.mp3');
      await addTrack(db, id, locator: 'x/b.mp3');
      await applyFolderExclusion(
        db,
        sourceId: id,
        folderKey: 'x',
        displayPath: '/m/x',
        now: 150,
      );
      await removeLocalSource(db, id, 200);

      final row = (await sourceRows()).single;
      expect(row['deleted_at'], 200);
      expect(row['enabled'], 0);
      expect(await excludedFolderKeys(db, id), isEmpty);
      final statuses = await db
          .customSelect('SELECT DISTINCT status FROM tracks')
          .get();
      expect(statuses.map((r) => r.read<String>('status')), ['hidden']);
    },
  );

  test('adding the removed root again keeps the id, no exclusions, tracks '
      'missing', () async {
    await addLocalSource(db, root: '/m', name: 'm', now: 100);
    final id = (await sourceRows()).single['id']! as int;
    await addTrack(db, id, locator: 'a.mp3');
    await addTrack(db, id, locator: 'x/b.mp3');
    await applyFolderExclusion(
      db,
      sourceId: id,
      folderKey: 'x',
      displayPath: '/m/x',
      now: 150,
    );
    await removeLocalSource(db, id, 200);

    final result = await addLocalSource(
      db,
      root: '/m',
      name: 'Renamed',
      now: 300,
    );
    expect(result, SourceWrite.revived);
    final rows = await sourceRows();
    expect(rows, hasLength(1));
    expect(rows.single['id'], id);
    expect(rows.single['name'], 'Renamed');
    expect(rows.single['deleted_at'], isNull);
    expect(rows.single['enabled'], 1);
    expect(await excludedFolderKeys(db, id), isEmpty);
    final tracks = await db
        .customSelect('SELECT locator, status FROM tracks ORDER BY locator')
        .get();
    expect(tracks.map((r) => r.read<String>('status')), ['missing', 'missing']);
  });

  test('a live source with a disabled mount is enabled again', () async {
    await addLocalSource(db, root: '/m', name: 'm', now: 100);
    final id = (await sourceRows()).single['id']! as int;
    await setMountEnabled(db, id, false, 150);
    final result = await addLocalSource(db, root: '/m', name: 'm', now: 200);
    expect(result, SourceWrite.revived);
    expect((await sourceRows()).single['enabled'], 1);
  });
}
