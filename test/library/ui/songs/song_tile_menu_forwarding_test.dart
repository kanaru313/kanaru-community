import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/ui/menus/menu_model.dart';
import 'package:kanaru/src/library/ui/menus/more_button.dart';
import 'package:kanaru/src/library/ui/songs/song_tile.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../browse/support/library_fixture.dart';
import '../menus/menu_fixtures.dart';
import '../menus/menu_pump.dart';
import '../support/library_harness.dart';

const _extra = 'Extra page row';

/// A real song in a test library, listed by a [SongTile] that passes
/// `menuExtras` and `menuFavoriteRow: false` to its menu.
Future<void> _pump(WidgetTester tester, {required double width}) async {
  final h = await pumpLibrary(
    tester,
    initial: '/library/songs',
    width: width,
    height: 800,
  );
  final id = await addLibraryTrack(
    h.db,
    source: h.sourceId,
    locator: 'Blue/1.flac',
    title: 'So What',
    artists: ['Miles'],
    album: 'Blue',
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: h.container,
      child: MaterialApp(
        theme: buildKanaruTheme(brightness: Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SongTile(
            info: trackInfo(id: id),
            index: 0,
            ids: [trackInfo(id: id).id],
            playContext: const PlayContext(PlayContextKind.songs),
            menuFavoriteRow: false,
            menuExtras: const [
              MenuItemSpec(
                MenuItemId.playlistRemove,
                icon: KIcons.close,
                title: _extra,
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void _expectForwarded(WidgetTester tester) {
  expect(find.text(_extra), findsOneWidget);
  expect(find.text(l10n.libraryFavoriteAdd), findsNothing);
  expect(find.text(l10n.libraryFavoriteRemove), findsNothing);
}

void main() {
  testWidgets('the ⋮ menu carries the page rows and no heart row', (
    tester,
  ) async {
    await _pump(tester, width: 400);
    await tester.tap(find.byType(LibraryMoreButton));
    await pumpMenu(tester);
    _expectForwarded(tester);
  });

  testWidgets('right click carries them too', (tester) async {
    await _pump(tester, width: 1400);
    await tester.tap(find.byType(KMediaCard), buttons: kSecondaryButton);
    await pumpMenu(tester);
    _expectForwarded(tester);
  });
}
