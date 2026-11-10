import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/kanaru.dart';
import 'package:kanaru/src/shell/state/mobile_sidebar_state.dart';
import 'package:kanaru/src/shell/ui/mobile_sidebar.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/app_harness.dart';
import '../support/nav_fixture.dart';

/// A tab with a child item, to check that sub-items navigate by path.
class _Kid implements KanaruExtension {
  const _Kid();
  @override
  String get id => 'kid';
  @override
  void register(ExtensionRegistry r) {
    NavItem item(String id, String path, int order, {String? parentId}) =>
        NavItem(
          id: id,
          path: path,
          icon: KIcons.placeholder,
          selectedIcon: KIcons.placeholder,
          label: (_) => id[0].toUpperCase() + id.substring(1),
          order: order,
          mobileTab: parentId == null,
          parentId: parentId,
        );
    r
      ..addNavItem(item('parent', '/parent', 130))
      ..addNavItem(item('kid', '/parent/kid', 140, parentId: 'parent'))
      ..addRoute(
        GoRoute(
          path: '/parent',
          builder: (_, _) => const Text('parent page'),
          routes: [
            GoRoute(path: 'kid', builder: (_, _) => const Text('kid page')),
          ],
        ),
      );
  }
}

Future<_Handle> _pump(WidgetTester tester) async {
  final c = await pumpKanaruApp(
    tester,
    extensions: [const NavFixture(), const _Kid()],
    width: 400,
  );
  return _Handle(c);
}

class _Handle {
  _Handle(this.container);
  final ProviderContainer container;
  bool get open => container.read(mobileSidebarOpenProvider);
}

String _location(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .routerDelegate
        .currentConfiguration
        .uri
        .path;

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Menu').first);
  await tester.pumpAndSettle();
}

Finder _row(String label) =>
    find.descendant(of: find.byType(MobileSidebar), matching: find.text(label));

Finder _tab(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

/// A point on the dimmed content (the sidebar is 256 wide, window 400).
const _scrim = Offset(340, 400);

void main() {
  testWidgets('closed: the sidebar is not shown', (tester) async {
    final h = await _pump(tester);
    expect(h.open, isFalse);
    expect(find.byType(MobileSidebar), findsNothing);
  });

  testWidgets('the header menu button opens it: head, items, footer', (
    tester,
  ) async {
    final h = await _pump(tester);
    await _open(tester);
    expect(h.open, isTrue);
    expect(_row('Kanaru'), findsOneWidget);
    for (final label in [
      'Alpha',
      'Beta',
      'Gamma',
      'Parent',
      'Soon',
      'Kid',
      'Gear',
    ]) {
      expect(_row(label), findsOneWidget, reason: label);
    }
    // Content slid right by the sidebar width.
    final page = tester.getTopLeft(find.byType(NavigationBar));
    expect(page.dx, closeTo(256, 1));
  });

  testWidgets('a tap on the dimmed content closes it', (tester) async {
    final h = await _pump(tester);
    await _open(tester);
    await tester.tapAt(_scrim);
    await tester.pumpAndSettle();
    expect(h.open, isFalse);
    expect(tester.getTopLeft(find.byType(NavigationBar)).dx, closeTo(0, 1));
  });

  testWidgets('after closing, the page underneath takes taps again', (
    tester,
  ) async {
    final h = await _pump(tester);
    await _open(tester);
    await tester.tapAt(_scrim);
    await tester.pumpAndSettle();
    expect(h.open, isFalse);
    // The scrim is gone, not just transparent: the spring ends exactly at 0.
    expect(find.bySemanticsLabel('Close menu'), findsNothing);
    await tester.tap(_tab('Beta'));
    await tester.pumpAndSettle();
    expect(_location(tester), '/beta');
  });

  testWidgets('dragging the content left closes it from 61 dp, not 59', (
    tester,
  ) async {
    final h = await _pump(tester);
    await _open(tester);
    await tester.dragFrom(_scrim, const Offset(-59, 0));
    await tester.pumpAndSettle();
    expect(h.open, isTrue);
    await tester.dragFrom(_scrim, const Offset(-61, 0));
    await tester.pumpAndSettle();
    expect(h.open, isFalse);
  });

  testWidgets('Back closes it first and leaves the page alone', (tester) async {
    final h = await _pump(tester);
    await tester.tap(_tab('Beta'));
    await tester.pumpAndSettle();
    await _open(tester);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(h.open, isFalse);
    expect(_location(tester), '/beta');
  });

  testWidgets('choosing a tab item goes to that tab and closes', (
    tester,
  ) async {
    final h = await _pump(tester);
    await _open(tester);
    await tester.tap(_row('Beta'));
    await tester.pumpAndSettle();
    expect(_location(tester), '/beta');
    expect(h.open, isFalse);
  });

  testWidgets('choosing a sub-item goes to its path', (tester) async {
    await _pump(tester);
    await _open(tester);
    await tester.tap(_row('Kid'));
    await tester.pumpAndSettle();
    expect(_location(tester), '/parent/kid');
    expect(find.text('kid page'), findsOneWidget);
  });

  testWidgets('Settings is pushed full screen', (tester) async {
    await _pump(tester);
    await _open(tester);
    await tester.tap(_row('Gear'));
    await tester.pumpAndSettle();
    expect(find.text('page /gear'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('the highlighted item only closes the sidebar', (tester) async {
    final h = await _pump(tester);
    GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/parent/kid');
    await tester.pumpAndSettle();
    // The page has no header, so open it through the state.
    h.container.read(mobileSidebarOpenProvider.notifier).open();
    await tester.pumpAndSettle();
    // On /parent/kid the highlighted item is Kid; choosing it must not
    // navigate again.
    await tester.tap(_row('Kid'));
    await tester.pumpAndSettle();
    expect(h.open, isFalse);
    expect(_location(tester), '/parent/kid');
  });

  testWidgets('a coming-soon item is dimmed with a label and inert', (
    tester,
  ) async {
    final h = await _pump(tester);
    await _open(tester);
    expect(_row('Coming soon'), findsOneWidget);
    final label = tester.widget<Text>(_row('Soon'));
    final scheme = Theme.of(tester.element(_row('Soon'))).colorScheme;
    expect(label.style?.color, scheme.onSurface.withValues(alpha: 0.38));
    await tester.tap(_row('Soon'));
    await tester.pumpAndSettle();
    expect(h.open, isTrue);
    expect(_location(tester), '/');
  });

  testWidgets('rows are at least 48 dp tall', (tester) async {
    await _pump(tester);
    await _open(tester);
    expect(
      tester
          .getSize(
            find
                .ancestor(of: _row('Beta'), matching: find.byType(InkWell))
                .first,
          )
          .height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('reduced motion opens it at once', (tester) async {
    final h = await _pump(tester);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pump();
    await tester.tap(find.byTooltip('Menu').first);
    await tester.pump();
    await tester.pump();
    expect(h.open, isTrue);
    expect(tester.getTopLeft(find.byType(NavigationBar)).dx, closeTo(256, 1));
  });

  testWidgets('an open sidebar survives a trip through the desktop shell', (
    tester,
  ) async {
    final h = await _pump(tester);
    await _open(tester);
    expect(h.open, isTrue);

    tester.view.physicalSize = const Size(1300, 800);
    await tester.pumpAndSettle();
    expect(find.byType(MobileSidebar), findsNothing); // desktop shell
    tester.view.physicalSize = const Size(400, 800);
    await tester.pumpAndSettle();

    // The new mobile shell shows what the state says: open, content pushed,
    // and the dimmed content closes it with one tap (no invisible scrim).
    expect(h.open, isTrue);
    expect(tester.getTopLeft(find.byType(NavigationBar)).dx, closeTo(256, 1));
    await tester.tapAt(_scrim);
    await tester.pumpAndSettle();
    expect(h.open, isFalse);
    expect(tester.getTopLeft(find.byType(NavigationBar)).dx, closeTo(0, 1));
  });
}
