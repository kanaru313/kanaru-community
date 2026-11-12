import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/state/browse/list_prefs_providers.dart';
import 'package:kanaru/src/library/ui/browse/group_play.dart';
import 'package:kanaru/src/library/ui/menus/more_button.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../support/fake_playback_commands.dart';
import '../browse/support/library_fixture.dart';
import 'support/library_harness.dart';
import 'support/ui_harness.dart';

Future<LibraryHarness> _pump(
  WidgetTester tester, {
  FakePlaybackCommands? playback,
}) async {
  final h = await pumpLibrary(
    tester,
    initial: '/library/languages',
    playback: playback,
  );
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
  for (final r in tester.widgetList<KMediaCard>(find.byType(KMediaCard)))
    r.title,
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

  testWidgets('rows have a play button; the menu button opens the menu', (
    tester,
  ) async {
    await _pump(tester);
    for (final r in tester.widgetList<KMediaCard>(find.byType(KMediaCard))) {
      expect(r.onAction, isNotNull);
      expect(r.trailing, isNotNull);
    }
    await tester.tap(find.byType(LibraryMoreButton).first);
    await tester.pumpAndSettle();
    expect(find.text('Play'), findsWidgets);
    expect(find.text('Go to language'), findsOneWidget);
    expect(find.text('Go to genre'), findsNothing);
    expect(tester.takeException(), isNull);
    await unmountApp(tester);
  });

  testWidgets('play on a row sends the language like its page does', (
    tester,
  ) async {
    final playback = FakePlaybackCommands();
    await _pump(tester, playback: playback);
    final rows = tester.widgetList<KMediaCard>(find.byType(KMediaCard));
    final titles = [for (final r in rows) r.title];
    final vie = titles.indexWhere((t) => t.contains('Vi'));
    final unknown = titles.length - 1; // "unknown" stays last
    await tester.tap(find.byTooltip('Play all').at(vie));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    var call = playback.calls.single as PlayTracksCall;
    expect(call.tracks.length, 3);
    expect(call.context, languagePlayContext('vie', titles[vie]));
    await tester.tap(find.byTooltip('Play all').at(unknown));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    call = playback.calls.last as PlayTracksCall;
    expect(call.tracks.length, 2);
    expect(call.context.kind, PlayContextKind.language);
    expect(call.context.ref, '_unknown');
    await unmountApp(tester);
  });

  testWidgets('rows keep the shared extent and a zero list gutter on mobile', (
    tester,
  ) async {
    await _pump(tester);
    final list = tester.widget<SliverFixedExtentList>(
      find.byType(SliverFixedExtentList),
    );
    expect(list.itemExtent, KMediaCard.extentOf(TextScaler.noScaling));
    final pad = tester.widget<SliverPadding>(
      find.ancestor(
        of: find.byType(SliverFixedExtentList),
        matching: find.byType(SliverPadding),
      ),
    );
    expect(pad.padding, EdgeInsets.zero);
    await unmountApp(tester);
  });

  testWidgets('a language with detected songs counts them on line two', (
    tester,
  ) async {
    await _pump(tester);
    final cards = tester.widgetList<KMediaCard>(find.byType(KMediaCard));
    expect(
      cards.firstWhere((c) => c.title.startsWith('Tiếng')).line2,
      '3 songs · 1 auto-detected',
    );
    expect(cards.firstWhere((c) => c.title == 'Unknown').line2, '2 songs');
    await unmountApp(tester);
  });
}
