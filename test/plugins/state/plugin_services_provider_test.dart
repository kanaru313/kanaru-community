import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/platform/domain/app_paths.dart';
import 'package:kanaru/src/platform/state/document_picker_provider.dart';
import 'package:kanaru/src/platform/state/platform_providers.dart';
import 'package:kanaru/src/plugins/data/install/sweep_and_restore.dart';
import 'package:kanaru/src/plugins/data/store/plugin_files.dart';
import 'package:kanaru/src/plugins/data/store/plugin_row_types.dart';
import 'package:kanaru/src/plugins/data/store/plugin_rows.dart';
import 'package:kanaru/src/plugins/state/plugin_services_provider.dart';

import '../../database/support/test_db.dart';
import '../data/services_test_support.dart';
import '../data/store_test_support.dart';

class _Paths implements AppPaths {
  _Paths(this.dataDir);
  @override
  final Directory dataDir;
  @override
  Directory get cacheDir => dataDir;
  @override
  Directory get configDir => dataDir;
}

void main() {
  late AppDatabase db;
  late Directory dir;
  late ProviderContainer container;

  setUp(() {
    db = openTestDb();
    dir = tempDir();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        appPathsProvider.overrideWithValue(_Paths(dir)),
        documentPickerProvider.overrideWithValue(
          FakePicker((_, _) async => throw StateError('unused')),
        ),
        scriptCheckerProvider.overrideWithValue(FakeChecker()),
        pluginFetcherProvider.overrideWithValue(
          FakeFetcher((_) async => throw StateError('offline')),
        ),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await db.close();
    dir.deleteSync(recursive: true);
  });

  test(
    'the first job sweeps orphans and reports plugins with a missing folder',
    () async {
      final files = PluginFiles(dir);
      final rows = PluginRows(db);
      final package = packageOf();
      // A live plugin whose folder is then lost, and an orphan folder.
      final gone = await files.write(testInstallId(1), package);
      await rows.installOrRevive(
        testInstallId(1),
        draftOf(package, gone),
        const PluginSource.link('https://x.example.com/a.zip'),
      );
      await files.deleteFolder(testInstallId(1), gone);
      await files.write(testInstallId(2), package);

      final services = container.read(pluginServicesProvider);
      final missing = await services.startupRestore;

      expect([for (final c in missing) c.installId], [testInstallId(1)]);
      expect(missing.single.action, RestoreAction.download);
      expect(await files.listFolders(), isEmpty);
    },
  );

  test('a job queued right away runs after the startup job', () async {
    final services = container.read(pluginServicesProvider);
    var startupDone = false;
    unawaited(services.queue.startup.then((_) => startupDone = true));
    expect(await services.queue.run(() async => startupDone), isTrue);
  });

  test('findMissingPackages rescans through the queue', () async {
    final services = container.read(pluginServicesProvider);
    expect(await services.findMissingPackages(), isEmpty);
  });
}
