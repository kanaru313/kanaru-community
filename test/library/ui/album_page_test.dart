import 'dart:ui' show SemanticsAction, SemanticsFlag;

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/state/browse/list_prefs_providers.dart';
import 'package:kanaru/src/library/ui/browse/item_covers.dart';
import 'package:kanaru/src/library/ui/detail/detail_header.dart';
import 'package:kanaru/src/library/ui/library_locations.dart';
import 'package:kanaru/src/library/ui/songs/song_tile.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/fake_playback_commands.dart';
import 'menus/menu_pump.dart';
import 'support/detail_fixture.dart';
import 'support/library_harness.dart';
import 'support/ui_harness.dart';

Future<LibraryHarness> _pump(
  WidgetTester tester, {
  double width = 390,
  FakePlaybackCommands? playback,
}) async {
  final h = await pumpLibrary(
    tester,
    initial: '/library/songs',
    width: width,
    height: width > 1000 ? 800 : 844,
    playback: playback,
  );
  await addAlbum(h, 'Blue', 'Zed', year: 2001);
  await addAlbum(h, 'Amber', 'Yan', year: 2010);
  await h.settle(tester);
  h.router.push(
    LibraryLocations.album(AlbumKey.decode(albumId('Blue', 'Zed'))!),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await h.settle(tester);
  return h;
}

void main() {
  testWidgets('shows the album: title in the header, artist, year, songs', (
    tester,
  ) async {
    await _pump(tester);
    expect(
      find.descendant(of: find.byType(PageHeader), matching: find.text('Blue')),
      findsOneWidget,
    );
    expect(find.text('Zed'), findsWidgets);
    expect(find.text('2001'), findsOneWidget);
    expect(find.text('3 songs · 3 min'), findsOneWidget);
    expect(tileTitles(tester), ['Blue 1', 'Blue 2', 'Blue 3']);
    final tile = tester.widget<SongTile>(find.byType(SongTile).first);
    expect(tile.showNumber, isTrue);
    expect(find.text('1'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('a tap plays the album songs in order from that song', (
    tester,
  ) async {
    final playback = FakePlaybackCommands();
    final h = await _pump(tester, playback: playback);
    await tester.tap(find.text('Blue 2'));
    await tester.pump();
    final call = playback.calls.single as PlayTracksCall;
    expect(call.tracks.length, 3);
    expect(call.startIndex, 1);
    expect(call.context.kind, PlayContextKind.album);
    expect(call.context.label, 'Blue');
    expect(call.context.ref, albumId('Blue', 'Zed'));
    expect(h.playback, same(playback));
    await unmountApp(tester);
  });

  testWidgets('Play sends all songs, Shuffle shuffles them', (tester) async {
    final playback = FakePlaybackCommands();
    await _pump(tester, playback: playback);
    await tester.tap(find.text('Play'));
    await tester.pump();
    await tester.tap(find.byTooltip('Shuffle'));
    await tester.pump();
    final play = playback.calls[0] as PlayTracksCall;
    final shuffle = playback.calls[1] as PlayTracksCall;
    expect(play.tracks.length, 3);
    expect(play.startIndex, 0);
    expect(play.shuffle, isFalse);
    expect(shuffle.tracks, play.tracks);
    expect(shuffle.shuffle, isTrue);
    await unmountApp(tester);
  });

  testWidgets('the page menu is the album menu of its own page', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(DetailActions),
        matching: find.byIcon(KIcons.moreVert),
      ),
    );
    await pumpMenu(tester);
    final sheet = find.byType(BottomSheet);
    expect(sheet, findsOneWidget);
    // Links to the artist, but not back to this album; no Play (the page has
    // the buttons).
    expect(
      find.descendant(of: sheet, matching: find.text('Go to artist')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Go to album')),
      findsNothing,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Play')),
      findsNothing,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Play next')),
      findsOneWidget,
    );
    await tester.tapAt(const Offset(195, 20));
    await tester.pumpAndSettle();
    await unmountApp(tester);
  });

  testWidgets(
    'the sort starts at track number and follows the stored direction',
    (tester) async {
      final h = await _pump(tester);
      expect(find.text('Track number'), findsOneWidget);
      await h.container
          .read(libraryListViewsProvider.notifier)
          .setSort(
            BrowseList.albumTracks,
            const SortSpec(SortCriterion.trackNumber, descending: true),
          );
      await h.settle(tester, rounds: 2);
      expect(tileTitles(tester), ['Blue 3', 'Blue 2', 'Blue 1']);
      await unmountApp(tester);
    },
  );

  testWidgets('a sort chosen on one album is not the sort of another', (
    tester,
  ) async {
    final h = await _pump(tester);
    await tester.tap(find.text('Track number'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Name'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(
      h.container
          .read(detailSortOverridesProvider)[(
            list: BrowseList.albumTracks,
            item: albumId('Blue', 'Zed'),
          )]
          ?.criterion,
      SortCriterion.title,
    );
    h.router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    h.router.push(
      LibraryLocations.album(AlbumKey.decode(albumId('Amber', 'Yan'))!),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await h.settle(tester);
    expect(find.text('Track number'), findsOneWidget);
    // The remembered default of the kind is untouched.
    expect(
      h.container
          .read(libraryListViewsProvider)
          .of(BrowseList.albumTracks)
          .sort
          .criterion,
      SortCriterion.trackNumber,
    );
    await unmountApp(tester);
  });

  testWidgets('the filter narrows the songs and the count', (tester) async {
    await _pump(tester);
    await tester.tap(find.byTooltip('Filter'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'blue 2');
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(tileTitles(tester), ['Blue 2']);
    expect(find.text('1 / 3 songs'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('the artist link opens the artist and Back steps back', (
    tester,
  ) async {
    final h = await _pump(tester);
    final albumLocation = h.location;
    await tester.tap(find.text('Zed').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(h.location, startsWith('/library/artists/'));
    h.router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(h.location, albumLocation);
    h.router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(h.location, '/library/songs');
    await unmountApp(tester);
  });

  testWidgets('the artist link can be activated through semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final h = await _pump(tester);
    final link = find.semantics.byFlag(SemanticsFlag.isLink);
    expect(link, findsOneWidget);
    expect(
      link.evaluate().single.getSemanticsData().hasAction(SemanticsAction.tap),
      isTrue,
    );
    tester.semantics.tap(link);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(h.location, startsWith('/library/artists/'));
    handle.dispose();
    await unmountApp(tester);
  });

  testWidgets('a key that does not decode, or no album, is not found', (
    tester,
  ) async {
    final h = await _pump(tester);
    h.router.push('/library/albums/abc');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Not found'), findsWidgets);
    h.router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    h.router.push(LibraryLocations.album(AlbumKey('nobody', 'nothing')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await h.settle(tester);
    expect(find.text('Not found'), findsWidgets);
    expect(find.text('This is no longer in your library.'), findsOneWidget);
    await unmountApp(tester);
  });

  for (final (width, wide) in [(839.0, false), (840.0, true)]) {
    testWidgets('at $width px the layout is ${wide ? 'wide' : 'narrow'}', (
      tester,
    ) async {
      await _pump(tester, width: width);
      final cover = tester.getSize(find.byType(AlbumCover).first);
      expect(cover.width, wide ? 320 : 132);
      await unmountApp(tester);
    });
  }
}
