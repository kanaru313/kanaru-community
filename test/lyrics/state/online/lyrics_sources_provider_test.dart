import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/lyrics/domain/online/lyrics_source.dart';
import 'package:kanaru/src/lyrics/domain/online/source_prefs.dart';
import 'package:kanaru/src/lyrics/state/lyrics_settings.dart';
import 'package:kanaru/src/lyrics/state/online/lyrics_sources_provider.dart';
import 'package:kanaru/src/platform/domain/app_paths.dart';
import 'package:kanaru/src/platform/state/platform_providers.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/plugins/data/store/plugin_row_types.dart';
import 'package:kanaru/src/plugins/state/plugin_run_provider.dart';
import 'package:kanaru/src/plugins/state/plugin_store_providers.dart';

import '../../../database/support/test_db.dart';
import '../../../plugins/data/store_test_support.dart';
import '../../../plugins/domain/plugin_test_support.dart';
import '../../../support/memory_settings_store.dart';

class _Paths implements AppPaths {
  _Paths(this.dataDir);
  @override
  final Directory dataDir;
  @override
  Directory get cacheDir => dataDir;
  @override
  Directory get configDir => dataDir;
}

Map<String, Object?> _lyricsManifest(
  String name, {
  Map<String, Object?>? config,
}) {
  final json = validManifest();
  (json['metadata']! as Map<String, Object?>)['name'] = name;
  if (config != null) json['config'] = config;
  return json;
}

void main() {
  late AppDatabase db;
  late MemorySettingsStore settings;
  late ProviderContainer container;

  setUp(() {
    db = openTestDb();
    settings = MemorySettingsStore();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        appPathsProvider.overrideWithValue(_Paths(Directory.systemTemp)),
        settingsStoreProvider.overrideWithValue(settings),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> install(
    int n,
    Map<String, Object?> manifest, {
    PluginSource source = const PluginSource.file('demo.zip'),
    Map<String, Object> extra = const {},
  }) => container
      .read(pluginRowsProvider)
      .installOrRevive(
        testInstallId(n),
        draftOf(packageOf(manifest, extra)),
        source,
      );

  /// Listens so the stream providers stay alive, and waits for a value.
  List<LyricsSource> read() {
    container.listen(lyricsSourcesProvider, (_, _) {});
    return container.read(lyricsSourcesProvider);
  }

  Future<List<LyricsSource>> settled() async {
    container.listen(lyricsSourcesProvider, (_, _) {});
    await pumpEventQueue();
    return container.read(lyricsSourcesProvider);
  }

  test('empty and not loaded until the plugin list has a value', () async {
    container.listen(lyricsSourcesProvider, (_, _) {});
    expect(container.read(lyricsSourcesLoadedProvider), isFalse);
    expect(read(), isEmpty);
    await pumpEventQueue();
    expect(container.read(lyricsSourcesLoadedProvider), isTrue);
    expect(container.read(lyricsSourcesProvider), isEmpty);
  });

  test(
    'only lyrics plugins, in install order, with name and version',
    () async {
      await install(1, _lyricsManifest('One'));
      await install(
        2,
        translateManifest(),
        extra: {'src/translate.js': 'function execute() {}'},
      );
      await install(3, _lyricsManifest('Three'));
      final sources = await settled();
      expect([for (final s in sources) s.name], ['One', 'Three']);
      expect(sources.first.id, testInstallId(1));
      expect(sources.first.version, 3);
    },
  );

  test('repository installs start on, file and link installs off', () async {
    await install(
      1,
      _lyricsManifest('Repo'),
      source: const PluginSource.repo('https://r.example.com/p.json', 'repo'),
    );
    await install(2, _lyricsManifest('File'));
    await install(
      3,
      _lyricsManifest('Link'),
      source: const PluginSource.link('https://x.example.com/p.zip'),
    );
    final sources = await settled();
    expect(
      [for (final s in sources) (s.name, s.enabled, s.origin)],
      [
        ('Repo', true, LyricsSourceOrigin.repo),
        ('File', false, LyricsSourceOrigin.file),
        ('Link', false, LyricsSourceOrigin.link),
      ],
    );
  });

  test('saved order and switches apply, a removed plugin drops out', () async {
    await install(1, _lyricsManifest('One'));
    await install(2, _lyricsManifest('Two'));
    await install(3, _lyricsManifest('Three'));
    await container.read(lyricsOnlineSourcesProvider.notifier).set([
      SourcePref(testInstallId(3), on: true),
      SourcePref(testInstallId(9), on: true),
      SourcePref(testInstallId(1), on: true),
    ]);
    var sources = await settled();
    expect(
      [for (final s in sources) (s.name, s.enabled)],
      [('Three', true), ('One', true), ('Two', false)],
    );
    await container.read(pluginRowsProvider).remove(testInstallId(3));
    await pumpEventQueue();
    sources = container.read(lyricsSourcesProvider);
    expect([for (final s in sources) s.name], ['One', 'Two']);
  });

  test('a required field without a value is a needs-config problem', () async {
    await install(
      1,
      _lyricsManifest(
        'Keyed',
        config: {
          'token': {'title': 'Token', 'mode': 'input', 'required': true},
        },
      ),
    );
    var sources = await settled();
    expect(sources.single.problem, SourceProblem.needsConfig);
    expect(sources.single.askable, isFalse);
    await container
        .read(pluginConfigStoreProvider)
        .setValue(testInstallId(1), 'token', 'k');
    await pumpEventQueue();
    sources = container.read(lyricsSourcesProvider);
    expect(sources.single.problem, isNull);
    expect(sources.single.askable, isTrue);
  });

  test('a paused plugin carries the pause and clears when it ends', () async {
    await install(1, _lyricsManifest('One'));
    await settled();
    container
        .read(pluginPausesProvider)
        .pause(testInstallId(1), const Duration(milliseconds: 60));
    await pumpEventQueue();
    final paused = container.read(lyricsSourcesProvider).single;
    expect(paused.problem, SourceProblem.paused);
    expect(paused.pausedUntil, isNotNull);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await pumpEventQueue();
    final after = container.read(lyricsSourcesProvider).single;
    expect((after.problem, after.pausedUntil), (null, null));
  });

  test('a stored plugin.json that no longer parses is broken', () async {
    await install(1, _lyricsManifest('One'));
    await db.customStatement(
      "UPDATE plugins SET manifest_json = '{oops' WHERE install_id = ?",
      [testInstallId(1)],
    );
    final sources = await settled();
    expect(sources.single.problem, SourceProblem.broken);
  });

  test('the auto search setting defaults on and stores a bool', () async {
    expect(container.read(lyricsAutoSearchProvider), isTrue);
    await container.read(lyricsAutoSearchProvider.notifier).set(false);
    expect(settings.read('lyrics.auto_search'), false);
    expect(container.read(lyricsAutoSearchProvider), isFalse);
  });

  test(
    'the sources setting stores [{id, on}] and ignores a bad value',
    () async {
      await container.read(lyricsOnlineSourcesProvider.notifier).set([
        const SourcePref('a', on: false),
      ]);
      expect(settings.read('lyrics.online_sources'), [
        {'id': 'a', 'on': false},
      ]);
      final badStore = MemorySettingsStore();
      await badStore.write('lyrics.online_sources', 'nope');
      final bad = ProviderContainer(
        overrides: [settingsStoreProvider.overrideWithValue(badStore)],
      );
      addTearDown(bad.dispose);
      expect(bad.read(lyricsOnlineSourcesProvider), isEmpty);
    },
  );
}
