import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/ui/collections/album_tile.dart';
import 'package:kanaru/src/library/ui/collections/artist_tile.dart';
import 'package:kanaru/src/library/ui/library_locations.dart';
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

/// The "See all" button of the shelf block titled [title].
Finder _seeAll(String title) => find.descendant(
  of: find.ancestor(of: find.text(title), matching: find.byType(KShelfBlock)),
  matching: find.byWidgetPredicate(
    (w) => w is KIconButton && w.tooltip == 'See all',
  ),
);
void main() {
  testWidgets('genre: banner totals, both shelves, songs', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, LibraryLocations.genre('rock'));
    expect(find.text('Rock'), findsOneWidget);
    expect(inPageHeader('Rock'), findsNothing);
    expect(headerNodes(tester, 'Rock'), 1);
    expect(find.byType(KColorBanner), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(KColorBanner),
        matching: find.text('9 songs · 9 min'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('artists'), findsNothing);
    expect(find.textContaining('auto-detected'), findsNothing);
    expect(find.byType(ArtistCard), findsNWidgets(3));
    expect(find.byType(AlbumCard), findsNWidgets(3));
    expect(find.text('Artists'), findsOneWidget);
    expect(find.text('Albums'), findsOneWidget);
    handle.dispose();
    await unmountApp(tester);
  });

  testWidgets('a group with a single artist and album has no shelves', (
    tester,
  ) async {
    await _pump(tester, LibraryLocations.genre('jazz'));
    expect(find.byType(KShelfBlock), findsNothing);
    expect(find.text('2 songs · 2 min'), findsWidgets);
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
          of: find.byType(KShelfBlock),
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
      // The head shows the full count, not the cards of the row.
      expect(find.text('12'), findsNWidgets(2));
      await unmountApp(tester);
    }
  });

  testWidgets('genre see all opens the grid and Back returns', (tester) async {
    final h = await _pump(tester, LibraryLocations.genre('rock'));
    final genre = h.location;
    await tester.tap(_seeAll('Artists'));
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
    await tester.tap(_seeAll('Albums'));
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

  testWidgets('language: the name is the headline, songs and length under it', (
    tester,
  ) async {
    await _pump(tester, LibraryLocations.language('vie'));
    expect(
      find.descendant(
        of: find.byType(KColorBanner),
        matching: find.textContaining('Tiếng Việt'),
      ),
      findsOneWidget,
    );
    expect(inPageHeader('Tiếng Việt'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(KColorBanner),
        matching: find.text('6 songs · 6 min'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('auto-detected'), findsNothing);
    expect(find.textContaining('artists'), findsNothing);
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

  testWidgets('the unknown language page says it has no tag, with a note', (
    tester,
  ) async {
    await _pump(tester, LibraryLocations.language(null));
    expect(find.text('Unknown'), findsOneWidget);
    expect(find.text('No language tag'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(KColorBanner),
        matching: find.text('2 songs · 2 min'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('could not detect one'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('a long note folds at a narrow width and stays open on return', (
    tester,
  ) async {
    final h = await _pump(tester, LibraryLocations.language(null), width: 360);
    expect(find.text('Show more'), findsOneWidget);
    expect(find.text('Show less'), findsNothing);
    await tester.tap(find.text('Show more'));
    await tester.pump();
    expect(find.text('Show less'), findsOneWidget);
    h.router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    h.router.push(LibraryLocations.language(null));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await h.settle(tester);
    expect(find.text('Show less'), findsOneWidget);
    expect(find.text('Show more'), findsNothing);
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
