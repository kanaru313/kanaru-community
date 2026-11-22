import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/state/playing_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_body.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/ui/play_pause_button.dart';
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

final _routes = <RouteBase>[
  GoRoute(
    path: '/now-playing',
    builder: (context, state) => const NowPlayingPage(),
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
}) async {
  final overrides = <Override>[
    playingLyricsProvider.overrideWithValue(
      PlayingLyrics(entryId: 1, trackId: const TrackId(1), lyrics: lyrics),
    ),
    playingLyricsLineProvider.overrideWithValue(line),
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

  testWidgets('Dịch is dimmed and inert, with a "coming soon" tooltip', (
    tester,
  ) async {
    await _openScreen(tester);
    final button = tester.widget<KIconButton>(
      byIconButton('Translate lyrics · Coming soon'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('no source button until the lyrics source lands', (tester) async {
    await _openScreen(tester);
    expect(byIconButton('Lyrics for this song'), findsNothing);
    expect(find.text('Lyrics for this song'), findsNothing);
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

  testWidgets('a short pull on the footer springs back', (tester) async {
    await _openScreen(tester);
    await tester.drag(
      find.byType(NowPlayingSeekSlot).last,
      const Offset(0, 40),
    );
    await _pumpFor(tester);
    expect(find.byType(LyricsScreen), findsOneWidget);
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

  testWidgets('the off state shows, without a button until the source lands', (
    tester,
  ) async {
    await _openScreen(tester, lyrics: const LyricsOff(null));
    expect(find.text('Lyrics are off for this song'), findsOneWidget);
    expect(find.text('Lyrics for this song'), findsNothing);
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
