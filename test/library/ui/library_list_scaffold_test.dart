import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/scan_status.dart';
import 'package:kanaru/src/library/state/browse/list_prefs_providers.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../browse/support/library_fixture.dart';
import 'support/library_harness.dart';
import 'support/ui_harness.dart';

Widget _scope(Widget child) => PageHeaderScope(
  leading: const Text('LEAD'),
  rootTrailing: const [Text('ROOT-ACTION')],
  trailing: const [Text('SEARCH')],
  child: child,
);

void main() {
  testWidgets('a root list shows the shell header slots, a pushed page not', (
    tester,
  ) async {
    final h = await pumpLibrary(
      tester,
      initial: '/library/songs',
      header: _scope,
    );
    expect(find.text('LEAD'), findsOneWidget);
    expect(find.text('ROOT-ACTION'), findsOneWidget);
    expect(find.text('SEARCH'), findsOneWidget);
    h.router.push('/probe');
    await tester.pumpAndSettle();
    expect(find.text('Probe'), findsOneWidget);
    expect(find.text('LEAD'), findsNothing);
    expect(find.text('ROOT-ACTION'), findsNothing);
    expect(find.text('SEARCH'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('an empty library shows the empty state and no list bar', (
    tester,
  ) async {
    await pumpLibrary(tester, initial: '/library/albums');
    expect(find.text('Library is empty'), findsOneWidget);
    expect(find.text('No songs in the chosen folders.'), findsOneWidget);
    expect(find.byType(KListSortFilterBar), findsNothing);
    // Dimmed until the settings screen for folders exists.
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(find.byTooltip('Coming soon'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('the list bar appears once there is a song', (tester) async {
    final h = await pumpLibrary(tester, initial: '/library/albums');
    await addLibraryTrack(h.db, source: h.sourceId, locator: 'a.flac');
    await h.settle(tester);
    expect(find.text('Library is empty'), findsNothing);
    expect(find.byType(KListSortFilterBar), findsOneWidget);
    await unmountApp(tester);
  });

  group('scan banner', () {
    Future<void> check(
      WidgetTester tester,
      ScanStatus scan,
      String text, {
      required bool bar,
    }) async {
      final h = await pumpLibrary(
        tester,
        initial: '/library/songs',
        scan: scan,
      );
      await addLibraryTrack(h.db, source: h.sourceId, locator: 'a.flac');
      await h.settle(tester);
      expect(find.text(text), findsOneWidget);
      expect(
        find.byType(LinearProgressIndicator),
        bar ? findsOneWidget : findsNothing,
      );
      await unmountApp(tester);
    }

    testWidgets('listing has no count', (tester) async {
      await check(
        tester,
        const ScanRunning(phase: ScanPhase.listing, done: 0, total: 0),
        'Scanning…',
        bar: false,
      );
    });

    testWidgets('tags show songs done of total with a bar', (tester) async {
      await check(
        tester,
        const ScanRunning(phase: ScanPhase.tags, done: 120, total: 242),
        'Scanning · 120 / 242 songs',
        bar: true,
      );
    });

    testWidgets('an unknown total shows only the count', (tester) async {
      await check(
        tester,
        const ScanRunning(phase: ScanPhase.tags, done: 120, total: 0),
        'Scanning · 120 songs',
        bar: false,
      );
    });

    testWidgets('covers count covers', (tester) async {
      await check(
        tester,
        const ScanRunning(phase: ScanPhase.covers, done: 3, total: 9),
        'Fetching covers · 3 / 9',
        bar: true,
      );
    });

    testWidgets('missing music permission shows its line over the songs', (
      tester,
    ) async {
      final h = await pumpLibrary(
        tester,
        initial: '/library/songs',
        scan: const ScanFailed('permission'),
      );
      await addLibraryTrack(h.db, source: h.sourceId, locator: 'a.flac');
      await h.settle(tester);
      expect(find.text('Missing permission to read music'), findsOneWidget);
      expect(find.text('Grant'), findsOneWidget);
      expect(h.songTitles(tester).length, 1);
      await unmountApp(tester);
    });

    testWidgets('an idle scan shows no banner', (tester) async {
      final h = await pumpLibrary(tester, initial: '/library/songs');
      await addLibraryTrack(h.db, source: h.sourceId, locator: 'a.flac');
      await h.settle(tester);
      expect(find.textContaining('Scanning'), findsNothing);
      await unmountApp(tester);
    });
  });

  testWidgets('a scan with no song yet shows the list, not the empty state', (
    tester,
  ) async {
    await pumpLibrary(
      tester,
      initial: '/library/songs',
      scan: const ScanRunning(phase: ScanPhase.listing, done: 0, total: 0),
    );
    expect(find.text('Library is empty'), findsNothing);
    expect(find.byType(KListSortFilterBar), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('the sort chip lists the criteria and remembers the choice', (
    tester,
  ) async {
    final h = await pumpLibrary(tester, initial: '/library/songs');
    await addLibraryTrack(h.db, source: h.sourceId, locator: 'a.flac');
    await h.settle(tester);
    await tester.tap(find.text('Name'));
    await tester.pumpAndSettle();
    expect(find.text('A → Z'), findsOneWidget);
    expect(find.text('Play count'), findsOneWidget);
    // The order buttons keep the popover open.
    await tester.tap(find.text('Z → A'));
    await tester.pumpAndSettle();
    expect(find.text('Play count'), findsOneWidget);
    await tester.tap(find.text('Year'));
    await tester.pumpAndSettle();
    expect(find.text('Play count'), findsNothing);
    final sort = h.container
        .read(libraryListViewsProvider)
        .of(BrowseList.songs)
        .sort;
    expect(sort, const SortSpec(SortCriterion.year, descending: true));
    await unmountApp(tester);
  });

  testWidgets(
    'the filter field opens, narrows, and clears on close; Back closes it first',
    (tester) async {
      final h = await pumpLibrary(tester, initial: '/library/songs');
      for (final t in ['Vũ Cát Tường', 'Other']) {
        await addLibraryTrack(
          h.db,
          source: h.sourceId,
          locator: '$t.flac',
          title: t,
        );
      }
      await h.settle(tester);
      expect(h.songTitles(tester).length, 2);
      await tester.tap(find.byTooltip('Filter'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'vu');
      await h.settle(tester);
      expect(h.songTitles(tester), ['Vũ Cát Tường']);
      expect(find.text('1 / 2 songs'), findsOneWidget);
      // Back closes the field (and clears the text) before it leaves the page.
      await tester.binding.handlePopRoute();
      await h.settle(tester);
      expect(find.byType(TextField), findsNothing);
      expect(h.songTitles(tester).length, 2);
      await unmountApp(tester);
    },
  );
}
