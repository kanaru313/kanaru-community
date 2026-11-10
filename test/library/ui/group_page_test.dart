import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/ui/collections/album_tile.dart';
import 'package:kanaru/src/library/ui/collections/artist_tile.dart';
import 'package:kanaru/src/library/ui/library_locations.dart';
import 'package:kanaru/src/library/ui/songs/song_tile.dart';
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
  String location, {
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
  await addAlbum(h, 'A1', 'Ann', year: 2001, genre: 'Rock', language: 'en');
  await addAlbum(h, 'A2', 'Bob', year: 2002, genre: 'Rock', language: 'vi');
  await addAlbum(
    h,
    'A3',
    'Cid',
    year: 2003,
    genre: 'Rock',
    language: 'vi',
    languageDetected: true,
  );
  await addAlbum(h, 'Solo', 'Dee', year: 2004, genre: 'Jazz', tracks: 2);
  await h.settle(tester);
  h.router.push(location);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await h.settle(tester);
  return h;
}

void main() {
  testWidgets('genre: banner totals, both shelves, songs', (tester) async {
    await _pump(tester, LibraryLocations.genre('rock'));
    expect(
      find.descendant(of: find.byType(PageHeader), matching: find.text('Rock')),
      findsOneWidget,
    );
    expect(find.byType(KColorBanner), findsOneWidget);
    expect(find.text('9 songs'), findsWidgets);
    expect(find.text('3 artists · 9 min'), findsOneWidget);
    expect(find.byType(ArtistCard), findsNWidgets(3));
    expect(find.byType(AlbumCard), findsNWidgets(3));
    expect(find.text('Artists'), findsOneWidget);
    expect(find.text('Albums'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('a group with a single artist and album has no shelves', (
    tester,
  ) async {
    await _pump(tester, LibraryLocations.genre('jazz'));
    expect(find.byType(KShelf), findsNothing);
    expect(find.text('2 songs'), findsWidgets);
    await unmountApp(tester);
  });

  testWidgets('a shelf is capped at 10 on mobile and 8 on desktop', (
    tester,
  ) async {
    for (final (width, cap) in [(390.0, 10), (1280.0, 8)]) {
      final h = await pumpLibrary(
        tester,
        initial: '/library/songs',
        width: width,
        height: 800,
      );
      for (var i = 0; i < 12; i++) {
        await addAlbum(
          h,
          'Al$i',
          'Ar$i',
          year: 2000 + i,
          tracks: 1,
          genre: 'Pop',
        );
      }
      await h.settle(tester);
      h.router.push(LibraryLocations.genre('pop'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await h.settle(tester);
      // Shelf lists build lazily; the item count is on the list.
      final shelves = tester.widgetList<ListView>(
        find.descendant(
          of: find.byType(KShelf),
          matching: find.byType(ListView),
        ),
      );
      // A separated list counts items and gaps: n items = 2n - 1 children.
      final counts = [
        for (final l in shelves)
          ((l.childrenDelegate as SliverChildBuilderDelegate).childCount! +
                  1) ~/
              2,
      ];
      expect(counts, [cap, cap]);
      await unmountApp(tester);
    }
  });

  testWidgets('genre see all opens the grid and Back returns', (tester) async {
    final h = await _pump(tester, LibraryLocations.genre('rock'));
    final genre = h.location;
    await tester.tap(find.text('Artists'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await h.settle(tester);
    expect(h.location, '$genre/artists');
    expect(find.text('Artists · Rock'), findsOneWidget);
    expect(find.byType(ArtistCard), findsNWidgets(3));
    h.router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(h.location, genre);
    await tester.tap(find.text('Albums'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await h.settle(tester);
    expect(find.text('Albums · Rock'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('a tap plays the genre songs with the genre context', (
    tester,
  ) async {
    final playback = FakePlaybackCommands();
    await _pump(tester, LibraryLocations.genre('rock'), playback: playback);
    await tester.scrollUntilVisible(
      find.text('A1 1'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('A1 1'));
    await tester.pump();
    final call = playback.calls.single as PlayTracksCall;
    expect(call.tracks.length, 9);
    expect(call.context.kind, PlayContextKind.genre);
    expect(call.context.label, 'Rock');
    expect(call.context.ref, encodeKey('rock'));
    await unmountApp(tester);
  });

  testWidgets('language: names, detected count, note and tag on songs', (
    tester,
  ) async {
    await _pump(tester, LibraryLocations.language('vie'));
    expect(find.textContaining('Tiếng Việt'), findsWidgets);
    expect(find.text('2 artists · 6 min · 3 auto-detected'), findsOneWidget);
    expect(
      find.textContaining('Songs labelled “auto-detected”'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('A3 1'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final tiles = tester.widgetList<SongTile>(find.byType(SongTile));
    expect(tiles.every((t) => t.showDetected), isTrue);
    expect(find.text('auto-detected'), findsWidgets);
    await unmountApp(tester);
  });

  testWidgets('Shuffle on a genre page carries the genre context', (
    tester,
  ) async {
    final playback = FakePlaybackCommands();
    await _pump(tester, LibraryLocations.genre('rock'), playback: playback);
    await tester.tap(find.byTooltip('Shuffle'));
    await tester.pump();
    final call = playback.calls.single as PlayTracksCall;
    expect(call.shuffle, isTrue);
    expect(call.context.kind, PlayContextKind.genre);
    expect(call.context.label, 'Rock');
    expect(call.context.ref, encodeKey('rock'));
    await unmountApp(tester);
  });

  testWidgets('Shuffle on a language page carries the language context', (
    tester,
  ) async {
    final playback = FakePlaybackCommands();
    await _pump(tester, LibraryLocations.language('vie'), playback: playback);
    await tester.tap(find.byTooltip('Shuffle'));
    await tester.pump();
    final call = playback.calls.single as PlayTracksCall;
    expect(call.context.kind, PlayContextKind.language);
    expect(call.context.ref, encodeKey('vie'));
    expect(call.tracks.length, 6);
    await unmountApp(tester);
  });

  testWidgets('a language with no detected song has no detection note', (
    tester,
  ) async {
    await _pump(tester, LibraryLocations.language('eng'));
    expect(find.textContaining('auto-detected'), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('see all of an unknown group is not found', (tester) async {
    final h = await _pump(
      tester,
      '${LibraryLocations.genre('nothing')}/artists',
    );
    expect(find.text('Not found'), findsWidgets);
    h.router.go('${LibraryLocations.language('xyz')}/albums');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await h.settle(tester);
    expect(find.text('Not found'), findsWidgets);
    await unmountApp(tester);
  });

  testWidgets('the unknown language page shows its own note', (tester) async {
    await _pump(tester, LibraryLocations.language(null));
    expect(find.text('Unknown'), findsWidgets);
    expect(find.textContaining('could not detect one'), findsOneWidget);
    expect(find.text('2 songs'), findsWidgets);
    await unmountApp(tester);
  });

  testWidgets('bad ids are not found', (tester) async {
    final h = await _pump(tester, '/library/genres/%%');
    expect(find.text('Not found'), findsWidgets);
    h.router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    h.router.push(LibraryLocations.genre('nothing'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await h.settle(tester);
    expect(find.text('Not found'), findsWidgets);
    h.router.push(LibraryLocations.language('xyz'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await h.settle(tester);
    expect(find.text('Not found'), findsWidgets);
    await unmountApp(tester);
  });
}
