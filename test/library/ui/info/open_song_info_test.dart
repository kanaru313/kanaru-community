import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/state/favorites_providers.dart';
import 'package:kanaru/src/library/ui/info/open_song_info.dart';
import 'package:kanaru/src/library/ui/menus/menu_model.dart';
import 'package:kanaru/src/library/ui/library_locations.dart';
import 'package:kanaru/src/library/ui/songs/song_tile.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/platform/state/file_manager_provider.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/icon_button_finders.dart';
import '../menus/menu_fakes.dart';
import '../menus/menu_pump.dart';
import '../support/detail_fixture.dart';
import '../support/library_harness.dart';
import '../support/ui_harness.dart';
import 'song_info_harness.dart' show link;

Future<LibraryHarness> _pump(
  WidgetTester tester, {
  String initial = '/library/songs',
  double width = 390,
  List<Override> extra = const [],
}) async {
  final h = await pumpLibrary(
    tester,
    initial: initial,
    width: width,
    // Tall: the info list builds only what is on screen.
    height: 2600,
    overrides: [
      fileManagerProvider.overrideWithValue(FakeFileManager()),
      ...extra,
    ],
  );
  await addAlbum(h, 'Blue', 'Zed', year: 2001);
  await addAlbum(h, 'Amber', 'Yan', year: 2010);
  await h.settle(tester);
  return h;
}

Finder get _info => find.byType(KOverlayPageScope);
Finder get _sheet => find.byType(BottomSheet);
Finder _moreOfTile() => find.descendant(
  of: find.byType(SongTile).first,
  matching: find.byIcon(KIcons.moreVert),
);

Finder _infoMore() =>
    find.descendant(of: _info, matching: byIconButton('More options'));

BuildContext _tile(WidgetTester tester) =>
    tester.element(find.byType(SongTile).first);

SongTile _firstTile(WidgetTester tester) =>
    tester.widget<SongTile>(find.byType(SongTile).first);

/// Opens the song menu of the first row and then its info with `›`.
Future<void> _menuThenInfo(WidgetTester tester) async {
  await tester.tap(_moreOfTile());
  await pumpMenu(tester);
  final title = _firstTile(tester).info.title;
  await tester.tap(find.descendant(of: _sheet, matching: find.text(title)));
  await pumpMenu(tester);
}

void main() {
  testWidgets('menu > info: Esc closes the info only, Esc again the menu', (
    tester,
  ) async {
    await _pump(tester);
    await _menuThenInfo(tester);
    expect(_info, findsOneWidget);
    expect(_sheet, findsOneWidget);
    // The menu is below: no ⋮ in the info header.
    expect(_infoMore(), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await pumpMenu(tester);
    expect(_info, findsNothing);
    expect(_sheet, findsOneWidget);
    await tester.tapAt(const Offset(195, 20));
    await pumpMenu(tester);
    expect(_sheet, findsNothing);
    await unmountApp(tester);
  });

  testWidgets('menu > info: ← returns to the menu', (tester) async {
    await _pump(tester);
    await _menuThenInfo(tester);
    await tester.tap(
      find.descendant(of: _info, matching: byIconButton('Back')),
    );
    await pumpMenu(tester);
    expect(_info, findsNothing);
    expect(find.text('Go to artist'), findsOneWidget);
    await tester.tapAt(const Offset(195, 20));
    await pumpMenu(tester);
    await unmountApp(tester);
  });

  testWidgets(
    'a link of the info closes info and menu and pushes the page; Back returns',
    (tester) async {
      final h = await _pump(tester);
      await _menuThenInfo(tester);
      await tester.tap(link('Yan').first);
      await pumpMenu(tester);
      expect(_info, findsNothing);
      expect(_sheet, findsNothing);
      expect(h.location, LibraryLocations.artist(ArtistKey(groupKey('Yan'))));
      h.router.pop();
      await tester.pumpAndSettle();
      expect(h.location, '/library/songs');
      await unmountApp(tester);
    },
  );

  testWidgets('opened straight: ← goes back to the page; a link pushes', (
    tester,
  ) async {
    final h = await _pump(tester);
    unawaited(openSongInfo(_tile(tester), _firstTile(tester).info));
    await pumpMenu(tester);
    expect(_info, findsOneWidget);
    expect(_sheet, findsNothing);
    expect(find.text('Amber 1'), findsWidgets);
    await tester.tap(link('Amber'));
    await pumpMenu(tester);
    expect(_info, findsNothing);
    expect(h.location, startsWith('/library/albums/'));
    h.router.pop();
    await tester.pumpAndSettle();
    expect(h.location, '/library/songs');
    await unmountApp(tester);
  });

  testWidgets('a second open while one is open does nothing', (tester) async {
    await _pump(tester);
    final info = _firstTile(tester).info;
    final context = _tile(tester);
    unawaited(openSongInfo(context, info));
    unawaited(openSongInfo(context, info));
    await pumpMenu(tester);
    expect(_info, findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await pumpMenu(tester);
    expect(_info, findsNothing);
    await unmountApp(tester);
  });

  testWidgets(
    'the ⋮ of a straight info opens the menu with the page rows; › only closes it',
    (tester) async {
      await _pump(tester);
      const extra = MenuItemSpec(
        MenuItemId.playlistRemove,
        icon: KIcons.playlistRemove,
        title: 'Remove from this playlist',
        action: MenuAction.go('/probe'),
      );
      unawaited(
        openSongInfo(
          _tile(tester),
          _firstTile(tester).info,
          playlistGroup: const [extra],
          favoriteRow: false,
        ),
      );
      await pumpMenu(tester);
      await tester.tap(_infoMore());
      await pumpMenu(tester);
      expect(_sheet, findsOneWidget);
      expect(find.text('Remove from this playlist'), findsOneWidget);
      expect(find.text('Add to favorites'), findsNothing);
      expect(find.text('Remove from favorites'), findsNothing);
      // › of that menu closes it; the info stays.
      final title = _firstTile(tester).info.title;
      await tester.tap(find.descendant(of: _sheet, matching: find.text(title)));
      await pumpMenu(tester);
      expect(_sheet, findsNothing);
      expect(_info, findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await pumpMenu(tester);
      await unmountApp(tester);
    },
  );

  testWidgets(
    'a "Go to" row of the menu over the info closes both and pushes',
    (tester) async {
      final h = await _pump(tester);
      unawaited(openSongInfo(_tile(tester), _firstTile(tester).info));
      await pumpMenu(tester);
      await tester.tap(_infoMore());
      await pumpMenu(tester);
      await tester.tap(find.text('Go to album'));
      await pumpMenu(tester);
      expect(_info, findsNothing);
      expect(_sheet, findsNothing);
      expect(h.location, startsWith('/library/albums/'));
      await unmountApp(tester);
    },
  );

  testWidgets('a link to the page already open only closes the info', (
    tester,
  ) async {
    final h = await _pump(
      tester,
      initial: '/library/songs', // album page is pushed below
    );
    h.router.push(
      LibraryLocations.album(AlbumKey.decode(albumId('Blue', 'Zed'))!),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await h.settle(tester);
    final albumPage = h.location;
    unawaited(openSongInfo(_tile(tester), _firstTile(tester).info));
    await pumpMenu(tester);
    await tester.tap(link('Blue'));
    await pumpMenu(tester);
    expect(_info, findsNothing);
    expect(h.location, albumPage);
    await unmountApp(tester);
  });

  testWidgets('the heart of the info flips the heart row of the menu below', (
    tester,
  ) async {
    await _pump(tester);
    await _menuThenInfo(tester);
    expect(find.text('Add to favorites', skipOffstage: false), findsOneWidget);
    await tester.tap(find.widgetWithText(KChip, 'Not a favorite'));
    await pumpMenu(tester);
    expect(find.widgetWithText(KChip, 'Favorite'), findsOneWidget);
    expect(
      find.text('Remove from favorites', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('Add to favorites', skipOffstage: false), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await pumpMenu(tester);
    await tester.tapAt(const Offset(195, 20));
    await pumpMenu(tester);
    await unmountApp(tester);
  });

  testWidgets(
    'the heart row of the menu toggles in place and keeps the menu open',
    (tester) async {
      final h = await _pump(tester);
      await tester.tap(_moreOfTile());
      await pumpMenu(tester);
      await tester.tap(find.text('Add to favorites'));
      await pumpMenu(tester);
      expect(_sheet, findsOneWidget);
      expect(find.text('Remove from favorites'), findsOneWidget);
      expect(
        h.container.read(isFavoriteProvider(_firstTile(tester).info.id)),
        isTrue,
      );
      await tester.tapAt(const Offset(195, 20));
      await pumpMenu(tester);
      await unmountApp(tester);
    },
  );

  testWidgets('desktop: the info is a box over the menu', (tester) async {
    await _pump(tester, width: 1300);
    unawaited(openSongInfo(_tile(tester), _firstTile(tester).info));
    await pumpMenu(tester);
    expect(tester.widget<KOverlayPageScope>(_info).kind, KOverlayKind.box);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await pumpMenu(tester);
    await unmountApp(tester);
  });
}
