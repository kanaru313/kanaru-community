import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/state/browse/list_prefs_providers.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../browse/support/library_fixture.dart';
import 'support/library_harness.dart';
import 'support/ui_harness.dart';

Future<LibraryHarness> _pump(WidgetTester tester, {double width = 390}) async {
  final h = await pumpLibrary(
    tester,
    initial: '/library/genres',
    width: width,
    height: width > 1000 ? 800 : 844,
  );
  for (final (genre, n) in [('Rock', 3), ('Indie', 1), ('Jazz', 2)]) {
    for (var i = 0; i < n; i++) {
      await addLibraryTrack(
        h.db,
        source: h.sourceId,
        locator: '$genre/$i.flac',
        title: '$genre $i',
        genre: genre,
      );
    }
  }
  await addLibraryTrack(h.db, source: h.sourceId, locator: 'none.flac');
  await h.settle(tester);
  return h;
}

void main() {
  testWidgets('genres are coloured tiles in name order with song counts', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('3 genres'), findsOneWidget);
    final names = [
      for (final t in tester.widgetList<KColorTile>(find.byType(KColorTile)))
        t.title,
    ];
    expect(names, ['Indie', 'Jazz', 'Rock']);
    expect(find.text('3 songs'), findsOneWidget);
    expect(find.text('1 song'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await unmountApp(tester);
  });

  testWidgets('sorted by song count, most first', (tester) async {
    final h = await _pump(tester);
    await h.container
        .read(libraryListViewsProvider.notifier)
        .setSort(
          BrowseList.genres,
          const SortSpec(SortCriterion.trackCount, descending: true),
        );
    await tester.pump();
    final names = [
      for (final t in tester.widgetList<KColorTile>(find.byType(KColorTile)))
        t.title,
    ];
    expect(names, ['Rock', 'Jazz', 'Indie']);
    await unmountApp(tester);
  });

  testWidgets('a tap pushes the genre location', (tester) async {
    final h = await _pump(tester);
    await tester.tap(find.text('Jazz'));
    await tester.pump();
    expect(h.location, '/library/genres/${encodeKey(groupKey('Jazz'))}');
    await unmountApp(tester);
  });

  testWidgets('the grid has more columns on a wide window', (tester) async {
    await _pump(tester, width: 1280);
    final tiles = find.byType(KColorTile);
    final top = tester.getTopLeft(tiles.first).dy;
    expect(tester.getTopLeft(tiles.at(2)).dy, top);
    await unmountApp(tester);
  });
}
