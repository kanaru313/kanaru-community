import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/library/data/scan/music_folder_writer.dart';
import 'package:kanaru/src/library/domain/scan_status.dart';
import 'package:kanaru/src/library/state/scan/folder_candidates_provider.dart';
import 'package:kanaru/src/library/state/scan/media_index_refresh.dart';
import 'package:kanaru/src/library/state/scan_providers.dart';
import 'package:kanaru/src/platform/domain/local_audio_catalog.dart';
import 'package:kanaru/src/platform/domain/storage_volumes.dart';
import 'package:kanaru/src/platform/state/local_audio_catalog_provider.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/platform/state/storage_volumes_provider.dart';

import '../../database/support/test_db.dart';
import '../../support/memory_settings_store.dart';

class _Catalog implements LocalAudioCatalog {
  Completer<MediaIndexRefresh>? gate;
  MediaIndexRefresh outcome = MediaIndexRefresh.done;
  Object? refreshError;
  AudioFoldersResult folders = const AudioFoldersListed([
    AudioFolderSummary(path: '/storage/emulated/0/Music', audioCount: 3),
    AudioFolderSummary(path: '/storage/emulated/0/Podcasts', audioCount: 4),
  ]);
  int refreshes = 0;
  int folderReads = 0;
  List<String>? lastRoots;
  List<String>? lastFolders;

  @override
  Future<MediaIndexRefresh> refreshMediaIndex({
    required List<String> volumeRoots,
    required List<String> folders,
  }) async {
    refreshes++;
    lastRoots = volumeRoots;
    lastFolders = folders;
    if (refreshError != null) throw refreshError!;
    return await gate?.future ?? outcome;
  }

  @override
  Future<AudioFoldersResult> audioFolders({int minDurationMs = 30000}) async {
    folderReads++;
    return folders;
  }

  @override
  Future<String?> suggestedMusicFolder() async => null;
  @override
  Future<String> canonicalize(String path) async => path;
  @override
  Future<AudioListing> listAudio({
    required String root,
    required Set<String> excludedKeys,
    int skipShorterThanMs = 0,
    bool respectNomedia = false,
  }) async => const AudioListing();
  @override
  FolderChoice get folderChoice => FolderChoice.mediaStoreSheet;
  @override
  Future<String?> pickFolder({String? initialDirectory}) async => null;
}

class _Volumes implements StorageVolumes {
  @override
  Future<List<StorageVolume>> list() async => const [
    StorageVolume(
      root: '/storage/emulated/0',
      kind: StorageVolumeKind.internal,
    ),
    StorageVolume(root: '/', kind: StorageVolumeKind.other),
  ];
  @override
  StorageVolume volumeOf(String path) => otherVolume;
}

class _Scanner implements LibraryScanCommands {
  int rescans = 0;
  @override
  Future<void> rescan({bool full = false}) async => rescans++;
}

void main() {
  late AppDatabase db;
  late _Catalog catalog;
  late _Scanner scanner;
  late ProviderContainer container;

  ProviderContainer make() => ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
      localAudioCatalogProvider.overrideWithValue(catalog),
      storageVolumesProvider.overrideWithValue(_Volumes()),
      libraryScanCommandsProvider.overrideWithValue(scanner),
    ],
  );

  setUp(() {
    db = openTestDb();
    addTearDown(db.close);
    catalog = _Catalog();
    scanner = _Scanner();
    container = make();
    addTearDown(container.dispose);
  });

  MediaIndexRefreshNotifier notifier() =>
      container.read(mediaIndexRefreshProvider.notifier);
  IndexRefreshState state() => container.read(mediaIndexRefreshProvider);

  test('starts idle', () {
    expect(state(), isA<IndexRefreshIdle>());
    expect(state().runId, 0);
  });

  test('two run() calls share one refresh and both complete', () async {
    catalog.gate = Completer();
    final a = notifier().run();
    final b = notifier().run();
    expect(state(), isA<IndexRefreshRunning>());
    expect(state().runId, 1);
    await Future<void>.delayed(Duration.zero);
    catalog.gate!.complete(MediaIndexRefresh.done);
    await Future.wait([a, b]);
    expect(catalog.refreshes, 1);
    final done = state() as IndexRefreshFinished;
    expect(done.runId, 1);
    expect(done.outcome, MediaIndexRefresh.done);
    expect(done.found, 7);
    expect(catalog.lastRoots, ['/storage/emulated/0']);
  });

  test(
    'the chosen folders reach the refresh, none when nothing is chosen',
    () async {
      await notifier().run();
      expect(catalog.lastFolders, isEmpty);
      await addLocalSource(
        db,
        root: '/storage/emulated/0/KanaruRepro',
        name: 'KanaruRepro',
        now: 1,
      );
      await notifier().run();
      expect(catalog.lastFolders, ['/storage/emulated/0/KanaruRepro']);
    },
  );

  test('a later run gets the next runId', () async {
    await notifier().run();
    await notifier().run();
    expect(state().runId, 2);
    expect(catalog.refreshes, 2);
  });

  test('autoRunOnce runs once per launch', () async {
    await notifier().autoRunOnce();
    await notifier().autoRunOnce();
    expect(catalog.refreshes, 1);
  });

  test('re-reading the provider during a run does not start another', () async {
    catalog.gate = Completer();
    final run = notifier().run();
    await Future<void>.delayed(Duration.zero);
    container.read(mediaIndexRefreshProvider);
    final joined = notifier().run();
    catalog.gate!.complete(MediaIndexRefresh.done);
    await Future.wait([run, joined]);
    expect(catalog.refreshes, 1);
  });

  for (final outcome in [MediaIndexRefresh.done, MediaIndexRefresh.timedOut]) {
    test('$outcome reloads the lists and asks for a library rescan', () async {
      final sub = container.listen(audioFoldersProvider, (_, _) {});
      addTearDown(sub.close);
      await container.read(audioFoldersProvider.future);
      final readsBefore = catalog.folderReads;
      catalog.outcome = outcome;
      await notifier().run();
      // One read for `found`, one more when the invalidated provider reloads.
      await container.read(audioFoldersProvider.future);
      expect(catalog.folderReads, readsBefore + 2);
      expect(scanner.rescans, 1);
      expect((state() as IndexRefreshFinished).found, 7);
    });
  }

  for (final outcome in [
    MediaIndexRefresh.failed,
    MediaIndexRefresh.unsupported,
  ]) {
    test('$outcome neither reloads nor rescans', () async {
      catalog.outcome = outcome;
      await notifier().run();
      expect(catalog.folderReads, 0);
      expect(scanner.rescans, 0);
      final done = state() as IndexRefreshFinished;
      expect(done.outcome, outcome);
      expect(done.found, isNull);
    });
  }

  test('a failing catalog ends as failed', () async {
    catalog.refreshError = StateError('boom');
    await notifier().run();
    expect((state() as IndexRefreshFinished).outcome, MediaIndexRefresh.failed);
    expect(scanner.rescans, 0);
  });

  test('an unreadable index after a scan leaves found unknown', () async {
    catalog.folders = const AudioFoldersFailed(AudioFoldersFailure.failed);
    await notifier().run();
    final done = state() as IndexRefreshFinished;
    expect(done.outcome, MediaIndexRefresh.done);
    expect(done.found, isNull);
  });

  test('a library rescan is requested after the scan, not before', () async {
    catalog.gate = Completer();
    final run = notifier().run();
    await Future<void>.delayed(Duration.zero);
    expect(scanner.rescans, 0);
    catalog.gate!.complete(MediaIndexRefresh.done);
    await run;
    await Future<void>.delayed(Duration.zero);
    expect(scanner.rescans, 1);
  });

  test(
    'disposing the container mid-run writes nothing and throws nothing',
    () async {
      catalog.gate = Completer();
      final run = notifier().run();
      await Future<void>.delayed(Duration.zero);
      container.dispose();
      catalog.gate!.complete(MediaIndexRefresh.done);
      await run;
      expect(scanner.rescans, 0);
      expect(catalog.folderReads, 0);
    },
  );
}
