import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/kanaru.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/app_harness.dart';
import '../support/nav_fixture.dart';

/// A tab whose child page has a header with a back button, and an `ai`
/// top-bar action.
class _Pages implements KanaruExtension {
  const _Pages({this.ai = false});
  final bool ai;
  @override
  String get id => 'header-pages';
  @override
  void register(ExtensionRegistry r) {
    r
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
          builder: (_, _) =>
              const Scaffold(body: PageHeader(title: 'deep root')),
          routes: [
            GoRoute(
              path: 'child',
              builder: (context, _) => Scaffold(
                body: PageHeader(title: 'deep child', onBack: context.pop),
              ),
            ),
          ],
        ),
      );
    if (ai) {
      r.addTopBarAction(
        TopBarAction(
          id: 'ai',
          order: 1,
          builder: (_) => const Text('ai action'),
        ),
      );
    }
  }
}

Future<void> _pump(WidgetTester tester, {bool ai = false}) => pumpKanaruApp(
  tester,
  extensions: [
    const NavFixture(),
    _Pages(ai: ai),
  ],
  width: 400,
);

void _go(WidgetTester tester, String path) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);

void main() {
  testWidgets('a root page shows menu, AI and Settings in the header', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byTooltip('Menu'), findsOneWidget);
    expect(find.byIcon(KIcons.ai), findsOneWidget);
    expect(find.byTooltip('Gear'), findsOneWidget); // Settings (footer item)
    expect(find.byTooltip('Back'), findsNothing);
    // Order: menu, title, AI, Settings.
    final menu = tester.getCenter(find.byTooltip('Menu')).dx;
    final ai = tester.getCenter(find.byIcon(KIcons.ai)).dx;
    final gear = tester.getCenter(find.byTooltip('Gear')).dx;
    expect(menu, lessThan(ai));
    expect(ai, lessThan(gear));
  });

  testWidgets('a child page shows back and AI only', (tester) async {
    await _pump(tester);
    _go(tester, '/deep/child');
    await tester.pumpAndSettle();
    expect(find.text('deep child'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.byIcon(KIcons.ai), findsOneWidget);
    expect(find.byTooltip('Menu'), findsNothing);
    expect(find.byTooltip('Gear'), findsNothing);
  });

  testWidgets('the AI placeholder is dimmed with a coming-soon tooltip', (
    tester,
  ) async {
    await _pump(tester);
    final button = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(KIcons.ai),
        matching: find.byType(IconButton),
      ),
    );
    expect(button.onPressed, isNull);
    expect(button.tooltip, contains('Coming soon'));
  });

  testWidgets('a registered ai action replaces the placeholder', (
    tester,
  ) async {
    await _pump(tester, ai: true);
    expect(find.text('ai action'), findsOneWidget);
    expect(find.byIcon(KIcons.ai), findsNothing);
  });

  testWidgets('Settings in the header pushes the Settings page', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.byTooltip('Gear'));
    await tester.pumpAndSettle();
    expect(find.text('page /gear'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('the header keeps 48 dp targets', (tester) async {
    await _pump(tester);
    for (final tip in ['Menu', 'Gear']) {
      final size = tester.getSize(
        find
            .ancestor(
              of: find.byTooltip(tip),
              matching: find.byType(IconButton),
            )
            .first,
      );
      expect(size.width, greaterThanOrEqualTo(48), reason: tip);
      expect(size.height, greaterThanOrEqualTo(48), reason: tip);
    }
  });
}
