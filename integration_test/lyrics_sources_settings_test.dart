import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart' show Scrollable, Size, runApp;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kanaru/kanaru.dart';
import 'package:kanaru/kanaru_bootstrap.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/extension/state/extension_providers.dart';
import 'package:kanaru/src/foundation/app_logger.dart';
import 'package:kanaru/src/library/ui/menus/song_lyrics_entry.dart';
import 'package:kanaru/src/lyrics/data/native_local_lyrics_reader.dart';
import 'package:kanaru/src/lyrics/domain/online/lyrics_source.dart';
import 'package:kanaru/src/lyrics/state/lyrics_reader_provider.dart';
import 'package:kanaru/src/lyrics/state/lyrics_settings.dart';
import 'package:kanaru/src/lyrics/state/online/lyrics_sources_provider.dart';
import 'package:kanaru/src/lyrics/ui/song_lyrics_entry_impl.dart';
import 'package:kanaru/src/platform/data/app_paths_factory.dart';
import 'package:kanaru/src/platform/data/file_device_id.dart';
import 'package:kanaru/src/platform/data/json_settings_store.dart';
import 'package:kanaru/src/platform/data/native_library.dart';
import 'package:kanaru/src/platform/state/device_id_provider.dart';
import 'package:kanaru/src/platform/state/media_permissions_provider.dart';
import 'package:kanaru/src/platform/state/platform_providers.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/router/state/router_provider.dart';
import 'package:kanaru/src/router/ui/kanaru_app.dart';
import 'package:kanaru/src/screens/first_run/state/first_run_gate.dart';
import 'package:kanaru/src/screens/settings/state/appearance_settings.dart';
import 'package:kanaru/src/screens/settings/ui/lyrics/lyrics_settings_page.dart';
import 'package:kanaru/src/screens/settings/ui/lyrics/lyrics_sources_section.dart';
import 'package:kanaru_extensions/kanaru_extensions.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:media_kit/media_kit.dart';

import 'support/fixtures.dart';
import 'support/harness.dart' show RunningApp;

/// What `runKanaru` does, with [overrides] added: it has no hook for fakes
/// yet. Settings the harness needs (library minimum duration off) are written
/// first, as `startKanaru` does.
Future<RunningApp> _startWithFakes(
  WidgetTester tester,
  List<Override> overrides,
) async {
  final paths = await createAppPaths();
  final file = File('${paths.configDir.path}/settings.json');
  final values = <String, Object?>{};
  if (await file.exists()) {
    final json = jsonDecode(await file.readAsString());
    if (json is Map<String, Object?> && json['values'] is Map) {
      values.addAll((json['values'] as Map).cast<String, Object?>());
    }
  }
  values['library.min_duration_ms'] = 0;
  await file.writeAsString(
    jsonEncode({'format': 'kanaru-settings', 'version': 1, 'values': values}),
  );

  setupLogging();
  MediaKit.ensureInitialized();
  final started = await bootstrap(
    extensions: [...builtInExtensions, ...bundledExtensions],
    loadNative: loadNativeLibrary,
    createPaths: createAppPaths,
    openSettings: (paths) =>
        JsonSettingsStore.open(File('${paths.configDir.path}/settings.json')),
    loadDeviceId: (paths) =>
        FileDeviceId(File('${paths.dataDir.path}/device_id')).load(),
    openDatabase: (paths) =>
        AppDatabase.file(File('${paths.dataDir.path}/$databaseFileName')),
  );
  runApp(
    ProviderScope(
      overrides: [
        nativeVersionsProvider.overrideWithValue(started.nativeVersions),
        appPathsProvider.overrideWithValue(started.paths),
        settingsStoreProvider.overrideWithValue(started.settings),
        deviceIdProvider.overrideWithValue(started.deviceId),
        appDatabaseProvider.overrideWithValue(started.database),
        extensionRegistryProvider.overrideWithValue(started.registry),
        localLyricsReaderProvider.overrideWithValue(NativeLocalLyricsReader()),
        songLyricsEntryProvider.overrideWithValue(const LyricsSongEntry()),
        ...overrides,
      ],
      child: const KanaruApp(),
    ),
  );
  await tester.pump();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(KanaruApp)),
  );
  final app = RunningApp(tester, container);

  if (container.read(firstRunRequiredProvider)) {
    final next = find.byType(SetupNextButton);
    var lastRefresh = DateTime.fromMillisecondsSinceEpoch(0);
    await app.pumpUntil(
      () {
        final now = DateTime.now();
        if (now.difference(lastRefresh) >= const Duration(seconds: 1)) {
          lastRefresh = now;
          unawaited(
            container
                .read(mediaPermissionStateProvider.notifier)
                .refresh()
                .then<void>(
                  (_) {},
                  onError: (Object e) =>
                      debugPrint('permission refresh failed: $e'),
                ),
          );
        }
        return next.hitTestable().evaluate().isNotEmpty &&
            tester.widget<SetupNextButton>(next).onPressed != null;
      },
      what:
          'first-run page with a default music folder (is XDG_MUSIC_DIR set?)',
    );
    await tester.tap(next);
    await app.pumpUntil(
      () => !container.read(firstRunRequiredProvider),
      what: 'setup to finish',
    );
  }
  container.read(routerProvider).go('/library/songs');
  await tester.pump();
  final wanted = {for (final t in fixtureTracks) t.title};
  await app.pumpUntil(
    () async => (await app.trackIdsByTitle()).keys.toSet().containsAll(wanted),
    what: 'every fixture track in the library (scan)',
    timeout: const Duration(seconds: 120),
  );
  return app;
}

/// Settings › Lời bài on the real app (Linux, desktop width): the "Tự tìm lời"
/// switch and the "Nguồn lời trực tuyến" block with no source, with sources
/// (repo on, file off, one with a problem), the `?focus=sources` deep link and
/// the dark theme. The source list is a fixture (the installed-plugin store is
/// covered by unit tests); the page, switches and routing are the real ones.
/// Screenshots (PNG of the root layer) go to [_shots]. Asserts state, not pixels.
///
/// Run: `tool/integration_test.sh linux integration_test/lyrics_sources_settings_test.dart`

const _shots =
    '/home/hieunm/dev/apps/kanaru/plans/261123-0837-online-lyrics-plugins/reports/selfcheck-261123-lyrics-sources-settings';

class _FakeSources extends Notifier<List<LyricsSource>> {
  @override
  List<LyricsSource> build() => const [];
  void set(List<LyricsSource> v) => state = v;
}

final _fakeSources = NotifierProvider<_FakeSources, List<LyricsSource>>(
  _FakeSources.new,
);

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
  final view = RendererBinding.instance.renderViews.first;
  final layer = view.debugLayer as OffsetLayer;
  final image = await layer.toImage(Offset.zero & view.size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final dir = Directory(_shots)..createSync(recursive: true);
  File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('lyrics settings: online sources block', (tester) async {
    Logger.root.level = Level.WARNING;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 800);
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();

    final app = await _startWithFakes(tester, [
      lyricsSourcesLoadedProvider.overrideWithValue(true),
      lyricsSourcesProvider.overrideWith((ref) => ref.watch(_fakeSources)),
    ]);
    final container = app.container;
    await container.read(appLanguageProvider.notifier).set(AppLanguage.vi);
    await container.read(themeChoiceProvider.notifier).set(ThemeChoice.light);
    await container.read(lyricsAutoSearchProvider.notifier).set(true);
    await tester.pump();

    AppLocalizations l10n() =>
        AppLocalizations.of(tester.element(find.byType(LyricsSettingsPage)));
    Future<void> go(String location) async {
      container.read(routerProvider).go(location);
      await app.pumpUntil(
        () => find.byType(LyricsSettingsPage).evaluate().isNotEmpty,
        what: 'the lyrics settings page',
      );
      await tester.pump(const Duration(seconds: 1));
    }

    // (a) no lyrics plugin
    await go('/settings/lyrics');
    expect(find.text(l10n().lyricsSettingsAutoFind), findsOneWidget);
    expect(
      find.textContaining(l10n().lyricsSettingsAutoFindNone),
      findsOneWidget,
    );
    await _shot(tester, 'a-no-plugin-top');
    await tester.scrollUntilVisible(
      find.text(l10n().lyricsSettingsAddSource),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(l10n().lyricsSettingsSources), findsOneWidget);
    await _shot(tester, 'a-no-plugin-sources');

    // (b) sources: repo on, repo on, file off, file on with a problem
    container.read(_fakeSources.notifier).set(const [
      LyricsSource(
        id: 'lrclib',
        name: 'LRCLIB',
        version: 1,
        origin: LyricsSourceOrigin.repo,
        enabled: true,
      ),
      LyricsSource(
        id: 'netease',
        name: 'NetEase',
        version: 4,
        origin: LyricsSourceOrigin.repo,
        enabled: true,
      ),
      LyricsSource(
        id: 'zing',
        name: 'ZingMP3',
        version: 3,
        origin: LyricsSourceOrigin.repo,
        enabled: false,
      ),
      LyricsSource(
        id: 'mxm',
        name: 'Musixmatch',
        version: 6,
        origin: LyricsSourceOrigin.file,
        enabled: false,
        problem: SourceProblem.needsConfig,
      ),
    ]);
    await go('/settings/lyrics');
    expect(
      find.textContaining(l10n().lyricsSettingsAutoFindNone),
      findsNothing,
    );
    await tester.scrollUntilVisible(
      find.text(l10n().lyricsSettingsAddSource),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('LRCLIB'), findsOneWidget);
    expect(find.text(l10n().lyricsSettingsSourceRepo(1)), findsOneWidget);
    expect(
      find.text(
        l10n().lyricsSettingsSourceOff(l10n().lyricsSettingsSourceFile(6)),
      ),
      findsOneWidget,
    );
    expect(find.text(l10n().lyricsSettingsSourceNeedsConfig), findsOneWidget);
    await _shot(tester, 'b-sources');

    // (c) deep link scrolls to the block
    await go('/settings/lyrics?focus=sources');
    await app.pumpUntil(
      () =>
          find.byType(LyricsSourcesSection).hitTestable().evaluate().isNotEmpty,
      what: 'the sources block scrolled into view',
      timeout: const Duration(seconds: 10),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await _shot(tester, 'c-focus-sources-pulse');

    // (d) dark theme
    await container.read(themeChoiceProvider.notifier).set(ThemeChoice.dark);
    await tester.pump();
    await _shot(tester, 'd-dark-sources');

    semantics.dispose();
  });
}
