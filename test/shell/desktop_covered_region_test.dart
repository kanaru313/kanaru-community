import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/kanaru.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/extension/state/extension_providers.dart';
import 'package:kanaru/src/library/domain/scan_status.dart';
import 'package:kanaru/src/playback/domain/playback_settings.dart';
import 'package:kanaru/src/library/state/scan_providers.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru/src/shell/state/nav_history.dart';
import 'package:kanaru/src/shell/state/now_playing_panel.dart';
import 'package:kanaru/src/shell/ui/desktop_shell.dart';
import 'package:kanaru/src/shell/ui/player_bar.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../playback/support/controller_harness.dart';
import '../support/app_harness.dart';
import '../support/nav_fixture.dart';

/// Page with a scrollable list, to see that the covered region keeps state.
class _ListPage implements KanaruExtension {
  const _ListPage();
  @override
  String get id => 'list-page';
  @override
  void register(ExtensionRegistry r) => r
    ..addNavItem(
      NavItem(
        id: 'list',
        path: '/list',
        icon: KIcons.placeholder,
        selectedIcon: KIcons.placeholder,
        label: (_) => 'List',
        order: 300,
        mobileTab: false,
      ),
    )
    ..addRoute(
      GoRoute(
        path: '/list',
        builder: (_, _) => Scaffold(
          body: ListView(
            key: const ValueKey('list'),
            children: [
              for (var i = 0; i < 60; i++)
                SizedBox(height: 48, child: Text('row $i')),
            ],
          ),
        ),
      ),
    );
}

Future<ProviderContainer> _pump(WidgetTester tester) => pumpKanaruApp(
  tester,
  extensions: [const NavFixture(), const _ListPage()],
  overrides: [hasCurrentTrackProvider.overrideWithValue(true)],
);

void main() {
  testWidgets('a track shows the player bar, the sidebar and the page', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byType(PlayerBar), findsOneWidget);
    expect(find.byKey(const ValueKey('sidebar')), findsOneWidget);
  });

  testWidgets('covered: player bar, sidebar and page are offstage', (
    tester,
  ) async {
    final c = await _pump(tester);
    c.read(nowPlayingPanelProvider.notifier).setCovered(true);
    await tester.pump();
    expect(find.byType(PlayerBar), findsNothing);
    expect(find.byKey(const ValueKey('sidebar')), findsNothing);
    expect(find.text('page /'), findsNothing);
    expect(find.text('Kanaru'), findsOneWidget); // the top bar stays

    c.read(nowPlayingPanelProvider.notifier).setCovered(false);
    await tester.pump();
    expect(find.byType(PlayerBar), findsOneWidget);
    expect(find.text('page /'), findsOneWidget);
  });

  testWidgets('a scroll offset survives a covered period', (tester) async {
    final c = await _pump(tester);
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/list');
    await tester.pumpAndSettle();
    await tester.drag(find.text('row 3'), const Offset(0, -400));
    await tester.pumpAndSettle();
    double offset() => tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byKey(const ValueKey('list'), skipOffstage: false),
            matching: find.byType(Scrollable),
            skipOffstage: false,
          ),
        )
        .position
        .pixels;
    final before = offset();
    expect(before, greaterThan(100));

    c.read(nowPlayingPanelProvider.notifier).setCovered(true);
    await tester.pump();
    c.read(nowPlayingPanelProvider.notifier).setCovered(false);
    await tester.pump();
    expect(offset(), before);
  });

  testWidgets('covered: the region leaves Tab traversal and Ctrl+F is quiet', (
    tester,
  ) async {
    final c = await _pump(tester);
    ExcludeFocus excluder() => tester.widget<ExcludeFocus>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('sidebar'), skipOffstage: false),
            matching: find.byType(ExcludeFocus, skipOffstage: false),
          )
          .first,
    );
    expect(excluder().excluding, isFalse);
    c.read(nowPlayingPanelProvider.notifier).setCovered(true);
    await tester.pump();
    expect(excluder().excluding, isTrue);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
    expect(router.routerDelegate.currentConfiguration.uri.path, '/');

    // Uncovered, the same shortcut opens Search again.
    c.read(nowPlayingPanelProvider.notifier).setCovered(false);
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/search');
  });

  testWidgets('close clears covered', (tester) async {
    final c = await _pump(tester);
    final panel = c.read(nowPlayingPanelProvider.notifier);
    panel.open(NowPlayingTab.queue);
    panel.setCovered(true);
    expect(c.read(nowPlayingPanelProvider).covered, isTrue);
    panel.close();
    final state = c.read(nowPlayingPanelProvider);
    expect(state.open, isFalse);
    expect(state.covered, isFalse);
    expect(state.tab, NowPlayingTab.queue);
  });

  testWidgets('a docked right panel stays painted and tappable when covered', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);
    final h = (await tester.runAsync(() => Harness.create()))!;
    var taps = 0;
    late GoRouter router;
    router = GoRouter(
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => DesktopShell(
            navigationShell: shell,
            items: const [],
            history: NavHistory(router),
            rightPanel: SizedBox(
              width: 300,
              child: GestureDetector(
                onTap: () => taps++,
                child: const ColoredBox(
                  color: Colors.teal,
                  child: Center(child: Text('chat panel')),
                ),
              ),
            ),
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/', builder: (_, _) => const Text('left page')),
              ],
            ),
          ],
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        extensionRegistryProvider.overrideWithValue(ExtensionRegistry()),
        playerControllerProvider.overrideWithValue(h.c),
        appDatabaseProvider.overrideWithValue(h.db),
        settingsStoreProvider.overrideWithValue(h.settings),
        hasCurrentTrackProvider.overrideWithValue(true),
        scanStatusProvider.overrideWith(
          (ref) => Stream.value(const ScanIdle()),
        ),
        libraryScanCommandsProvider.overrideWithValue(NoopScanCommands()),
      ],
    );
    addTearDown(() async {
      container.dispose();
      router.dispose();
      await tester.runAsync(h.close);
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          theme: buildKanaruTheme(brightness: Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('left page'), findsOneWidget);

    container.read(nowPlayingPanelProvider.notifier).setCovered(true);
    await tester.pump();
    expect(find.text('left page'), findsNothing);
    expect(find.byType(PlayerBar), findsNothing);
    expect(find.text('chat panel'), findsOneWidget);
    await tester.tap(find.text('chat panel'));
    expect(taps, 1);
  });
}
