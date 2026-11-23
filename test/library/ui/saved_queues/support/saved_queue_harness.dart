import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/library/state/custom_cover_providers.dart';
import 'package:kanaru/src/library/state/history/local_day_provider.dart';
import 'package:kanaru/src/library/state/saved_queues/saved_queue_providers.dart';
import 'package:kanaru/src/library/domain/history/history_days.dart';
import 'package:kanaru/src/library/ui/saved_queues/saved_queue_routes.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/playback/domain/now_playing.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../database/support/test_db.dart';
import '../../../../support/fake_playback_commands.dart';
import '../../../../support/memory_settings_store.dart';
import 'fake_saved_queue_store.dart';

/// The moment the saved queue tests run at: Saturday 21 Nov 2026, 21:30.
final testNow = DateTime(2026, 11, 21, 21, 30);

/// What a saved queue page test drives.
class SavedQueueHarness {
  SavedQueueHarness(this.container, this.store, this.playback, this.router);

  final ProviderContainer container;
  final FakeSavedQueueStore store;
  final FakePlaybackCommands playback;
  final GoRouter router;

  /// Path on top of the router, a page opened by a push included.
  String get location {
    final config = router.routerDelegate.currentConfiguration;
    final top = config.last;
    return (top is ImperativeRouteMatch ? top.matches.uri : config.uri).path;
  }
}

/// A local day that never ticks (no midnight timer left pending).
class _FixedDay extends LocalDayNotifier {
  @override
  DateTime build() => localDay(testNow);
}

/// Pumps the real saved queue routes (under `/playlists`, as the app has
/// them) over a scripted [store], starting at [start], on a window of [width]
/// x [height] (device pixel ratio 1, text scale [textScale]).
Future<SavedQueueHarness> pumpSavedQueues(
  WidgetTester tester, {
  FakeSavedQueueStore? store,
  String start = '/playlists/queues',
  double width = 400,
  double height = 800,
  double textScale = 1,
  bool animations = true,
  Brightness brightness = Brightness.light,
  FakePlaybackCommands? playback,
  List<Override> overrides = const [],
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.reset);
  final fake = store ?? FakeSavedQueueStore();
  addTearDown(fake.close);
  final commands = playback ?? FakePlaybackCommands();
  final db = openTestDb();
  addTearDown(db.close);
  final now = StreamController<NowPlaying>()..add(NowPlaying.none);
  addTearDown(() => unawaited(now.close()));
  final container = ProviderContainer(
    overrides: [
      savedQueueStoreProvider.overrideWithValue(fake),
      appDatabaseProvider.overrideWithValue(db),
      settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
      playbackCommandsProvider.overrideWithValue(commands),
      nowPlayingProvider.overrideWith((ref) => now.stream),
      historyClockProvider.overrideWithValue(() => testNow),
      localDayProvider.overrideWith(_FixedDay.new),
      customCoverKeepAliveProvider.overrideWithValue(Duration.zero),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  final router = GoRouter(
    initialLocation: start,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('HOME')),
      ),
      GoRoute(
        path: '/playlists',
        builder: (_, _) => const Scaffold(body: Text('PLAYLISTS')),
        routes: savedQueueRoutes(),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: buildKanaruTheme(brightness: brightness),
        locale: const Locale('vi'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        // The app shell's Scaffold is what shows the toasts.
        builder: (context, child) => Scaffold(
          body: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: !animations,
            ),
            child: child!,
          ),
        ),
        routerConfig: router,
      ),
    ),
  );
  await settle(tester);
  return SavedQueueHarness(container, fake, commands, router);
}

/// Lets streams and routes finish: the fake store answers on microtasks.
Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

/// The l10n of the page on screen (Vietnamese).
AppLocalizations l10nOf(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Navigator).first));
