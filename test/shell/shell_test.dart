import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/kanaru.dart';
import 'package:kanaru/src/extension/state/extension_providers.dart';
import 'package:kanaru/src/platform/state/platform_providers.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/router/app_router.dart';
import 'package:kanaru/src/router/ui/kanaru_app.dart';

import '../support/memory_settings_store.dart';

class _Fake implements KanaruExtension {
  @override
  String get id => 'fake';
  @override
  void register(ExtensionRegistry r) {
    r
      ..addNavItem(NavItem(
        id: 'fake',
        path: '/fake',
        icon: KIcons.extension,
        selectedIcon: KIcons.extensionSelected,
        label: (_) => 'FakeNav',
        order: 45,
      ))
      ..addRoute(GoRoute(path: '/fake', builder: (_, _) => const Text('fake page')))
      ..addRoute(GoRoute(path: '/hidden', builder: (_, _) => const Text('hidden page')))
      ..addRoute(GoRoute(
        path: '/album/:id',
        builder: (_, state) => Text('album ${state.pathParameters['id']}'),
      ));
  }
}

class _Early implements KanaruExtension {
  @override
  String get id => 'early';
  @override
  void register(ExtensionRegistry r) {
    r
      ..addNavItem(NavItem(
        id: 'early',
        path: '/early',
        icon: KIcons.bolt,
        selectedIcon: KIcons.boltSelected,
        label: (_) => 'EarlyNav',
        order: 1,
      ))
      ..addRoute(GoRoute(path: '/early', builder: (_, _) => const Text('early page')));
  }
}

class _Orphan implements KanaruExtension {
  @override
  String get id => 'orphan';
  @override
  void register(ExtensionRegistry r) => r.addNavItem(NavItem(
        id: 'orphan',
        path: '/orphan',
        icon: KIcons.placeholder,
        selectedIcon: KIcons.placeholder,
        label: (_) => 'Orphan',
        order: 1,
      ));
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
      settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
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
    expect(_byTooltip('Show or hide the sidebar'), findsNothing);
  });

  testWidgets('tapping a tab changes the page', (tester) async {
    await _pump(tester, 360);
    expect(find.text('Your library is empty.'), findsNothing);
    await tester.tap(_byTooltip('Library'));
    await tester.pumpAndSettle();
    expect(find.text('Your library is empty.'), findsOneWidget);
  });

  testWidgets('mobile Settings opens from Home and hides the bar', (tester) async {
    await _pump(tester, 360);
    await tester.tap(_byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Native libraries'), findsOneWidget);
    expect(find.text('bridge test'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(_byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('mobile system back from Settings returns to Home', (tester) async {
    await _pump(tester, 360);
    await tester.tap(_byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Native libraries'), findsOneWidget);

    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(handled, isTrue);
    expect(find.text('Native libraries'), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Your library is empty.'), findsNothing);
    expect(_byTooltip('Settings'), findsOneWidget); // Home header icon
  });

  testWidgets('desktop Settings opens from the sidebar and Back returns', (tester) async {
    await _pump(tester, 1280);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Native libraries'), findsOneWidget);
    await tester.tap(_byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Native libraries'), findsNothing);
    expect(find.byKey(const ValueKey('sidebar')), findsOneWidget);
  });

  testWidgets('desktop Home button goes to / even with a lower-order tab', (tester) async {
    await _pump(tester, 1280, extra: [_Early()]);
    await tester.tap(_byTooltip('Home'));
    await tester.pumpAndSettle();
    expect(find.text('early page'), findsNothing);
  });

  testWidgets('1199 px is mobile, 1200 px is desktop', (tester) async {
    await _pump(tester, 1199);
    expect(find.byType(NavigationBar), findsOneWidget);
    await _pump(tester, 1200);
    expect(find.byType(NavigationBar), findsNothing);
    expect(_byTooltip('Show or hide the sidebar'), findsOneWidget);
  });

  testWidgets('1280 px: top bar and sidebar toggles 240 and 72', (tester) async {
    await _pump(tester, 1280);
    expect(find.text('Kanaru'), findsOneWidget);
    expect(_sidebarWidth(tester), 240);
    await tester.tap(_byTooltip('Show or hide the sidebar'));
    await tester.pumpAndSettle();
    expect(_sidebarWidth(tester), 72);
    await tester.tap(_byTooltip('Show or hide the sidebar'));
    await tester.pumpAndSettle();
    expect(_sidebarWidth(tester), 240);
  });

  testWidgets('desktop back and forward follow visited pages', (tester) async {
    await _pump(tester, 1280);
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(find.text('Your library is empty.'), findsOneWidget);
    await tester.tap(_byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Your library is empty.'), findsNothing);
    await tester.tap(_byTooltip('Forward'));
    await tester.pumpAndSettle();
    expect(find.text('Your library is empty.'), findsOneWidget);
  });

  testWidgets('an extension nav item and route appear in both shells', (tester) async {
    await _pump(tester, 360, extra: [_Fake()]);
    expect(find.byType(NavigationDestination), findsNWidgets(6));
    await tester.tap(_byTooltip('FakeNav'));
    await tester.pumpAndSettle();
    expect(find.text('fake page'), findsOneWidget);

    await _pump(tester, 1280, extra: [_Fake()]);
    expect(find.text('FakeNav'), findsOneWidget);
  });

  testWidgets('a route without a nav item opens above the shell', (tester) async {
    await _pump(tester, 360, extra: [_Fake()]);
    final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
    router.push('/hidden');
    await tester.pumpAndSettle();
    expect(find.text('hidden page'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('hidden page'), findsNothing);
  });

  testWidgets('an extension route with a path parameter works', (tester) async {
    await _pump(tester, 360, extra: [_Fake()]);
    final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
    router.push('/album/42');
    await tester.pumpAndSettle();
    expect(find.text('album 42'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('album 42'), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('a nav item without a route fails router creation', (tester) async {
    final registry = ExtensionRegistry()..install([_Orphan()]);
    expect(() => buildRouter(registry), throwsStateError);
  });

  testWidgets('vietnamese labels follow the locale', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('vi')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await _pump(tester, 360);
    expect(_byTooltip('Thư viện'), findsOneWidget);
  });
}

/// flutter_test's `find.byTooltip` does not match the `Tooltip` of material_ui.
Finder _byTooltip(String message) => find.byWidgetPredicate(
      (w) => w is Tooltip && w.message == message,
    );
