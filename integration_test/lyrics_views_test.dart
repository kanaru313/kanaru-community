import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/widgets.dart' show Scrollable, Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/lyrics/state/playing_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_body.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_card.dart';
import 'package:kanaru/src/lyrics/ui/plain_lyrics_view.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_state_view.dart';
import 'package:kanaru/src/lyrics/ui/synced_lyrics_view.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/state/now_playing_panel.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru/src/playback/ui/mini_player.dart';
import 'package:kanaru/src/screens/now_playing/ui/desktop/desktop_side_pane.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/lyrics_screen.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/mobile_now_playing.dart';

import 'support/harness.dart';

/// The lyrics views on the real app, fed by the real readers and the real
/// engine: the mobile card and lyrics screen (synced, seek, plain, none, the
/// way back) and then, by widening the window, the desktop tab. Asserts state
/// (selected line through semantics, providers, widget types), never pixels;
/// the screenshots are for comparing with the mockup by eye.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('lyrics views follow the song on both shells', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 900);
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);

    final app = await startKanaru(tester);
    final container = app.container;
    final ids = await app.trackIdsByTitle();
    final player = container.read(playerControllerProvider);

    Future<void> shot(String name) async {
      await tester.pump(const Duration(milliseconds: 400));
      try {
        final bytes = await binding.takeScreenshot(name);
        final dir = Directory('/tmp/kanaru-it/shots');
        if (Platform.isLinux) {
          dir.createSync(recursive: true);
          File('${dir.path}/$name.png').writeAsBytesSync(bytes);
        }
      } on Object catch (e) {
        // A screenshot is for the eye only: never fail the test for it.
        debugPrint('screenshot $name failed: $e');
      }
    }

    Future<void> playPaused(String title) async {
      final id = TrackId(ids[title]!);
      await player.playTracks([
        id,
      ], context: const PlayContext(PlayContextKind.songs));
      await app.pumpUntil(
        () => container.read(nowPlayingProvider).value?.trackId == id,
        what: '"$title" to be the playing track',
      );
      await player.pause();
      await player.seek(Duration.zero);
    }

    int line() => container.read(playingLyricsLineProvider);

    bool selected(String text) =>
        isSemantics(isSelected: true)
            .matches(tester.getSemantics(find.text(text)), {});

    Future<void> seekTo(Duration to, int expectedLine) async {
      await player.seek(to);
      await app.pumpUntil(
        () => line() == expectedLine,
        what: 'the current line to be $expectedLine at $to',
        timeout: const Duration(seconds: 15),
      );
      await tester.pump(const Duration(milliseconds: 700));
    }

    AppLocalizations l10n() =>
        AppLocalizations.of(tester.element(find.byType(LyricsBody)));

    // ---- mobile shell: 800 dp wide ----
    await playPaused('IT Sylt Tag');
    expect(find.byType(MiniPlayer), findsOneWidget);
    await tester.tap(find.byType(MiniPlayer));
    await app.pumpUntil(
      () => find.byType(MobileNowPlaying).evaluate().isNotEmpty,
      what: 'the mobile Now Playing page',
    );
    await tester.scrollUntilVisible(
      find.byType(LyricsCard),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await app.pumpUntil(
      () => find.text('Sylt first line').evaluate().isNotEmpty,
      what: 'the card to show the synced lyrics',
    );
    await shot('mobile-01-card-synced');

    await tester.tap(find.byType(LyricsCard));
    await app.pumpUntil(
      () => find.byType(LyricsScreen).evaluate().isNotEmpty,
      what: 'the lyrics screen',
    );
    await app.pumpUntil(
      () => find.byType(SyncedLyricsView).evaluate().isNotEmpty,
      what: 'the synced view',
    );
    expect(find.text('Sylt second line'), findsOneWidget);

    // Seeking moves the highlight.
    await seekTo(const Duration(milliseconds: 700), 0);
    expect(selected('Sylt first line'), isTrue);
    expect(selected('Sylt second line'), isFalse);
    await shot('mobile-02-screen-first-line');
    await seekTo(const Duration(milliseconds: 2000), 1);
    expect(selected('Sylt second line'), isTrue);
    expect(selected('Sylt first line'), isFalse);

    // Pressing a line seeks to it.
    await tester.tap(find.text('Sylt first line'));
    await app.pumpUntil(
      () => line() == 0,
      what: 'a press on the first line to seek to it',
    );
    expect(selected('Sylt first line'), isTrue);

    // The highlight follows the song as it plays.
    await player.seek(Duration.zero);
    await player.play();
    await app.pumpUntil(
      () => line() == 0,
      what: 'line 0 while playing',
      timeout: const Duration(seconds: 15),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(selected('Sylt first line'), isTrue);
    await app.pumpUntil(
      () => line() == 1,
      what: 'line 1 while playing',
      timeout: const Duration(seconds: 15),
    );
    await tester.pump(const Duration(milliseconds: 700));
    expect(selected('Sylt second line'), isTrue);
    expect(selected('Sylt first line'), isFalse);
    await player.pause();

    // Back goes to Now Playing, not past it.
    await tester.binding.handlePopRoute();
    await app.pumpUntil(
      () => find.byType(LyricsScreen).evaluate().isEmpty,
      what: 'the lyrics screen to close on Back',
    );
    expect(find.byType(MobileNowPlaying), findsOneWidget);

    // Plain lyrics: the plain view with its note.
    await playPaused('IT Ogg Plain Tag');
    await app.pumpUntil(
      () => find.text('Ogg first line').evaluate().isNotEmpty,
      what: 'the card to show the plain lyrics',
    );
    await tester.tap(find.byType(LyricsCard));
    await app.pumpUntil(
      () => find.byType(PlainLyricsView).evaluate().isNotEmpty,
      what: 'the plain view',
    );
    expect(find.text(l10n().lyricsPlainNote), findsOneWidget);
    expect(find.byType(SyncedLyricsView), findsNothing);
    await shot('mobile-03-screen-plain');
    await tester.binding.handlePopRoute();
    await app.pumpUntil(
      () => find.byType(LyricsScreen).evaluate().isEmpty,
      what: 'the lyrics screen to close',
    );

    // No lyrics: the none state, no button.
    await playPaused('IT No Lyrics');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byType(LyricsCard));
    await app.pumpUntil(
      () => find.byType(LyricsStateView).evaluate().isNotEmpty,
      what: 'the none state',
    );
    expect(find.text(l10n().lyricsNoneTitle), findsOneWidget);
    expect(find.text(l10n().lyricsNoneMessage), findsOneWidget);
    expect(find.text(l10n().lyricsOffOpenChoice), findsNothing);
    await shot('mobile-04-screen-none');
    await tester.binding.handlePopRoute();
    await app.pumpUntil(
      () => find.byType(LyricsScreen).evaluate().isEmpty,
      what: 'the lyrics screen to close',
    );

    // ---- desktop shell: widen the window ----
    await playPaused('IT Sylt Tag');
    tester.view.physicalSize = const Size(1400, 900);
    await app.pumpUntil(
      () => container.read(nowPlayingPanelProvider).covered,
      what: 'the desktop Now Playing panel after widening',
    );
    await app.pumpUntil(
      () => find
          .descendant(
            of: find.byType(DesktopSidePane),
            matching: find.byType(SyncedLyricsView),
          )
          .evaluate()
          .isNotEmpty,
      what: 'the synced view in the desktop tab',
    );
    await seekTo(const Duration(milliseconds: 700), 0);
    expect(selected('Sylt first line'), isTrue);
    await shot('desktop-01-tab-synced');
    await seekTo(const Duration(milliseconds: 2000), 1);
    expect(selected('Sylt second line'), isTrue);
    expect(selected('Sylt first line'), isFalse);

    await playPaused('IT Uslt Tag');
    await app.pumpUntil(
      () => find
          .descendant(
            of: find.byType(DesktopSidePane),
            matching: find.byType(PlainLyricsView),
          )
          .evaluate()
          .isNotEmpty,
      what: 'the plain view in the desktop tab',
    );
    await shot('desktop-02-tab-plain');
    await playPaused('IT No Lyrics');
    await app.pumpUntil(
      () => find.text(l10n().lyricsNoneTitle).evaluate().isNotEmpty,
      what: 'the none state in the desktop tab',
    );
    await shot('desktop-03-tab-none');
  }, timeout: const Timeout(Duration(minutes: 6)));
}
