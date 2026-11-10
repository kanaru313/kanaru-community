import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/library/data/folder_exclusion_repository.dart';
import 'package:kanaru/src/library/domain/music_folder.dart';
import 'package:kanaru/src/library/domain/scan_status.dart';
import 'package:kanaru/src/library/state/folder_exclusion_providers.dart';
import 'package:kanaru/src/library/state/scan_providers.dart';
import 'package:kanaru/src/platform/domain/storage_volumes.dart';

import '../database/support/test_db.dart';

class _RecordingScanner implements LibraryScanCommands {
  final List<bool> rescans = [];
  @override
  Future<void> rescan({bool full = false}) async => rescans.add(full);
}

class _HangingScanner implements LibraryScanCommands {
  @override
  Future<void> rescan({bool full = false}) => Completer<void>().future;
}

class _ThrowingScanner implements LibraryScanCommands {
  @override
  Future<void> rescan({bool full = false}) async => throw StateError('boom');
}

void main() {
  late AppDatabase db;
  late ProviderContainer c;
  late _RecordingScanner scanner;
  late MusicFolder folder;

  setUp(() async {
    db = openTestDb();
    // Registered first, so it runs after the container is disposed.
    addTearDown(db.close);
    final src = await addSource(db, uid: 'src-1');
    await addMount(db, src, root: '/m');
    folder = MusicFolder(
      sourceId: src,
      sourceUid: 'src-1',
      root: '/m',
      volume: otherVolume,
      name: 'Music',
    );
    scanner = _RecordingScanner();
    c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        libraryScanCommandsProvider.overrideWithValue(scanner),
      ],
    );
    addTearDown(c.dispose);
  });

  Future<String> status(int id) async => (await (db.select(
    db.tracks,
  )..where((t) => t.id.equals(id))).getSingle()).status;

  test(
    'exclude hides the folder at once, include brings rows back and rescans',
    () async {
      final inside = await addTrack(db, folder.sourceId, locator: 'A/x.flac');
      final outside = await addTrack(db, folder.sourceId, locator: 'B/y.flac');
      final exclusions = c.read(folderExclusionsProvider);

      await exclusions.exclude(folder, 'A', displayPath: '/m/A');
      expect(await status(inside), TrackStatus.hidden);
      expect(await status(outside), TrackStatus.present);
      expect(scanner.rescans, isEmpty);

      await exclusions.include(folder, 'A');
      expect(await status(inside), TrackStatus.missing);
      await pumpEventQueue();
      expect(scanner.rescans, [false]);
    },
  );

  test('include does not wait for or fail on the rescan', () async {
    for (final scan in [_HangingScanner(), _ThrowingScanner()]) {
      final exclusions = FolderExclusionRepository(db, scan);
      final t = await addTrack(
        db,
        folder.sourceId,
        locator: 'H${scan.runtimeType}/x.flac',
      );
      final key = 'H${scan.runtimeType}';
      await exclusions.exclude(folder, key, displayPath: '/m/$key');
      await exclusions.include(folder, key).timeout(const Duration(seconds: 5));
      expect(await status(t), TrackStatus.missing);
      expect(
        await db.select(db.excludedFolders).get(),
        everyElement(
          isA<ExcludedFolder>().having(
            (e) => e.deletedAt,
            'deletedAt',
            isNotNull,
          ),
        ),
      );
      await db.customUpdate(
        'DELETE FROM excluded_folders',
        updates: {db.excludedFolders},
      );
    }
  });

  test('watch lists live exclusions of the folder', () async {
    final exclusions = c.read(folderExclusionsProvider);
    final seen = <List<({String folderKey, String displayPath})>>[];
    final sub = exclusions.watch(folder).listen(seen.add);
    await pumpEventQueue();
    await exclusions.exclude(folder, 'B', displayPath: '/m/B');
    await exclusions.exclude(folder, 'A', displayPath: '/m/A');
    await pumpEventQueue();
    await exclusions.include(folder, 'B');
    await pumpEventQueue();
    await sub.cancel();
    expect(seen.first, isEmpty);
    expect(seen.last.map((e) => e.folderKey), ['A']);
    expect(seen.last.single.displayPath, '/m/A');
  });

  test('a malformed folder key throws and changes nothing', () async {
    final t = await addTrack(db, folder.sourceId, locator: 'A/x.flac');
    await expectLater(
      c.read(folderExclusionsProvider).exclude(folder, '/A', displayPath: 'x'),
      throwsArgumentError,
    );
    expect(await status(t), TrackStatus.present);
  });

  test('the seeded scanner logs and returns', () async {
    await const NoLibraryScanner().rescan(full: true);
  });
}
