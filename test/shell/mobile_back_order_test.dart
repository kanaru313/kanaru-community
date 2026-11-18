import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/kanaru.dart';
import 'package:kanaru/src/shell/state/mobile_sidebar_state.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/app_harness.dart';
import '../support/nav_fixture.dart';
import '../support/icon_button_finders.dart';

class _Child implements KanaruExtension {
  const _Child();
  @override
  String get id => 'back-child';
  @override
  void register(ExtensionRegistry r) => r
    ..addNavItem(
      NavItem(
        id: 'deep',
        path: '/deep',
        icon: KIcons.placeholder,
        selectedIcon: KIcons.placeholder,
        label: (_) => 'Deep',
        order: 300,
      ),
    )
    ..addRoute(
      GoRoute(
        path: '/deep',
        builder: (_, _) => const Text('deep root'),
        routes: [
          GoRoute(path: 'child', builder: (_, _) => const Text('deep child')),
        ],
      ),
    );
}

String _location(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .routerDelegate
        .currentConfiguration
        .uri
        .path;

void _go(WidgetTester tester, String path) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);

Future<bool> _back(WidgetTester tester) async {
  final handled = await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
  return handled;
}

void main() {
  testWidgets(
    'Back: sidebar, then child page, then tab root to Home, then exit',
    (tester) async {
      final c = await pumpKanaruApp(
        tester,
        extensions: [const NavFixture(), const _Child()],
        width: 400,
      );
      _go(tester, '/deep/child');
      await tester.pumpAndSettle();
      c.read(mobileSidebarOpenProvider.notifier).open();
      await tester.pumpAndSettle();

      // 1. The sidebar closes first; the page stays.
      expect(await _back(tester), isTrue);
      expect(c.read(mobileSidebarOpenProvider), isFalse);
      expect(_location(tester), '/deep/child');

      // 2. The child page closes.
      expect(await _back(tester), isTrue);
      expect(_location(tester), '/deep');

      // 3. A tab root other than Home goes to Home.
      expect(await _back(tester), isTrue);
      expect(_location(tester), '/');

      // 4. On Home Back is not taken: the app exits.
      expect(await _back(tester), isFalse);
    },
  );

  testWidgets('Back from a pushed Settings page closes it, not the tab', (
    tester,
  ) async {
    await pumpKanaruApp(
      tester,
      extensions: [const NavFixture(), const _Child()],
      width: 400,
    );
    _go(tester, '/beta');
    await tester.pumpAndSettle();
    await tester.tap(byIconButton('Gear'));
    await tester.pumpAndSettle();
    expect(find.text('page /gear'), findsOneWidget);

    expect(await _back(tester), isTrue);
    expect(find.text('page /gear'), findsNothing);
    // Still on the Beta tab, not sent Home.
    expect(find.text('page /beta'), findsOneWidget);
  });

  testWidgets('the platform is told the app handles Back at a tab root and '
      'with the sidebar open', (tester) async {
    final calls = <bool>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
          calls.add(call.arguments as bool);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final c = await pumpKanaruApp(
      tester,
      extensions: [const NavFixture(), const _Child()],
      width: 400,
    );
    // Home: Back is left to the system.
    expect(calls.where((v) => v), isEmpty);

    _go(tester, '/deep');
    await tester.pumpAndSettle();
    expect(calls.last, isTrue);

    // One Back goes Home and releases the claim.
    expect(await _back(tester), isTrue);
    expect(_location(tester), '/');
    expect(calls.last, isFalse);

    // The open sidebar claims Back on Home, too.
    c.read(mobileSidebarOpenProvider.notifier).open();
    await tester.pumpAndSettle();
    expect(calls.last, isTrue);
    expect(await _back(tester), isTrue);
    expect(c.read(mobileSidebarOpenProvider), isFalse);
    expect(calls.last, isFalse);
  });
}
