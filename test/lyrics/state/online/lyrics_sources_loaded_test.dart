import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/database/tables.dart' show PluginRow;
import 'package:kanaru/src/lyrics/state/online/lyrics_sources_provider.dart';
import 'package:kanaru/src/platform/domain/app_paths.dart';
import 'package:kanaru/src/platform/state/platform_providers.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/plugins/data/store/plugin_row_types.dart';
import 'package:kanaru/src/plugins/state/plugin_store_providers.dart';

import '../../../database/support/test_db.dart';
import '../../../plugins/data/store_test_support.dart';
import '../../../plugins/domain/plugin_test_support.dart';
import '../../../support/memory_settings_store.dart';

class _Paths implements AppPaths {
  @override
  Directory get dataDir => Directory.systemTemp;
  @override
  Directory get cacheDir => Directory.systemTemp;
  @override
  Directory get configDir => Directory.systemTemp;
}

/// What the overridden config status of every plugin answers.
class _Gate extends Notifier<AsyncValue<PluginConfigStatus?>> {
  @override
  AsyncValue<PluginConfigStatus?> build() => const AsyncLoading();

  void set(AsyncValue<PluginConfigStatus?> v) => state = v;
}

final _gate = NotifierProvider<_Gate, AsyncValue<PluginConfigStatus?>>(
  _Gate.new,
);

void main() {
  late AppDatabase db;
  late PluginRow row;

  setUp(() async {
    db = openTestDb();
    final real = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        appPathsProvider.overrideWithValue(_Paths()),
        settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
      ],
    );
    await real
        .read(pluginRowsProvider)
        .installOrRevive(
          testInstallId(1),
          draftOf(packageOf(validManifest(), const {})),
          const PluginSource.file('demo.zip'),
        );
    row = (await db.select(db.plugins).get()).single;
    real.dispose();
  });
  tearDown(() => db.close());

  ProviderContainer containerOf(Stream<List<PluginRow>> rows) =>
      ProviderContainer(
        overrides: [
          installedPluginsProvider.overrideWith((ref) => rows),
          pluginConfigStatusProvider.overrideWith(
            (ref, id) => ref.watch(_gate),
          ),
          settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
        ],
      );

  test(
    'false while the list or a lyrics plugin status loads, true after',
    () async {
      final rows = StreamController<List<PluginRow>>();
      final container = containerOf(rows.stream);
      addTearDown(() async {
        container.dispose();
        await rows.close();
      });
      container.listen(lyricsSourcesLoadedProvider, (_, _) {});
      expect(container.read(lyricsSourcesLoadedProvider), isFalse);

      rows.add([]);
      await pumpEventQueue();
      expect(container.read(lyricsSourcesLoadedProvider), isTrue);

      rows.add([row]);
      await pumpEventQueue();
      expect(
        container.read(lyricsSourcesLoadedProvider),
        isFalse,
        reason: 'the status of the lyrics plugin still loads',
      );

      container.read(_gate.notifier).set(const AsyncData(null));
      await pumpEventQueue();
      expect(container.read(lyricsSourcesLoadedProvider), isTrue);
    },
  );

  test('a failing status counts as loaded; a failing list does not', () async {
    final rows = StreamController<List<PluginRow>>();
    final container = containerOf(rows.stream);
    addTearDown(() async {
      container.dispose();
      await rows.close();
    });
    container.listen(lyricsSourcesLoadedProvider, (_, _) {});
    rows.add([row]);
    container
        .read(_gate.notifier)
        .set(AsyncError(StateError('db'), StackTrace.empty));
    await pumpEventQueue();
    expect(container.read(lyricsSourcesLoadedProvider), isTrue);

    final failing = StreamController<List<PluginRow>>();
    final other = containerOf(failing.stream);
    addTearDown(() async {
      other.dispose();
      await failing.close();
    });
    other.listen(lyricsSourcesLoadedProvider, (_, _) {});
    failing.addError(StateError('db'));
    await pumpEventQueue();
    expect(other.read(lyricsSourcesLoadedProvider), isFalse);
  });
}
