import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/library_tabs.dart';
import 'package:kanaru/src/library/ui/collections/album_tile.dart';
import 'package:kanaru/src/library/ui/library_locations.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import 'support/detail_fixture.dart';
import 'support/library_harness.dart';
import 'support/ui_harness.dart';

void main() {
  testWidgets('every library location opens its page', (tester) async {
    final h = await pumpLibrary(tester, initial: '/library/songs');
    await addAlbum(h, 'Old', 'Zed', year: 1999, genre: 'Rock', language: 'en');
    await addAlbum(h, 'New', 'Zed', year: 2020, genre: 'Rock', language: 'en');
    await h.settle(tester);
    final album = AlbumKey.decode(albumId('Old', 'Zed'))!;
    final artist = ArtistKey('zed');
    final locations = <String, String>{
      LibraryLocations.album(album): 'Old',
      LibraryLocations.artist(artist): 'Zed',
      '${LibraryLocations.artist(artist)}/albums': 'Albums · Zed',
      '${LibraryLocations.artist(artist)}/appears': 'Appears on · Zed',
      LibraryLocations.genre('rock'): 'Rock',
      '${LibraryLocations.genre('rock')}/artists': 'Artists · Rock',
      '${LibraryLocations.genre('rock')}/albums': 'Albums · Rock',
      LibraryLocations.language('eng'): 'English',
      '${LibraryLocations.language('eng')}/artists': 'Artists · English',
      '${LibraryLocations.language('eng')}/albums': 'Albums · English',
    };
    for (final entry in locations.entries) {
      h.router.go(entry.key);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await h.settle(tester, rounds: 3);
      expect(h.location, entry.key);
      expect(
        find.descendant(
          of: find.byType(PageHeader),
          matching: find.textContaining(entry.value),
        ),
        findsOneWidget,
        reason: entry.key,
      );
      expect(find.text('Not found'), findsNothing, reason: entry.key);
    }
    await unmountApp(tester);
  });

  testWidgets('Back steps one page at a time through pushed pages', (
    tester,
  ) async {
    final h = await pumpLibrary(tester, initial: '/library/genres');
    await addAlbum(h, 'Old', 'Zed', year: 1999, genre: 'Rock');
    await addAlbum(h, 'New', 'Zed', year: 2020, genre: 'Rock');
    await h.settle(tester);
    final genre = LibraryLocations.genre('rock');
    Future<void> settle() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await h.settle(tester, rounds: 3);
    }

    await tester.tap(find.text('Rock'));
    await settle();
    expect(h.location, genre);
    // Shelf album card -> album page -> artist link -> artist page.
    await tester.tap(find.byType(AlbumCard).first);
    await settle();
    expect(h.location, startsWith('/library/albums/'));
    await tester.tap(find.text('Zed').first);
    await settle();
    expect(h.location, startsWith('/library/artists/'));
    h.router.pop();
    await settle();
    expect(h.location, startsWith('/library/albums/'));
    h.router.pop();
    await settle();
    expect(h.location, genre);
    // The on-screen back button does the same.
    await tester.tap(find.byTooltip('Back'));
    await settle();
    expect(h.location, '/library/genres');
    await unmountApp(tester);
  });

  testWidgets('a page opened from outside goes back to its list', (
    tester,
  ) async {
    final h = await pumpLibrary(tester, initial: '/library/songs');
    await addAlbum(h, 'Old', 'Zed');
    await h.settle(tester);
    h.router.go(LibraryLocations.artist(ArtistKey('zed')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await h.settle(tester, rounds: 3);
    expect(h.router.canPop(), isFalse);
    await tester.tap(find.byTooltip('Back'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(h.location, LibraryLocations.list(LibraryTab.artists));
    await unmountApp(tester);
  });

  testWidgets('the grid has album cards sized like the Albums list', (
    tester,
  ) async {
    final h = await pumpLibrary(tester, initial: '/library/songs', width: 1280);
    await addAlbum(h, 'Old', 'Zed', year: 1999);
    await addAlbum(h, 'New', 'Zed', year: 2020);
    await h.settle(tester);
    h.router.go('${LibraryLocations.artist(ArtistKey('zed'))}/albums');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await h.settle(tester, rounds: 3);
    final cards = find.byType(AlbumCard);
    expect(cards, findsNWidgets(2));
    // Newest first.
    expect(
      tester.getTopLeft(find.text('Zed · 2020')).dx,
      lessThan(tester.getTopLeft(find.text('Zed · 1999')).dx),
    );
    await unmountApp(tester);
  });
}
