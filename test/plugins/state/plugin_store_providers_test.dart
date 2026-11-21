import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/platform/domain/app_paths.dart';
import 'package:kanaru/src/platform/state/platform_providers.dart';
import 'package:kanaru/src/plugins/data/store/plugin_row_types.dart';
import 'package:kanaru/src/plugins/data/store/plugin_rows.dart';
import 'package:kanaru/src/plugins/domain/net/address_rules.dart';
import 'package:kanaru/src/plugins/state/plugin_store_providers.dart';

import '../../database/support/test_db.dart';
import '../data/store_test_support.dart';
import '../domain/plugin_test_support.dart';

class _Paths implements AppPaths {
  _Paths(this.dataDir);
  @override
  final Directory dataDir;
  @override
  Directory get cacheDir => dataDir;
  @override
  Directory get configDir => dataDir;
}

/// Rows whose live stream fails, like a database that broke on a release
/// build.
class _FailingRows extends PluginRows {
  _FailingRows(super.db);

  @override
  Stream<List<PluginRow>> watchLive() => Stream.error(StateError('db gone'));
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  final id = testInstallId();

  setUp(() {
    db = openTestDb();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        appPathsProvider.overrideWithValue(_Paths(Directory.systemTemp)),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> install(Map<String, Object?> manifest) => container
      .read(pluginRowsProvider)
      .installOrRevive(
        id,
        draftOf(packageOf(manifest)),
        const PluginSource.file('demo.zip'),
      );

  test('the installed list follows installs and removes', () async {
    final live = container.listen(installedPluginsProvider, (_, _) {});
    await pumpEventQueue();
    expect(live.read().requireValue, isEmpty);
    await install(validManifest());
    await pumpEventQueue();
    expect(live.read().requireValue.single.installId, id);
    await container.read(pluginRowsProvider).remove(id);
    await pumpEventQueue();
    expect(live.read().requireValue, isEmpty);
  });

  test('a database error is an error state, not a thrown exception', () async {
    final failing = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        pluginRowsProvider.overrideWithValue(_FailingRows(db)),
      ],
    );
    addTearDown(failing.dispose);
    final sub = failing.listen(installedPluginsProvider, (_, _) {});
    await pumpEventQueue();
    expect(sub.read().hasError, isTrue);
    expect(sub.read().error, isA<StateError>());
    // The per-plugin view reports the same error instead of "not installed".
    final one = failing.listen(installedPluginProvider(id), (_, _) {});
    await pumpEventQueue();
    expect(one.read().hasError, isTrue);
  });

  test('status lists the required fields that have no value', () async {
    await install(
      manifestWith({
        'token': {'title': 'Token', 'mode': 'input', 'required': true},
        'region': {
          'title': 'Region',
          'mode': 'input',
          'required': true,
          'default': 'eu',
        },
      }),
    );
    final status = container.listen(pluginConfigStatusProvider(id), (_, _) {});
    await pumpEventQueue();
    expect(status.read().requireValue!.missingRequired.map((f) => f.key), [
      'token',
    ]);

    await container.read(pluginConfigStoreProvider).setValue(id, 'token', 'k');
    await pumpEventQueue();
    expect(status.read().requireValue!.missingRequired, isEmpty);
    expect(status.read().requireValue!.manifest?.name, 'Demo');
  });

  test('status of a plugin that is not installed is null data', () async {
    final status = container.listen(
      pluginConfigStatusProvider(testInstallId(7)),
      (_, _) {},
    );
    await pumpEventQueue();
    expect(status.read().hasValue, isTrue);
    expect(status.read().value, isNull);
  });

  test('repositories are listed oldest first', () async {
    final repos = container.read(pluginRepoRowsProvider);
    await repos.add(
      url: 'https://b.example.com/p.json',
      name: 'B',
      catalogJson: '{}',
      addressKind: AddressKind.public,
      now: 20,
    );
    await repos.add(
      url: 'https://a.example.com/p.json',
      name: 'A',
      catalogJson: '{}',
      addressKind: AddressKind.public,
      now: 10,
    );
    final list = container.listen(pluginReposProvider, (_, _) {});
    await pumpEventQueue();
    expect(list.read().requireValue.map((r) => r.name), ['A', 'B']);
  });
}
