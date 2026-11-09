import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/kanaru.dart';
import 'package:kanaru/src/extension/state/extension_providers.dart';
import 'package:kanaru/src/platform/state/platform_providers.dart';
import 'package:kanaru/src/router/ui/kanaru_app.dart';

class _Fake implements KanaruExtension {
  @override
  String get id => 'fake';
  @override
  void register(ExtensionRegistry r) {
    r
      ..addNavItem(NavItem(
        id: 'fake',
        path: '/fake',
        icon: Icons.extension_outlined,
        selectedIcon: Icons.extension,
        label: (_) => 'FakeNav',
        order: 45,
      ))
      ..addRoute(GoRoute(path: '/fake', builder: (_, _) => const Text('fake page')))
      ..addRoute(GoRoute(path: '/hidden', builder: (_, _) => const Text('hidden page')));
  }
}

Future<void> _pump(WidgetTester tester, double width,
    {List<KanaruExtension> extra = const []}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 800);
  addTearDown(tester.view.reset);
  final registry = ExtensionRegistry()..install([...builtInExtensions, ...extra]);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      extensionRegistryProvider.overrideWithValue(registry),
      nativeVersionsProvider.overrideWithValue('bridge test'),
    ],
    child: const KanaruApp(),
  ));
  await tester.pumpAndSettle();
}

double _sidebarWidth(WidgetTester tester) =>
    tester.getSize(find.byKey(const ValueKey('sidebar'))).width;

void main() {
  testWidgets('360 px: bottom bar with 5 icon destinations, no top bar', (tester) async {
    await _pump(tester, 360);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    expect(find.byTooltip('Show or hide the sidebar'), findsNothing);
  });

  testWidgets('tapping a tab changes the page', (tester) async {
    await _pump(tester, 360);
    expect(find.text('Your library is empty.'), findsNothing);
    await tester.tap(find.byTooltip('Library'));
    await tester.pumpAndSettle();
    expect(find.text('Your library is empty.'), findsOneWidget);
  });

  testWidgets('mobile Settings opens from Home and hides the bar', (tester) async {
    await _pump(tester, 360);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Native libraries'), findsOneWidget);
    expect(find.text('bridge test'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('1199 px is mobile, 1200 px is desktop', (tester) async {
    await _pump(tester, 1199);
    expect(find.byType(NavigationBar), findsOneWidget);
    await _pump(tester, 1200);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byTooltip('Show or hide the sidebar'), findsOneWidget);
  });

  testWidgets('1280 px: top bar and sidebar toggles 240 and 72', (tester) async {
    await _pump(tester, 1280);
    expect(find.text('Kanaru'), findsOneWidget);
    expect(_sidebarWidth(tester), 240);
    await tester.tap(find.byTooltip('Show or hide the sidebar'));
    await tester.pumpAndSettle();
    expect(_sidebarWidth(tester), 72);
    await tester.tap(find.byTooltip('Show or hide the sidebar'));
    await tester.pumpAndSettle();
    expect(_sidebarWidth(tester), 240);
  });

  testWidgets('desktop back and forward follow visited pages', (tester) async {
    await _pump(tester, 1280);
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(find.text('Your library is empty.'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Your library is empty.'), findsNothing);
    await tester.tap(find.byTooltip('Forward'));
    await tester.pumpAndSettle();
    expect(find.text('Your library is empty.'), findsOneWidget);
  });

  testWidgets('an extension nav item and route appear in both shells', (tester) async {
    await _pump(tester, 360, extra: [_Fake()]);
    expect(find.byType(NavigationDestination), findsNWidgets(6));
    await tester.tap(find.byTooltip('FakeNav'));
    await tester.pumpAndSettle();
    expect(find.text('fake page'), findsOneWidget);

    await _pump(tester, 1280, extra: [_Fake()]);
    expect(find.text('FakeNav'), findsOneWidget);
  });

  testWidgets('a route without a nav item opens inside the shell', (tester) async {
    await _pump(tester, 360, extra: [_Fake()]);
    final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
    router.go('/hidden');
    await tester.pumpAndSettle();
    expect(find.text('hidden page'), findsOneWidget);
  });

  testWidgets('vietnamese labels follow the locale', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('vi')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await _pump(tester, 360);
    expect(find.byTooltip('Thư viện'), findsOneWidget);
  });
}
