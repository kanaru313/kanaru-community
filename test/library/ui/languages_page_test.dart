import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/state/browse/list_prefs_providers.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../browse/support/library_fixture.dart';
import 'support/library_harness.dart';
import 'support/ui_harness.dart';

Future<LibraryHarness> _pump(WidgetTester tester) async {
  final h = await pumpLibrary(tester, initial: '/library/languages');
  var n = 0;
  Future<void> add(String? language, {bool detected = false}) =>
      addLibraryTrack(
        h.db,
        source: h.sourceId,
        locator: 'l${n++}.flac',
        language: language,
        languageDetected: detected,
      );
  await add('vie');
  await add('vie');
  await add('vie', detected: true);
  await add('jpn');
  await add(null);
  await add(null);
  await h.settle(tester);
  return h;
}

List<String> _rows(WidgetTester tester) => [
  for (final r in tester.widgetList<KListRow>(find.byType(KListRow)))
    (r.title as dynamic).data as String,
];

void main() {
  testWidgets('languages by song count, "unknown" last, with the note', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('3 languages'), findsOneWidget);
    expect(
      find.textContaining('From the language tag of each song'),
      findsOneWidget,
    );
    expect(_rows(tester), [
      'Tiếng Việt · Vietnamese',
      '日本語 · Japanese',
      'Unknown',
    ]);
    expect(find.text('3 songs · 1 auto-detected'), findsOneWidget);
    expect(find.text('1 song'), findsOneWidget);
    expect(find.text('2 songs'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('"unknown" stays last in both orders', (tester) async {
    final h = await _pump(tester);
    for (final desc in [false, true]) {
      await h.container
          .read(libraryListViewsProvider.notifier)
          .setSort(
            BrowseList.languages,
            SortSpec(SortCriterion.title, descending: desc),
          );
      await tester.pump();
      expect(_rows(tester).last, 'Unknown');
    }
    expect(_rows(tester), [
      '日本語 · Japanese',
      'Tiếng Việt · Vietnamese',
      'Unknown',
    ]);
    await unmountApp(tester);
  });

  testWidgets('a tap pushes the language, "unknown" its own location', (
    tester,
  ) async {
    final h = await _pump(tester);
    await tester.tap(find.text('Unknown'));
    await tester.pump();
    expect(h.location, '/library/languages/_unknown');
    h.router.pop();
    await tester.pump();
    await tester.tap(find.text('Tiếng Việt · Vietnamese'));
    await tester.pump();
    expect(h.location, startsWith('/library/languages/'));
    expect(h.location, isNot('/library/languages/_unknown'));
    await unmountApp(tester);
  });
}
