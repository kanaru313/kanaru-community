import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/kanaru.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/app_harness.dart';
import '../support/nav_fixture.dart';

NavItem _item(String id, String path, int order) => NavItem(
  id: id,
  path: path,
  icon: KIcons.placeholder,
  selectedIcon: KIcons.placeholder,
  label: (_) => id,
  order: order,
  mobileTab: false,
);

/// Two pages the fixture lacks: one with a menu, one with a text field.
class _Pages implements KanaruExtension {
  const _Pages();
  @override
  String get id => 'history-pages';
  @override
  void register(ExtensionRegistry r) => r
    ..addNavItem(_item('menu', '/menu', 300))
    ..addNavItem(_item('field', '/field', 310))
    ..addRoute(
      GoRoute(
        path: '/menu',
        builder: (_, _) => Scaffold(
          body: Row(
            children: [
              MenuAnchor(
                menuChildren: const [MenuItemButton(child: Text('menu entry'))],
                builder: (context, controller, _) => TextButton(
                  onPressed: controller.open,
                  child: const Text('open menu'),
                ),
              ),
              PopupMenuButton<int>(
                child: const Text('open popup'),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 1, child: Text('popup entry')),
                ],
              ),
            ],
          ),
        ),
      ),
    )
    ..addRoute(
      GoRoute(
        path: '/field',
        builder: (_, _) => const Scaffold(
          body: TextField(autofocus: true, key: ValueKey('field')),
        ),
      ),
    );
}

Future<void> _pump(WidgetTester tester) => pumpKanaruApp(
  tester,
  extensions: [const NavFixture(), const _Pages()],
  width: 1280,
);

String _location(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .routerDelegate
        .currentConfiguration
        .uri
        .path;

void _go(WidgetTester tester, String path) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);

Future<void> _alt(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
  await tester.pumpAndSettle();
}

Future<void> _esc(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await tester.pumpAndSettle();
}

Future<void> _mouse(WidgetTester tester, int button) async {
  final g = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
    buttons: button,
  );
  await g.down(const Offset(600, 400));
  await g.up();
  await tester.pumpAndSettle();
}

/// Moves focus into the shell, the way Tab does.
Future<void> _focusShell(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pump();
  expect(FocusManager.instance.primaryFocus, isNotNull);
  expect(
    FocusManager.instance.primaryFocus,
    isNot(FocusManager.instance.rootScope),
  );
}

void main() {
  for (final focused in [false, true]) {
    final mode = focused ? 'with focus in the shell' : 'with nothing focused';
    group('history keys $mode', () {
      testWidgets('Alt+Left goes back and Alt+Right forward, once each', (
        tester,
      ) async {
        await _pump(tester);
        _go(tester, '/beta');
        await tester.pumpAndSettle();
        _go(tester, '/gamma');
        await tester.pumpAndSettle();
        if (focused) await _focusShell(tester);

        await _alt(tester, LogicalKeyboardKey.arrowLeft);
        expect(_location(tester), '/beta');
        await _alt(tester, LogicalKeyboardKey.arrowRight);
        expect(_location(tester), '/gamma');
      });

      testWidgets('Esc goes back; with nothing to go back to it does nothing', (
        tester,
      ) async {
        await _pump(tester);
        _go(tester, '/beta');
        await tester.pumpAndSettle();
        if (focused) await _focusShell(tester);

        await _esc(tester);
        expect(_location(tester), '/');
        await _esc(tester);
        expect(_location(tester), '/');
      });
    });
  }

  testWidgets('mouse Back and Forward walk the history', (tester) async {
    await _pump(tester);
    _go(tester, '/beta');
    await tester.pumpAndSettle();
    await _mouse(tester, kBackMouseButton);
    expect(_location(tester), '/');
    await _mouse(tester, kForwardMouseButton);
    expect(_location(tester), '/beta');
  });

  testWidgets('Esc with a dialog open closes only the dialog', (tester) async {
    await _pump(tester);
    _go(tester, '/beta');
    await tester.pumpAndSettle();
    showKDialog<void>(
      tester.element(find.byType(Scaffold).first),
      builder: (_) => const AlertDialog(content: Text('a dialog')),
    );
    await tester.pumpAndSettle();
    expect(find.text('a dialog'), findsOneWidget);

    await _esc(tester);
    expect(find.text('a dialog'), findsNothing);
    expect(_location(tester), '/beta');
  });

  testWidgets('Esc with a sheet open closes only the sheet', (tester) async {
    await _pump(tester);
    _go(tester, '/beta');
    await tester.pumpAndSettle();
    showKSheet<void>(
      tester.element(find.byType(Scaffold).first),
      builder: (_) => const SizedBox(height: 200, child: Text('a sheet')),
    );
    await tester.pumpAndSettle();
    expect(find.text('a sheet'), findsOneWidget);

    await _esc(tester);
    expect(find.text('a sheet'), findsNothing);
    expect(_location(tester), '/beta');
  });

  testWidgets('Esc with a menu open closes only the menu', (tester) async {
    await _pump(tester);
    _go(tester, '/menu');
    await tester.pumpAndSettle();
    await tester.tap(find.text('open menu'));
    await tester.pumpAndSettle();
    expect(find.text('menu entry'), findsOneWidget);

    await _esc(tester);
    expect(find.text('menu entry'), findsNothing);
    expect(_location(tester), '/menu');
  });

  testWidgets('mouse Back while a popup menu is open does nothing', (
    tester,
  ) async {
    await _pump(tester);
    _go(tester, '/menu');
    await tester.pumpAndSettle();
    await tester.tap(find.text('open popup'));
    await tester.pumpAndSettle();
    expect(find.text('popup entry'), findsOneWidget);

    await _mouse(tester, kBackMouseButton);
    expect(_location(tester), '/menu');
  });

  testWidgets('a focused text field keeps Esc, Alt+Left still goes back', (
    tester,
  ) async {
    await _pump(tester);
    _go(tester, '/field');
    await tester.pumpAndSettle();
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<EditableText>(),
      isNotNull,
    );

    await _esc(tester);
    expect(_location(tester), '/field');
    await _alt(tester, LogicalKeyboardKey.arrowLeft);
    expect(_location(tester), '/');
  });
}
