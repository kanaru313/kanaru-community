import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/data/browse/song_ids_query.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/domain/browse/list_view_prefs.dart';
import 'package:kanaru/src/library/domain/browse/sort_order.dart';
import 'package:kanaru/src/library/domain/browse/song_scope.dart';
import 'package:kanaru/src/library/state/browse/list_prefs_providers.dart';
import 'package:kanaru/src/library/ui/browse/group_play.dart';
import 'package:kanaru/src/library/ui/collections/collection_parts.dart';
import 'package:kanaru/src/library/ui/menus/more_button.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../support/fake_playback_commands.dart';
import '../browse/support/library_fixture.dart';
import 'support/library_harness.dart';
import 'support/ui_harness.dart';
import '../../support/icon_button_finders.dart';

Future<LibraryHarness> _pump(
  WidgetTester tester, {
  FakePlaybackCommands? playback,
  bool grid = false,
  double width = 390,
}) async {
  final h = await pumpLibrary(
    tester,
    initial: '/library/languages',
    playback: playback,
    width: width,
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
  if (!grid) {
    await h.container
        .read(libraryListViewsProvider.notifier)
        .setView(BrowseList.languages, CollectionView.list);
    await tester.pump();
  }
  return h;
}

List<String> _rows(WidgetTester tester) => [
  for (final r in tester.widgetList<KMediaCard>(find.byType(KMediaCard)))
    r.title,
];

void main() {
  for (final (width, scale) in [
    (400.0, 1.0),
    (400.0, 2.0),
    (1400.0, 1.0),
    (1400.0, 2.0),
  ]) {
    testWidgets('grid tiles fit at width $width, text scale $scale', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await _pump(tester, grid: true, width: width);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(KColorTile), findsNWidgets(3));
      expect(find.text('Tiếng Việt · Vietnamese'), findsOneWidget);
      expect(find.text('Unknown'), findsOneWidget);
      await unmountApp(tester);
    });
  }

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
    expect(find.text('3 songs'), findsOneWidget);
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
            SortOrder.by(SortCriterion.title, descending: desc),
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
    final vie = titles.indexOf('Tiếng Việt · Vietnamese');
    expect(vie, isNonNegative);
    final unknown = titles.length - 1; // "unknown" stays last
    await tester.tap(byIconButton('Play').at(vie));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    var call = playback.calls.single as PlayTracksCall;
    expect(call.tracks.length, 3);
    expect(call.context, languagePlayContext('vie', titles[vie]));
    await tester.tap(byIconButton('Play').at(unknown));
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

  testWidgets('play on a row follows the sort chosen on the language page', (
    tester,
  ) async {
    final playback = FakePlaybackCommands();
    final h = await _pump(tester, playback: playback);
    await h.container.read(detailSortOverridesProvider.notifier).set((
      list: BrowseList.detailSongs,
      item: languageDetailItem('vie'),
    ), SortOrder.by(SortCriterion.title, descending: true));
    await tester.pump();
    final titles = [
      for (final r in tester.widgetList<KMediaCard>(find.byType(KMediaCard)))
        r.title,
    ];
    await tester.tap(
      byIconButton('Play').at(titles.indexOf('Tiếng Việt · Vietnamese')),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    final call = playback.calls.single as PlayTracksCall;
    final ascending = await songIds(
      h.db,
      const SongScope.language('vie'),
      SortOrder.by(SortCriterion.title),
      '',
    );
    expect(call.tracks, ascending.reversed.toList());
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

  testWidgets('line two is the song count', (tester) async {
    await _pump(tester);
    final cards = tester.widgetList<KMediaCard>(find.byType(KMediaCard));
    expect(
      cards.firstWhere((c) => c.title.startsWith('Tiếng')).line2,
      '3 songs',
    );
    expect(cards.firstWhere((c) => c.title == 'Unknown').line2, '2 songs');
    await unmountApp(tester);
  });

  testWidgets('grid is the default: tiles, note first, "unknown" last', (
    tester,
  ) async {
    await _pump(tester, grid: true);
    expect(find.byType(KMediaCard), findsNothing);
    expect(
      find.textContaining('From the language tag of each song'),
      findsOneWidget,
    );
    final tiles = tester.widgetList<KColorTile>(find.byType(KColorTile));
    expect(
      [for (final t in tiles) t.title],
      ['Tiếng Việt · Vietnamese', '日本語 · Japanese', 'Unknown'],
    );
    expect(find.text('3 songs'), findsOneWidget);
    expect(find.byType(LibraryMoreButton), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('a grid tile exposes its menu as a screen-reader action', (
    tester,
  ) async {
    await _pump(tester, grid: true);
    final handle = tester.ensureSemantics();
    await tester.pump();
    final tile = find.widgetWithText(KColorTile, 'Tiếng Việt · Vietnamese');
    final node = tester.getSemantics(tile);
    final id = node.getSemanticsData().customSemanticsActionIds!.single;
    expect(CustomSemanticsAction.getAction(id)!.label, 'More options');
    tester.semantics.performAction(
      find.semantics.byLabel(RegExp('^Tiếng Việt')),
      SemanticsAction.customAction,
      args: id,
    );
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    expect(find.text('Go to language'), findsOneWidget);
    handle.dispose();
    await unmountApp(tester);
  });

  for (final (name, press) in <(String, Future<void> Function(WidgetTester))>[
    ('Menu key', (t) => t.sendKeyEvent(LogicalKeyboardKey.contextMenu)),
    (
      'Shift+F10',
      (t) async {
        await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await t.sendKeyEvent(LogicalKeyboardKey.f10);
        await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      },
    ),
  ]) {
    testWidgets('$name on a focused grid tile opens its menu (desktop)', (
      tester,
    ) async {
      final h = await pumpLibrary(
        tester,
        initial: '/library/languages',
        width: 1400,
        height: 900,
      );
      await addLibraryTrack(
        h.db,
        source: h.sourceId,
        locator: 'k0.flac',
        language: 'vie',
      );
      await h.settle(tester);
      final tile = find.widgetWithText(KColorTile, 'Tiếng Việt · Vietnamese');
      expect(tile, findsOneWidget);
      // The text sits under the tile's InkWell, so its nearest Focus is the
      // tile's own focus node.
      Focus.of(
        tester.element(
          find.descendant(of: tile, matching: find.byType(Text)).first,
        ),
      ).requestFocus();
      await tester.pump();
      await press(tester);
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();
      expect(find.text('Go to language'), findsOneWidget);
      await unmountApp(tester);
    });
  }

  testWidgets('the view toggle switches the grid to rows and back', (
    tester,
  ) async {
    await _pump(tester, grid: true);
    await tester.tap(byIconButton('List'));
    await tester.pumpAndSettle();
    expect(find.byType(KColorTile), findsNothing);
    expect(_rows(tester).last, 'Unknown');
    await tester.tap(byIconButton('Grid'));
    await tester.pumpAndSettle();
    expect(find.byType(KMediaCard), findsNothing);
    expect(find.byType(KColorTile), findsNWidgets(3));
    await unmountApp(tester);
  });

  testWidgets('a row and its grid tile share the colour seed', (tester) async {
    await _pump(tester, grid: true);
    final tileSeeds = [
      for (final t in tester.widgetList<KColorTile>(find.byType(KColorTile)))
        t.seed,
    ];
    await tester.tap(byIconButton('List'));
    await tester.pumpAndSettle();
    final rowSeeds = [
      for (final c in tester.widgetList<CategoryIcon>(
        find.byType(CategoryIcon),
      ))
        c.genre,
    ];
    expect(tileSeeds, hasLength(3));
    expect(rowSeeds, tileSeeds);
    await unmountApp(tester);
  });
}
