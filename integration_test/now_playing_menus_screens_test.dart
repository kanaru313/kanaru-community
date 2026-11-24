import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/rendering.dart' show OffsetLayer;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart' show FocusManager, Offset, Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/state/now_playing_panel.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru/src/playback/ui/queue/queue_list.dart';
import 'package:kanaru/src/screens/now_playing/ui/desktop/desktop_now_playing.dart';
import 'package:kanaru/src/screens/now_playing/ui/desktop/desktop_now_playing_header.dart';
import 'package:kanaru/src/screens/now_playing/ui/desktop/now_playing_auto_hide.dart';
import 'package:kanaru/src/shell/state/right_panel.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart' show Navigator;

import 'support/harness.dart';

/// Desktop shell: the ⋮ of Now Playing opens the song menu of the playing song
/// (the header stays shown while it is open, Esc closes it and focus returns
/// to the ⋮), and the ⋮ of a queue row opens the song menu of that entry
/// (no Now Playing rows). Screenshots (the app's own root layer, nothing of
/// the desktop) go to `/tmp/kanaru-it/shots/np-menus-*.png`.
///
/// Run: `tool/integration_test.sh linux integration_test/now_playing_menus_screens_test.dart`
/// (through the main checkout's `main-build.sh`).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('desktop: Now Playing menu and queue row menu', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1400, 900);
    addTearDown(tester.view.reset);

    final app = await startKanaru(tester);
    final container = app.container;
    final ids = await app.trackIdsByTitle();
    final player = container.read(playerControllerProvider);

    Future<void> shot(String name) async {
      await tester.pump(const Duration(milliseconds: 400));
      try {
        final view = tester.binding.renderViews.first;
        final layer = view.debugLayer! as OffsetLayer;
        final image = await layer.toImage(Offset.zero & view.size);
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        final dir = Directory('/tmp/kanaru-it/shots')
          ..createSync(recursive: true);
        File('${dir.path}/np-menus-$name.png')
            .writeAsBytesSync(bytes.buffer.asUint8List());
      } on Object catch (e) {
        // A screenshot is for the eye only: never fail the test for it.
        debugPrint('screenshot $name failed: $e');
      }
    }

    AppLocalizations l10n() =>
        AppLocalizations.of(tester.element(find.byType(Navigator).first));

    // Three tracks in the queue, paused on the first.
    final queue = [
      for (final t in const ['IT Sylt Tag', 'IT Uslt Tag', 'IT No Lyrics'])
        TrackId(ids[t]!),
    ];
    await player.playTracks(
      queue,
      context: const PlayContext(PlayContextKind.songs),
    );
    await app.pumpUntil(
      () => container.read(nowPlayingProvider).value?.trackId == queue.first,
      what: 'the first queued track to be playing',
    );
    await player.pause();

    container.read(nowPlayingPanelProvider.notifier).open();
    await app.pumpUntil(
      () =>
          container.read(nowPlayingPanelProvider).covered &&
          find.byType(DesktopNowPlaying).evaluate().isNotEmpty,
      what: 'the desktop Now Playing page',
    );

    // ---- Now Playing ⋮ ----
    final header = find.byType(DesktopNowPlayingHeader);
    final more = find.descendant(
      of: header,
      matching: find.byWidgetPredicate(
        (w) => w is KIconButton && w.tooltip == l10n().playbackMore,
      ),
    );
    final chrome = tester.widget<DesktopNowPlayingHeader>(header).chrome;
    await tester.tap(more);
    await app.pumpUntil(
      () => find.text(l10n().playbackSleepTimer).evaluate().isNotEmpty,
      what: 'the song menu of the playing song',
    );
    expect(find.text(l10n().playbackLyricsSource), findsOneWidget);
    await shot('01-np-menu');

    // The header stays shown past the auto-hide delay while the menu is open.
    await Future<void>.delayed(
      nowPlayingHideAfter + const Duration(seconds: 1),
    );
    await tester.pump();
    expect(chrome.visible.value, isTrue, reason: 'header pinned by the menu');
    expect(chrome.hasFloating, isTrue);
    await shot('02-np-menu-after-hide-delay');

    // Esc closes the menu and focus returns to the ⋮.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await app.pumpUntil(
      () => find.text(l10n().playbackSleepTimer).evaluate().isEmpty,
      what: 'Esc to close the song menu',
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(chrome.hasFloating, isFalse, reason: 'the pin is released');
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'desktop more menu',
      reason: 'focus returns to the ⋮',
    );
    await shot('03-np-menu-closed-focus-on-more');

    // ---- queue row ⋮ ----
    // The queue panel lives in the shell, which Now Playing covers: close the
    // page first, or the rows are in the tree but taps never reach them.
    container.read(nowPlayingPanelProvider.notifier).close();
    await app.pumpUntil(
      () => !container.read(nowPlayingPanelProvider).covered,
      what: 'Now Playing to stop covering the shell',
    );
    container.read(rightPanelProvider.notifier).show(RightPanelKind.queue);
    await app.pumpUntil(
      () => find.byType(QueueList).evaluate().isNotEmpty,
      what: 'the queue panel',
    );
    final rowMore = find.descendant(
      of: find.byType(QueueList),
      matching: find.byType(KMoreButton),
    );
    await app.pumpUntil(
      () => rowMore.evaluate().length >= 2,
      what: 'queue rows with their ⋮',
    );
    await tester.tap(rowMore.hitTestable().at(1));
    await app.pumpUntil(
      () => find.text(l10n().playbackRowPlay).evaluate().isNotEmpty,
      what: 'the song menu of the queue entry',
    );
    expect(find.text(l10n().playbackRowPlayNext), findsOneWidget);
    expect(find.text(l10n().playbackSleepTimer), findsNothing);
    expect(find.text(l10n().playbackTranslateLyrics), findsNothing);
    await shot('04-queue-row-menu');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await app.pumpUntil(
      () => find.text(l10n().playbackRowPlay).evaluate().isEmpty,
      what: 'Esc to close the queue row menu',
    );
    await shot('05-queue-row-menu-closed');
  }, timeout: const Timeout(Duration(minutes: 4)));
}
