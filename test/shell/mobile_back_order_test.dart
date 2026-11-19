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

/// A tab like Library: the root route only redirects to a child list page;
/// `b` holds a page that claims Back (an open filter); `d` is a detail page.
class _Lists implements KanaruExtension {
  const _Lists();
  @override
  String get id => 'back-lists';
  @override
  void register(ExtensionRegistry r) => r
    ..addNavItem(
      NavItem(
        id: 'lists',
        path: '/lists',
        icon: KIcons.placeholder,
        selectedIcon: KIcons.placeholder,
        label: (_) => 'Lists',
        order: 310,
        isRootPath: (p) => p == '/lists/a' || p == '/lists/b',
      ),
    )
    ..addRoute(
      GoRoute(
        path: '/lists',
        redirect: (_, state) => state.uri.path == '/lists' ? '/lists/a' : null,
        routes: [
          GoRoute(path: 'a', builder: (_, _) => const Text('list a')),
          GoRoute(
            path: 'b',
            builder: (_, _) => ValueListenableBuilder<bool>(
              valueListenable: _filterOpen,
              builder: (_, open, _) => PopScope(
                canPop: !open,
                onPopInvokedWithResult: (didPop, _) {
                  if (!didPop) _filterOpen.value = false;
                },
                child: const Text('list b'),
              ),
            ),
          ),
          GoRoute(path: 'd', builder: (_, _) => const Text('detail d')),
        ],
      ),
    );
}

/// An open filter: its page claims Back until the first Back closes it.
final _filterOpen = ValueNotifier<bool>(false);

String _location(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .routerDelegate
        .currentConfiguration
        .uri
        .path;

void _push(WidgetTester tester, String path) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first)).push(path);

void _go(WidgetTester tester, String path) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);

/// Records `SystemNavigator.pop` (the app exits) and returns the count.
List<int> _trackExit(WidgetTester tester) {
  final exits = <int>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'SystemNavigator.pop') exits.add(exits.length);
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return exits;
}

Future<bool> _back(WidgetTester tester) async {
  final handled = await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
  return handled;
}

void main() {
  testWidgets(
    'Back: sidebar, then child page, then tab root to Home, then exit',
    (tester) async {
      final exits = _trackExit(tester);
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

      // 4. On Home the shell exits the app.
      expect(exits, isEmpty);
      expect(await _back(tester), isTrue);
      expect(exits, hasLength(1));
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

  group('tab whose root only redirects to a list page', () {
    Future<void> pump(WidgetTester tester) async {
      _filterOpen.value = true;
      await pumpKanaruApp(
        tester,
        extensions: [const NavFixture(), const _Lists()],
        width: 400,
      );
    }

    testWidgets('Back at the list root goes Home and the platform is told '
        'the app handles Back', (tester) async {
      final calls = <bool>[];
      final exits = <int>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
            calls.add(call.arguments as bool);
          } else if (call.method == 'SystemNavigator.pop') {
            exits.add(exits.length);
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
      await pump(tester);
      _go(tester, '/lists/a');
      await tester.pumpAndSettle();
      _go(tester, '/lists');
      await tester.pumpAndSettle();
      expect(_location(tester), '/lists/a');
      expect(calls.last, isTrue);

      expect(await _back(tester), isTrue);
      expect(_location(tester), '/');
      // The hidden tab may keep go_router's own Back claim; the shell still
      // ends Back at Home by exiting the app.
      expect(await _back(tester), isTrue);
      expect(exits, hasLength(1));
    });

    testWidgets('a page that claims Back handles the first Back, the second '
        'goes Home', (tester) async {
      await pump(tester);
      _go(tester, '/lists/b');
      await tester.pumpAndSettle();

      // Back 1 closes the filter; the tab stays.
      expect(await _back(tester), isTrue);
      expect(_filterOpen.value, isFalse);
      expect(_location(tester), '/lists/b');

      // Back 2 leaves the tab.
      expect(await _back(tester), isTrue);
      expect(_location(tester), '/');
    });

    testWidgets('a pushed detail pops first, then the list root goes Home', (
      tester,
    ) async {
      await pump(tester);
      _go(tester, '/lists/a');
      await tester.pumpAndSettle();
      GoRouter.of(tester.element(find.byType(Scaffold).first)).push('/lists/d');
      await tester.pumpAndSettle();
      expect(find.text('detail d'), findsOneWidget);

      expect(await _back(tester), isTrue);
      expect(find.text('detail d'), findsNothing);
      expect(_location(tester), '/lists/a');

      expect(await _back(tester), isTrue);
      expect(_location(tester), '/');
    });

    testWidgets('a detail pushed in the tab, then Home: Back at Home exits', (
      tester,
    ) async {
      final exits = _trackExit(tester);
      await pump(tester);
      _go(tester, '/lists/a');
      await tester.pumpAndSettle();
      _push(tester, '/lists/d');
      _go(tester, '/');
      await tester.pumpAndSettle();
      expect(_location(tester), '/');

      expect(await _back(tester), isTrue);
      expect(exits, hasLength(1));
    });

    testWidgets('a nested child pushed in a tab, then Home: Back exits', (
      tester,
    ) async {
      final exits = _trackExit(tester);
      await pumpKanaruApp(
        tester,
        extensions: [const NavFixture(), const _Child()],
        width: 400,
      );
      _go(tester, '/deep');
      await tester.pumpAndSettle();
      _push(tester, '/deep/child');
      _go(tester, '/');
      await tester.pumpAndSettle();

      expect(await _back(tester), isTrue);
      expect(exits, hasLength(1));
      expect(_location(tester), '/');
    });

    testWidgets('a detail reached with go: Back goes to the tab list, then '
        'Home, then exit', (tester) async {
      final exits = _trackExit(tester);
      await pump(tester);
      _go(tester, '/lists/d');
      await tester.pumpAndSettle();
      expect(find.text('detail d'), findsOneWidget);

      expect(await _back(tester), isTrue);
      expect(_location(tester), '/lists/a');
      expect(await _back(tester), isTrue);
      expect(_location(tester), '/');
      expect(exits, isEmpty);
      expect(await _back(tester), isTrue);
      expect(exits, hasLength(1));
    });
  });
}
