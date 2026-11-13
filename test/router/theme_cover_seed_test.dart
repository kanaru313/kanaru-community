import 'dart:io';

import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/kanaru.dart' hide CoverColors;
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/extension/state/extension_providers.dart';
import 'package:kanaru/src/library/domain/scan_status.dart';
import 'package:kanaru/src/library/state/scan_providers.dart';
import 'package:kanaru/src/platform/data/noop_window_close_guard.dart';
import 'package:kanaru/src/platform/domain/app_paths.dart';
import 'package:kanaru/src/platform/state/device_id_provider.dart';
import 'package:kanaru/src/platform/state/platform_providers.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/platform/state/window_close_provider.dart';
import 'package:kanaru/src/media/domain/cover_colors.dart';
import 'package:kanaru/src/playback/state/playing_cover_colors.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru/src/router/ui/app_theme_provider.dart';
import 'package:kanaru/src/router/ui/kanaru_app.dart';
import 'package:kanaru/src/screens/settings/state/appearance_settings.dart';
import 'package:kanaru/src/screens/first_run/state/first_run_gate.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../database/support/test_db.dart';
import '../support/app_harness.dart' show NoopScanCommands;
import '../support/memory_settings_store.dart';
import '../support/nav_fixture.dart';

class _Paths implements AppPaths {
  _Paths(Directory root)
    : dataDir = Directory('${root.path}/data')..createSync(),
      cacheDir = Directory('${root.path}/cache')..createSync(),
      configDir = Directory('${root.path}/config')..createSync();
  @override
  final Directory dataDir;
  @override
  final Directory cacheDir;
  @override
  final Directory configDir;
}

class _Welcome implements KanaruExtension {
  const _Welcome();
  @override
  String get id => 'welcome';
  @override
  void register(ExtensionRegistry r) => r.addRoute(
    GoRoute(path: firstRunPath, builder: (_, _) => const Text('welcome page')),
  );
}

/// Records where the player was created. The shared test harness pins the
/// now-playing stream, which hides a build that creates the player; this one
/// leaves the real player and its providers in place.
base class _CreationRecorder extends ProviderObserver {
  final phases = <SchedulerPhase>[];

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    if (context.provider == playerControllerProvider) {
      phases.add(SchedulerBinding.instance.schedulerPhase);
    }
  }
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required MemorySettingsStore settings,
  required bool firstRun,
  _CreationRecorder? recorder,
  ProviderObserver? observer,
  List<Override> overrides = const [],
  Size size = const Size(400, 800),

  /// One more frame after the first, which the post-frame work has run by.
  bool extraFrame = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  final root = Directory.systemTemp.createTempSync('kanaru_theme_test');
  addTearDown(() => root.deleteSync(recursive: true));
  final db = openTestDb();
  addTearDown(db.close);
  final registry = ExtensionRegistry()
    ..install([const NavFixture(), const _Welcome()]);
  final container = ProviderContainer(
    observers: [?recorder, ?observer],
    overrides: [
      extensionRegistryProvider.overrideWithValue(registry),
      nativeVersionsProvider.overrideWithValue('bridge test'),
      settingsStoreProvider.overrideWithValue(settings),
      deviceIdProvider.overrideWithValue('test-device'),
      windowCloseGuardProvider.overrideWithValue(const NoopWindowCloseGuard()),
      appPathsProvider.overrideWithValue(_Paths(root)),
      appDatabaseProvider.overrideWithValue(db),
      scanStatusProvider.overrideWith((ref) => Stream.value(const ScanIdle())),
      libraryScanCommandsProvider.overrideWithValue(NoopScanCommands()),
      firstRunRequiredProvider.overrideWithValue(firstRun),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const KanaruApp()),
  );
  if (extraFrame) await tester.pump();
  return container;
}

/// Scheme of the theme in use (the app builds only the active brightness).
ColorScheme _scheme(WidgetTester tester) {
  final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
  return (app.themeMode == ThemeMode.dark ? app.darkTheme! : app.theme!)
      .colorScheme;
}

/// Counts how often the app theme provider (re)builds, per brightness.
base class _ThemeBuilds extends ProviderObserver {
  final built = <Brightness>[];

  void _count(ProviderObserverContext context) {
    if (context.provider.from == appThemeProvider) {
      built.add(context.provider.argument! as Brightness);
    }
  }

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) =>
      _count(context);

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) => _count(context);
}

class _CoverNotifier extends Notifier<PlayingCoverColors> {
  @override
  PlayingCoverColors build() => const PlayingCoverColorsPending();

  @override
  set state(PlayingCoverColors v) => super.state = v;
}

final _cover = NotifierProvider<_CoverNotifier, PlayingCoverColors>(
  _CoverNotifier.new,
);

void main() {
  const stored = 0xFF1E88E5;

  testWidgets('a stored seed themes the first frame, light and dark', (
    tester,
  ) async {
    final settings = MemorySettingsStore()..write('app.coverSeed', stored);
    final c = await _pump(
      tester,
      settings: settings,
      firstRun: false,
      extraFrame: false,
    );
    expect(
      _scheme(tester).primary,
      buildKanaruTheme(
        brightness: Brightness.light,
        seed: const Color(stored),
      ).colorScheme.primary,
    );
    await c.read(themeChoiceProvider.notifier).set(ThemeChoice.dark);
    await tester.pump();
    expect(_scheme(tester).brightness, Brightness.dark);
    expect(
      _scheme(tester).primary,
      buildKanaruTheme(
        brightness: Brightness.dark,
        seed: const Color(stored),
      ).colorScheme.primary,
    );
  });

  testWidgets('system mode follows the platform brightness; a fixed mode '
      'ignores it', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final c = await _pump(
      tester,
      settings: MemorySettingsStore(),
      firstRun: false,
    );
    expect(_scheme(tester).brightness, Brightness.dark);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pump();
    expect(_scheme(tester).brightness, Brightness.light);
    await c.read(themeChoiceProvider.notifier).set(ThemeChoice.dark);
    await tester.pump();
    expect(_scheme(tester).brightness, Brightness.dark);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await c.read(themeChoiceProvider.notifier).set(ThemeChoice.light);
    await tester.pump();
    expect(_scheme(tester).brightness, Brightness.light);
  });

  testWidgets('a cover change builds one theme, for the brightness in use', (
    tester,
  ) async {
    final observer = _ThemeBuilds();
    final c = await _pump(
      tester,
      settings: MemorySettingsStore(),
      firstRun: false,
      observer: observer,
      overrides: [
        playingCoverColorsProvider.overrideWith((ref) => ref.watch(_cover)),
      ],
    );
    // Make the dark member exist, then come back to light.
    await c.read(themeChoiceProvider.notifier).set(ThemeChoice.dark);
    await tester.pump();
    await c.read(themeChoiceProvider.notifier).set(ThemeChoice.light);
    await tester.pump();
    expect(observer.built, contains(Brightness.dark));
    observer.built.clear();

    c.read(_cover.notifier).state = const PlayingCoverColorsFound(
      CoverColors(seed: stored, palette: [stored]),
    );
    await tester.pump();
    await tester.pump();
    expect(observer.built, [Brightness.light]);
    expect(
      _scheme(tester).primary,
      buildKanaruTheme(
        brightness: Brightness.light,
        seed: const Color(stored),
      ).colorScheme.primary,
    );

    // The dark theme, built only now, comes from the new seed.
    await c.read(themeChoiceProvider.notifier).set(ThemeChoice.dark);
    await tester.pump();
    expect(
      _scheme(tester).primary,
      buildKanaruTheme(
        brightness: Brightness.dark,
        seed: const Color(stored),
      ).colorScheme.primary,
    );
  });

  testWidgets('no stored seed gives the default theme', (tester) async {
    await _pump(tester, settings: MemorySettingsStore(), firstRun: false);
    expect(
      _scheme(tester).primary,
      buildKanaruTheme(brightness: Brightness.light).colorScheme.primary,
    );
  });

  testWidgets('the app switches theme at once', (tester) async {
    await _pump(tester, settings: MemorySettingsStore(), firstRun: false);
    expect(
      tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .themeAnimationDuration,
      Duration.zero,
    );
  });

  testWidgets('colours of the playing cover re-theme the app through the '
      'stored seed', (tester) async {
    final settings = MemorySettingsStore();
    await _pump(
      tester,
      settings: settings,
      firstRun: false,
      overrides: [
        playingCoverColorsProvider.overrideWithValue(
          const PlayingCoverColorsFound(
            CoverColors(seed: stored, palette: [stored]),
          ),
        ),
      ],
    );
    await tester.pump();
    expect(settings.read('app.coverSeed'), stored);
    expect(
      _scheme(tester).primary,
      buildKanaruTheme(
        brightness: Brightness.light,
        seed: const Color(stored),
      ).colorScheme.primary,
    );
  });

  testWidgets('the first frame does not touch the player', (tester) async {
    final recorder = _CreationRecorder();
    final c = await _pump(
      tester,
      settings: MemorySettingsStore()..write('app.coverSeed', stored),
      firstRun: false,
      recorder: recorder,
    );
    // Whatever created it did so after the frame, not while building.
    expect(c.read(playerControllerProvider.exists), isTrue);
    expect(recorder.phases, isNotEmpty);
    expect(recorder.phases, everyElement(SchedulerPhase.postFrameCallbacks));
  });

  for (final firstRun in [true, false]) {
    testWidgets('the player is never created while building '
        '(${firstRun ? 'first-run route' : 'shell route'})', (tester) async {
      final recorder = _CreationRecorder();
      await _pump(
        tester,
        settings: MemorySettingsStore(),
        firstRun: firstRun,
        recorder: recorder,
      );
      await tester.pumpAndSettle();
      expect(
        find.text('welcome page'),
        firstRun ? findsOneWidget : findsNothing,
      );
      for (final phase in recorder.phases) {
        expect(phase, isNot(SchedulerPhase.persistentCallbacks));
      }
      // On the first-run route there is no shell, hence no player yet.
      if (!firstRun) expect(recorder.phases, isNotEmpty);
    });
  }

  for (final panel in ['queue', 'closed']) {
    testWidgets('desktop width, right panel saved as $panel: the player is '
        'never created while building', (tester) async {
      final recorder = _CreationRecorder();
      final c = await _pump(
        tester,
        settings: MemorySettingsStore()..write('shell.right_panel', panel),
        firstRun: false,
        recorder: recorder,
        size: const Size(1400, 900),
      );
      await tester.pumpAndSettle();
      expect(c.read(playerControllerProvider.exists), isTrue);
      expect(recorder.phases, isNotEmpty);
      expect(recorder.phases, everyElement(SchedulerPhase.postFrameCallbacks));
    });
  }

  testWidgets('a stale stored seed is cleared once the restored session is '
      'empty (real shell and player)', (tester) async {
    final settings = MemorySettingsStore()..write('app.coverSeed', stored);
    await _pump(tester, settings: settings, firstRun: false);
    for (var i = 0; i < 40 && settings.read('app.coverSeed') != null; i++) {
      // The restore reads the database: it needs real time.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      await tester.pump();
    }
    expect(settings.read('app.coverSeed'), isNull);
  });
}
