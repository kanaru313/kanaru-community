import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/app_harness.dart';
import 'support/ui_harness.dart';

/// The navigation the public app ships: sidebar list and order, mobile bar
/// and the Library page. Shell mechanics are tested with a synthetic
/// navigation in `test/shell`.
Finder _byTooltip(String message) =>
    find.byWidgetPredicate((w) => w is Tooltip && w.message == message);

Color? _rowColor(WidgetTester tester, String label) {
  final material = find
      .ancestor(of: find.text(label), matching: find.byType(Material))
      .first;
  return tester.widget<Material>(material).color;
}

void main() {
  group('desktop sidebar', () {
    testWidgets(
      'lists every item in order, dividers between bands, no Search',
      (tester) async {
        await pumpKanaruApp(tester);
        final sidebar = find.byKey(const ValueKey('sidebar'));
        const labels = [
          'Home',
          'Online',
          'Songs',
          'Albums',
          'Artists',
          'Genres',
          'Languages',
          'Folders',
          'Playlists',
          'Favorites',
          'Queue',
          'History',
          'Most played',
          'Settings',
        ];
        double? previous;
        for (final label in labels) {
          final item = find.descendant(of: sidebar, matching: find.text(label));
          expect(item, findsOneWidget, reason: label);
          final y = tester.getTopLeft(item).dy;
          expect(y, greaterThan(previous ?? -1), reason: label);
          previous = y;
        }
        expect(
          find.descendant(of: sidebar, matching: find.text('Search')),
          findsNothing,
        );
        expect(
          find.descendant(of: sidebar, matching: find.byType(Divider)),
          findsNWidgets(2),
        );
      },
    );

    testWidgets('out-of-scope items are dimmed with a tooltip and do nothing', (
      tester,
    ) async {
      await pumpKanaruApp(tester);
      // Favorites, Queue, History, Most played.
      expect(_byTooltip('Coming soon'), findsNWidgets(4));
      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();
      expect(find.text('Your library is empty.'), findsNothing);
    });

    testWidgets('the item of the open page is tinted', (tester) async {
      await pumpKanaruApp(tester);
      final scheme = Theme.of(tester.element(find.byType(Scaffold).first))
          .colorScheme;
      expect(_rowColor(tester, 'Home'), scheme.secondaryContainer);
      expect(_rowColor(tester, 'Songs'), Colors.transparent);
      await tester.tap(find.text('Songs'));
      await tester.pumpAndSettle();
      expect(_rowColor(tester, 'Songs'), scheme.secondaryContainer);
      expect(_rowColor(tester, 'Albums'), Colors.transparent);
      expect(_rowColor(tester, 'Home'), Colors.transparent);
      await unmountApp(tester);
    });

    testWidgets('Search opens from the page header and has its own page', (
      tester,
    ) async {
      await pumpKanaruApp(tester);
      await tester.tap(_byTooltip('Search'));
      await tester.pumpAndSettle();
      expect(find.text('Search your music.'), findsOneWidget);
    });

    testWidgets('Back and Forward follow the Library pages', (tester) async {
      await pumpKanaruApp(tester);
      await tester.tap(find.text('Songs'));
      await tester.pumpAndSettle();
      expect(find.text('Library is empty'), findsOneWidget);
      await tester.tap(_byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Library is empty'), findsNothing);
      await tester.tap(_byTooltip('Forward'));
      await tester.pumpAndSettle();
      expect(find.text('Library is empty'), findsOneWidget);
      await unmountApp(tester);
    });
  });

  group('mobile bar', () {
    testWidgets('five destinations in order, Search is a tab', (tester) async {
      await pumpKanaruApp(tester, width: 360);
      final labels = [
        for (final d in tester.widgetList<NavigationDestination>(
          find.byType(NavigationDestination),
        ))
          d.label,
      ];
      expect(labels, ['Home', 'Library', 'Playlists', 'Search', 'Online']);
    });

    testWidgets('the Library tab shows the Songs list under sub-tabs', (
      tester,
    ) async {
      await pumpKanaruApp(tester, width: 360);
      expect(find.text('Library is empty'), findsNothing);
      await tester.tap(_byTooltip('Library'));
      await tester.pumpAndSettle();
      expect(find.text('Library is empty'), findsOneWidget);
      expect(find.byType(KSubTabBar), findsOneWidget);
      await unmountApp(tester);
    });

    testWidgets('no header search icon, only the tab', (tester) async {
      await pumpKanaruApp(tester, width: 360);
      expect(_byTooltip('Search'), findsOneWidget);
    });

    testWidgets('labels follow the locale', (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('vi')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await pumpKanaruApp(tester, width: 360);
      expect(_byTooltip('Thư viện'), findsOneWidget);
    });
  });
}
