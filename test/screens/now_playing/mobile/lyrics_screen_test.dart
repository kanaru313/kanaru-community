import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/state/playing_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/state/track_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/state/translation/track_translation_notifier.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_providers.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_view.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_body.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_for_track_body.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_settings_link.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_source_button.dart';
import 'package:kanaru/src/lyrics/ui/translation/modal/translate_body.dart';
import 'package:kanaru/src/lyrics/ui/translation/translate_button.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/media/domain/track_info.dart';
import 'package:kanaru/src/playback/domain/audio_engine.dart';
import 'package:kanaru/src/playback/state/track_info_providers.dart';
import 'package:kanaru/src/playback/ui/play_pause_button.dart';
import 'package:kanaru/src/playback/ui/playback_time_label.dart';
import 'package:kanaru/src/playback/ui/transport_buttons.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_card.dart';
import 'package:kanaru/src/screens/now_playing/ui/favorite_button.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/lyrics_screen.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/mobile_now_playing.dart';
import 'package:kanaru/src/screens/now_playing/ui/now_playing_page.dart';
import 'package:kanaru/src/screens/now_playing/ui/now_playing_seek_slot.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../lyrics/ui/lyrics_ui_host.dart' show plainLyrics, syncedLyrics;
import '../../../playback/support/ui_host.dart';
import '../../../support/icon_button_finders.dart';

class _IdleTranslation extends TrackTranslation {
  _IdleTranslation(super.trackId);

  @override
  TranslationView build() => TranslationView.idle;
}

final _routes = <RouteBase>[
  GoRoute(
    path: '/now-playing',
    builder: (context, state) => const NowPlayingPage(),
  ),
  GoRoute(
    path: lyricsSettingsLocation,
    builder: (context, state) => const Text('lyrics settings page'),
  ),
];

Future<void> _pumpFor(WidgetTester tester, [int steps = 8]) async {
  await tester.pump();
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Now Playing at 390 x 844 with the lyrics screen open on top.
Future<UiHost> _openScreen(
  WidgetTester tester, {
  TrackLyrics lyrics = const LyricsNone(),
  int line = 5,
  List<Override> extra = const [],
}) async {
  final overrides = <Override>[
    playingLyricsProvider.overrideWithValue(
      PlayingLyrics(entryId: 1, trackId: const TrackId(1), lyrics: lyrics),
    ),
    playingLyricsLineProvider.overrideWithValue(line),
    trackLyricsProvider.overrideWith((ref, id) => lyrics),
    // The modal of the translate button reads the translation of the song;
    // its engine is the app root's, not this host's.
    trackTranslationProvider.overrideWith2((id) => _IdleTranslation(id)),
    ...extra,
  ];
  final host = await pumpWithPlayer(
    tester,
    const Text('home'),
    overrides: overrides,
    routes: _routes,
    size: const Size(390, 844),
  );
  host.router!.push('/now-playing');
  await _pumpFor(tester, 5);
  await host.letStreamsArrive(tester);
  await tester.scrollUntilVisible(
    find.byType(LyricsCard),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.byType(LyricsCard));
  await _pumpFor(tester);
  await host.letStreamsArrive(tester);
  return host;
}

/// Loads a 240 s duration for the playing entry, so the seek bar seeks.
Future<void> _loadDuration(WidgetTester tester, UiHost host) async {
  await host.run(
    tester,
    () async => host.h.engine.emit(
      EngineLoaded(host.h.loadedToken, const Duration(seconds: 240)),
    ),
  );
  await host.letStreamsArrive(tester);
}

/// The elapsed time label in the lyrics screen's footer.
String _elapsed(WidgetTester tester) => tester
    .widget<Text>(
      find.descendant(
        of: find.descendant(
          of: find.byType(LyricsScreen),
          matching: find.byWidgetPredicate(
            (w) => w is PlaybackTimeLabel && !w.total,
          ),
        ),
        matching: find.byType(Text),
      ),
    )
    .data!;

Iterable<String> _seeks(UiHost host) =>
    host.h.engine.commands.where((c) => c.startsWith('seek:'));

/// Lets go in the real zone, so a seek reaches the engine before checking.
/// Real time runs once more after the frames: a spring the release started
/// in the real zone finishes there, before the test ends.
Future<void> _release(WidgetTester tester, UiHost host, TestGesture g) async {
  await tester.runAsync(() async {
    await g.up();
    await host.h.settle();
  });
  await _pumpFor(tester);
  await host.letStreamsArrive(tester);
}

Future<void> _back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await _pumpFor(tester);
}

void main() {
  testWidgets('header, lyrics and footer are there', (tester) async {
    await _openScreen(tester, lyrics: LyricsShown(syncedLyrics(40)));
    expect(find.byType(LyricsScreen), findsOneWidget);
    expect(byIconButton('Minimise'), findsOneWidget);
    expect(find.text('T0'), findsWidgets);
    expect(find.byType(FavoriteButton), findsOneWidget);
    expect(find.byType(LyricsBody), findsOneWidget);
    expect(find.byType(NowPlayingSeekSlot), findsOneWidget);
    expect(find.byType(PreviousButton), findsOneWidget);
    expect(find.byType(NextButton), findsOneWidget);
    expect(tester.getSize(find.byType(PlayPauseButton)).width, 64);
    // The lyrics line of the playing song is in the body.
    expect(find.text('Line 5'), findsOneWidget);
  });

  testWidgets('Dịch is inert without lyrics and live with them', (
    tester,
  ) async {
    await _openScreen(tester);
    final none = tester.widget<KIconButton>(
      byIconButton('Translate lyrics · No lyrics to translate'),
    );
    expect(none.onPressed, isNull);
  });

  testWidgets('Dịch opens "Translate lyrics" over the screen', (tester) async {
    await _openScreen(tester, lyrics: LyricsShown(syncedLyrics(40)));
    final button = tester.widget<KIconButton>(
      byIconButton('Translate lyrics · Off'),
    );
    expect(button.onPressed, isNotNull);
    await tester.tap(find.byType(TranslateButton));
    await tester.pumpAndSettle();
    expect(find.byType(TranslateBody), findsOneWidget);
    expect(find.byType(LyricsScreen), findsOneWidget);
  });

  testWidgets('the source button opens the modal over the screen', (
    tester,
  ) async {
    await _openScreen(tester, lyrics: LyricsShown(syncedLyrics(40)));
    await tester.tap(find.byType(LyricsSourceButton));
    await tester.pumpAndSettle();
    expect(find.byType(LyricsForTrackBody), findsOneWidget);
    expect(find.byType(LyricsScreen), findsOneWidget);
  });

  testWidgets('the modal settings button leaves the lyrics screen and Now '
      'Playing for Settings', (tester) async {
    final host = await _openScreen(
      tester,
      lyrics: LyricsShown(syncedLyrics(40)),
    );
    await tester.tap(find.byType(LyricsSourceButton));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is KIconButton && w.tooltip == 'Lyrics settings',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LyricsForTrackBody), findsNothing);
    expect(find.byType(LyricsScreen), findsNothing);
    expect(find.byType(MobileNowPlaying), findsNothing);
    expect(find.text('lyrics settings page'), findsOneWidget);
    expect(
      host.router!.routerDelegate.currentConfiguration.last.matchedLocation,
      lyricsSettingsLocation,
    );
    expect(tester.takeException(), isNull);
    // The translate button's database stream ends with the screen: let its
    // zero-length timer fire.
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('the trailing buttons touch: no gap between them', (
    tester,
  ) async {
    await _openScreen(tester, lyrics: LyricsShown(syncedLyrics(40)));
    Rect rect(Finder f) => tester.getRect(f);
    final source = rect(find.byType(LyricsSourceButton));
    final translate = rect(find.byType(TranslateButton));
    final favourite = rect(find.byType(FavoriteButton));
    expect(translate.left, closeTo(source.right, 0.01));
    expect(favourite.left, closeTo(translate.right, 0.01));
  });

  testWidgets('Back order: modal, then the lyrics screen, then Now Playing', (
    tester,
  ) async {
    await _openScreen(tester, lyrics: LyricsShown(syncedLyrics(40)));
    await tester.tap(find.byType(LyricsSourceButton));
    await tester.pumpAndSettle();
    await _back(tester);
    expect(find.byType(LyricsForTrackBody), findsNothing);
    expect(find.byType(LyricsScreen), findsOneWidget);
    await _back(tester);
    expect(find.byType(LyricsScreen), findsNothing);
    expect(find.byType(MobileNowPlaying), findsOneWidget);
  });

  testWidgets('the minimise button closes it and leaves Now Playing', (
    tester,
  ) async {
    await _openScreen(tester);
    await tester.tap(byIconButton('Minimise'));
    await _pumpFor(tester);
    expect(find.byType(LyricsScreen), findsNothing);
    expect(find.byType(MobileNowPlaying), findsOneWidget);
  });

  testWidgets('Back closes it and leaves Now Playing open', (tester) async {
    await _openScreen(tester);
    await _back(tester);
    expect(find.byType(LyricsScreen), findsNothing);
    expect(find.byType(MobileNowPlaying), findsOneWidget);
    await _back(tester);
    expect(find.byType(MobileNowPlaying), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('a pull down on the header closes it', (tester) async {
    await _openScreen(tester);
    await tester.drag(find.text('T0').first, const Offset(0, 260));
    await _pumpFor(tester);
    expect(find.byType(LyricsScreen), findsNothing);
    expect(find.byType(MobileNowPlaying), findsOneWidget);
  });

  testWidgets('the footer keeps its 56 band and its place between songs', (
    tester,
  ) async {
    var known = true;
    final host = await _openScreen(
      tester,
      lyrics: LyricsShown(syncedLyrics(40)),
      extra: [
        trackInfoProvider.overrideWith(
          (ref, id) => Stream.value(
            known
                ? TrackInfo(
                    id: id,
                    title: 'Song',
                    status: TrackAvailability.present,
                    relPath: 'song.flac',
                    artist: 'Art',
                    album: 'A' * 200,
                  )
                : null,
          ),
        ),
      ],
    );
    Finder inScreen(Finder f) =>
        find.descendant(of: find.byType(LyricsScreen), matching: f);
    final slot = inScreen(find.byType(NowPlayingSeekSlot));
    expect(tester.getSize(slot).height, 56);
    final seek = tester.getTopLeft(slot);
    final play = tester.getTopLeft(inScreen(find.byType(PlayPauseButton)));
    // A song whose info is not known yet (no title, no artist).
    known = false;
    host.container.invalidate(trackInfoProvider);
    await tester.pump();
    await host.letStreamsArrive(tester);
    expect(find.byType(LyricsScreen), findsOneWidget);
    expect(tester.getTopLeft(slot), seek);
    expect(tester.getTopLeft(inScreen(find.byType(PlayPauseButton))), play);
  });

  testWidgets('a short pull on the footer springs back', (tester) async {
    await _openScreen(tester);
    await tester.drag(
      find.byType(NowPlayingSeekSlot).last,
      const Offset(0, 40),
    );
    await _pumpFor(tester);
    expect(find.byType(LyricsScreen), findsOneWidget);
  });

  group('seek bar in the footer', () {
    double shift(WidgetTester tester) =>
        tester.getTopLeft(find.byType(Scaffold).last).dy;

    testWidgets('drag right then up 60: no seek, the screen stays put', (
      tester,
    ) async {
      final host = await _openScreen(tester);
      await _loadDuration(tester, host);
      final bar = tester.getRect(find.byType(KWaveformSeekBar).last);
      final g = await tester.startGesture(Offset(bar.left + 40, bar.center.dy));
      await g.moveBy(const Offset(80, 0));
      await tester.pump();
      await g.moveBy(const Offset(0, -30));
      await g.moveBy(const Offset(0, -30));
      await tester.pump();
      expect(find.text('Release to cancel'), findsOneWidget);
      expect(shift(tester), 0);
      await _release(tester, host, g);
      expect(_seeks(host), isEmpty);
      expect(find.text('Release to cancel'), findsNothing);
      expect(find.byType(LyricsScreen), findsOneWidget);
      expect(shift(tester), 0);

      // The same drag without going up seeks once.
      final again = await tester.startGesture(
        Offset(bar.left + 40, bar.center.dy),
      );
      await again.moveBy(const Offset(80, 0));
      await tester.pump();
      await _release(tester, host, again);
      expect(_seeks(host), hasLength(1));
    });

    testWidgets('a drag shows the finger time as elapsed in the footer', (
      tester,
    ) async {
      final host = await _openScreen(tester);
      await _loadDuration(tester, host);
      String shown() => _elapsed(tester);
      expect(shown(), '0:00');
      final bar = tester.getRect(find.byType(KWaveformSeekBar).last);
      final g = await tester.startGesture(Offset(bar.left + 40, bar.center.dy));
      await g.moveTo(
        Offset(bar.left + 6 + (bar.width - 12) * 65.5 / 240, bar.center.dy),
      );
      await tester.pump();
      expect(shown(), '1:05');
      await g.moveBy(const Offset(0, -60));
      await tester.pump();
      expect(shown(), '0:00');
      await _release(tester, host, g);
      expect(_seeks(host), isEmpty);
      expect(shown(), '0:00');
    });

    testWidgets('a hold then a pull down pulls the screen, no seek', (
      tester,
    ) async {
      final host = await _openScreen(tester);
      await _loadDuration(tester, host);
      final bar = tester.getRect(find.byType(KWaveformSeekBar).last);
      final g = await tester.startGesture(bar.center);
      await tester.pump(const Duration(milliseconds: 200));
      // The middle of a 240 s bar, as the elapsed time (and in the bubble).
      expect(_elapsed(tester), '2:00');
      await g.moveBy(const Offset(0, 20));
      await g.moveBy(const Offset(0, 20));
      await tester.pump();
      expect(shift(tester), greaterThan(20));
      expect(find.text('2:00'), findsNothing);
      expect(_elapsed(tester), '0:00');
      expect(find.text('Release to cancel'), findsNothing);
      await _release(tester, host, g);
      expect(_seeks(host), isEmpty);
      expect(find.byType(LyricsScreen), findsOneWidget);
      expect(shift(tester), closeTo(0, 0.01));
    });

    testWidgets('a hold then straight up: no seek, no cancel text', (
      tester,
    ) async {
      final host = await _openScreen(tester);
      await _loadDuration(tester, host);
      final bar = tester.getRect(find.byType(KWaveformSeekBar).last);
      final g = await tester.startGesture(bar.center);
      await tester.pump(const Duration(milliseconds: 200));
      // As the elapsed time (and in the bubble).
      expect(_elapsed(tester), '2:00');
      await g.moveBy(const Offset(0, -30));
      await g.moveBy(const Offset(0, -30));
      await tester.pump();
      expect(find.text('2:00'), findsNothing);
      expect(_elapsed(tester), '0:00');
      expect(find.text('Release to cancel'), findsNothing);
      await _release(tester, host, g);
      expect(_seeks(host), isEmpty);
      expect(find.byType(LyricsScreen), findsOneWidget);
      expect(shift(tester), 0);
    });
  });

  testWidgets('scrolling the lyrics never closes it', (tester) async {
    await _openScreen(tester, lyrics: LyricsShown(plainLyrics(80)));
    final list = find.byType(ListView);
    await tester.drag(list, const Offset(0, -400));
    await tester.drag(list, const Offset(0, 150));
    await _pumpFor(tester);
    expect(find.byType(LyricsScreen), findsOneWidget);
  });

  testWidgets('a pull down past the top of the lyrics closes it', (
    tester,
  ) async {
    await _openScreen(tester, lyrics: LyricsShown(plainLyrics(80)));
    final list = find.byType(ListView);
    // At the top already: this drag is all overscroll.
    await tester.drag(list, const Offset(0, 300));
    await _pumpFor(tester);
    expect(find.byType(LyricsScreen), findsNothing);
    expect(find.byType(MobileNowPlaying), findsOneWidget);
  });

  testWidgets('the off state shows a button that opens the modal', (
    tester,
  ) async {
    await _openScreen(tester, lyrics: const LyricsOff(null));
    expect(find.text('Lyrics are off for this song'), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.byType(LyricsForTrackBody), findsOneWidget);
  });

  testWidgets('with no track left the screen and the page leave, once', (
    tester,
  ) async {
    final host = await _openScreen(tester);
    final ids = {for (final i in host.h.c.queueState.items) i.entryId};
    await host.run(tester, () async => host.h.c.remove(ids));
    await host.letStreamsArrive(tester);
    await _pumpFor(tester);
    expect(find.byType(LyricsScreen), findsNothing);
    expect(find.byType(MobileNowPlaying), findsNothing);
    expect(find.text('home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dragging back up gives the pull back before the text scrolls', (
    tester,
  ) async {
    await _openScreen(tester, lyrics: LyricsShown(plainLyrics(80)));
    double shift() => tester.getTopLeft(find.byType(Scaffold).last).dy;
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ListView)),
    );
    await gesture.moveBy(const Offset(0, 80));
    await tester.pump();
    final pulled = shift();
    expect(pulled, greaterThan(20));
    await gesture.moveBy(const Offset(0, -40));
    await tester.pump();
    expect(shift(), lessThan(pulled - 20));
    await gesture.up();
    await _pumpFor(tester);
    expect(shift(), closeTo(0, 0.01));
    expect(find.byType(LyricsScreen), findsOneWidget);
  });

  testWidgets('a tablet width uses the larger lyrics line', (tester) async {
    final host = await pumpWithPlayer(
      tester,
      const Text('home'),
      overrides: [
        playingLyricsProvider.overrideWithValue(
          PlayingLyrics(
            entryId: 1,
            trackId: const TrackId(1),
            lyrics: LyricsShown(plainLyrics(5)),
          ),
        ),
      ],
      routes: _routes,
      size: const Size(700, 1000),
    );
    host.router!.push('/now-playing');
    await _pumpFor(tester, 5);
    await host.letStreamsArrive(tester);
    await tester.scrollUntilVisible(
      find.byType(LyricsCard),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(LyricsCard));
    await _pumpFor(tester);
    final style = tester.widget<Text>(find.text('Plain 0')).style!;
    expect(style.fontSize, closeTo(34 * 0.7, 1e-9));
  });
}
