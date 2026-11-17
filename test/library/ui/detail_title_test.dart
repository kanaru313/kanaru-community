import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncLoading;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/state/browse/detail_providers.dart';
import 'package:kanaru/src/library/ui/library_locations.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/detail_fixture.dart';
import 'support/library_harness.dart';
import 'support/ui_harness.dart';

void main() {
  testWidgets('every detail page shows its name in the header only while '
      'the name is scrolled out of sight', (tester) async {
    final handle = tester.ensureSemantics();
    final h = await pumpLibrary(
      tester,
      initial: '/library/songs',
      width: 390,
      height: 844,
    );
    for (var i = 0; i < 14; i++) {
      await addAlbum(
        h,
        'Al$i',
        'Zed',
        year: 1990 + i,
        genre: 'Rock',
        language: 'en',
      );
      await addAlbum(
        h,
        'Ot$i',
        'Other$i',
        year: 1990 + i,
        genre: 'Rock',
        language: 'en',
        tracks: 1,
        trackArtists: ['Other$i', 'Zed'],
      );
      await addAlbum(h, 'Nl$i', 'Nob$i', year: 1990 + i);
    }
    await h.settle(tester);
    final artist = LibraryLocations.artist(ArtistKey('zed'));
    final pages = <String, String>{
      artist: 'Zed',
      '$artist/albums': 'Albums · Zed',
      '$artist/appears': 'Appears on · Zed',
      LibraryLocations.genre('rock'): 'Rock',
      '${LibraryLocations.genre('rock')}/artists': 'Artists · Rock',
      '${LibraryLocations.genre('rock')}/albums': 'Albums · Rock',
      LibraryLocations.language('eng'): 'English',
      LibraryLocations.language(null): 'Unknown',
    };
    for (final e in pages.entries) {
      h.router.go(e.key);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await h.settle(tester, rounds: 3);
      expect(inPageHeader(e.value), findsNothing, reason: e.key);
      expect(headerNodes(tester, e.value), 1, reason: e.key);
      final list = find.byType(CustomScrollView).last;
      await tester.drag(list, const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(inPageHeader(e.value), findsOneWidget, reason: e.key);
      await tester.drag(list, const Offset(0, 2000));
      await tester.pumpAndSettle();
      expect(inPageHeader(e.value), findsNothing, reason: e.key);
    }
    handle.dispose();
    await unmountApp(tester);
  });

  testWidgets('a page still waiting for its name has an empty header', (
    tester,
  ) async {
    final key = ArtistKey('zed');
    final h = await pumpLibrary(
      tester,
      initial: '/library/songs',
      overrides: [
        artistNameProvider(key).overrideWithValue(const AsyncLoading()),
      ],
    );
    await addAlbum(h, 'Old', 'Zed');
    await h.settle(tester);
    h.router.go(LibraryLocations.artist(key));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await h.settle(tester, rounds: 3);
    expect(find.byType(PageHeader), findsOneWidget);
    expect(
      find.descendant(of: find.byType(PageHeader), matching: find.byType(Text)),
      findsNothing,
    );
    await unmountApp(tester);
  });

  testWidgets('a collapsed page keeps a right header through a resize to a '
      'short wide window and back', (tester) async {
    final h = await pumpLibrary(
      tester,
      initial: '/library/songs',
      width: 400,
      height: 844,
    );
    await addAlbum(h, 'Long', 'Zed', year: 2002, tracks: 30);
    await h.settle(tester);
    h.router.push(
      LibraryLocations.album(AlbumKey.decode(albumId('Long', 'Zed'))!),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await h.settle(tester);
    await tester.drag(
      find.byType(CustomScrollView).last,
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    expect(inPageHeader('Long'), findsOneWidget);

    tester.view.physicalSize = const Size(1300, 420);
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // The wide layout keeps the name in a column that never scrolls it away.
    expect(inPageHeader('Long'), findsNothing);

    tester.view.physicalSize = const Size(400, 844);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(inPageHeader('Long'), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('a detail page pushed over a collapsed one has its own header '
      'state and the page below keeps its own', (tester) async {
    final h = await pumpLibrary(
      tester,
      initial: '/library/songs',
      width: 400,
      height: 844,
    );
    await addAlbum(h, 'Long', 'Zed', year: 2002, tracks: 30);
    await h.settle(tester);
    h.router.push(
      LibraryLocations.album(AlbumKey.decode(albumId('Long', 'Zed'))!),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await h.settle(tester);
    await tester.drag(
      find.byType(CustomScrollView).last,
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    expect(inPageHeader('Long'), findsOneWidget);

    h.router.push(LibraryLocations.artist(ArtistKey('zed')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await h.settle(tester);
    expect(inPageHeader('Zed'), findsNothing);
    expect(tester.takeException(), isNull);

    h.router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await h.settle(tester);
    expect(inPageHeader('Long'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await unmountApp(tester);
  });
}
