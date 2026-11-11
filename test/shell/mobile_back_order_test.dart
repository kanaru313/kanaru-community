import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/kanaru.dart';
import 'package:kanaru/src/shell/state/mobile_sidebar_state.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/app_harness.dart';
import '../support/nav_fixture.dart';

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
    await tester.tap(find.byTooltip('Gear'));
    await tester.pumpAndSettle();
    expect(find.text('page /gear'), findsOneWidget);

    expect(await _back(tester), isTrue);
    expect(find.text('page /gear'), findsNothing);
    // Still on the Beta tab, not sent Home.
    expect(find.text('page /beta'), findsOneWidget);
  });
}
