import 'dart:async';
import 'dart:ui' show SemanticsAction, SemanticsFlag;

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/state/browse/list_prefs_providers.dart';
import 'package:kanaru/src/library/ui/browse/item_covers.dart';
import 'package:kanaru/src/library/ui/detail/detail_header.dart';
import 'package:kanaru/src/library/ui/library_locations.dart';
import 'package:kanaru/src/library/state/browse/song_list_providers.dart';
import 'package:kanaru/src/library/ui/songs/song_tile.dart';
import 'package:kanaru/src/media/domain/track_info.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/playback/domain/now_playing.dart';
import 'package:kanaru/src/playback/ui/track_cover.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/fake_playback_commands.dart';
import '../browse/support/library_fixture.dart';
import 'menus/menu_pump.dart';
import 'support/detail_fixture.dart';
import 'support/library_harness.dart';
import 'support/ui_harness.dart';

Future<LibraryHarness> _pump(
  WidgetTester tester, {
  double width = 390,
  double? height,
  List<Override> overrides = const [],
  FakePlaybackCommands? playback,
  Widget Function(Widget)? header,
  Future<void> Function(LibraryHarness h)? extra,
}) async {
  final h = await pumpLibrary(
    tester,
    initial: '/library/songs',
    width: width,
    height: height ?? (width > 1000 ? 800 : 844),
    playback: playback,
    header: header,
    overrides: overrides,
  );
  await addAlbum(h, 'Blue', 'Zed', year: 2001);
  await extra?.call(h);
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

  testWidgets('a song swiped to info keeps the page origin: no link back', (
    tester,
  ) async {
    await _pump(tester);
    final row = tester.getCenter(find.byType(SongTile).first);
    final g = await tester.startGesture(row);
    for (var i = 0; i < 10; i++) {
      await g.moveBy(const Offset(20, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await pumpMenu(tester);
    final sheet = find.byType(BottomSheet);
    expect(sheet, findsOneWidget);
    await tester.tap(
      find.descendant(of: sheet, matching: find.byIcon(KIcons.back)),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: sheet, matching: find.text('Go to artist')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Go to album')),
      findsNothing,
    );
    await tester.tapAt(const Offset(195, 20));
    await tester.pumpAndSettle();
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
    final h = await _pump(tester);
    await tester.tap(find.byTooltip('Filter'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'blue 2');
    await tester.pump(const Duration(milliseconds: 300));
    await h.settle(tester);
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

  /// The badge of [card] (found by its key) that shows the text [n]; matches
  /// nothing when the card has no badge or the badge shows another number.
  Finder badgeOf(Finder card, String n) => find.ancestor(
    of: find.descendant(of: card, matching: find.text(n)),
    matching: find.byKey(songTileBadgeKey),
  );

  Finder coverOf(Finder card) =>
      find.descendant(of: card, matching: find.byType(TrackCover));

  testWidgets('badgeOf matches only the badge with the asked number', (
    tester,
  ) async {
    await _pump(tester);
    final card = find.byType(KMediaCard).first;
    expect(badgeOf(card, '1'), findsOneWidget);
    expect(badgeOf(card, '2'), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('each row shows its number as a badge in the cover corner', (
    tester,
  ) async {
    await _pump(tester);
    final cards = find.byType(KMediaCard);
    expect(cards, findsNWidgets(3));
    for (var n = 1; n <= 3; n++) {
      final card = cards.at(n - 1);
      expect(find.descendant(of: card, matching: find.text('$n')), findsOne);
      final cover = tester.getRect(coverOf(card));
      final badge = tester.getRect(badgeOf(card, '$n'));
      expect(cover.contains(badge.topLeft), isTrue);
      expect(badge.right, closeTo(cover.right - 4, 0.01));
      expect(badge.bottom, closeTo(cover.bottom - 4, 0.01));
      // Round for one digit.
      expect(badge.width, closeTo(badge.height, 0.5));
      // The cover sits at the row inset like every list.
      expect(cover.left - tester.getTopLeft(card).dx, lessThan(20));
    }
    await unmountApp(tester);
  });

  testWidgets('the badge is hidden while the row is selected', (tester) async {
    await _pump(tester);
    final card = find.byType(KMediaCard).first;
    expect(find.descendant(of: card, matching: find.text('1')), findsOne);
    await tester.longPress(card);
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.widget<KMediaCard>(card).selected, isTrue);
    expect(find.descendant(of: card, matching: find.text('1')), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('the badge is above the playing overlay, equalizer centred', (
    tester,
  ) async {
    final h = await _pump(tester);
    final id = tester.widget<SongTile>(find.byType(SongTile).first).info.id;
    h.setNowPlaying(NowPlaying(entryId: 1, trackId: id, playing: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final card = find.byType(KMediaCard).first;
    // Paint order: the badge comes after the overlay in the same Stack.
    final stack = find
        .ancestor(of: coverOf(card), matching: find.byType(Stack))
        .first;
    final children = tester.widget<Stack>(stack).children;
    final overlay = children.indexWhere(
      (w) => w is Positioned && w.left == 0 && w.right == 0,
    );
    final badge = children.indexWhere((w) => w.key == songTileBadgeKey);
    expect(overlay, greaterThanOrEqualTo(0));
    expect(badge, greaterThan(overlay));
    expect(find.descendant(of: card, matching: find.text('1')), findsOne);
    final cover = tester.getRect(coverOf(card));
    expect(
      tester.getCenter(find.byType(KEqualizerIcon)),
      offsetMoreOrLessEquals(cover.center, epsilon: 0.5),
    );
    await unmountApp(tester);
  });

  testWidgets('text scale 2 clamps the badge font to 1.3, no overflow', (
    tester,
  ) async {
    await _pump(tester, header: (page) => _scaled(2, page));
    final text = tester.widget<Text>(find.text('1'));
    expect(text.textScaler!.scale(10), closeTo(13, 0.001));
    final card = find.byType(KMediaCard).first;
    final cover = tester.getRect(coverOf(card));
    expect(cover.contains(tester.getRect(badgeOf(card, '1')).topLeft), isTrue);
    expect(tester.takeException(), isNull);
    await unmountApp(tester);
  });

  testWidgets('a 3-digit number grows the badge but stays inside the cover', (
    tester,
  ) async {
    await _pump(
      tester,
      header: (page) => _scaled(2, page),
      extra: (h) => addLibraryTrack(
        h.db,
        source: h.sourceId,
        locator: 'Blue/123.flac',
        title: 'Blue big',
        artists: ['Zed'],
        album: 'Blue',
        albumArtist: 'Zed',
        year: 2001,
        trackNo: 123,
        durationMs: 60000,
      ),
    );
    final card = find.ancestor(
      of: find.text('Blue big'),
      matching: find.byType(KMediaCard),
    );
    final cover = tester.getRect(coverOf(card));
    final badge = tester.getRect(badgeOf(card, '123'));
    expect(badge.width, greaterThan(badge.height));
    expect(badge.left, greaterThanOrEqualTo(cover.left));
    expect(badge.right, lessThanOrEqualTo(cover.right));
    expect(badge.top, greaterThanOrEqualTo(cover.top));
    expect(tester.takeException(), isNull);
    await unmountApp(tester);
  });

  testWidgets('a song without a track number has no badge', (tester) async {
    await _pump(
      tester,
      extra: (h) => addLibraryTrack(
        h.db,
        source: h.sourceId,
        locator: 'Blue/none.flac',
        title: 'Blue none',
        artists: ['Zed'],
        album: 'Blue',
        albumArtist: 'Zed',
        year: 2001,
        durationMs: 60000,
      ),
    );
    final card = find.ancestor(
      of: find.text('Blue none'),
      matching: find.byType(KMediaCard),
    );
    expect(card, findsOneWidget);
    expect(badgeOf(card, ''), findsNothing);
    expect(tester.takeException(), isNull);
    await unmountApp(tester);
  });

  testWidgets('track number 0 or below has no badge', (tester) async {
    await _pump(
      tester,
      extra: (h) => addLibraryTrack(
        h.db,
        source: h.sourceId,
        locator: 'Blue/zero.flac',
        title: 'Blue zero',
        artists: ['Zed'],
        album: 'Blue',
        albumArtist: 'Zed',
        year: 2001,
        trackNo: 0,
        durationMs: 60000,
      ),
    );
    final card = find.ancestor(
      of: find.text('Blue zero'),
      matching: find.byType(KMediaCard),
    );
    expect(card, findsOneWidget);
    expect(badgeOf(card, '0'), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('the badge sits at the left-bottom in RTL', (tester) async {
    await _pump(
      tester,
      header: (page) =>
          Directionality(textDirection: TextDirection.rtl, child: page),
    );
    final card = find.byType(KMediaCard).first;
    final cover = tester.getRect(coverOf(card));
    final badge = tester.getRect(badgeOf(card, '1'));
    expect(badge.left, closeTo(cover.left + 4, 0.01));
    expect(badge.bottom, closeTo(cover.bottom - 4, 0.01));
    await unmountApp(tester);
  });

  testWidgets('the track number is read once by screen readers', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);
    // Exactly one semantics node of the page reads the first row's number.
    expect(find.semantics.byLabel(RegExp(r'(^|\n)1($|\n)')), findsOne);
    handle.dispose();
    await unmountApp(tester);
  });

  testWidgets('a loading row of the list has the loaded rows cover x', (
    tester,
  ) async {
    // Loader that never answers: every row stays a skeleton.
    await _pump(
      tester,
      overrides: [
        trackRowLoaderProvider.overrideWithValue(
          (ids) => Completer<List<TrackInfo>>().future,
        ),
      ],
    );
    final skeleton = find.descendant(
      of: find.byType(KMediaCard),
      matching: find.byType(KCover),
    );
    expect(skeleton, findsWidgets);
    final loadingX = tester.getTopLeft(skeleton.first).dx;
    await unmountApp(tester);

    await _pump(tester);
    final loaded = find.descendant(
      of: find.byType(KMediaCard).first,
      matching: find.byType(TrackCover),
    );
    expect(tester.getTopLeft(loaded).dx, closeTo(loadingX, 0.5));
    await unmountApp(tester);
  });
}

Widget _scaled(double scale, Widget page) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: page,
  ),
);
