import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/library/state/music_folders_providers.dart';
import 'package:kanaru/src/platform/domain/storage_volumes.dart';
import 'package:kanaru/src/platform/state/storage_volumes_provider.dart';

import '../database/support/test_db.dart';

class _FailingVolumes implements StorageVolumes {
  int lists = 0;
  @override
  Future<List<StorageVolume>> list() async {
    lists++;
    throw StateError('no volumes');
  }

  @override
  StorageVolume volumeOf(String path) => otherVolume;
}

class _Volumes implements StorageVolumes {
  static const sd = StorageVolume(
    root: '/storage/AAAA-1111',
    kind: StorageVolumeKind.sdCard,
  );
  @override
  Future<List<StorageVolume>> list() async => [sd];
  @override
  StorageVolume volumeOf(String path) => volumeForPath([sd], path);
}

void main() {
  late AppDatabase db;
  late ProviderContainer c;
  setUp(() {
    db = openTestDb();
    // Registered first, so it runs after the container is disposed.
    addTearDown(db.close);
    c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        storageVolumesProvider.overrideWithValue(_Volumes()),
      ],
    );
    addTearDown(c.dispose);
  });

  test(
    'lists live local sources with an enabled mount, by root, live',
    () async {
      final b = await addSource(db, uid: 'src-b', name: 'B');
      await addMount(db, b, root: '/storage/AAAA-1111/Music');
      final a = await addSource(db, uid: 'src-a', name: 'A');
      await addMount(db, a, root: '/home/me/Music');
      final off = await addSource(db, uid: 'src-off', name: 'Off');
      await addMount(db, off, root: '/off', enabled: false);
      final remote = await addSource(
        db,
        uid: 'src-r',
        kind: SourceKind.webdav,
        name: 'R',
      );
      await addMount(db, remote, root: '/dav');
      final removed = await addSource(db, uid: 'src-x', name: 'X');
      await addMount(db, removed, root: '/gone');
      await db.customUpdate(
        'UPDATE sources SET deleted_at = 5 WHERE id = $removed',
        updates: {db.sources},
      );

      final sub = c.listen(musicFoldersProvider, (_, _) {});
      final folders = await c.read(musicFoldersProvider.future);
      expect(folders.map((f) => f.root), [
        '/home/me/Music',
        '/storage/AAAA-1111/Music',
      ]);
      expect(folders[0].volume, otherVolume);
      expect(folders[1].volume.kind, StorageVolumeKind.sdCard);
      expect(folders[1].sourceUid, 'src-b');

      await db.customUpdate(
        'UPDATE source_mounts SET enabled = 0 WHERE source_id = $a',
        updates: {db.sourceMounts},
      );
      await pumpEventQueue();
      expect(c.read(musicFoldersProvider).value!.map((f) => f.name), ['B']);
      sub.close();
    },
  );

  test(
    'a failing volume listing still lists folders; relists per emission',
    () async {
      final failing = _FailingVolumes();
      final own = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          storageVolumesProvider.overrideWithValue(failing),
        ],
      );
      addTearDown(own.dispose);
      final a = await addSource(db, uid: 'src-a', name: 'A');
      await addMount(db, a, root: '/x');
      own.listen(musicFoldersProvider, (_, _) {});
      expect(
        (await own.read(musicFoldersProvider.future)).single.volume,
        otherVolume,
      );
      final b = await addSource(db, uid: 'src-b', name: 'B');
      await addMount(db, b, root: '/y');
      await pumpEventQueue();
      expect(own.read(musicFoldersProvider).value, hasLength(2));
      expect(failing.lists, greaterThanOrEqualTo(2));
    },
  );
}
