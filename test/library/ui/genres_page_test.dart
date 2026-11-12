import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/data/browse/song_ids_query.dart';
import 'package:kanaru/src/library/domain/browse/song_scope.dart';
import 'package:kanaru/src/library/ui/browse/group_play.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/library/domain/browse/list_view_prefs.dart';
import 'package:kanaru/src/library/ui/menus/more_button.dart';
import 'package:kanaru/src/library/state/browse/list_prefs_providers.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../support/fake_playback_commands.dart';
import '../browse/support/library_fixture.dart';
import 'support/library_harness.dart';
import 'support/ui_harness.dart';

Future<LibraryHarness> _pump(
  WidgetTester tester, {
  double width = 390,
  FakePlaybackCommands? playback,
}) async {
  final h = await pumpLibrary(
    tester,
    playback: playback,
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
    expect(find.byType(KMediaCard), findsNothing);
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

  testWidgets('the list view shows rows with a play button', (tester) async {
    final h = await _pump(tester);
    await h.container
        .read(libraryListViewsProvider.notifier)
        .setView(BrowseList.genres, CollectionView.list);
    await tester.pump();
    expect(find.byType(KColorTile), findsNothing);
    final rows = tester.widgetList<KMediaCard>(find.byType(KMediaCard));
    expect([for (final r in rows) r.title], ['Indie', 'Jazz', 'Rock']);
    expect(rows.every((r) => r.onAction != null), isTrue);
    await tester.tap(find.text('Jazz'));
    await tester.pump();
    expect(h.location, '/library/genres/${encodeKey(groupKey('Jazz'))}');
    await unmountApp(tester);
  });

  testWidgets('play on a row sends the genre like its page does', (
    tester,
  ) async {
    final playback = FakePlaybackCommands();
    final h = await _pump(tester, playback: playback);
    await h.container
        .read(libraryListViewsProvider.notifier)
        .setView(BrowseList.genres, CollectionView.list);
    await tester.pump();
    await tester.tap(find.byTooltip('Play all').at(1)); // Jazz
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    final call = playback.calls.single as PlayTracksCall;
    expect(call.context, genrePlayContext(groupKey('Jazz'), 'Jazz'));
    expect(call.context.kind, PlayContextKind.genre);
    // Same ids, same order as the genre page's Play reads.
    final expected = await songIds(
      h.db,
      SongScope.genre(groupKey('Jazz')),
      defaultSortOf(BrowseList.detailSongs),
      '',
    );
    expect(call.tracks, expected);
    await unmountApp(tester);
  });

  testWidgets('list rows: shared extent, zero gutter, menu is the genre menu', (
    tester,
  ) async {
    final h = await _pump(tester);
    await h.container
        .read(libraryListViewsProvider.notifier)
        .setView(BrowseList.genres, CollectionView.list);
    await tester.pump();
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
    await tester.tap(find.byType(LibraryMoreButton).first);
    await tester.pumpAndSettle();
    expect(find.text('Go to genre'), findsOneWidget);
    expect(find.text('Go to language'), findsNothing);
    expect(tester.takeException(), isNull);
    await unmountApp(tester);
  });
}
