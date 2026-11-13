import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/kanaru.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/extension/state/extension_providers.dart';
import 'package:kanaru/src/library/domain/scan_status.dart';
import 'package:kanaru/src/library/state/scan_providers.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru/src/shell/state/nav_history.dart';
import 'package:kanaru/src/shell/state/right_panel.dart';
import 'package:kanaru/src/shell/ui/desktop_shell.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../playback/support/controller_harness.dart';
import '../../playback/support/ui_host.dart';
import '../../support/app_harness.dart';
import '../../support/player_phase_override.dart';

/// A [DesktopShell] on a real controller (in-memory database, fake engine),
/// with a list page at `/` and a second page at `/other`.
class DesktopHost extends UiHost {
  DesktopHost(super.h, super.container, {required this.routerRef})
    : super(router: routerRef);

  final GoRouter routerRef;
  int chatTaps = 0;
  int pageTaps = 0;
}

Future<DesktopHost> pumpDesktopShell(
  WidgetTester tester, {
  Size size = const Size(1280, 800),

  /// Installs a stand-in chat surface (the public build has none) and opens
  /// the right panel on it.
  bool withChat = false,
  bool play = true,
  List<Override> overrides = const [],

  /// Extra pages inside the shell (album and artist pages, for example).
  List<RouteBase> routes = const [],
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  final h = (await tester.runAsync(() => Harness.create()))!;
  late DesktopHost host;
  late GoRouter router;
  router = GoRouter(
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => DesktopShell(
          navigationShell: shell,
          items: const [],
          history: NavHistory(router),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => ListView(
                  key: const ValueKey('page list'),
                  children: [
                    for (var i = 0; i < 60; i++)
                      SizedBox(
                        height: 48,
                        child: GestureDetector(
                          onTap: () => host.pageTaps++,
                          child: Text('row $i'),
                        ),
                      ),
                  ],
                ),
              ),
              GoRoute(path: '/other', builder: (_, _) => const Text('other')),
              ...routes,
            ],
          ),
        ],
      ),
    ],
  );
  final registry = ExtensionRegistry();
  if (withChat) {
    registry.addPanelSurface(
      PanelSurface(
        id: 'chat',
        order: 0,
        body: (_) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => host.chatTaps++,
          child: const Center(child: Text('chat panel')),
        ),
        menu: (_) => const Icon(KIcons.moreVert, key: ValueKey('chat menu')),
      ),
    );
  }
  final container = ProviderContainer(
    overrides: [
      playerPhaseOverride(),
      extensionRegistryProvider.overrideWithValue(registry),
      playerControllerProvider.overrideWithValue(h.c),
      appDatabaseProvider.overrideWithValue(h.db),
      settingsStoreProvider.overrideWithValue(h.settings),
      scanStatusProvider.overrideWith((ref) => Stream.value(const ScanIdle())),
      libraryScanCommandsProvider.overrideWithValue(NoopScanCommands()),
      ...overrides,
    ],
  );
  host = DesktopHost(h, container, routerRef: router);
  addTearDown(() async {
    // Unmount first, so nothing builds against a disposed container.
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    router.dispose();
    await host.letStreamsArrive(tester);
    await tester.runAsync(h.close);
  });
  if (play) {
    await host.run(tester, h.play);
    await host.run(tester, h.c.pause);
  }
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        theme: buildKanaruTheme(brightness: Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pump();
  if (withChat) {
    container.read(rightPanelProvider.notifier).show(RightPanelKind.chat);
  }
  await tester.pump();
  await host.letStreamsArrive(tester);
  return host;
}

/// Pumps frames so a 500 ms slide finishes.
Future<void> settleSlide(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
