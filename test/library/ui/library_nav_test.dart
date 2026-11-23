import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/library/ui/library_locations.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/app_harness.dart';
import 'support/ui_harness.dart';

/// The navigation the public app ships: sidebar list and order, mobile bar
/// and the Library page. Shell mechanics are tested with a synthetic
/// navigation in `test/shell`.
Finder _byTooltip(String message) =>
    find.byWidgetPredicate((w) => w is Tooltip && w.message == message);

/// Selection state of the sidebar row [label], read from semantics.
bool _isSelected(WidgetTester tester, String label) =>
    tester
        .getSemantics(
          find
              .ancestor(of: find.text(label), matching: find.byType(KNavRow))
              .first,
        )
        .flagsCollection
        .isSelected ==
    Tristate.isTrue;

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

    testWidgets('no item is coming soon; Queue is live and opens its page', (
      tester,
    ) async {
      await pumpKanaruApp(tester);
      // The dimmed "Coming soon" state is covered with a synthetic navigation
      // in `test/shell`; the shipped navigation has no such item left.
      expect(_byTooltip('Coming soon'), findsNothing);
      expect(_isSelected(tester, 'Queue'), isFalse);
      await tester.tap(find.text('Queue'));
      await tester.pumpAndSettle();
      expect(
        GoRouter.of(tester.element(find.byType(Scaffold).first))
            .routerDelegate
            .currentConfiguration
            .uri
            .path,
        LibraryLocations.savedQueues,
      );
      expect(_isSelected(tester, 'Queue'), isTrue);
      expect(_isSelected(tester, 'Home'), isFalse);
      await unmountApp(tester);
    });

    testWidgets('the item of the open page is selected', (tester) async {
      await pumpKanaruApp(tester);
      expect(_isSelected(tester, 'Home'), isTrue);
      expect(_isSelected(tester, 'Songs'), isFalse);
      await tester.tap(find.text('Songs'));
      await tester.pumpAndSettle();
      expect(_isSelected(tester, 'Songs'), isTrue);
      expect(_isSelected(tester, 'Albums'), isFalse);
      expect(_isSelected(tester, 'Home'), isFalse);
      await unmountApp(tester);
    });

    testWidgets('a detail page keeps its list lit in the sidebar', (
      tester,
    ) async {
      await pumpKanaruApp(tester);
      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
      for (final (location, label) in [
        (LibraryLocations.album(AlbumKey('a', 'b')), 'Albums'),
        (LibraryLocations.artist(ArtistKey('a')), 'Artists'),
        ('${LibraryLocations.artist(ArtistKey('a'))}/albums', 'Artists'),
        (LibraryLocations.genre('rock'), 'Genres'),
        (LibraryLocations.language('eng'), 'Languages'),
      ]) {
        unawaited(router.push(location));
        await tester.pumpAndSettle();
        expect(_isSelected(tester, label), isTrue, reason: location);
        expect(_isSelected(tester, 'Songs'), isFalse);
      }
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
