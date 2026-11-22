import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/rendering.dart' show OffsetLayer;
import 'package:flutter/widgets.dart'
    show DefaultTextStyle, Offset, Scrollable, Size, Text, TextAlign;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/lyrics/domain/local_lyrics_pick.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_display_prefs.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/state/lyrics_settings.dart';
import 'package:kanaru/src/lyrics/state/track_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_card.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_for_track_body.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_source_button.dart';
import 'package:kanaru/src/lyrics/ui/synced_lyrics_view.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru/src/playback/ui/mini_player.dart';
import 'package:kanaru/src/router/state/router_provider.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/lyrics_screen.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/mobile_now_playing.dart';
import 'package:kanaru/src/screens/settings/settings_routes.dart';
import 'package:kanaru/src/screens/settings/ui/lyrics/lyrics_choice_row.dart';
import 'package:kanaru/src/screens/settings/ui/lyrics/lyrics_settings_page.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart' show Navigator;

import 'support/harness.dart';

/// Settings › Lời bài, the "Nguồn lời bài" row of every song menu and the ⚙ of
/// "Lời cho bài này", on the real app, Linux. Mobile (500 wide, sheets) first,
/// then desktop (1400 wide, dialogs). Asserts state (providers, widget
/// fields, positions of rows in one menu), never icons; screenshots (app
/// window only) are for comparing with `mockups/` by eye.
///
/// Run: `tool/integration_test.sh linux integration_test/lyrics_menu_settings_test.dart`
/// (through the main checkout's `main-build.sh`).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('song menu lyrics row and Settings › Lời bài on both shells', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(500, 900);
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();

    final app = await startKanaru(tester);
    final container = app.container;
    final router = container.read(routerProvider);
    final player = container.read(playerControllerProvider);
    final ids = await app.trackIdsByTitle();
    final syltId = TrackId(ids['IT Sylt Tag']!);

    var width = 'mobile';

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
          File('${dir.path}/linux-lyrics-menu-$width-$name.png')
              .writeAsBytesSync(bytes.buffer.asUint8List());
        } else {
          await binding.takeScreenshot('linux-lyrics-menu-$width-$name');
        }
      } on Object catch (e) {
        // A screenshot is for the eye only: never fail the test for it.
        debugPrint('screenshot $name failed: $e');
      }
    }

    AppLocalizations l10n() =>
        AppLocalizations.of(tester.element(find.byType(Navigator).first));

    final modal = find.byType(LyricsForTrackBody);

    Future<void> playPaused(TrackId id) async {
      await player.playTracks([
        id,
      ], context: const PlayContext(PlayContextKind.songs));
      await app.pumpUntil(
        () => container.read(nowPlayingProvider).value?.trackId == id,
        what: 'the track to be the playing track',
      );
      await player.pause();
      await player.seek(Duration.zero);
    }

    /// Pops routes (sheets, pages, dialogs) while [what] is still on screen.
    Future<void> popUntilGone(Finder what, String name) async {
      for (var i = 0; i < 6 && what.evaluate().isNotEmpty; i++) {
        await tester.binding.handlePopRoute();
        await tester.pump(const Duration(milliseconds: 400));
      }
      expect(what, findsNothing, reason: 'closed: $name');
    }

    /// Leaves the Lời bài page (it covers the shell) and goes to the library,
    /// then waits until the shell's mini player is back.
    Future<void> leaveSettings() async {
      await popUntilGone(find.byType(LyricsSettingsPage), 'the Lời bài page');
      router.go('/library/songs');
      // The library location is the shell on both widths (the mini player
      // exists on mobile only).
      await app.pumpUntil(
        () =>
            router.routeInformationProvider.value.uri.path ==
                '/library/songs' &&
            find.byType(LyricsSettingsPage).evaluate().isEmpty,
        what: 'the library location after leaving Settings',
      );
    }

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

    /// The size the text draws at: its own style, else the inherited one.
    double? effectiveFontSize(Finder text) {
      final own = tester.widget<Text>(text).style?.fontSize;
      return own ?? DefaultTextStyle.of(tester.element(text)).style.fontSize;
    }

    /// The alignment the line draws with: its own, else the inherited one
    /// (the app sets it on the line's AnimatedDefaultTextStyle).
    TextAlign? effectiveAlign(Finder text) =>
        tester.widget<Text>(text).textAlign ??
        DefaultTextStyle.of(tester.element(text)).textAlign;

    /// Picks [label] in the choice row [row]; waits until [saved] holds.
    Future<void> pick(
      Finder row,
      String label,
      String name,
      bool Function() saved,
    ) async {
      await tester.ensureVisible(row);
      await tester.tap(row);
      await app.pumpUntil(
        () => find.text(label).evaluate().isNotEmpty,
        what: 'the picker option "$label"',
      );
      await shot('picker-$name');
      // The row shows the current value too: the picker is the last one.
      await tester.tap(find.text(label).last);
      await app.pumpUntil(saved, what: '"$label" saved for $name');
      await tester.pump(const Duration(milliseconds: 300));
    }

    Finder onLyricsPage(Finder what) =>
        find.descendant(of: find.byType(LyricsSettingsPage), matching: what);

    Future<void> openSettingsLyrics() async {
      router.go(SettingsPaths.root);
      await app.pumpUntil(
        () => find.text(l10n().settingsRootLyrics).evaluate().isNotEmpty,
        what: 'the Settings root page',
      );
      // A real tap on the root row. Wait for a title only the Lời bài page
      // shows (the root does not have it). The route is not read here: after a
      // `push` the router's routeInformationProvider keeps the old location.
      await tester.tap(find.text(l10n().settingsRootLyrics));
      await app.pumpUntil(
        () =>
            onLyricsPage(find.text(l10n().lyricsSettingsDisplay))
                .evaluate()
                .isNotEmpty,
        what: 'the Lời bài page after the root row tap',
        timeout: const Duration(seconds: 15),
      );
    }

    /// The page: every section title, the live pickers, the "coming soon" rows.
    Future<void> checkSettingsPage() async {
      final t = l10n();
      await openSettingsLyrics();
      for (final title in [
        t.lyricsSettingsDisplay,
        t.lyricsSettingsFind,
        t.lyricsSettingsSources,
        t.lyricsSettingsWhere,
        t.lyricsSettingsTranslation,
        t.lyricsSettingsSpeech,
      ]) {
        // Plain text finder: the list builds its sections lazily, so a finder
        // that needs the section already built cannot drive the scroll.
        final heading = onLyricsPage(find.text(title));
        await tester.scrollUntilVisible(
          heading,
          300,
          scrollable: onLyricsPage(find.byType(Scrollable)).first,
        );
        expect(heading, findsWidgets, reason: 'section "$title"');
      }
      await shot('settings-page-bottom');
      await tester.scrollUntilVisible(
        find.text(t.lyricsSettingsDisplay),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await shot('settings-page-top');
      // Coming-soon rows exist and are inert (a tap does not open a picker).
      expect(find.text(t.appComingSoon), findsWidgets);
      expect(find.text(t.lyricsSettingsRomanize), findsOneWidget);
      expect(find.text(t.lyricsSettingsAddSource), findsOneWidget);
    }

    // ================= mobile shell: 500 dp wide =================
    await playPaused(syltId);
    expect(container.read(lyricsFontScaleProvider), LyricsFontScale.medium);
    expect(container.read(lyricsAlignProvider), LyricsAlign.start);
    expect(container.read(lyricsDimProvider), LyricsDim.light);
    expect(container.read(lyricsLocalFirstProvider), LocalFirst.tag);

    // Read Sylt once (Now Playing loads the lyrics): the menu subtitle needs it.
    router.go('/library/songs');
    await openMobileNowPlaying();
    await openLyricsScreen();
    await app.pumpUntil(
      () => find.byType(SyncedLyricsView).evaluate().isNotEmpty,
      what: 'the synced view',
    );
    final baselineSize = effectiveFontSize(
      find.descendant(
        of: find.byType(SyncedLyricsView),
        matching: find.text('Sylt first line'),
      ),
    );
    final baselineAlign = effectiveAlign(
      find.descendant(
        of: find.byType(SyncedLyricsView),
        matching: find.text('Sylt first line'),
      ),
    );
    await app.pumpUntil(
      () => container.read(trackLyricsProvider(syltId)) is LyricsShown,
      what: 'Sylt lyrics read',
    );
    // Close the Now Playing page: back to the list.
    await popUntilGone(find.byType(LyricsScreen), 'the lyrics screen');
    await popUntilGone(find.byType(MobileNowPlaying), 'Now Playing');

    await checkSettingsPage();

    // Live pickers, values reflected in the lyrics view.
    final fontRow = find.byType(LyricsChoiceRow<LyricsFontScale>);
    final alignRow = find.byType(LyricsChoiceRow<LyricsAlign>);
    final dimRow = find.byType(LyricsChoiceRow<LyricsDim>);
    final localRow = find.byType(LyricsChoiceRow<LocalFirst>);

    await pick(
      fontRow,
      l10n().lyricsSettingsSizeLarge,
      'font',
      () => container.read(lyricsFontScaleProvider) == LyricsFontScale.large,
    );
    await pick(
      alignRow,
      l10n().lyricsSettingsAlignCenter,
      'align',
      () => container.read(lyricsAlignProvider) == LyricsAlign.center,
    );
    await pick(
      dimRow,
      l10n().lyricsSettingsDimStrong,
      'dim',
      () => container.read(lyricsDimProvider) == LyricsDim.strong,
    );
    await pick(
      localRow,
      l10n().lyricsSettingsLocalLrc,
      'local',
      () => container.read(lyricsLocalFirstProvider) == LocalFirst.lrc,
    );

    // The lyrics screen shows the new size and alignment.
    await leaveSettings();
    await openMobileNowPlaying();
    await openLyricsScreen();
    await app.pumpUntil(
      () => find.byType(SyncedLyricsView).evaluate().isNotEmpty,
      what: 'the synced view after the settings change',
    );
    expect(
      effectiveFontSize(
        find.descendant(
          of: find.byType(SyncedLyricsView),
          matching: find.text('Sylt first line'),
        ),
      ),
      greaterThan(baselineSize!),
      reason: 'large font shows bigger lyrics',
    );
    expect(baselineAlign, isNot(TextAlign.center), reason: 'baseline');
    expect(
      effectiveAlign(
        find.descendant(
          of: find.byType(SyncedLyricsView),
          matching: find.text('Sylt first line'),
        ),
      ),
      TextAlign.center,
      reason: 'centred lyrics',
    );
    await shot('lyrics-after-settings');

    // ⚙ of "Lời cho bài này" over Now Playing: the modal closes, Now Playing
    // closes too, and the Lời bài page opens.
    await tester.tap(find.byType(LyricsSourceButton));
    await app.pumpUntil(
      () => modal.evaluate().isNotEmpty,
      what: 'the lyrics modal from the header',
    );
    await tester.tap(
      find.byWidgetPredicate(
        (w) =>
            w is KIconButton && w.tooltip == l10n().lyricsSettingsModalSettings,
      ),
    );
    await app.pumpUntil(
      () => find.byType(LyricsSettingsPage).evaluate().isNotEmpty,
      what: 'the Lời bài page from the modal ⚙',
    );
    expect(modal, findsNothing, reason: 'the modal closed');
    expect(find.byType(MobileNowPlaying), findsNothing, reason: 'NP closed');
    await shot('settings-from-gear');

    // Restore every changed setting to its default.
    await pick(
      find.byType(LyricsChoiceRow<LyricsFontScale>),
      l10n().lyricsSettingsSizeMedium,
      'font-restore',
      () => container.read(lyricsFontScaleProvider) == LyricsFontScale.medium,
    );
    await pick(
      find.byType(LyricsChoiceRow<LyricsAlign>),
      l10n().lyricsSettingsAlignStart,
      'align-restore',
      () => container.read(lyricsAlignProvider) == LyricsAlign.start,
    );
    await pick(
      find.byType(LyricsChoiceRow<LyricsDim>),
      l10n().lyricsSettingsDimLight,
      'dim-restore',
      () => container.read(lyricsDimProvider) == LyricsDim.light,
    );
    await pick(
      find.byType(LyricsChoiceRow<LocalFirst>),
      l10n().lyricsSettingsLocalTag,
      'local-restore',
      () => container.read(lyricsLocalFirstProvider) == LocalFirst.tag,
    );

    semantics.dispose();
  });
}
