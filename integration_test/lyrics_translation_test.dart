import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/gestures.dart' show kSecondaryButton;
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart'
    show Navigator, RepaintBoundary, Size, runApp;
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
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/library/ui/menus/song_lyrics_entry.dart';
import 'package:kanaru/src/lyrics/data/native_local_lyrics_reader.dart';
import 'package:kanaru/src/lyrics/domain/translation/translation_status.dart';
import 'package:kanaru/src/lyrics/state/lyrics_reader_provider.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_providers.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_settings.dart';
import 'package:kanaru/src/lyrics/ui/song_lyrics_entry_impl.dart';
import 'package:kanaru/src/lyrics/ui/translation/modal/translate_body.dart';
import 'package:kanaru/src/lyrics/ui/translation/modal/translate_language_row.dart';
import 'package:kanaru/src/lyrics/ui/translation/modal/translate_service_row.dart';
import 'package:kanaru/src/lyrics/ui/translation/translate_pill.dart';
import 'package:kanaru/src/lyrics/ui/translation/translation_language_name.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/platform/data/app_paths_factory.dart';
import 'package:kanaru/src/platform/data/file_device_id.dart';
import 'package:kanaru/src/platform/data/json_settings_store.dart';
import 'package:kanaru/src/platform/data/native_library.dart';
import 'package:kanaru/src/platform/state/device_id_provider.dart';
import 'package:kanaru/src/platform/state/media_permissions_provider.dart';
import 'package:kanaru/src/platform/state/platform_providers.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/playback/state/now_playing_panel.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru/src/plugins/domain/install/install_result.dart';
import 'package:kanaru/src/plugins/domain/install/repo_results.dart';
import 'package:kanaru/src/plugins/domain/run/plugin_engine.dart';
import 'package:kanaru/src/plugins/data/run/rust_plugin_engine.dart';
import 'package:kanaru/src/plugins/state/install_ops.dart';
import 'package:kanaru/src/plugins/state/plugin_run_provider.dart';
import 'package:kanaru/src/plugins/domain/install/install_id.dart';
import 'package:kanaru/src/plugins/state/plugin_services_provider.dart';
import 'package:kanaru/src/plugins/state/store_ops.dart';
import 'package:kanaru/src/router/state/router_provider.dart';
import 'package:kanaru/src/router/ui/kanaru_app.dart';
import 'package:kanaru/src/screens/first_run/state/first_run_gate.dart';
import 'package:kanaru/src/screens/now_playing/ui/desktop/desktop_now_playing.dart';
import 'package:kanaru_extensions/kanaru_extensions.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:media_kit/media_kit.dart';

import 'support/harness.dart' show RunningApp;

/// Lyrics translation on the real app (Linux), with the real
/// `google-translate` plugin installed from the live catalog of
/// `kanaru313/kanaru-plugins`: pick it, turn translation on, see the lines
/// of a synced and of a plain song translated, see a second visit served from
/// the cache (the plugin engine is not run again), a song change closing the
/// modal, and the `T` key and the pill's right click toggling. Skipped when
/// the catalog cannot be reached. Asserts state (providers, semantics, widget
/// types); the screenshots, written to `/tmp/kanaru-it/shots` (override with
/// `KANARU_IT_SHOTS`), are for comparing with the mockup by eye.
///
/// Run (through the main checkout's `main-build.sh`):
/// `tool/integration_test.sh linux integration_test/lyrics_translation_test.dart`
///
/// Screenshots: `tr-pill-off`, `tr-pill-translated`, `tr-pill-loading`
/// (when the run is slow enough to be caught), `tr-lines-under`,
/// `tr-lines-replace`, `tr-lines-plain`, `tr-modal-default`,
/// `tr-modal-service`, `tr-modal-target`, `tr-toast-on`, `tr-toast-off`.

const _catalog =
    'https://raw.githubusercontent.com/kanaru313/kanaru-plugins/main/plugins.json';
const _slug = 'google-translate';

/// The song with synced lyrics in its tag ("Sylt first line") and the one
/// with plain lyrics ("Uslt first line").
const _synced = 'IT Sylt Tag';
const _plain = 'IT Uslt Tag';
const _syncedFirstLine = 'Sylt first line';

/// Counts the runs that reach the real plugin runtime.
class _CountingEngine implements PluginEngine {
  _CountingEngine(this._inner);

  final PluginEngine _inner;
  final runs = <String>[];

  @override
  void reset() => _inner.reset();

  @override
  int begin() => _inner.begin();

  @override
  void cancel(int job) => _inner.cancel(job);

  @override
  Future<EngineResult> run(EngineRequest request, EngineFetch fetch) {
    runs.add(request.installId);
    return _inner.run(request, fetch);
  }
}

Future<bool> _catalogReachable() async {
  try {
    final found = await InternetAddress.lookup('raw.githubusercontent.com')
        .timeout(const Duration(seconds: 5));
    return found.isNotEmpty;
  } on Object {
    return false;
  }
}

/// What `startKanaru` does, with [overrides] added (`runKanaru` has no hook
/// for them): settings the harness needs are written first.
Future<RunningApp> _start(WidgetTester tester, List<Override> overrides) async {
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
  await app.pumpUntil(
    () async => (await app.trackIdsByTitle()).keys.toSet().containsAll({
      _synced,
      _plain,
    }),
    what: 'the fixture songs in the library (scan)',
    timeout: const Duration(seconds: 120),
  );
  return app;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('google-translate from the live catalog translates lyrics', (
    tester,
  ) async {
    if (!await _catalogReachable()) {
      debugPrint('lyrics translation test skipped: the catalog is offline');
      markTestSkipped('the plugin catalog is not reachable');
      return;
    }
    Logger.root.level = Level.WARNING;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 900);
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();

    final engine = _CountingEngine(const RustPluginEngine());
    final app = await _start(tester, [
      pluginEngineProvider.overrideWithValue(engine),
    ]);
    final container = app.container;
    final ids = await app.trackIdsByTitle();
    final syncedId = TrackId(ids[_synced]!);
    final plainId = TrackId(ids[_plain]!);
    final player = container.read(playerControllerProvider);
    AppLocalizations l10n() =>
        AppLocalizations.of(tester.element(find.byType(Navigator).first));

    Future<void> shot(String name) async {
      await tester.pump(const Duration(milliseconds: 400));
      try {
        // The Linux embedder has no screenshot plugin: draw the app's
        // outermost repaint boundary (the app's own window only).
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byType(RepaintBoundary).first,
        );
        final image = await boundary.toImage();
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        final dir = Directory(
          Platform.environment['KANARU_IT_SHOTS'] ?? '/tmp/kanaru-it/shots',
        )..createSync(recursive: true);
        File('${dir.path}/$name.png')
            .writeAsBytesSync(bytes.buffer.asUint8List());
      } on Object catch (e) {
        // A screenshot is for the eye only: never fail the test for it.
        debugPrint('screenshot $name failed: $e');
      }
    }

    Future<void> playPaused(TrackId id) async {
      await player.playTracks([
        id,
      ], context: const PlayContext(PlayContextKind.songs));
      await app.pumpUntil(
        () => container.read(nowPlayingProvider).value?.trackId == id,
        what: 'track $id to be playing',
      );
      await player.pause();
    }

    TranslationStatus statusOf(TrackId id) =>
        container.read(trackTranslationProvider(id)).status;

    // ===== install google-translate from the live catalog ===================
    final added = await container.read(storeOpsProvider).add(_catalog);
    if (added is! RepoAdded) {
      throw TestFailure('the catalog could not be added: $added');
    }
    // The package is prepared straight from the repository row and its stored
    // catalog (what the store page does on "Cài đặt"), not through the store
    // list provider: nothing here watches that list, and the test must not
    // depend on a screen.
    final repo = await container.read(storeOpsProvider).describe(added.repoId);
    if (repo == null) throw TestFailure('the added repository is not stored');
    if (repo.pluginCount == 0) {
      throw TestFailure('the stored catalog lists no plugin: $repo');
    }
    final installId = repoInstallId(repo.url, _slug);
    final installOps = container.read(installOpsProvider);
    final prepared = await container
        .read(pluginServicesProvider)
        .held
        .prepareFromRepo(added.repoId, _slug)
        .result;
    final held = switch (prepared) {
      Ok(:final value) => value,
      Err(:final error) => throw TestFailure(
        'the package is unreadable: $error',
      ),
    };
    final installed = await installOps.install(held.token);
    expect(installed, isA<Installed>(), reason: '$installed');

    // ===== pick it, target Vietnamese, translation still off ================
    await container.read(translationServiceProvider.notifier).set(installId);
    await container.read(translationTargetProvider.notifier).set('vi');
    await playPaused(syncedId);
    container.read(nowPlayingPanelProvider.notifier).open();
    await app.pumpUntil(
      () => find.byType(DesktopNowPlaying).evaluate().isNotEmpty,
      what: 'desktop Now Playing',
    );
    await app.pumpUntil(
      () => find.text(_syncedFirstLine).evaluate().isNotEmpty,
      what: 'the synced lyrics on screen',
    );
    final pill = find.byType(TranslatePill);
    // The Now Playing header hides after 3 s without input: it ignores the
    // pointer and its Riverpod consumers stop rebuilding (muted tickers), so
    // the pill would show stale state. Any key shows it again (Shift is not
    // one of the page's shortcuts).
    Future<void> showHeader() async {
      await tester.sendKeyEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump(const Duration(milliseconds: 600));
    }

    expect(pill, findsOneWidget);
    await shot('tr-pill-off');

    // ===== turn it on: the synced song is translated ========================
    final watching = container.listen(
      trackTranslationProvider(syncedId),
      (_, _) {},
    );
    addTearDown(watching.close);
    await container.read(translationOnProvider.notifier).set(true);
    // Poll without a shot inside the condition: a shot pumps too, and two
    // pumps at once are a guarded-function conflict. A run this short can
    // finish before it is seen loading; the loading shot is best effort.
    void failIfFailed() {
      final status = statusOf(syncedId);
      if (status is StatusFailed) {
        throw TestFailure('the translation failed: ${status.failure}');
      }
    }

    await app.pumpUntil(
      () {
        failIfFailed();
        final status = statusOf(syncedId);
        return status is StatusLoading || status is StatusReady;
      },
      what: 'the synced song to start or finish translating',
      timeout: const Duration(seconds: 30),
    );
    if (statusOf(syncedId) is StatusLoading) await shot('tr-pill-loading');
    await app.pumpUntil(
      () {
        failIfFailed();
        return statusOf(syncedId) is StatusReady;
      },
      what: 'the synced song to be translated',
      timeout: const Duration(seconds: 90),
    );
    final view = container.read(trackTranslationProvider(syncedId));
    expect(view.map[_syncedFirstLine], isNotEmpty);
    expect(view.map[_syncedFirstLine], isNot(_syncedFirstLine));
    final runsAfterFirst = engine.runs.length;
    expect(runsAfterFirst, greaterThan(0));
    await tester.pump(const Duration(milliseconds: 500));
    // The translated line is on screen under the original one.
    expect(
      find.text(view.map[_syncedFirstLine]!).evaluate().isNotEmpty,
      isTrue,
    );
    // The pill names the language of the translation.
    await showHeader();
    expect(
      find.descendant(
        of: pill,
        matching: find.text(translationLanguageName(l10n(), 'vi')),
      ),
      findsOneWidget,
    );
    await shot('tr-pill-translated');
    await shot('tr-lines-under');

    // ===== replace display ==================================================
    await container
        .read(translationDisplayProvider.notifier)
        .set(TranslationDisplay.replace);
    await tester.pump(const Duration(milliseconds: 500));
    await shot('tr-lines-replace');
    await container
        .read(translationDisplayProvider.notifier)
        .set(TranslationDisplay.under);

    // ===== the modal: default, service page, target page ====================
    await showHeader();
    await tester.tap(pill);
    await app.pumpUntil(
      () => find.byType(TranslateBody).evaluate().isNotEmpty,
      what: 'the "Dịch lời" modal',
      timeout: const Duration(seconds: 15),
    );
    await shot('tr-modal-default');
    await tester.tap(find.byType(TranslateServiceRow));
    await tester.pump(const Duration(seconds: 1));
    await shot('tr-modal-service');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(
      find.descendant(
        of: find.byType(TranslateLanguageRow),
        matching: find.text(translationLanguageName(l10n(), 'vi')),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await shot('tr-modal-target');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(seconds: 1));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await app.pumpUntil(
      () => find.byType(TranslateBody).evaluate().isEmpty,
      what: 'the modal to close with Esc',
      timeout: const Duration(seconds: 15),
    );

    // ===== a song change closes the modal ===================================
    await showHeader();
    await tester.tap(pill);
    await app.pumpUntil(
      () => find.byType(TranslateBody).evaluate().isNotEmpty,
      what: 'the modal again',
      timeout: const Duration(seconds: 15),
    );
    await playPaused(plainId);
    await app.pumpUntil(
      () => find.byType(TranslateBody).evaluate().isEmpty,
      what: 'the modal to close when the song changes',
      timeout: const Duration(seconds: 15),
    );

    // ===== the plain song gets its own translation ==========================
    final watchingPlain = container.listen(
      trackTranslationProvider(plainId),
      (_, _) {},
    );
    addTearDown(watchingPlain.close);
    await app.pumpUntil(
      () {
        final status = statusOf(plainId);
        if (status is StatusFailed) {
          throw TestFailure('the plain song failed: ${status.failure}');
        }
        return status is StatusReady;
      },
      what: 'the plain song to be translated',
      timeout: const Duration(seconds: 90),
    );
    expect(
      container.read(trackTranslationProvider(plainId)).map['Uslt first line'],
      isNotEmpty,
    );
    await shot('tr-lines-plain');

    // ===== back to the first song: the cache answers, no new run ============
    final runsBeforeReplay = engine.runs.length;
    await playPaused(syncedId);
    await app.pumpUntil(
      () => statusOf(syncedId) is StatusReady,
      what: 'the synced song to be translated again from the cache',
    );
    await tester.pump(const Duration(seconds: 3));
    expect(
      engine.runs.length,
      runsBeforeReplay,
      reason: 'a saved translation must not run the plugin again',
    );

    // ===== T and the pill's right click toggle ==============================
    await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
    await app.pumpUntil(
      () => !container.read(translationOnProvider),
      what: 'T to turn translation off',
      timeout: const Duration(seconds: 10),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(l10n().lyricsTranslateToastOff), findsOneWidget);
    await shot('tr-toast-off');
    await showHeader();
    await tester.tap(pill, buttons: kSecondaryButton);
    await app.pumpUntil(
      () => container.read(translationOnProvider),
      what: 'the right click to turn translation on',
      timeout: const Duration(seconds: 10),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text(
        l10n().lyricsTranslateToastOn(translationLanguageName(l10n(), 'vi')),
      ),
      findsOneWidget,
    );
    await shot('tr-toast-on');
    expect(
      engine.runs.length,
      runsBeforeReplay,
      reason: 'turning it back on is served from the cache',
    );

    semantics.dispose();
  });
}
