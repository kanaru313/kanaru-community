import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/library/domain/music_folder.dart';
import 'package:kanaru/src/library/state/browse/folder_providers.dart';
import 'package:kanaru/src/library/state/browse/song_list_providers.dart';
import 'package:kanaru/src/library/state/music_folders_providers.dart';
import 'package:kanaru/src/platform/domain/storage_volumes.dart';

import '../../database/support/test_db.dart';
import 'support/library_fixture.dart';
import 'support/query_counter.dart';
import 'support/wait.dart';

const _tick = Duration(milliseconds: 15);

void main() {
  late AppDatabase db;
  late QueryCounter counter;
  late int src;
  late MusicFolder folder;
  late int isolateRuns;
  late StreamController<List<MusicFolder>> roots;

  setUp(() async {
    counter = QueryCounter();
    db = openCountingDb(counter);
    addTearDown(db.close);
    src = await addSource(db);
    isolateRuns = 0;
    roots = StreamController<List<MusicFolder>>();
    // Not awaited: close() of a controller nobody listened to never completes.
    addTearDown(() {
      unawaited(roots.close());
    });
    folder = MusicFolder(
      sourceId: src,
      sourceUid: 'uid',
      root: '/music',
      volume: const StorageVolume(root: '/', kind: StorageVolumeKind.home),
      name: 'Music',
    );
    roots.add([folder]);
  });

  ProviderContainer container({int threshold = 5000}) {
    final c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        musicFoldersProvider.overrideWith((ref) => roots.stream),
        folderRefreshIntervalProvider.overrideWithValue(_tick),
        browseRefreshIntervalProvider.overrideWithValue(_tick),
        folderIsolateThresholdProvider.overrideWithValue(threshold),
        folderIsolateRunnerProvider.overrideWithValue(<R>(
          FutureOr<R> Function() run,
        ) {
          isolateRuns++;
          return Future.sync(run);
        }),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  /// Revisions of a sibling that reloads on the same table writes.
  List<int> siblingTicks(ProviderContainer c) {
    final seen = <int>[];
    c.listen(songRowsRevisionProvider, (_, next) {
      if (next.hasValue) seen.add(next.requireValue);
    }, fireImmediately: true);
    return seen;
  }

  Future<void> add(String locator) =>
      addLibraryTrack(db, source: src, locator: locator);

  test('builds the tree from the present files and follows writes', () async {
    await add('a/1.flac');
    final c = container();
    final seen = <int>[];
    c.listen(folderTreesProvider, (_, next) {
      final v = next.value;
      if (v != null) seen.add(v.single.node.deepSongs);
    }, fireImmediately: true);
    await until(() => seen.isNotEmpty);
    await add('a/2.flac');
    await until(() => seen.length == 2);
    expect(seen, [1, 2]);
    expect(isolateRuns, 0);
  });

  test(
    'from the row threshold up the tree is built through the isolate runner',
    () async {
      await add('a/1.flac');
      await add('a/2.flac');
      final c = container(threshold: 2);
      c.listen(folderTreesProvider, (_, _) {});
      await until(() => isolateRuns == 1);
    },
  );

  test('20k rows go through the isolate runner', () async {
    final rows = [
      for (var i = 0; i < 20000; i++)
        (sourceId: 1, locator: 'd${i % 500}/f$i.flac', coverKey: null),
    ];
    var runs = 0;
    final roots = await buildFolderTreesOffIsolate(
      [folder],
      rows,
      threshold: folderIsolateThreshold,
      run: <R>(FutureOr<R> Function() run) {
        runs++;
        return Future.sync(run);
      },
    );
    expect(runs, 1);
    expect(roots.single.node.deepSongs, 20000);
    // Below the threshold nothing leaves the isolate.
    await buildFolderTreesOffIsolate(
      [folder],
      rows.take(10).toList(),
      threshold: folderIsolateThreshold,
      run: <R>(FutureOr<R> Function() run) => throw StateError('no isolate'),
    );
  });

  test('the real isolate returns a usable tree', () async {
    final rows = [
      for (var i = 0; i < 50; i++)
        (sourceId: src, locator: 'd${i % 5}/f$i.flac', coverKey: 'c'),
    ];
    final roots = await buildFolderTreesOffIsolate(
      [folder],
      rows,
      threshold: 1,
      run: container().read(folderIsolateRunnerProvider),
    );
    final node = roots.single.nodeAt('d3')!;
    expect((node.directSongs, node.coverKey), (10, 'c'));
    expect(roots.single.folder, folder);
  });

  test(
    'nothing reloads while paused or after the last listener left',
    () async {
      await add('a/1.flac');
      final c = container(threshold: 0);
      final ticks = siblingTicks(c);
      final sub = c.listen(folderTreesProvider, (_, _) {});
      await until(() => isolateRuns == 1 && ticks.isNotEmpty);
      sub.pause();
      final ticksBeforePause = ticks.length;
      await add('a/2.flac');
      await afterSiblingReload(ticks, after: ticksBeforePause);
      expect(isolateRuns, 1);
      sub.resume();
      await until(() => isolateRuns == 2);
      sub.close();
      await until(() => !c.read(folderTreesProvider.exists));
      final ticksBeforeLast = ticks.length;
      await add('a/3.flac');
      await afterSiblingReload(ticks, after: ticksBeforeLast);
      expect(isolateRuns, 2);
    },
  );

  test(
    'a rewrite of the music folders that changes nothing reloads nothing',
    () async {
      await add('a/1.flac');
      final c = container(threshold: 0);
      final ticks = siblingTicks(c);
      c.listen(folderTreesProvider, (_, _) {});
      await until(() => isolateRuns == 1 && ticks.isNotEmpty);
      // A new list with equal folders, as every sources/source_mounts write
      // produces.
      roots.add([
        MusicFolder(
          sourceId: folder.sourceId,
          sourceUid: folder.sourceUid,
          root: folder.root,
          volume: folder.volume,
          name: folder.name,
        ),
      ]);
      await pumpEventQueue();
      int loads() => counter.loads('SELECT t.source_id, t.locator');
      final before = loads();
      await add('a/2.flac');
      await afterLoad(loads, after: before);
      // Exactly one reload, for the new file; none for the folder list.
      expect(loads(), before + 1);
      expect(isolateRuns, 2);
      // A different folder list does rebuild.
      roots.add([folder, folder]);
      await until(() => isolateRuns == 3);
    },
  );
}
