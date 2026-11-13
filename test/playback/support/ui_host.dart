import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/player_phase_override.dart';
import 'controller_harness.dart';

/// A widget under test wired to a real [PlayerController] on an in-memory
/// database with a fake engine.
class UiHost {
  UiHost(this.h, this.container, {this.router});

  final Harness h;
  final ProviderContainer container;

  /// Set when the widget was pumped with [pumpWithPlayer]'s `routes`.
  final GoRouter? router;

  /// Lets database streams (track info, favorites) deliver their first value.
  Future<void> letStreamsArrive(WidgetTester tester) async {
    // Controller work started from a widget callback runs in the test's fake
    // zone: it advances only when real time and pumps alternate.
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump();
    }
  }

  /// Taps [finder] in the real zone and waits for the controller to finish
  /// what the tap started, then pumps. A tap in the fake zone would leave the
  /// controller's database work waiting for real time.
  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.runAsync(() async {
      await tester.tap(finder);
      await h.settle();
    });
    await tester.pump();
    await letStreamsArrive(tester);
  }

  /// Runs real async work (database, controller chain) outside fake time.
  Future<void> run(WidgetTester tester, Future<void> Function() body) async {
    await tester.runAsync(() async {
      await body();
      await h.settle();
    });
    await tester.pump();
    // A provider stream delivers after the first frame; its rebuild needs one more.
    await tester.pump();
  }
}

/// Pumps [child] in a themed, localized app. With [play] the six harness
/// tracks are queued and the first one is current and playing. The player and
/// every provider it needs are overridden; [overrides] adds more.
Future<UiHost> pumpWithPlayer(
  WidgetTester tester,
  Widget child, {
  bool play = true,
  List<Override> overrides = const [],
  Size size = const Size(400, 800),
  Brightness brightness = Brightness.light,
  double textScale = 1,

  /// Extra routes: the app then runs on a `GoRouter` whose `/` shows [child].
  List<RouteBase>? routes,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  final h = (await tester.runAsync(() => Harness.create()))!;
  final container = ProviderContainer(
    overrides: [
      playerControllerProvider.overrideWithValue(h.c),
      playerPhaseOverride(),
      appDatabaseProvider.overrideWithValue(h.db),
      settingsStoreProvider.overrideWithValue(h.settings),
      ...overrides,
    ],
  );
  final router = routes == null
      ? null
      : GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Scaffold(body: child),
            ),
            ...routes,
          ],
        );
  final host = UiHost(h, container, router: router);
  addTearDown(() async {
    container.dispose();
    await host.letStreamsArrive(tester);
    await tester.runAsync(h.close);
  });
  if (play) await host.run(tester, h.play);
  Widget scale(BuildContext context, Widget? app) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: app!,
  );
  final theme = buildKanaruTheme(brightness: brightness);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: router == null
          ? MaterialApp(
              theme: theme,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: scale,
              home: Scaffold(body: child),
            )
          : MaterialApp.router(
              theme: theme,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: scale,
              routerConfig: router,
            ),
    ),
  );
  await tester.pump();
  await host.letStreamsArrive(tester);
  return host;
}
