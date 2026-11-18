import 'dart:io';

import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/database/custom_covers_store.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/state/custom_cover_providers.dart';
import 'package:kanaru/src/library/ui/browse/library_routes.dart';
import 'package:kanaru/src/library/state/playlists/playlist_providers.dart';
import 'package:kanaru/src/platform/domain/app_paths.dart';
import 'package:kanaru/src/platform/domain/settings_store.dart';
import 'package:kanaru/src/platform/state/platform_providers.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../support/fake_cover_importer.dart';
import '../../../../support/memory_settings_store.dart';
import '../../../playlists/support/playlist_fixtures.dart';
import 'test_store.dart';

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

/// Waits (real time, bounded) until [condition] holds, pumping between polls:
/// for results of real database work that fake time cannot advance.
Future<void> eventually(
  WidgetTester tester,
  bool Function() condition, {
  String? what,
}) async {
  final end = DateTime.now().add(const Duration(seconds: 10));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) {
      fail('timed out waiting for ${what ?? 'condition'}');
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    // Advancing fake time too, so route and snack bar animations proceed.
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// A [MaterialApp.router] over the real repository (in-memory database) with
/// a host screen at `/`, a list stub at `/playlists` and `/playlists/:uid`
/// built by [pageBuilder]. Use [launch] to run a flow with the host's context.
class PlaylistUiHarness {
  PlaylistUiHarness._(
    this.fixture,
    this.store,
    this.container,
    this.router,
    this._hostKey,
  );

  final PlaylistFixture fixture;
  final TestStore store;
  final ProviderContainer container;
  final GoRouter router;
  final GlobalKey _hostKey;

  static Future<PlaylistUiHarness> pump(
    WidgetTester tester, {
    double width = 400,
    Widget Function(BuildContext, String uid)? pageBuilder,
    bool disableAnimations = false,
    double textScale = 1,
    List<Override> overrides = const [],
    SettingsStore? settings,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 900);
    addTearDown(tester.view.reset);
    final fixture = (await tester.runAsync(PlaylistFixture.open))!;
    final root = Directory.systemTemp.createTempSync('kanaru_pl_ui');
    addTearDown(() => root.deleteSync(recursive: true));
    final store = TestStore(fixture.repo);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(fixture.db),
        playlistStoreProvider.overrideWithValue(store),
        settingsStoreProvider.overrideWithValue(
          settings ?? MemorySettingsStore(),
        ),
        appPathsProvider.overrideWithValue(_Paths(root)),
        coverImporterProvider.overrideWithValue(FakeCoverImporter()),
        // Covers are not kept loaded after their tile goes: no 5 s timer.
        customCoverKeepAliveProvider.overrideWithValue(Duration.zero),
        ...overrides,
      ],
    );
    addTearDown(container.dispose);
    final key = GlobalKey();
    late final GoRouter router;
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(body: SizedBox(key: key)),
        ),
        GoRoute(
          path: '/playlists',
          builder: (_, _) => const Scaffold(body: Text('PLAYLISTS LIST')),
        ),
        GoRoute(
          path: '/playlists/:uid',
          // The real detail transition: its 240 ms exit is what the delete
          // flow has to wait for.
          pageBuilder: (context, state) => libraryDetailPage(
            state,
            pageBuilder == null
                ? Scaffold(body: Text('PAGE ${state.pathParameters['uid']}'))
                : pageBuilder(context, state.pathParameters['uid']!),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: disableAnimations,
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pump();
    return PlaylistUiHarness._(fixture, store, container, router, key);
  }

  BuildContext hostContext(WidgetTester tester) =>
      tester.element(find.byKey(_hostKey, skipOffstage: false));

  AppLocalizations l10n(WidgetTester tester) =>
      AppLocalizations.of(hostContext(tester));

  /// Runs [flow] with the host's context; the future is returned unawaited by
  /// the caller (a dialog future completes when it closes).
  Future<T> launch<T>(
    WidgetTester tester,
    Future<T> Function(BuildContext context) flow,
  ) => flow(hostContext(tester));

  /// Gives playlist [uid] a custom cover row (no files needed).
  Future<void> giveCustomCover(WidgetTester tester, String uid) async {
    await tester.runAsync(
      () => setCustomCover(fixture.db, 'playlist', uid, 'ab/cover-key', now: 1),
    );
  }
}

/// Whether the button found by [finder] can be activated, read from its
/// semantics (a disabled button exposes no tap action).
bool canTap(WidgetTester tester, Finder finder) => tester
    .getSemantics(finder)
    .getSemanticsData()
    .hasAction(SemanticsAction.tap);

/// Playlists (Favorites excluded) as stored now, newest data from the
/// repository.
Future<List<PlaylistSummary>> storedPlaylists(
  WidgetTester tester,
  PlaylistUiHarness h,
) async =>
    (await tester.runAsync(() => h.fixture.repo.watchSummaries().first))!
        .playlists;

/// Toggle state of the control found by [finder], from its semantics.
bool? toggled(WidgetTester tester, Finder finder) {
  final state = tester
      .getSemantics(finder)
      .getSemanticsData()
      .flagsCollection
      .isToggled
      .name;
  return switch (state) {
    'isTrue' => true,
    'isFalse' => false,
    _ => null,
  };
}

/// Creates playlist [name] holding [trackCount] songs and returns its summary.
Future<PlaylistSummary> seedPlaylist(
  WidgetTester tester,
  PlaylistUiHarness h, {
  String name = 'Src',
  String description = '',
  int trackCount = 2,
}) async {
  final uid = (await tester.runAsync(() async {
    // Locators are unique per playlist name, so two seeds do not clash.
    final tracks = [
      for (var i = 0; i < trackCount; i++) await h.fixture.track('$name-$i'),
    ];
    return h.fixture.repo.createPlaylist(
      name: name,
      description: description,
      tracks: tracks,
    );
  }))!;
  return (await storedPlaylists(tester, h)).singleWhere((p) => p.uid == uid);
}

/// Settles animations and lets the timers that cancelled database streams
/// leave behind run, so a test can end with nothing pending.
Future<void> drain(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 1));
  await tester.pump(const Duration(milliseconds: 1));
}

/// [testWidgets] whose body is followed by [drain]: the dialogs watch
/// database streams whose cancellation leaves a timer behind.
void uiTest(String description, Future<void> Function(WidgetTester t) body) =>
    testWidgets(description, (t) async {
      await body(t);
      await drain(t);
    });

/// Waits until the live track ids of playlist [uid] satisfy [ok] and returns
/// them: the result of a write that finishes in real time.
Future<List<int>> eventuallyLive(
  WidgetTester tester,
  PlaylistUiHarness h,
  String uid,
  bool Function(List<int> tracks) ok, {
  String? what,
}) async {
  final end = DateTime.now().add(const Duration(seconds: 10));
  while (true) {
    final tracks = (await tester.runAsync(() => h.fixture.liveTracks(uid)))!;
    if (ok(tracks)) return tracks;
    if (DateTime.now().isAfter(end)) {
      fail('timed out waiting for ${what ?? 'tracks of $uid'}: $tracks');
    }
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Taps the Undo action of the toast on screen, after its slide-in finished
/// (a tap during the animation lands off the screen).
Future<void> tapUndo(WidgetTester tester, AppLocalizations l10n) async {
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(find.text(l10n.libraryMenuUndo));
  await tester.pump();
}
