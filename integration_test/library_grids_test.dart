import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/rendering.dart' show OffsetLayer;
import 'package:flutter/widgets.dart' show Offset, Size, Text;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/library/domain/browse/list_sort.dart';
import 'package:kanaru/src/library/domain/browse/list_view_prefs.dart';
import 'package:kanaru/src/library/state/browse/list_prefs_providers.dart';
import 'package:kanaru/src/library/state/browse/selection_providers.dart';
import 'package:kanaru/src/library/ui/collections/album_tile.dart';
import 'package:kanaru/src/library/ui/songs/song_grid_card.dart';
import 'package:kanaru/src/library/ui/songs/song_tile.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru/src/router/state/router_provider.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart' show Navigator;

import 'support/harness.dart';

/// The Songs grid and the Albums grid on the real app: rows → grid switch,
/// a tap plays, a long press selects, the album cards. Screenshots are for
/// comparing with `mockups/` (04a) by eye and never fail the test: on Linux
/// the app's own root layer to `/tmp/kanaru-it/shots/`, on Android the line
/// `KANARU_SHOT <name>` and a pause, for the runner to `adb screencap`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('songs and albums grids', (tester) async {
    final desktop = Platform.isLinux;
    if (desktop) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1400, 900);
      addTearDown(tester.view.reset);
    }
    final app = await startKanaru(tester);
    final container = app.container;
    final router = container.read(routerProvider);

    Future<void> settle([int ms = 600]) async {
      final end = DateTime.now().add(Duration(milliseconds: ms));
      while (DateTime.now().isBefore(end)) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    }

    var width = desktop ? 'desktop' : 'phone';
    Future<void> shot(String name) async {
      await settle();
      final full = '$width-$name';
      try {
        if (desktop) {
          final view = tester.binding.renderViews.first;
          final layer = view.debugLayer! as OffsetLayer;
          final image = await layer.toImage(Offset.zero & view.size);
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!;
          final dir = Directory('/tmp/kanaru-it/shots')
            ..createSync(recursive: true);
          File('${dir.path}/linux-grids-$full.png')
              .writeAsBytesSync(bytes.buffer.asUint8List());
        } else {
          debugPrint('KANARU_SHOT $full');
          await settle(3000);
        }
      } on Object catch (e) {
        debugPrint('screenshot $full failed: $e');
      }
    }

    AppLocalizations l10n() =>
        AppLocalizations.of(tester.element(find.byType(Navigator).first));

    Finder iconButton(String tooltip) =>
        find.byWidgetPredicate((w) => w is KIconButton && w.tooltip == tooltip);

    Future<void> songsRound() async {
      await container
          .read(libraryListViewsProvider.notifier)
          .setView(BrowseList.songs, CollectionView.list);
      router.go('/library/songs');
      await app.pumpUntil(
        () => find.byType(SongTile).evaluate().isNotEmpty,
        what: 'song rows',
      );
      await shot('songs-list');

      await tester.tap(iconButton(l10n().libraryViewGrid).first);
      await app.pumpUntil(
        () => find.byType(SongGridCard).evaluate().isNotEmpty,
        what: 'song cards after the grid switch',
      );
      expect(find.byType(SongTile), findsNothing);
      await shot('songs-grid');
      // Every text line of a card is 20 (title) or 16 tall, whatever font
      // draws it (CJK titles use a fallback font on Android).
      final odd = [
        for (final e
            in find
                .descendant(
                  of: find.byType(SongGridCard),
                  matching: find.byType(Text),
                )
                .evaluate())
          if (e.size!.height != 20 && e.size!.height != 16)
            '${(e.widget as Text).data}: ${e.size!.height}',
      ];
      expect(odd, isEmpty);

      final cards = find.byType(SongGridCard);
      final first = tester.widget<SongGridCard>(cards.first);
      await tester.tap(cards.first);
      await app.pumpUntil(
        () =>
            container.read(nowPlayingProvider).value?.trackId == first.info.id,
        what: 'the tapped card to play',
      );
      await container.read(playerControllerProvider).pause();
      await shot('songs-grid-playing');

      await tester.longPress(cards.at(1));
      await tester.pump();
      expect(container.read(librarySelectionProvider).ids, isNotEmpty);
      await tester.tap(cards.at(2));
      await tester.pump();
      expect(container.read(librarySelectionProvider).ids.length, 2);
      await shot('songs-grid-selecting');
      container.read(librarySelectionProvider.notifier).clear();
      await settle();
    }

    Future<void> albumsRound() async {
      // The Linux fixtures carry no album tag, so there is no album to show;
      // the phone's real library has them.
      final db = container.read(appDatabaseProvider);
      final withAlbum = await (db.select(
        db.tracks,
      )..where((t) => t.album.isNotNull())).get();
      if (withAlbum.isEmpty) {
        debugPrint('no album in the library: album grid not checked here');
        return;
      }
      await container
          .read(libraryListViewsProvider.notifier)
          .setView(BrowseList.albums, CollectionView.grid);
      router.go('/library/albums');
      await app.pumpUntil(
        () => find.byType(AlbumCard).evaluate().isNotEmpty,
        what: 'album cards',
      );
      await shot('albums-grid');
    }

    await songsRound();
    await albumsRound();

    if (desktop) {
      // Mobile shell on Linux too.
      width = 'narrow';
      tester.view.physicalSize = const Size(412, 900);
      await settle();
      await songsRound();
      await albumsRound();
    }
    // Leave the setting as a fresh install has it.
    await container
        .read(libraryListViewsProvider.notifier)
        .setView(BrowseList.songs, CollectionView.list);
  });
}
