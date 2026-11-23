import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/gestures.dart' show kSecondaryButton;
import 'package:flutter/rendering.dart' show OffsetLayer;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart' show Offset, Scrollable, Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_summary.dart';
import 'package:kanaru/src/lyrics/state/playing_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/state/track_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_card.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_for_track_body.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_gap_mark.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_labels.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_source_button.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_state_view.dart';
import 'package:kanaru/src/lyrics/ui/synced_lyrics_view.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/state/now_playing_panel.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru/src/playback/ui/mini_player.dart';
import 'package:kanaru/src/screens/now_playing/ui/desktop/desktop_now_playing.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/lyrics_screen.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/mobile_now_playing.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/more_sheet.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart' show Dialog, Navigator;

import 'support/harness.dart';

/// "Lời cho bài này" (the lyrics source modal), the source button, the intro
/// gap and the `L` key on the real app, Linux. One launch: the window starts
/// narrow, under 600 (mobile shell: bottom sheet) and is widened at the end (desktop
/// shell: dialog). Asserts state (semantics, providers, widget types), never
/// pixels; the screenshots (app window only) are for comparing with
/// `mockups/screens/07-lyrics.md` by eye.
///
/// Run: `tool/integration_test.sh linux integration_test/lyrics_source_test.dart`
/// (through the main checkout's `main-build.sh`).
/// A [KIconButton] by its tooltip text (`find.byTooltip` cannot: it has no
/// Tooltip widget on every shell).
Finder iconButton(String tooltip) =>
    find.byWidgetPredicate((w) => w is KIconButton && w.tooltip == tooltip);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('lyrics source modal, gap and shortcuts on both shells', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(500, 900);
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();

    // A synced file whose first line starts at 6 s (the intro gap), made
    // before the scan: a copy of the no-lyrics tone with an `.lrc` beside it.
    final gapPrepared = _prepareGapFixture();

    final app = await startKanaru(tester);
    final container = app.container;
    final ids = await app.trackIdsByTitle();
    final player = container.read(playerControllerProvider);

    Future<void> shot(String name) async {
      await tester.pump(const Duration(milliseconds: 400));
      try {
        if (Platform.isLinux) {
          // No screenshot plugin on Linux: draw the app's own root layer
          // (the whole window, modals included; nothing of the desktop).
          final view = tester.binding.renderViews.first;
          final layer = view.debugLayer! as OffsetLayer;
          final image = await layer.toImage(Offset.zero & view.size);
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!;
          final dir = Directory('/tmp/kanaru-it/shots')
            ..createSync(recursive: true);
          File('${dir.path}/lyrics-source-$name.png')
              .writeAsBytesSync(bytes.buffer.asUint8List());
        } else {
          await binding.takeScreenshot('lyrics-source-$name');
        }
      } on Object catch (e) {
        // A screenshot is for the eye only: never fail the test for it.
        debugPrint('screenshot $name failed: $e');
      }
    }

    /// A track id by the end of its path in the library (titles can repeat:
    /// the gap copy has the title of `none.mp3`).
    Future<TrackId?> idByPath(String suffix) async {
      final db = container.read(appDatabaseProvider);
      final rows = await db.select(db.tracks).get();
      for (final row in rows) {
        if (row.relPath.endsWith(suffix)) return TrackId(row.id);
      }
      return null;
    }

    Future<void> playPaused(List<TrackId> queue) async {
      await player.playTracks(
        queue,
        context: const PlayContext(PlayContextKind.songs),
      );
      await app.pumpUntil(
        () => container.read(nowPlayingProvider).value?.trackId == queue.first,
        what: 'the first queued track to be the playing track',
      );
      await player.pause();
      await player.seek(Duration.zero);
    }

    int line() => container.read(playingLyricsLineProvider);
    TrackLyrics lyricsOf(TrackId id) => container.read(trackLyricsProvider(id));

    AppLocalizations l10n() =>
        AppLocalizations.of(tester.element(find.byType(Navigator).first));

    final modal = find.byType(LyricsForTrackBody);

    Future<void> waitOpen(String what) => app.pumpUntil(
      () => modal.evaluate().isNotEmpty,
      what: 'the lyrics source modal ($what)',
      timeout: const Duration(seconds: 15),
    );
    Future<void> waitClosed(String what) => app.pumpUntil(
      () => modal.evaluate().isEmpty,
      what: 'the lyrics source modal to close ($what)',
      timeout: const Duration(seconds: 15),
    );

    /// Whether the choice row titled [title] reads as selected.
    bool rowSelected(String title) => isSemantics(isSelected: true).matches(
      tester.getSemantics(
        find.ancestor(
          of: find.text(title),
          matching: find.byType(SelectionRow),
        ),
      ),
      {},
    );

    Future<void> waitLyrics(
      TrackId id,
      bool Function(TrackLyrics) test,
      String what,
    ) => app.pumpUntil(
      () => test(lyricsOf(id)),
      what: what,
      timeout: const Duration(seconds: 15),
    );

    Future<void> openFromButton(String what) async {
      await tester.tap(find.byType(LyricsSourceButton));
      await waitOpen(what);
    }

    /// Opens the mobile Now Playing page from the mini player.
    Future<void> openMobileNowPlaying() async {
      await tester.tap(find.byType(MiniPlayer));
      await app.pumpUntil(
        () => find.byType(MobileNowPlaying).evaluate().isNotEmpty,
        what: 'the mobile Now Playing page',
      );
    }

    Future<void> openLyricsScreen() async {
      await tester.scrollUntilVisible(
        find.byType(LyricsCard),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byType(LyricsCard));
      await app.pumpUntil(
        () => find.byType(LyricsScreen).evaluate().isNotEmpty,
        what: 'the lyrics screen',
      );
    }

    Future<void> back(bool Function() done, String what) async {
      await tester.binding.handlePopRoute();
      await app.pumpUntil(done, what: what);
    }

    /// Assertions shared by the sheet and the dialog: the two choice rows,
    /// the two inert "coming soon" rows, the close button.
    Future<void> expectModalContent({required bool fileSelected}) async {
      final t = l10n();
      expect(find.text(t.lyricsForTrackTitle), findsWidgets);
      expect(find.text(t.lyricsChoiceFile), findsOneWidget);
      expect(find.text(t.lyricsChoiceOff), findsOneWidget);
      expect(rowSelected(t.lyricsChoiceFile), fileSelected);
      expect(rowSelected(t.lyricsChoiceOff), !fileSelected);
      expect(find.text(t.appComingSoon), findsNWidgets(2));
      expect(iconButton(t.lyricsModalClose), findsOneWidget);
      // The search row opens the Chọn lời picker in the modal's place; ← of
      // the picker brings the modal back.
      await tester.tap(find.text(t.lyricsFindOnline));
      await app.pumpUntil(
        () => find.text(t.lyricsPickerTitle).evaluate().isNotEmpty,
        what: 'the Chọn lời picker',
        timeout: const Duration(seconds: 15),
      );
      await tester.tap(iconButton(t.lyricsPickerBack));
      await app.pumpUntil(
        () => modal.evaluate().isNotEmpty,
        what: 'the modal back after ← of the picker',
        timeout: const Duration(seconds: 15),
      );
      expect(modal, findsOneWidget);
    }

    // ================= mobile shell: 500 dp wide (a sheet below KBreakpoints.compactSheet, 600) =================
    final syltId = TrackId(ids['IT Sylt Tag']!);
    final usltId = TrackId(ids['IT Uslt Tag']!);
    final noneId = (await idByPath('none.mp3'))!;

    await playPaused([syltId]);
    await openMobileNowPlaying();
    await openLyricsScreen();
    await app.pumpUntil(
      () => find.byType(SyncedLyricsView).evaluate().isNotEmpty,
      what: 'the synced view',
    );

    // 1. Header source button -> sheet.
    expect(find.byType(LyricsSourceButton), findsOneWidget);
    await openFromButton('mobile, header button');
    expect(find.byType(Dialog), findsNothing, reason: 'mobile uses a sheet');
    await expectModalContent(fileSelected: true);
    expect(
      find.text(l10n().lyricsChoiceSubTagSynced),
      findsOneWidget,
      reason: 'the file row says where the lyrics come from',
    );
    expect(find.text(l10n().lyricsModalNoneOnDevice), findsNothing);
    await shot('mobile-01-sheet-file-chosen');

    // "Không hiện lời": closes, off state with the button.
    await tester.tap(find.text(l10n().lyricsChoiceOff));
    await waitClosed('choosing off');
    await waitLyrics(syltId, (l) => l is LyricsOff, 'the song to be off');
    await app.pumpUntil(
      () => find.byType(LyricsStateView).evaluate().isNotEmpty,
      what: 'the off state',
    );
    expect(find.text(l10n().lyricsOffTitle), findsOneWidget);
    expect(find.byType(SyncedLyricsView), findsNothing);
    final openChoice = find.text(l10n().lyricsOffOpenChoice);
    expect(openChoice, findsOneWidget);
    await shot('mobile-02-screen-off');

    // The [Lời cho bài này] button reopens it, off row selected.
    await tester.tap(openChoice);
    await waitOpen('mobile, off-state button');
    await expectModalContent(fileSelected: false);
    await shot('mobile-03-sheet-off-chosen');

    // Choose the file again: lyrics are back.
    await tester.tap(find.text(l10n().lyricsChoiceFile));
    await waitClosed('choosing the file');
    await waitLyrics(syltId, (l) => l is LyricsShown, 'lyrics to be back');
    await app.pumpUntil(
      () => find.byType(SyncedLyricsView).evaluate().isNotEmpty,
      what: 'the synced view after choosing the file',
    );
    expect(find.byType(LyricsStateView), findsNothing);
    await shot('mobile-04-screen-lyrics-back');

    // Back order: modal -> lyrics screen -> Now Playing.
    await openFromButton('mobile, for Back');
    await back(() => modal.evaluate().isEmpty, 'Back to close the modal');
    expect(find.byType(LyricsScreen), findsOneWidget);
    await back(
      () => find.byType(LyricsScreen).evaluate().isEmpty,
      'Back to close the lyrics screen',
    );
    expect(find.byType(MobileNowPlaying), findsOneWidget);

    // 2. Now Playing more sheet -> "Nguồn lời bài", opened after it closes.
    await tester.tap(iconButton(l10n().playbackMore));
    await app.pumpUntil(
      () => find.byType(NowPlayingMoreSheet).evaluate().isNotEmpty,
      what: 'the Now Playing more sheet',
    );
    await shot('mobile-05-more-sheet');
    await tester.tap(find.text(l10n().playbackLyricsSource));
    await waitOpen('mobile, more sheet item');
    await app.pumpUntil(
      () => find.byType(NowPlayingMoreSheet).evaluate().isEmpty,
      what: 'the more sheet to be gone',
      timeout: const Duration(seconds: 15),
    );
    await expectModalContent(fileSelected: true);
    await tester.tap(iconButton(l10n().lyricsModalClose));
    await waitClosed('the close button');
    expect(find.byType(MobileNowPlaying), findsOneWidget);

    // 5. A track without lyrics: the status line, file row disabled.
    await playPaused([noneId]);
    await tester.tap(iconButton(l10n().playbackMore));
    await app.pumpUntil(
      () => find.byType(NowPlayingMoreSheet).evaluate().isNotEmpty,
      what: 'the more sheet (no lyrics track)',
    );
    await tester.tap(find.text(l10n().playbackLyricsSource));
    await waitOpen('mobile, track without lyrics');
    expect(find.text(l10n().lyricsModalNoneOnDevice), findsOneWidget);
    expect(find.text(l10n().lyricsChoiceFileNone), findsOneWidget);
    await shot('mobile-06-sheet-none-on-device');
    await tester.tap(iconButton(l10n().lyricsModalClose));
    await waitClosed('the close button (no lyrics)');

    // 4. The modal follows the playing track: skipping closes it.
    await playPaused([syltId, usltId]);
    await tester.tap(iconButton(l10n().playbackMore));
    await app.pumpUntil(
      () => find.byType(NowPlayingMoreSheet).evaluate().isNotEmpty,
      what: 'the more sheet (queue of two)',
    );
    await tester.tap(find.text(l10n().playbackLyricsSource));
    await waitOpen('mobile, before skipping');
    await player.next();
    await waitClosed('the playing track changing');
    await app.pumpUntil(
      () => container.read(nowPlayingProvider).value?.trackId == usltId,
      what: 'the next track to be playing',
    );
    await player.pause();
    expect(find.byType(MobileNowPlaying), findsOneWidget);

    // 6. Intro gap: first line at 6 s, so the gap mark is the current line.
    if (gapPrepared) {
      late final TrackId gapId;
      await app.pumpUntil(
        () async {
          final id = await idByPath('gap.mp3');
          if (id != null) gapId = id;
          return id != null;
        },
        what: 'the gap fixture in the library',
        timeout: const Duration(seconds: 120),
      );
      await playPaused([gapId]);
      await waitLyrics(
        gapId,
        (l) =>
            l is LyricsShown &&
            l.lyrics.synced &&
            l.lyrics.lines.first.isGap &&
            l.lyrics.lines.first.time == Duration.zero &&
            l.lyrics.lines[1].text == 'Gap first line' &&
            l.lyrics.lines[1].time == const Duration(seconds: 6),
        'the gap lyrics: a gap line at 0, then the line at 6 s',
      );
      // The card (Now Playing page).
      await tester.scrollUntilVisible(
        find.byType(LyricsCard),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await app.pumpUntil(
        () => find
            .descendant(
              of: find.byType(LyricsCard),
              matching: find.byType(LyricsGapMark),
            )
            .evaluate()
            .isNotEmpty,
        what: 'the gap mark in the card',
      );
      expect(line(), 0, reason: 'the gap is the current line during the intro');
      expect(find.text('Gap first line'), findsOneWidget);
      await shot('mobile-07-card-intro-gap');

      // The lyrics screen.
      await openLyricsScreen();
      await app.pumpUntil(
        () => find.byType(SyncedLyricsView).evaluate().isNotEmpty,
        what: 'the synced view (gap song)',
      );
      expect(
        find.descendant(
          of: find.byType(SyncedLyricsView),
          matching: find.byType(LyricsGapMark),
        ),
        findsWidgets,
      );
      expect(line(), 0);
      expect(
        find.descendant(
          of: find.byType(SyncedLyricsView),
          matching: find.text('Gap first line'),
        ),
        findsOneWidget,
      );
      await shot('mobile-08-screen-intro-gap');
      await back(
        () => find.byType(LyricsScreen).evaluate().isEmpty,
        'Back from the gap lyrics screen',
      );
    } else {
      debugPrint('intro gap case skipped: no writable fixture music folder');
    }

    // ================= desktop shell: widen the window =================
    await playPaused([syltId]);
    tester.view.physicalSize = const Size(1400, 900);
    await app.pumpUntil(
      () => container.read(nowPlayingPanelProvider).covered,
      what: 'the desktop Now Playing panel after widening',
    );
    await app.pumpUntil(
      () =>
          find.byType(DesktopNowPlaying).evaluate().isNotEmpty &&
          find.byType(LyricsSourceButton).evaluate().isNotEmpty,
      what: 'the desktop Now Playing page with the source button',
    );
    await waitLyrics(syltId, (l) => l is LyricsShown, 'desktop lyrics');

    // The tooltip names the key and the right-click.
    final tagLabel = lyricsSummaryLabel(l10n(), LyricsSummary.tagSynced);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is KIconButton &&
            w.tooltip.startsWith(l10n().lyricsSourceTooltipDesktop(tagLabel)) &&
            w.tooltip.contains(l10n().lyricsSourceToggleHint),
      ),
      findsOneWidget,
    );
    await shot('desktop-01-page');

    // 3a. Button -> dialog; Esc closes.
    await openFromButton('desktop, button');
    expect(find.byType(Dialog), findsOneWidget, reason: 'desktop: a dialog');
    expect(tester.getSize(modal).width, lessThanOrEqualTo(KLayout.dialog));
    await expectModalContent(fileSelected: true);
    await shot('desktop-02-dialog-file-chosen');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await waitClosed('Esc');
    expect(find.byType(DesktopNowPlaying), findsOneWidget);

    // 3b. `L` opens it.
    await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
    await waitOpen('the L key');
    expect(find.byType(Dialog), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await waitClosed('Esc after L');

    // 3c. Right-click on the button turns lyrics off, then back on.
    await tester.tap(
      find.byType(LyricsSourceButton),
      buttons: kSecondaryButton,
    );
    await waitLyrics(syltId, (l) => l is LyricsOff, 'right-click: off');
    expect(modal, findsNothing, reason: 'right-click must not open the modal');
    await app.pumpUntil(
      () => find.text(l10n().lyricsOffTitle).evaluate().isNotEmpty,
      what: 'the off state on desktop',
    );
    await shot('desktop-03-off-state');
    await tester.tap(
      find.byType(LyricsSourceButton),
      buttons: kSecondaryButton,
    );
    await waitLyrics(syltId, (l) => l is LyricsShown, 'right-click: on again');

    // 3d. Desktop ⋮ menu item opens it after the menu closes.
    await tester.tap(iconButton(l10n().playbackMore).hitTestable().first);
    await app.pumpUntil(
      () => find.text(l10n().playbackLyricsSource).evaluate().isNotEmpty,
      what: 'the desktop more menu',
    );
    await shot('desktop-04-more-menu');
    await tester.tap(find.text(l10n().playbackLyricsSource));
    await waitOpen('desktop, more menu item');
    expect(find.text(l10n().playbackLyricsSource), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await waitClosed('Esc after the menu item');

    // 4 (desktop). Skipping with the dialog open closes it too.
    await playPaused([syltId, usltId]);
    await openFromButton('desktop, before skipping');
    await player.next();
    await waitClosed('the playing track changing (desktop)');
    await player.pause();

    semantics.dispose();
  }, timeout: const Timeout(Duration(minutes: 8)));
}

/// Writes `gap.mp3` (a copy of `none.mp3`) and `gap.lrc`, whose first line
/// starts at 6 s, into the fixture music folder the runner announced as
/// `XDG_MUSIC_DIR` (`tool/integration_test.sh`). False when there is no such
/// local folder (Android), so the intro gap case is skipped.
bool _prepareGapFixture() {
  if (!Platform.isLinux) return false;
  final config =
      Platform.environment['XDG_CONFIG_HOME'] ?? '/tmp/kanaru-it/config';
  final dirs = File('$config/user-dirs.dirs');
  if (!dirs.existsSync()) return false;
  final match = RegExp(
    r'^XDG_MUSIC_DIR="([^"]+)"',
    multiLine: true,
  ).firstMatch(dirs.readAsStringSync());
  if (match == null) return false;
  final music = Directory(
    match.group(1)!.replaceFirst(r'$HOME', Platform.environment['HOME'] ?? ''),
  );
  final none = File('${music.path}/none.mp3');
  if (!none.existsSync()) return false;
  none.copySync('${music.path}/gap.mp3');
  File(
    '${music.path}/gap.lrc',
  ).writeAsStringSync('[00:06.00]Gap first line\n[00:09.00]Gap second line\n');
  return true;
}
