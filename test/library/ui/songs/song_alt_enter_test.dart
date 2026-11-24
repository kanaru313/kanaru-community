import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/ui/menus/menu_model.dart';
import 'package:kanaru/src/library/ui/songs/song_grid_card.dart';
import 'package:kanaru/src/library/ui/songs/song_tile.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/media/domain/track_info.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/icon_button_finders.dart';
import '../menus/menu_pump.dart';
import '../support/detail_fixture.dart';
import '../support/library_harness.dart';

const _extra = MenuItemSpec(
  MenuItemId.playlistRemove,
  icon: KIcons.playlistRemove,
  title: 'Remove from this playlist',
  action: MenuAction.go('/probe'),
);

/// Alt+Enter key downs that bubbled past the tile to an ancestor (the shell
/// fallback's place).
int _bubbled = 0;

Future<void> _pump(
  WidgetTester tester,
  Widget Function(TrackInfo track) build,
) async {
  _bubbled = 0;
  final h = await pumpLibrary(
    tester,
    initial: '/library/songs',
    width: 1400,
    height: 900,
  );
  // A song the database knows, so its menu does not report it missing.
  await addAlbum(h, 'Blue', 'Zed', year: 2001);
  await h.settle(tester);
  final track = tester.widgetList<SongTile>(find.byType(SongTile)).first.info;
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: h.container,
      child: MaterialApp(
        theme: buildKanaruTheme(brightness: Brightness.light),
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: Focus(
              canRequestFocus: false,
              onKeyEvent: (_, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.enter &&
                    HardwareKeyboard.instance.isAltPressed) {
                  _bubbled++;
                }
                return KeyEventResult.ignored;
              },
              child: build(track),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _altEnter(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
  await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('Alt+Enter on a focused history row opens its info, whose ⋮ '
      'keeps the row rows', (tester) async {
    await _pump(
      tester,
      (t) => SongTile(
        info: t,
        index: 0,
        ids: [t.id],
        playContext: const PlayContext(PlayContextKind.songs),
        menuExtras: const [_extra],
        menuFavoriteRow: false,
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await _altEnter(tester);
    expect(find.byType(KOverlayPageScope), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(KOverlayPageScope),
        matching: byIconButton('More options'),
      ),
    );
    await pumpMenu(tester);
    expect(find.text('Remove from this playlist'), findsOneWidget);
  });

  testWidgets('a held Alt+Enter on a row opens one info route', (tester) async {
    await _pump(
      tester,
      (t) => SongTile(
        info: t,
        index: 0,
        ids: [t.id],
        playContext: const PlayContext(PlayContextKind.songs),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(KOverlayPageScope), findsOneWidget);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
  });

  testWidgets('Alt+Enter on a focused grid card opens its info', (
    tester,
  ) async {
    await _pump(
      tester,
      (t) => SongGridCard(
        info: t,
        index: 0,
        ids: [t.id],
        playContext: const PlayContext(PlayContextKind.songs),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await _altEnter(tester);
    expect(find.byType(KOverlayPageScope), findsOneWidget);
  });

  for (final edit in [false, true]) {
    testWidgets(
      'a ${edit ? 'editing' : 'missing'} row takes the key and does nothing',
      (tester) async {
        await _pump(
          tester,
          (t) => SongTile(
            info: t,
            index: 0,
            ids: [t.id],
            playContext: const PlayContext(PlayContextKind.songs),
            unavailable: !edit,
            // A reachable missing row: it has a menu, so it takes focus.
            onUnavailableTap: edit ? null : () {},
            onMenu: edit ? null : ({required bool viaKeyboard}) async {},
            edit: edit
                ? SongTileEdit(
                    handle: const SizedBox(),
                    removeLabel: 'Remove',
                    onRemove: () async => true,
                  )
                : null,
          ),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await _altEnter(tester);
        expect(find.byType(KOverlayPageScope), findsNothing);
        expect(_bubbled, 0, reason: 'the row consumes the key');
      },
    );
  }
}
