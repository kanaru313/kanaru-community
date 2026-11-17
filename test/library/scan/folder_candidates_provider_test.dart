import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/library/domain/scan/folder_list_state.dart';
import 'package:kanaru/src/library/state/scan/folder_candidates_provider.dart';
import 'package:kanaru/src/library/state/scan_providers.dart';
import 'package:kanaru/src/platform/domain/local_audio_catalog.dart';
import 'package:kanaru/src/platform/domain/media_permissions.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';

import '../../database/support/test_db.dart';
import '../../screens/first_run/support/first_run_host.dart';
import '../../support/memory_settings_store.dart';

void main() {
  late FakeCatalog catalog;
  late ProviderContainer container;

  setUp(() {
    final db = openTestDb();
    addTearDown(db.close);
    catalog = FakeCatalog(android: true);
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
        libraryScanCommandsProvider.overrideWithValue(CountingScanner()),
        ...platformOverrides(
          catalog: catalog,
          permissions: FakePermissions(
            perms(MediaPermissionStatus.granted, MediaPermissionStatus.granted),
          ),
          android: true,
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  test('a failed read has no estimate, counts or candidates', () async {
    catalog.result = const AudioFoldersFailed(AudioFoldersFailure.failed);
    expect(await container.read(estimatedTrackCountProvider.future), isNull);
    expect(await container.read(folderCountsProvider.future), isNull);
    expect(
      await container.read(folderCandidatesProvider.future),
      isA<FolderListLoadFailed>(),
    );
  });

  test('an empty index has no estimate or counts, and says so', () async {
    catalog.result = const AudioFoldersListed([]);
    expect(await container.read(estimatedTrackCountProvider.future), isNull);
    expect(await container.read(folderCountsProvider.future), isNull);
    expect(
      await container.read(folderCandidatesProvider.future),
      isA<FolderListNoIndexedMusic>(),
    );
  });

  test('an index with music has an estimate and candidates', () async {
    catalog.folders = [
      const AudioFolderSummary(
        path: '/storage/emulated/0/Music',
        audioCount: 3,
      ),
    ];
    expect(await container.read(estimatedTrackCountProvider.future), 0);
    expect(await container.read(folderCountsProvider.future), isNotNull);
    final state = await container.read(folderCandidatesProvider.future);
    expect(state, isA<FolderListReady>());
    expect((state as FolderListReady).candidates, isNotEmpty);
  });
}
