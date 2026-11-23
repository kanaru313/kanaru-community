import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/kanaru.dart';
import 'package:kanaru/src/shell/state/mobile_sidebar_state.dart';
import 'package:kanaru/src/shell/state/nav_history.dart';
import 'package:kanaru/src/shell/ui/desktop_top_bar.dart';
import 'package:kanaru/src/shell/ui/mobile_sidebar.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/app_harness.dart';
import '../support/nav_fixture.dart';

/// A list tab with detail pages that are opened with `push`.
class _Pushed implements KanaruExtension {
  const _Pushed();
  @override
  String get id => 'pushed-pages';
  @override
  void register(ExtensionRegistry r) {
    r
      ..addNavItem(
        NavItem(
          id: 'albums',
          path: '/albums',
          icon: KIcons.placeholder,
          selectedIcon: KIcons.placeholder,
          label: (_) => 'Albums',
          order: 120,
          mobileTab: true,
        ),
      )
      ..addNavItem(
        NavItem(
          id: 'prefs',
          path: '/prefs',
          icon: KIcons.placeholder,
          selectedIcon: KIcons.placeholder,
          label: (_) => 'Prefs',
          order: 950,
          mobileTab: false,
          footer: true,
        ),
      )
      ..addRoute(
        GoRoute(
          path: '/prefs',
          builder: (_, _) => const Scaffold(body: Text('prefs root')),
          routes: [
            GoRoute(
              path: 'sub',
              builder: (_, _) => const Scaffold(body: Text('prefs sub')),
            ),
          ],
        ),
      )
      ..addRoute(
        GoRoute(
          path: '/albums',
          builder: (_, _) => const Scaffold(body: Text('albums list')),
          routes: [
            GoRoute(
              path: 'a/:id',
              builder: (_, s) =>
                  Scaffold(body: Text('detail ${s.pathParameters['id']}')),
            ),
          ],
        ),
      );
  }
}

GoRouter _router(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first));

/// Pages in the router's current stack: base uri plus pushed pages.
int _pushedCount(WidgetTester tester) {
  var n = 0;
  void walk(List<RouteMatchBase> ms) {
    for (final m in ms) {
      if (m is ImperativeRouteMatch) n++;
      if (m is ShellRouteMatch) walk(m.matches);
    }
  }

  walk(_router(tester).routerDelegate.currentConfiguration.matches);
  return n;
}

String _top(WidgetTester tester) =>
    _router(tester).routerDelegate.currentConfiguration.last.matchedLocation;

Future<void> _push(WidgetTester tester, String path) async {
  _router(tester).push<void>(path);
  await tester.pumpAndSettle();
}

Future<void> _pop(WidgetTester tester) async {
  _router(tester).pop();
  await tester.pumpAndSettle();
}

Future<void> _pumpDesktop(WidgetTester tester) => pumpKanaruApp(
  tester,
  extensions: [const NavFixture(), const _Pushed()],
  width: 1280,
);

Finder _sidebarRow(String label) => find.descendant(
  of: find.byKey(const ValueKey('sidebar')),
  matching: find.text(label),
);

void main() {
  group('desktop NavHistory records pushed pages', () {
    NavHistory? history; // set per test
    Future<void> back(WidgetTester t) async {
      history!.back();
      await t.pumpAndSettle();
    }

    Future<void> fwd(WidgetTester t) async {
      history!.forward();
      await t.pumpAndSettle();
    }

    Future<void> setUp(WidgetTester tester) async {
      await _pumpDesktop(tester);
      history = null;
      // The shell owns the history; read it through its widget.
      history = tester
          .widget<DesktopTopBar>(find.byType(DesktopTopBar))
          .history;
    }

    testWidgets('A -> push B -> push C: back walks C, B, A', (tester) async {
      await setUp(tester);
      _router(tester).go('/albums/a/1');
      await tester.pumpAndSettle();
      await _push(tester, '/albums/a/2');
      await _push(tester, '/albums/a/3');
      expect(_top(tester), '/albums/a/3');

      await back(tester);
      expect(_top(tester), '/albums/a/2');
      await back(tester);
      expect(_top(tester), '/albums/a/1');
      await fwd(tester);
      expect(_top(tester), '/albums/a/2');
      await fwd(tester);
      expect(_top(tester), '/albums/a/3');
    });

    testWidgets('popping a page counts as back and keeps forward', (
      tester,
    ) async {
      await setUp(tester);
      _router(tester).go('/albums');
      await tester.pumpAndSettle();
      await _push(tester, '/albums/a/1');
      await _pop(tester);
      expect(history!.canGoBack, isTrue);
      expect(history!.canGoForward, isTrue);
      await fwd(tester);
      expect(_top(tester), '/albums/a/1');
      // Double pop: the restored page has a fresh completer.
      await _pop(tester);
      expect(_pushedCount(tester), 0);
      await fwd(tester);
      expect(_top(tester), '/albums/a/1');
      await _pop(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('pop, forward, pop again: fresh completer, no throw', (
      tester,
    ) async {
      await setUp(tester);
      _router(tester).go('/albums');
      await tester.pumpAndSettle();
      await _push(tester, '/albums/a/1');
      _router(tester).pop();
      await tester.pumpAndSettle();
      await fwd(tester);
      expect(_pushedCount(tester), 1);
      _router(tester).pop();
      await tester.pumpAndSettle();
      await fwd(tester);
      _router(tester).pop();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(_pushedCount(tester), 0);
    });

    testWidgets('tab ping-pong Home -> Albums -> Home is three entries', (
      tester,
    ) async {
      await setUp(tester);
      _router(tester).go('/albums');
      await tester.pumpAndSettle();
      _router(tester).go('/');
      await tester.pumpAndSettle();
      expect(history!.canGoBack, isTrue);
      expect(history!.canGoForward, isFalse);
      await back(tester);
      expect(_top(tester), '/albums');
      expect(history!.canGoBack, isTrue);
      await back(tester);
      expect(_top(tester), '/');
      expect(history!.canGoBack, isFalse);
    });

    testWidgets('X -> A -> B -> A walks back through B', (tester) async {
      await setUp(tester);
      _router(tester).go('/beta');
      await tester.pumpAndSettle();
      _router(tester).go('/albums');
      await tester.pumpAndSettle();
      _router(tester).go('/gamma');
      await tester.pumpAndSettle();
      _router(tester).go('/albums');
      await tester.pumpAndSettle();
      await back(tester);
      expect(_top(tester), '/gamma');
      await back(tester);
      expect(_top(tester), '/albums');
      await back(tester);
      expect(_top(tester), '/beta');
    });

    testWidgets('context.replace is a new visit; back restores the old page', (
      tester,
    ) async {
      await setUp(tester);
      _router(tester).go('/albums');
      await tester.pumpAndSettle();
      await _push(tester, '/albums/a/1');
      _router(tester).replace<void>('/albums/a/2');
      await tester.pumpAndSettle();
      expect(_top(tester), '/albums/a/2');
      expect(_pushedCount(tester), 1);
      await back(tester);
      expect(_top(tester), '/albums/a/1');
      expect(_pushedCount(tester), 1);
      await fwd(tester);
      expect(_top(tester), '/albums/a/2');
      await _pop(tester);
      expect(tester.takeException(), isNull);
      expect(_pushedCount(tester), 0);
    });

    testWidgets('history is capped at 50 entries', (tester) async {
      await setUp(tester);
      for (var i = 0; i < 60; i++) {
        _router(tester).go(i.isEven ? '/beta' : '/gamma');
        await tester.pump();
      }
      await tester.pumpAndSettle();
      var steps = 0;
      while (history!.canGoBack) {
        history!.back();
        await tester.pump();
        steps++;
      }
      expect(steps, 49);
    });

    testWidgets('back/forward restore a page pushed on another branch', (
      tester,
    ) async {
      await setUp(tester);
      _router(tester).go('/albums');
      await tester.pumpAndSettle();
      await _push(tester, '/albums/a/1');
      _router(tester).go('/beta');
      await tester.pumpAndSettle();
      await back(tester);
      expect(_top(tester), '/albums/a/1');
      await fwd(tester);
      expect(_top(tester), '/beta');
      expect(_pushedCount(tester), 0);
      await back(tester);
      expect(_pushedCount(tester), 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('back to an entry whose pages were popped does not throw', (
      tester,
    ) async {
      await setUp(tester);
      _router(tester).go('/albums');
      await tester.pumpAndSettle();
      await _push(tester, '/albums/a/1');
      _router(tester).go('/beta');
      await tester.pumpAndSettle();
      await back(tester);
      expect(_top(tester), '/albums/a/1');
      await _pop(tester);
      expect(tester.takeException(), isNull);
      expect(_pushedCount(tester), 0);
    });
  });

  group('desktop sidebar', () {
    testWidgets('another tab keeps its sub-page', (tester) async {
      await _pumpDesktop(tester);
      _router(tester).go('/albums');
      await tester.pumpAndSettle();
      await _push(tester, '/albums/a/1');
      await tester.tap(_sidebarRow('Beta'));
      await tester.pumpAndSettle();
      expect(_top(tester), '/beta');
      await tester.tap(_sidebarRow('Albums'));
      await tester.pumpAndSettle();
      expect(_top(tester), '/albums/a/1');
    });

    testWidgets('re-selecting the open tab opens its root', (tester) async {
      await _pumpDesktop(tester);
      _router(tester).go('/albums');
      await tester.pumpAndSettle();
      await _push(tester, '/albums/a/1');
      await tester.tap(_sidebarRow('Albums'));
      await tester.pumpAndSettle();
      expect(_top(tester), '/albums');
      expect(_pushedCount(tester), 0);
    });

    testWidgets('the footer item opens its root from another tab', (
      tester,
    ) async {
      await _pumpDesktop(tester);
      _router(tester).go('/prefs/sub');
      await tester.pumpAndSettle();
      await tester.tap(_sidebarRow('Beta'));
      await tester.pumpAndSettle();
      await tester.tap(_sidebarRow('Prefs'));
      await tester.pumpAndSettle();
      expect(_top(tester), '/prefs');
    });
  });

  group('mobile sidebar re-select', () {
    Future<ProviderContainer> pump(WidgetTester tester) => pumpKanaruApp(
      tester,
      extensions: [const NavFixture(), const _Pushed()],
      width: 400,
    );

    testWidgets('pushed detail: Albums returns to the list and closes', (
      tester,
    ) async {
      final c = await pump(tester);
      _router(tester).go('/albums');
      await tester.pumpAndSettle();
      await _push(tester, '/albums/a/1');
      c.read(mobileSidebarOpenProvider.notifier).open();
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(MobileSidebar),
          matching: find.text('Albums'),
        ),
      );
      await tester.pumpAndSettle();
      expect(_top(tester), '/albums');
      expect(_pushedCount(tester), 0);
      expect(c.read(mobileSidebarOpenProvider), isFalse);
    });

    testWidgets('at the list root: only closes the sidebar', (tester) async {
      final c = await pump(tester);
      _router(tester).go('/albums');
      await tester.pumpAndSettle();
      c.read(mobileSidebarOpenProvider.notifier).open();
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(MobileSidebar),
          matching: find.text('Albums'),
        ),
      );
      await tester.pumpAndSettle();
      expect(_top(tester), '/albums');
      expect(c.read(mobileSidebarOpenProvider), isFalse);
    });
  });
}
