import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/ui/library_locations.dart';
import 'package:kanaru/src/library/ui/collections/album_tile.dart';
import 'package:kanaru/src/library/ui/detail/detail_header.dart';
import 'package:kanaru/src/library/ui/detail/detail_songs.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/fake_playback_commands.dart';
import 'support/detail_fixture.dart';
import 'support/library_harness.dart';
import 'support/ui_harness.dart';

Future<LibraryHarness> _pump(
  WidgetTester tester,
  String artist, {
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
  await addAlbum(h, 'Old', 'Zed', year: 1999, tracks: 2);
  await addAlbum(h, 'New', 'Zed', year: 2020, tracks: 2);
  // Another artist's album with a track by Zed.
  await addAlbum(
    h,
    'Mix',
    'Yan',
    year: 2005,
    tracks: 2,
    trackArtists: ['Yan', 'Zed'],
  );
  // Compilation owned by an artist with no track of its own.
  await addAlbum(
    h,
    'Hits',
    'Various',
    year: 2001,
    tracks: 1,
    trackArtists: ['Solo'],
    albumArtist: 'Various',
  );
  await h.settle(tester);
  h.router.push(LibraryLocations.artist(ArtistKey(artist.toLowerCase())));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await h.settle(tester);
  return h;
}

void main() {
  testWidgets('shows album count, shelves newest first and every song', (
    tester,
  ) async {
    await _pump(tester, 'Zed');
    expect(
      find.descendant(of: find.byType(PageHeader), matching: find.text('Zed')),
      findsOneWidget,
    );
    expect(find.text('2 albums'), findsOneWidget);
    expect(find.text('Albums'), findsOneWidget);
    expect(find.text('Appears on'), findsOneWidget);
    final shelfAlbums = [
      for (final c in tester.widgetList<AlbumCard>(find.byType(AlbumCard)))
        c.album.title,
    ];
    expect(shelfAlbums, ['New', 'Old', 'Mix']);
    expect(find.byType(KShelf), findsNWidgets(2));
    await unmountApp(tester);
  });

  testWidgets('a tap plays the artist songs with the artist context', (
    tester,
  ) async {
    final playback = FakePlaybackCommands();
    await _pump(tester, 'Zed', playback: playback);
    await tester.scrollUntilVisible(
      find.text('Old 1'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Old 1'));
    await tester.pump();
    final call = playback.calls.single as PlayTracksCall;
    expect(call.tracks.length, 6);
    expect(call.context.kind, PlayContextKind.artist);
    expect(call.context.label, 'Zed');
    expect(call.context.ref, ArtistKey('zed').encode());
    await unmountApp(tester);
  });

  testWidgets('an album artist with no song of its own has no songs part', (
    tester,
  ) async {
    await _pump(tester, 'Various');
    expect(find.text('1 album'), findsOneWidget);
    expect(find.byType(KListSortFilterBar), findsNothing);
    expect(find.text('Appears on'), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('Play and Shuffle on such a page play what its albums hold', (
    tester,
  ) async {
    final playback = FakePlaybackCommands();
    await _pump(tester, 'Various', playback: playback);
    await tester.tap(find.text('Play'));
    await tester.pump();
    await tester.tap(find.byTooltip('Shuffle'));
    await tester.pump();
    for (final call in playback.calls.cast<PlayTracksCall>()) {
      expect(call.tracks.length, 1);
      expect(call.context.kind, PlayContextKind.artist);
      expect(call.context.label, 'Various');
      expect(call.context.ref, ArtistKey('various').encode());
    }
    expect(playback.calls.length, 2);
    expect((playback.calls[1] as PlayTracksCall).shuffle, isTrue);
    await unmountApp(tester);
  });

  testWidgets('Shuffle on an artist page carries the artist context', (
    tester,
  ) async {
    final playback = FakePlaybackCommands();
    await _pump(tester, 'Zed', playback: playback);
    await tester.tap(find.byTooltip('Shuffle'));
    await tester.pump();
    final call = playback.calls.single as PlayTracksCall;
    expect(call.shuffle, isTrue);
    expect(call.tracks.length, 6);
    expect(call.context.kind, PlayContextKind.artist);
    expect(call.context.label, 'Zed');
    expect(call.context.ref, ArtistKey('zed').encode());
    await unmountApp(tester);
  });

  testWidgets('an artist that only appears on albums shows no album count', (
    tester,
  ) async {
    await _pump(tester, 'Solo');
    expect(find.textContaining('album'), findsNothing);
    expect(find.text('Appears on'), findsOneWidget);
    expect(find.byType(KListSortFilterBar), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('the first song arriving keeps the page, filter and all', (
    tester,
  ) async {
    final h = await _pump(tester, 'Various');
    final host = tester.state(find.byType(DetailSongsHost));
    await addAlbum(h, 'Late', 'Yan', tracks: 1, trackArtists: ['Various']);
    await h.settle(tester);
    expect(find.byType(KListSortFilterBar), findsOneWidget);
    expect(tester.state(find.byType(DetailSongsHost)), same(host));
    await unmountApp(tester);
  });

  testWidgets('a shelf › opens see all, Back returns to the artist', (
    tester,
  ) async {
    final h = await _pump(tester, 'Zed');
    final artistLocation = h.location;
    await tester.tap(find.text('Albums'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await h.settle(tester);
    expect(h.location, '$artistLocation/albums');
    expect(
      find.descendant(
        of: find.byType(PageHeader),
        matching: find.text('Albums · Zed'),
      ),
      findsOneWidget,
    );
    expect(find.byType(AlbumCard), findsNWidgets(2));
    h.router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(h.location, artistLocation);
    await tester.tap(find.text('Appears on'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await h.settle(tester);
    expect(h.location, '$artistLocation/appears');
    expect(find.text('Appears on · Zed'), findsOneWidget);
    expect(find.byType(AlbumCard), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('an unknown artist is not found', (tester) async {
    await _pump(tester, 'Nobody');
    expect(find.text('Not found'), findsWidgets);
    await unmountApp(tester);
  });

  testWidgets('a wide page keeps the photo and buttons in the left column', (
    tester,
  ) async {
    await _pump(tester, 'Zed', width: 1280);
    expect(find.byType(DetailActions), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(DetailActions)).dx,
      lessThan(KDetailLayout.columnWidth),
    );
    await unmountApp(tester);
  });
}
