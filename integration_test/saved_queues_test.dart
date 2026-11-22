import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/rendering.dart' show OffsetLayer;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart' show Offset, Size, Text;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/ui/menus/more_button.dart';
import 'package:kanaru/src/library/ui/saved_queues/saved_queue_hero.dart';
import 'package:kanaru/src/library/ui/saved_queues/saved_queue_page.dart';
import 'package:kanaru/src/library/ui/saved_queues/saved_queue_tile.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru/src/playback/state/saved_queue_recorder_provider.dart';
import 'package:kanaru/src/router/state/router_provider.dart';
import 'package:material_ui/material_ui.dart'
    show
        AlertDialog,
        MaterialLocalizations,
        Navigator,
        SnackBarAction,
        TextButton;

import 'support/harness.dart';

/// The Queue page of the Playlist tab (`/playlists/queues`) and one saved
/// queue's page (`/playlists/queues/<uid>`) on the real app, Linux: empty
/// state, rows, hover, the row and hero menus, Play, delete (cancel, then
/// confirm). Desktop window first (1400 wide), then narrower windows for the
/// page layout. Saved queues are made by playing lists through the player's
/// commands (the real recorder saves each queue that gets replaced); every
/// other step is a real tap, hover or key press. Asserts state (texts from the
/// app's own l10n, row counts), never icons; screenshots (app window only,
/// `/tmp/kanaru-it/shots/linux-savedqueues-*.png`) are for comparing with
/// `mockups/` by eye and never fail the test.
///
/// Run: `tool/integration_test.sh linux saved_queues_test.dart` (through the
/// main checkout's `main-build.sh`).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('saved queues list and page on desktop and narrow windows', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 900);
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);

    final app = await startKanaru(tester);
    final container = app.container;
    final router = container.read(routerProvider);
    final commands = container.read(playbackCommandsProvider);
    final player = container.read(playerControllerProvider);
    final ids = await app.trackIdsByTitle();
    TrackId id(String title) => TrackId(ids[title]!);

    Future<void> shot(String name) async {
      await tester.pump(const Duration(milliseconds: 400));
      try {
        if (Platform.isLinux) {
          // No screenshot plugin on Linux: the app's own root layer only.
          final view = tester.binding.renderViews.first;
          final layer = view.debugLayer! as OffsetLayer;
          final image = await layer.toImage(Offset.zero & view.size);
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!;
          final dir = Directory('/tmp/kanaru-it/shots')
            ..createSync(recursive: true);
          File('${dir.path}/linux-savedqueues-$name.png')
              .writeAsBytesSync(bytes.buffer.asUint8List());
        } else {
          await binding.takeScreenshot('linux-savedqueues-$name');
        }
      } on Object catch (e) {
        // A screenshot is for the eye only: never fail the test for it.
        debugPrint('screenshot $name failed: $e');
      }
    }

    AppLocalizations l10n() =>
        AppLocalizations.of(tester.element(find.byType(Navigator).first));

    /// What a failing run needs to be read: where the app is and what is on
    /// screen.
    String diag() {
      String route;
      try {
        route = router.routerDelegate.currentConfiguration.uri.toString();
      } on Object catch (e) {
        route = '? ($e)';
      }
      return 'route=$route, tiles=${find.byType(SavedQueueTile).evaluate().length}, '
          'pages=${find.byType(SavedQueuePage).evaluate().length}, '
          'texts=${find.byType(Text).evaluate().map((e) => (e.widget as Text).data).whereType<String>().take(25).toList()}';
    }

    Future<void> waitFor(
      bool Function() condition,
      String what, {
      Duration timeout = const Duration(seconds: 20),
    }) => app.pumpUntil(
      () => condition(),
      what: '$what [${diag()}]',
      timeout: timeout,
    );

    int tileCount() => find.byType(SavedQueueTile).evaluate().length;

    Future<void> resize(double width) async {
      tester.view.physicalSize = Size(width, 900);
      await tester.pump(const Duration(milliseconds: 500));
    }

    /// Plays [titles] under [context] and waits until the recorder has
    /// written the queue this replaced.
    Future<void> playList(List<String> titles, PlayContext context) async {
      await commands.playTracks([
        for (final t in titles) id(t),
      ], context: context);
      final first = id(titles.first);
      await waitFor(
        () => container.read(nowPlayingProvider).value?.trackId == first,
        'the first track of $titles to play',
      );
      await container.read(savedQueueRecorderProvider).idle;
    }

    Future<void> popRoute() async {
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 400));
    }

    Future<void> openList() async {
      router.go('/playlists/queues');
      await tester.pump(const Duration(milliseconds: 400));
    }

    Future<void> closeMenuWithEscape(Finder item, String name) async {
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump(const Duration(milliseconds: 400));
      expect(item, findsNothing, reason: 'Esc closes the $name [${diag()}]');
    }

    Finder firstRowMore() => find
        .descendant(
          of: find.byType(SavedQueueTile).first,
          matching: find.byType(LibraryMoreButton),
        )
        .first;

    // ---- 1. empty state ----
    await openList();
    await waitFor(
      () => find.text(l10n().savedQueueEmpty).evaluate().isNotEmpty,
      'the empty message',
    );
    expect(tileCount(), 0, reason: 'fresh database has no saved queue');
    await shot('empty');

    // ---- 2. make saved queues (player commands; the recorder is real) ----
    // Three different lists: playing the 2nd saves the 1st, the 3rd the 2nd.
    await playList([
      'IT Sylt Tag',
      'IT Uslt Tag',
      'IT Flac Lrc Tag',
    ], const PlayContext(PlayContextKind.album, label: 'IT Album A'));
    await playList([
      'IT Ogg Plain Tag',
      'IT Lrc Utf8',
    ], const PlayContext(PlayContextKind.songs));
    await playList([
      'IT Lrc Utf16',
      'IT Lrc Upper',
      'IT No Lyrics',
    ], const PlayContext(PlayContextKind.songs));
    await player.pause();

    // ---- 3. list ----
    await waitFor(() => tileCount() == 2, 'two saved queue rows');
    expect(
      find.text(l10n().savedQueueEmpty),
      findsNothing,
      reason: 'rows replace the empty state',
    );
    expect(find.text(l10n().savedQueueExplain), findsOneWidget);
    // Newest first: the 2-song queue (songs) is above the album one.
    final fromSongs = find.text(l10n().savedQueueFromSongs);
    final fromAlbum = find.text(l10n().savedQueueFromAlbum('IT Album A'));
    expect(fromSongs, findsOneWidget, reason: 'source line "From Songs"');
    expect(fromAlbum, findsOneWidget, reason: 'source line "From album"');
    expect(
      tester.getTopLeft(fromSongs).dy < tester.getTopLeft(fromAlbum).dy,
      isTrue,
      reason: 'newest saved queue first [${diag()}]',
    );
    await shot('list');

    // Hover the first row with a mouse.
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(SavedQueueTile).first));
    await tester.pump(const Duration(milliseconds: 300));
    await shot('list-hover');
    await mouse.moveTo(Offset.zero);
    await tester.pump(const Duration(milliseconds: 300));

    // Row menu (nothing is missing: no "remove gone songs" row).
    await tester.tap(firstRowMore());
    final menuPlay = find.text(l10n().savedQueueMenuPlay);
    await waitFor(() => menuPlay.evaluate().isNotEmpty, 'the row menu');
    for (final label in [
      l10n().savedQueueMenuPlay,
      l10n().libraryShuffle,
      l10n().savedQueueMenuAppend,
      l10n().savedQueueMenuSaveAsPlaylist,
      l10n().libraryMenuFavoriteAll,
      l10n().historyMenuExportM3u,
      l10n().savedQueueMenuDelete,
    ]) {
      expect(find.text(label), findsWidgets, reason: 'menu item "$label"');
    }
    expect(find.text(l10n().savedQueueMenuRemoveMissing), findsNothing);
    await shot('list-menu');
    await closeMenuWithEscape(menuPlay, 'row menu');

    // ---- 4. the page of the first row ----
    await tester.tap(find.byType(SavedQueueTile).first);
    await waitFor(
      () => find.byType(SavedQueuePage).evaluate().isNotEmpty,
      'the saved queue page',
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SavedQueueHero), findsOneWidget);
    // The 2-song queue: stats line and the bar `N songs, in played order`.
    expect(find.text(l10n().savedQueueBar(2)), findsOneWidget);
    expect(find.textContaining(l10n().librarySongCount(2)), findsWidgets);
    await shot('page-1400');
    await resize(1000);
    await shot('page-1000');
    await resize(500);
    await shot('page-500');
    await resize(1400);

    final heroMore = find.descendant(
      of: find.byType(SavedQueueHero),
      matching: find.byType(LibraryMoreButton),
    );
    await tester.tap(heroMore.first);
    await waitFor(() => menuPlay.evaluate().isNotEmpty, 'the hero menu');
    await shot('page-menu');
    await closeMenuWithEscape(menuPlay, 'hero menu');

    // ---- 5. Play: toast, no Undo, queue moves to the top ----
    await tester.tap(
      find.descendant(
        of: find.byType(SavedQueueHero),
        matching: find.text(l10n().libraryPlay),
      ),
    );
    // "Playing queue {name} (N songs). ..." : match its fixed beginning.
    final playingPrefix = l10n()
        .savedQueuePlaying('', 0)
        .split(' (')
        .first
        .trim();
    await waitFor(
      () => find.textContaining(playingPrefix).evaluate().isNotEmpty,
      'the "playing queue" toast',
    );
    expect(find.byType(SnackBarAction), findsNothing, reason: 'no Undo');
    await shot('play-snackbar');
    await container.read(savedQueueRecorderProvider).idle;
    await player.pause();

    await popRoute();
    await waitFor(
      () => find.byType(SavedQueuePage).evaluate().isEmpty,
      'the page to close',
    );
    // The queue replaced by the play (the 3-song one) is saved too.
    await waitFor(() => tileCount() == 3, 'three rows after the replay');

    // ---- 6. delete: cancel keeps it, confirm removes it ----
    await tester.tap(firstRowMore());
    final menuDelete = find.text(l10n().savedQueueMenuDelete);
    await waitFor(() => menuDelete.evaluate().isNotEmpty, 'the delete row');
    await tester.tap(menuDelete.last);
    final dialog = find.byType(AlertDialog);
    await waitFor(() => dialog.evaluate().isNotEmpty, 'the delete dialog');
    expect(
      find.descendant(
        of: dialog,
        matching: find.text(l10n().savedQueueDeleteTitle),
      ),
      findsOneWidget,
    );
    await shot('delete-dialog');
    await tester.tap(
      find.descendant(
        of: dialog,
        matching: find.text(
          MaterialLocalizations.of(tester.element(dialog)).cancelButtonLabel,
        ),
      ),
    );
    await waitFor(() => dialog.evaluate().isEmpty, 'the dialog to close');
    expect(tileCount(), 3, reason: 'Cancel keeps the queue [${diag()}]');

    await tester.tap(firstRowMore());
    await waitFor(
      () => menuDelete.evaluate().isNotEmpty,
      'the delete row again',
    );
    await tester.tap(menuDelete.last);
    await waitFor(
      () => dialog.evaluate().isNotEmpty,
      'the delete dialog again',
    );
    await tester.tap(
      find.descendant(
        of: dialog,
        matching: find.widgetWithText(TextButton, l10n().playlistDeleteConfirm),
      ),
    );
    await waitFor(() => tileCount() == 2, 'one row fewer after the delete');
    await waitFor(
      () => find.text(l10n().savedQueueDeleted).evaluate().isNotEmpty,
      'the "queue deleted" toast',
    );
    await shot('deleted');

    // ---- 7. narrow list (mobile shell) ----
    await resize(500);
    expect(tileCount(), 2, reason: 'rows survive a window resize [${diag()}]');
    await shot('list-500');
    await resize(1400);

    // Dark theme pass skipped: the harness has no cheap theme switch.
  });
}
