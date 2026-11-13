import 'dart:async';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart' show TrackStatus;
import 'package:kanaru/src/library/state/favorites_providers.dart';
import 'package:kanaru/src/library/state/folder_exclusion_providers.dart';
import 'package:kanaru/src/library/ui/collections/album_tile.dart';
import 'package:kanaru/src/library/ui/menus/open_menu.dart';
import 'package:kanaru/src/library/ui/songs/song_tile.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/platform/state/file_manager_provider.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/fake_playback_commands.dart';
import '../support/detail_fixture.dart';
import '../support/library_harness.dart';
import '../support/ui_harness.dart';
import 'menu_fakes.dart';
import 'menu_pump.dart';

Future<LibraryHarness> _pump(
  WidgetTester tester, {
  String initial = '/library/songs',
  double width = 390,
  FakePlaybackCommands? playback,
  bool canReveal = true,
  FakeFolderExclusions? exclusions,
}) async {
  final h = await pumpLibrary(
    tester,
    initial: initial,
    width: width,
    height: width > 1000 ? 800 : 844,
    playback: playback,
    overrides: [
      fileManagerProvider.overrideWithValue(
        FakeFileManager(canReveal: canReveal),
      ),
      if (exclusions != null)
        folderExclusionsProvider.overrideWithValue(exclusions),
    ],
  );
  await addAlbum(h, 'Blue', 'Zed', year: 2001);
  await addAlbum(h, 'Amber', 'Yan', year: 2010);
  await h.settle(tester);
  return h;
}

Finder _firstMore() => find.descendant(
  of: find.byType(SongTile).first,
  matching: find.byIcon(KIcons.moreVert),
);

/// Moves a mouse over [finder], so the ⋮ of a desktop row shows.
Future<void> _hover(WidgetTester tester, Finder finder) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  addTearDown(mouse.removePointer);
  await mouse.moveTo(tester.getCenter(finder));
  await tester.pump(const Duration(milliseconds: 200));
}

/// The desktop dialog scrolls; "Advanced" is its last row.
Future<void> _tapAdvanced(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Advanced'),
    100,
    scrollable: find
        .descendant(of: find.byType(Dialog), matching: find.byType(Scrollable))
        .first,
  );
  await tester.tap(find.text('Advanced'));
  await pumpMenu(tester);
}

Finder _sheet() => find.byType(BottomSheet);

Finder _dialog() => find.byType(Dialog);

void main() {
  testWidgets('the ⋮ of a song opens its menu on the mobile shell', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(_firstMore());
    await pumpMenu(tester);
    expect(_sheet(), findsOneWidget);
    expect(
      find.descendant(of: _sheet(), matching: find.text('Amber 1')),
      findsOneWidget,
    );
    expect(find.text('Go to album'), findsOneWidget);
    expect(find.text('Add to favorites'), findsWidgets);
    expect(find.text('Play next'), findsOneWidget);
    expect(find.text('Add to queue'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('the menu is a centred dialog on desktop; Esc closes it', (
    tester,
  ) async {
    await _pump(tester, width: 1280);
    await _hover(tester, find.byType(SongTile).first);
    await tester.tap(_firstMore());
    await pumpMenu(tester);
    expect(_dialog(), findsOneWidget);
    expect(_sheet(), findsNothing);
    final box = tester.getRect(
      find
          .descendant(of: _dialog(), matching: find.byType(ConstrainedBox))
          .first,
    );
    expect(box.center.dx, closeTo(640, 1));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await pumpMenu(tester);
    expect(_dialog(), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('right click opens the menu on desktop', (tester) async {
    await _pump(tester, width: 1280);
    final tile = find.byType(SongTile).first;
    final gesture = await tester.startGesture(
      tester.getCenter(tile),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await gesture.up();
    await pumpMenu(tester);
    expect(_dialog(), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('Shift+F10 opens the menu of the focused row', (tester) async {
    await _pump(tester, width: 1280);
    Focus.of(tester.element(_firstMore())).requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.f10);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await pumpMenu(tester);
    expect(_dialog(), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets(
    'long press on an album card opens its menu, on a song it does not',
    (tester) async {
      final h = await _pump(tester, initial: '/library/albums');
      await tester.longPress(find.byType(AlbumCard).first);
      await pumpMenu(tester);
      expect(_sheet(), findsOneWidget);
      expect(
        find.descendant(of: _sheet(), matching: find.text('Amber')),
        findsWidgets,
      );
      await tester.tapAt(const Offset(195, 20));
      await pumpMenu(tester);
      expect(_sheet(), findsNothing);

      h.router.go('/library/songs');
      await tester.pump();
      await h.settle(tester);
      await tester.longPress(find.byType(SongTile).first);
      await pumpMenu(tester);
      expect(_sheet(), findsNothing);
      await unmountApp(tester);
    },
  );

  testWidgets('a sub-page replaces the menu; the arrow and Esc return', (
    tester,
  ) async {
    await _pump(tester, width: 1280);
    await _hover(tester, find.byType(SongTile).first);
    await tester.tap(_firstMore());
    await pumpMenu(tester);
    await _tapAdvanced(tester);
    expect(find.text('Find lyrics online…'), findsOneWidget);
    expect(find.text('Go to album'), findsNothing);
    await tester.tap(find.byTooltip('Back'));
    await pumpMenu(tester);
    // Back lands where the page was left: Advanced is still in view.
    expect(find.text('Advanced'), findsOneWidget);
    await _tapAdvanced(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await pumpMenu(tester);
    expect(_dialog(), findsOneWidget);
    expect(find.text('Advanced'), findsOneWidget);
    expect(find.text('Find lyrics online…'), findsNothing);
    await unmountApp(tester);
  });

  testWidgets('the footer queues the ids captured when the menu opened', (
    tester,
  ) async {
    final playback = FakePlaybackCommands();
    final h = await _pump(
      tester,
      initial: '/library/albums',
      playback: playback,
    );
    await tester.tap(
      find.descendant(
        of: find.byType(AlbumCard).first,
        matching: find.byIcon(KIcons.moreVert),
      ),
    );
    await pumpMenu(tester);
    // A song arrives after the menu opened: the buttons keep their ids.
    await addAlbum(h, 'Amber', 'Yan', year: 2010, tracks: 5);
    // Same album, now with 5 songs: the buttons still carry the 3 captured.
    final count = await h.db
        .customSelect("SELECT COUNT(*) AS n FROM tracks WHERE album = 'Amber'")
        .getSingle();
    expect(count.read<int>('n'), 5);
    await tester.tap(find.text('Play next'));
    await pumpMenu(tester);
    final call = playback.calls.single as PlayNextCall;
    expect(call.tracks.length, 3);
    expect(find.text('Playing next'), findsOneWidget);
    expect(_sheet(), findsNothing);
    // The harness puts its Scaffold above the navigator, so the toast would
    // sit over the next sheet.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(AlbumCard).first,
        matching: find.byIcon(KIcons.moreVert),
      ),
    );
    await pumpMenu(tester);
    await tester.tap(find.text('Add to queue'));
    await pumpMenu(tester);
    expect(playback.calls.last, isA<EnqueueCall>());
    expect(find.text('Added to queue'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('dimmed rows are inert and say "coming soon"', (tester) async {
    final playback = FakePlaybackCommands();
    await _pump(tester, playback: playback);
    await tester.tap(_firstMore());
    await pumpMenu(tester);
    expect(find.text('Coming soon'), findsWidgets);
    await tester.tap(find.text('Add to playlist…'));
    await pumpMenu(tester);
    expect(_sheet(), findsOneWidget);
    expect(playback.calls, isEmpty);
    await unmountApp(tester);
  });

  testWidgets('Go to artist pushes the page; Back returns to the list', (
    tester,
  ) async {
    final h = await _pump(tester);
    await tester.tap(_firstMore());
    await pumpMenu(tester);
    await tester.tap(find.text('Go to artist'));
    await pumpMenu(tester);
    await h.settle(tester);
    final artist = ArtistKey(groupKey('Yan'));
    expect(h.location, contains(artist.encode()));
    h.router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(h.location, '/library/songs');
    await unmountApp(tester);
  });

  testWidgets('the menu of a song on its album page has no link back', (
    tester,
  ) async {
    final h = await _pump(tester);
    h.router.push('/library/albums/${albumId('Blue', 'Zed')}');
    await tester.pump(const Duration(milliseconds: 400));
    await h.settle(tester);
    await tester.tap(_firstMore());
    await pumpMenu(tester);
    expect(find.text('Go to album'), findsNothing);
    expect(find.text('Go to artist'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('the ♥ row sets the favorite of the captured track', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(_firstMore());
    await pumpMenu(tester);
    await tester.tap(
      find.descendant(of: _sheet(), matching: find.text('Add to favorites')),
    );
    await pumpMenu(tester);
    await tester.tap(_firstMore());
    await pumpMenu(tester);
    expect(
      find.descendant(
        of: _sheet(),
        matching: find.text('Remove from favorites'),
      ),
      findsOneWidget,
    );
    await unmountApp(tester);
  });

  testWidgets('a track that is gone says so instead of opening', (
    tester,
  ) async {
    final h = await _pump(tester);
    final info = tester.widget<SongTile>(find.byType(SongTile).first).info;
    await h.db.customUpdate(
      'UPDATE tracks SET status = ?, missing_since = ? WHERE id = ?',
      variables: [
        Variable.withString(TrackStatus.missing),
        Variable.withInt(1),
        Variable.withInt(info.id.value),
      ],
      updates: {h.db.tracks},
    );
    await tester.tap(_firstMore());
    await pumpMenu(tester);
    expect(_sheet(), findsNothing);
    expect(find.text('This is no longer in your library.'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets(
    'a menu read that never ends is given up, and the next tap tries',
    (tester) async {
      final h = await pumpLibrary(
        tester,
        overrides: [
          favoriteTrackIdsProvider.overrideWith((ref) => const Stream.empty()),
        ],
      );
      await addAlbum(h, 'Blue', 'Zed');
      await h.settle(tester);
      await tester.tap(_firstMore());
      await tester.pump(const Duration(seconds: 11));
      expect(find.text('Could not open the menu'), findsOneWidget);
      expect(_sheet(), findsNothing);
      // The flag is free again: a second tap starts a new load, which fails
      // the same way.
      await tester.pump(const Duration(seconds: 5));
      await tester.tap(_firstMore());
      await tester.pump(const Duration(seconds: 11));
      expect(find.text('Could not open the menu'), findsOneWidget);
      await unmountApp(tester);
    },
  );

  testWidgets('song info opens on the info page; Back shows the song menu', (
    tester,
  ) async {
    await _pump(tester);
    final tile = tester.widget<SongTile>(find.byType(SongTile).first);
    unawaited(
      openSongInfo(tester.element(find.byType(SongTile).first), tile.info),
    );
    await pumpMenu(tester);
    expect(_sheet(), findsOneWidget);
    expect(find.byIcon(KIcons.back), findsOneWidget);
    expect(find.text('Go to album'), findsNothing);
    await tester.tap(find.byIcon(KIcons.back));
    await tester.pumpAndSettle();
    expect(find.text('Go to album'), findsOneWidget);
    expect(find.text('Play next'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('song info of a song that is gone says so, opens nothing', (
    tester,
  ) async {
    final h = await _pump(tester);
    final tile = tester.widget<SongTile>(find.byType(SongTile).first);
    final context = tester.element(find.byType(SongTile).first);
    await h.db.customUpdate(
      'UPDATE tracks SET status = ?, missing_since = ? WHERE id = ?',
      variables: [
        Variable.withString(TrackStatus.missing),
        Variable.withInt(1),
        Variable.withInt(tile.info.id.value),
      ],
      updates: {h.db.tracks},
    );
    unawaited(openSongInfo(context, tile.info));
    await pumpMenu(tester);
    expect(_sheet(), findsNothing);
    expect(find.text('This is no longer in your library.'), findsOneWidget);
    expect(find.text("Could not open the menu"), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await unmountApp(tester);
  });
}
