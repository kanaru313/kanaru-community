import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/domain/browse/list_view_prefs.dart';
import 'package:kanaru/src/library/state/browse/list_prefs_providers.dart';
import 'package:kanaru/src/library/ui/collections/album_tile.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/fake_playback_commands.dart';
import '../browse/support/library_fixture.dart';
import 'support/library_harness.dart';
import 'support/ui_harness.dart';

Future<List<int>> _album(
  LibraryHarness h,
  String album,
  String artist,
  int year, {
  int tracks = 2,
}) async => [
  for (var n = 1; n <= tracks; n++)
    await addLibraryTrack(
      h.db,
      source: h.sourceId,
      locator: '$album/$n.flac',
      title: '$album $n',
      artists: [artist],
      album: album,
      albumArtist: artist,
      year: year,
      trackNo: n,
      durationMs: 120000,
      addedAt: year,
    ),
];

Future<LibraryHarness> _pump(
  WidgetTester tester, {
  double width = 390,
  FakePlaybackCommands? playback,
}) async {
  final h = await pumpLibrary(
    tester,
    initial: '/library/albums',
    width: width,
    height: width > 1000 ? 800 : 844,
    playback: playback,
  );
  await _album(h, 'Blue', 'Zed', 2001);
  await _album(h, 'Amber', 'Yan', 2010, tracks: 3);
  await _album(h, 'Coral', 'Xi', 1999);
  await h.settle(tester);
  return h;
}

void main() {
  testWidgets('albums are a grid of covers with a count', (tester) async {
    await _pump(tester);
    expect(find.text('3 albums'), findsOneWidget);
    expect(find.byType(AlbumCard), findsNWidgets(3));
    expect(find.text('Zed · 2001'), findsOneWidget);
    expect(find.byType(AlbumTile), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('the view switch shows rows and is remembered', (tester) async {
    final h = await _pump(tester);
    await tester.tap(find.byTooltip('List'));
    await h.settle(tester, rounds: 1);
    expect(find.byType(AlbumTile), findsNWidgets(3));
    expect(find.text('Yan • 2010'), findsOneWidget);
    expect(find.text('3 songs • 6 min'), findsOneWidget);
    expect(
      h.container.read(libraryListViewsProvider).of(BrowseList.albums).view,
      CollectionView.list,
    );
    // A new page of the same app reads it back.
    h.router.go('/library/songs');
    await tester.pump();
    h.router.go('/library/albums');
    await h.settle(tester, rounds: 1);
    expect(find.byType(AlbumTile), findsNWidgets(3));
    await unmountApp(tester);
  });

  testWidgets('sort by year, newest first, and filter by artist', (
    tester,
  ) async {
    final h = await _pump(tester);
    await h.container
        .read(libraryListViewsProvider.notifier)
        .setSort(
          BrowseList.albums,
          const SortSpec(SortCriterion.year, descending: true),
        );
    await tester.pump();
    final titles = [
      for (final c in tester.widgetList<AlbumCard>(find.byType(AlbumCard)))
        c.album.title,
    ];
    expect(titles, ['Amber', 'Blue', 'Coral']);
    await tester.tap(find.byTooltip('Filter'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'yan');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(AlbumCard), findsOneWidget);
    expect(find.text('1 / 3 albums'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('play on a row sends the album in track order', (tester) async {
    final playback = FakePlaybackCommands();
    final h = await _pump(tester, playback: playback);
    await tester.tap(find.byTooltip('List'));
    await h.settle(tester, rounds: 1);
    await tester.tap(find.byTooltip('Play album').at(0)); // Amber (A-Z order)
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    final call = playback.calls.single as PlayTracksCall;
    expect(call.tracks.length, 3);
    expect(call.context.kind, PlayContextKind.album);
    expect(call.context.label, 'Amber');
    final titles = [
      for (final id in call.tracks)
        (await h.db
                .customSelect('SELECT title FROM tracks WHERE id = ${id.value}')
                .getSingle())
            .data['title'],
    ];
    expect(titles, ['Amber 1', 'Amber 2', 'Amber 3']);
    await unmountApp(tester);
  });

  testWidgets('a tap pushes the album page location', (tester) async {
    final h = await _pump(tester);
    await tester.tap(find.text('Amber'));
    await tester.pump();
    final key = albumKeyFor(
      album: 'Amber',
      albumArtist: 'Yan',
      artists: ['Yan'],
    )!;
    expect(h.location, '/library/albums/${key.encode()}');
    expect(h.router.canPop(), isTrue);
    h.router.pop();
    await tester.pump();
    expect(h.location, '/library/albums');
    await unmountApp(tester);
  });

  for (final (width, expected) in [(390.0, 2), (1280.0, 3)]) {
    testWidgets('the grid has $expected columns at $width px', (tester) async {
      await _pump(tester, width: width);
      final cards = find.byType(AlbumCard);
      final top = tester.getTopLeft(cards.first).dy;
      final inFirstRow = [
        for (var i = 0; i < 3; i++)
          if (tester.getTopLeft(cards.at(i)).dy == top) i,
      ];
      expect(inFirstRow.length, expected);
      await unmountApp(tester);
    });
  }

  testWidgets('the filter text reaches the list after typing pauses', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.byTooltip('Filter'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ya');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'yan');
    await tester.pump(const Duration(milliseconds: 200));
    // 300 ms since the first key, 200 since the last: not applied yet.
    expect(find.byType(AlbumCard), findsNWidgets(3));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(AlbumCard), findsOneWidget);
    // Emptying the field applies at once.
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(find.byType(AlbumCard), findsNWidgets(3));
    await unmountApp(tester);
  });
}
