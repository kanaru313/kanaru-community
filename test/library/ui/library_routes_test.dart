import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/library_tabs.dart';
import 'package:kanaru/src/library/state/library_tabs_providers.dart';
import 'package:kanaru/src/library/ui/browse/library_navigation.dart';
import 'package:kanaru/src/library/ui/library_locations.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../browse/support/library_fixture.dart';
import 'support/library_harness.dart';
import 'support/ui_harness.dart';

List<String> _tabLabels(WidgetTester tester) =>
    tester.widget<KSubTabBar>(find.byType(KSubTabBar)).labels;

void main() {
  testWidgets('/library opens the first visible list, then the last one seen', (
    tester,
  ) async {
    final h = await pumpLibrary(tester);
    expect(h.location, '/library/songs');
    h.router.go('/library/albums');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(h.location, '/library/albums');
    h.router.go('/probe');
    await tester.pump();
    h.router.go('/library');
    await tester.pump();
    expect(h.location, '/library/albums');
    await unmountApp(tester);
  });

  testWidgets('every other /library location keeps its place', (tester) async {
    final h = await pumpLibrary(tester);
    for (final location in [
      '/library/albums/abc',
      '/library/folders?at=Zm9vL2Jhcg',
      '/library/languages/_unknown',
    ]) {
      h.router.go(location);
      await tester.pump();
      expect(h.location, location);
    }
    await unmountApp(tester);
  });

  testWidgets('a disabled list is not a sub-tab but its route works', (
    tester,
  ) async {
    final h = await pumpLibrary(tester, initial: '/library/songs');
    expect(_tabLabels(tester), contains('Albums'));
    await h.container
        .read(libraryTabsProvider.notifier)
        .setEnabled(LibraryTab.albums, false);
    await tester.pump();
    expect(_tabLabels(tester), isNot(contains('Albums')));
    h.router.go(LibraryLocations.list(LibraryTab.albums));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(h.location, '/library/albums');
    expect(find.byType(KSubTabBar), findsOneWidget);
    // The last visited list is hidden now: /library falls back to the first
    // visible one.
    h.router.go('/probe');
    await tester.pump();
    h.router.go('/library');
    await tester.pump();
    expect(h.location, '/library/songs');
    await unmountApp(tester);
  });

  testWidgets('opening a page pushes it, Back returns one page', (
    tester,
  ) async {
    final h = await pumpLibrary(tester, initial: '/library/songs');
    final context = tester.element(find.byType(KSubTabBar));
    openLibraryPage<void>(context, '/probe');
    await tester.pumpAndSettle();
    expect(find.text('probe page'), findsOneWidget);
    expect(h.router.canPop(), isTrue);
    h.router.pop();
    await tester.pumpAndSettle();
    expect(h.location, '/library/songs');
    await unmountApp(tester);
  });

  testWidgets('a sub-tab tap switches list and the tab row keeps its place', (
    tester,
  ) async {
    final h = await pumpLibrary(tester);
    final rowBefore = tester.getTopLeft(find.byType(KSubTabBar));
    await tester.tap(find.text('Albums'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(h.location, '/library/albums');
    expect(tester.getTopLeft(find.byType(KSubTabBar)), rowBefore);
    await tester.pump(const Duration(seconds: 1));
    await unmountApp(tester);
  });

  testWidgets('a swipe of more than 60 px moves one list, a short one none', (
    tester,
  ) async {
    final h = await pumpLibrary(tester, initial: '/library/albums');
    await addLibraryTrack(h.db, source: h.sourceId, locator: 'a.flac');
    await h.settle(tester);
    await tester.drag(find.byType(Scaffold).first, const Offset(-40, 0));
    await tester.pump(const Duration(milliseconds: 400));
    expect(h.location, '/library/albums');
    await tester.drag(find.byType(Scaffold).first, const Offset(-120, 0));
    await tester.pump(const Duration(milliseconds: 400));
    expect(h.location, '/library/artists');
    await tester.drag(find.byType(Scaffold).first, const Offset(120, 0));
    await tester.pump(const Duration(milliseconds: 400));
    expect(h.location, '/library/albums');
    await unmountApp(tester);
  });

  testWidgets('the list body slides in, the header stays', (tester) async {
    final h = await pumpLibrary(tester, initial: '/library/songs');
    await addLibraryTrack(h.db, source: h.sourceId, locator: 'a.flac');
    await h.settle(tester);
    final header = tester.getTopLeft(find.byType(PageHeader));
    h.router.go('/library/albums');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    // Mid-slide: the body is still moving, the header is not.
    expect(tester.getTopLeft(find.byType(PageHeader)), header);
    await tester.pump(const Duration(seconds: 1));
    await unmountApp(tester);
  });

  testWidgets('desktop has no sub-tab row and titles the page by its list', (
    tester,
  ) async {
    final h = await pumpLibrary(
      tester,
      initial: '/library/albums',
      width: 1280,
      height: 800,
    );
    expect(find.byType(KSubTabBar), findsNothing);
    expect(
      find.descendant(
        of: find.byType(PageHeader),
        matching: find.text('Albums'),
      ),
      findsOneWidget,
    );
    expect(h.location, '/library/albums');
    await unmountApp(tester);
  });
}
