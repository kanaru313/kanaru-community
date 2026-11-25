import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_card.dart';
import 'package:kanaru/src/media/domain/cover_colors.dart';
import 'package:kanaru/src/playback/domain/audio_engine.dart';
import 'package:kanaru/src/playback/domain/repeat_mode.dart';
import 'package:kanaru/src/playback/state/playing_cover_colors.dart';
import 'package:kanaru/src/playback/state/playback_settings_providers.dart';
import 'package:kanaru/src/playback/ui/play_pause_button.dart';
import 'package:kanaru/src/playback/ui/transport_buttons.dart';
import 'package:kanaru/src/screens/now_playing/ui/favorite_button.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/cover_swiper.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/lyrics_screen.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/mobile_now_playing.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/now_playing_button_row.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/now_playing_header.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/track_info_card.dart';
import 'package:kanaru/src/screens/now_playing/ui/now_playing_page.dart';
import 'package:kanaru/src/screens/now_playing/ui/now_playing_seek_slot.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart' hide RepeatMode;

import '../../../playback/support/ui_host.dart';
import '../../../support/icon_button_finders.dart';

final _routes = <RouteBase>[
  GoRoute(
    path: '/now-playing',
    builder: (context, state) => const NowPlayingPage(),
  ),
];

/// A host whose home page is a stand-in, with Now Playing pushed on top.
Future<UiHost> _open(
  WidgetTester tester, {
  Size? size,
  double textScale = 1,
  List<Override> overrides = const [],
}) async {
  final host = await pumpWithPlayer(
    tester,
    const Center(child: Text('home page')),
    overrides: overrides,
    routes: _routes,
    size: size ?? const Size(390, 844),
    textScale: textScale,
  );
  host.router!.push('/now-playing');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
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

Iterable<String> _seeks(UiHost host) =>
    host.h.engine.commands.where((c) => c.startsWith('seek:'));

/// Lets go in the real zone, so a seek reaches the engine before checking.
/// Real time runs once more after the frames, so what the release started in
/// the real zone finishes before the test ends.
Future<void> _release(WidgetTester tester, UiHost host, TestGesture g) async {
  await tester.runAsync(() async {
    await g.up();
    await host.h.settle();
  });
  await tester.pumpAndSettle();
  await host.letStreamsArrive(tester);
}

String _location(UiHost host) =>
    host.router!.routerDelegate.currentConfiguration.last.matchedLocation;

void main() {
  testWidgets('the tint takes the playing cover palette', (tester) async {
    await _open(
      tester,
      overrides: [
        playingCoverColorsProvider.overrideWithValue(
          const PlayingCoverColorsFound(
            CoverColors(seed: 1, palette: [0xFFFF0000, 0xFF0000FF]),
          ),
        ),
      ],
    );
    final tint = tester.widget<CoverTintBackground>(
      find.byType(CoverTintBackground),
    );
    expect(tint.palette, const [Color(0xFFFF0000), Color(0xFF0000FF)]);
    expect(tint.loading, isFalse);
  });

  testWidgets('a pending cover leaves the tint loading, not faded out', (
    tester,
  ) async {
    await _open(
      tester,
      overrides: [
        playingCoverColorsProvider.overrideWithValue(
          const PlayingCoverColorsPending(),
        ),
      ],
    );
    final tint = tester.widget<CoverTintBackground>(
      find.byType(CoverTintBackground),
    );
    expect(tint.palette, isNull);
    expect(tint.loading, isTrue);
  });

  for (final (size, scale) in [
    (const Size(360, 640), 1.0),
    (const Size(360, 640), 1.3),
    (const Size(320, 568), 1.3),
    (const Size(390, 844), 1.3),
    (const Size(360, 640), 1.5),
  ]) {
    testWidgets('lays out without overflow at $size, text ×$scale', (
      tester,
    ) async {
      await _open(tester, size: size, textScale: scale);
      expect(tester.takeException(), isNull);
      // The page scrolls to its end without an error either.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('opens at the top of the page', (tester) async {
    await _open(tester);
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    expect(scroll.position.pixels, 0);
    expect(find.byType(MobileNowPlaying), findsOneWidget);
  });

  group('seek bar on the page', () {
    double scrolled(WidgetTester tester) => tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .pixels;

    testWidgets('drag right then up 60: no seek, the page stays put', (
      tester,
    ) async {
      final host = await _open(tester);
      await _loadDuration(tester, host);
      final bar = tester.getRect(find.byType(KWaveformSeekBar));
      final g = await tester.startGesture(Offset(bar.left + 40, bar.center.dy));
      await g.moveBy(const Offset(80, 0));
      await tester.pump();
      await g.moveBy(const Offset(0, -30));
      await g.moveBy(const Offset(0, -30));
      await tester.pump();
      expect(find.text('Release to cancel'), findsOneWidget);
      expect(scrolled(tester), 0);
      await _release(tester, host, g);
      expect(_seeks(host), isEmpty);
      expect(scrolled(tester), 0);
      expect(find.byType(MobileNowPlaying), findsOneWidget);
      expect(_location(host), '/now-playing');

      // The same drag without going up seeks once.
      final again = await tester.startGesture(
        Offset(bar.left + 40, bar.center.dy),
      );
      await again.moveBy(const Offset(80, 0));
      await tester.pump();
      await _release(tester, host, again);
      expect(_seeks(host), hasLength(1));
    });

    testWidgets('a hold then straight up scrolls the page, no seek', (
      tester,
    ) async {
      final host = await _open(tester);
      await _loadDuration(tester, host);
      // Without room to scroll there is no vertical ancestor and the bar's
      // own drag would take the move.
      final page = tester.state<ScrollableState>(find.byType(Scrollable).first);
      expect(page.position.maxScrollExtent, greaterThan(0));
      final bar = tester.getRect(find.byType(KWaveformSeekBar));
      final g = await tester.startGesture(bar.center);
      await tester.pump(const Duration(milliseconds: 200));
      // The middle of a 240 s bar.
      expect(find.text('2:00'), findsOneWidget);
      await g.moveBy(const Offset(0, -30));
      await g.moveBy(const Offset(0, -30));
      await tester.pump();
      // The page has little to scroll at this size; any scroll shows that
      // the drag went to it.
      expect(scrolled(tester), greaterThan(0));
      expect(find.text('2:00'), findsNothing);
      expect(find.text('Release to cancel'), findsNothing);
      await _release(tester, host, g);
      expect(_seeks(host), isEmpty);
      expect(find.byType(MobileNowPlaying), findsOneWidget);
    });
  });

  testWidgets('the header shows position over the album, empty without one', (
    tester,
  ) async {
    final host = await _open(tester);
    expect(find.text('1/6'), findsOneWidget);
    // The harness tracks have no album: no source text either.
    expect(find.text('Songs'), findsNothing);
    await host.run(tester, () async {
      await host.h.db.customUpdate(
        "UPDATE tracks SET album = 'HeaderAlb' WHERE title = 'T0'",
        updates: {host.h.db.tracks},
      );
    });
    await host.letStreamsArrive(tester);
    expect(
      find.descendant(
        of: find.byType(NowPlayingHeader),
        matching: find.text('HeaderAlb'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the chevron closes the page', (tester) async {
    final host = await _open(tester);
    await tester.tap(byIconButton('Minimise'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MobileNowPlaying), findsNothing);
    expect(_location(host), '/');
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('system back closes the page', (tester) async {
    final host = await _open(tester);
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MobileNowPlaying), findsNothing);
    expect(_location(host), '/');
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a 121 px pull on the header closes, 119 px returns', (
    tester,
  ) async {
    final host = await _open(tester);
    await tester.drag(find.text('1/6'), const Offset(0, 119));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(MobileNowPlaying), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(NowPlayingHeader)).dy,
      closeTo(0, 0.5),
    );
    await tester.drag(find.text('1/6'), const Offset(0, 121));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MobileNowPlaying), findsNothing);
    expect(_location(host), '/');
    await tester.pump(const Duration(seconds: 1));
  });

  for (final width in [360.0, 390.0, 800.0]) {
    testWidgets('layout order and sizes at ${width.toInt()} dp', (
      tester,
    ) async {
      await _open(tester, size: Size(width, 900));
      double y(Finder f) => tester.getTopLeft(f.first).dy;
      final order = [
        y(find.byType(NowPlayingHeader)),
        y(find.byType(CoverSwiper)),
        y(find.text('T0')),
        y(find.byType(NowPlayingSeekSlot)),
        y(find.byType(PlayPauseButton)),
        y(find.byType(NowPlayingButtonRow)),
        y(find.byType(LyricsCard)),
        y(find.byType(TrackInfoCard)),
      ];
      expect(order, [...order]..sort());
      final cover = tester.getSize(
        find
            .descendant(
              of: find.byType(NowPlayingCoverBox),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(cover.width, NowPlayingCoverBox.sideFor(width));
      expect(cover.height, cover.width);
      expect(tester.getSize(find.byType(NowPlayingSeekSlot)).height, 48);
      expect(
        tester.getSize(find.byType(NowPlayingButtonRow)).height,
        nowPlayingButtonRowHeight,
      );
      expect(tester.getSize(find.byType(PlayPauseButton)).width, 72);
      expect(tester.getSize(find.byType(NowPlayingHeader)).height, 56);
    });
  }

  testWidgets('title is 22 bold with the heart on the right', (tester) async {
    await _open(tester);
    final title = tester.widget<Text>(find.text('T0'));
    expect(title.style?.fontSize, 22);
    expect(title.style?.fontWeight, FontWeight.w700);
    expect(
      tester.getTopLeft(find.byType(FavoriteButton)).dx,
      greaterThan(tester.getTopRight(find.text('T0')).dx - 1),
    );
  });

  testWidgets('the heart is as large as Next', (tester) async {
    await _open(tester);
    final heart = tester.widget<KIconButton>(
      find.descendant(
        of: find.byType(FavoriteButton),
        matching: find.byType(KIconButton),
      ),
    );
    final next = tester.widget<KIconButton>(byIconButton('Next'));
    expect(heart.size, KIconSize.lg);
    expect(heart.size, next.size);
  });

  testWidgets('the heart is at the end of the title row', (tester) async {
    await _open(tester);
    // Row(Expanded(title), heart): the button ends at the page padding.
    final right = tester.getTopRight(find.byType(FavoriteButton)).dx;
    expect(right, greaterThan(390 - 32));
  });

  testWidgets('controls: time, previous, play, next, total in one row', (
    tester,
  ) async {
    await _open(tester);
    final ys = {
      for (final t in [
        find.byType(PreviousButton),
        find.byType(PlayPauseButton),
        find.byType(NextButton),
      ])
        tester.getCenter(t).dy,
    };
    expect(ys.length, 1);
    expect(find.text('0:00'), findsWidgets);
  });

  testWidgets('the repeat button of the row opens the repeat menu', (
    tester,
  ) async {
    final host = await _open(tester);
    final row = find.byType(NowPlayingButtonRow);
    await host.tap(
      tester,
      find.descendant(of: row, matching: find.byType(RepeatButton)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SelectionRow), findsNWidgets(5));
    expect(find.text('Repeat the whole queue'), findsOneWidget);
    await host.tap(tester, find.text('Repeat the whole queue'));
    await tester.pumpAndSettle();
    expect(host.container.read(repeatSettingProvider), RepeatMode.all);
    expect(find.byType(SelectionRow), findsNothing);
    expect(
      find.descendant(of: row, matching: find.byKey(KToggleIconButton.dotKey)),
      findsOneWidget,
    );
  });

  testWidgets('button row: shuffle, repeat, Ask AI (soon), queue', (
    tester,
  ) async {
    await _open(tester);
    final row = find.byType(NowPlayingButtonRow);
    final xs = [
      for (final icon in [
        KIcons.shuffle,
        KIcons.repeat,
        KIcons.ai,
        KIcons.queueMusic,
      ])
        tester
            .getCenter(find.descendant(of: row, matching: find.byIcon(icon)))
            .dx,
    ];
    expect(xs, [...xs]..sort());
    final ai = tester.widget<KIconButton>(
      find.descendant(
        of: row,
        matching: find.widgetWithIcon(KIconButton, KIcons.ai),
      ),
    );
    expect(ai.onPressed, isNull);
  });

  testWidgets('the lyrics card is a live button that opens the lyrics screen', (
    tester,
  ) async {
    await _open(tester);
    await tester.scrollUntilVisible(
      find.byType(LyricsCard),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Coming soon'), findsNothing);
    expect(find.byType(LyricsScreen), findsNothing);
    await tester.tap(find.byType(LyricsCard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(LyricsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the info card lists album and artist, then the technical line', (
    tester,
  ) async {
    final host = await _open(tester, size: const Size(390, 1400));
    await host.run(tester, () async {
      await host.h.db.customUpdate(
        "UPDATE tracks SET album = 'Alb', artist = 'Art', codec = 'FLAC', "
        "sample_rate = 44100, bitrate = 900 WHERE title = 'T0'",
        updates: {host.h.db.tracks},
      );
    });
    await host.letStreamsArrive(tester);
    expect(find.text('Alb · Art'), findsOneWidget);
    expect(find.textContaining('FLAC · 44.1 kHz · 900 kbps'), findsOneWidget);
  });

  testWidgets('without a track the page leaves', (tester) async {
    final host = await _open(tester);
    final ids = {for (final i in host.h.c.queueState.items) i.entryId};
    await host.run(tester, () async => host.h.c.remove(ids));
    await host.letStreamsArrive(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MobileNowPlaying), findsNothing);
    expect(_location(host), '/');
    await tester.pump(const Duration(seconds: 1));
  });

  group('the cover swipe at the last entry', () {
    Future<UiHost> openAtLast(WidgetTester tester, RepeatMode repeat) async {
      final host = await _open(tester);
      await host.run(tester, () async {
        await host.h.c.setRepeat(repeat);
        // Jump to the last of the six entries.
        for (var i = 0; i < 5; i++) {
          await host.h.c.next();
        }
      });
      await host.letStreamsArrive(tester);
      return host;
    }

    Future<void> swipeNext(WidgetTester tester, UiHost host) async {
      await tester.runAsync(() async {
        await tester.timedDrag(
          find.byType(CoverSwiper),
          const Offset(-200, 0),
          const Duration(milliseconds: 400),
        );
        await host.h.settle();
      });
      await tester.pump(const Duration(seconds: 1));
      await host.letStreamsArrive(tester);
    }

    testWidgets('repeat all: a left swipe wraps to the first entry', (
      tester,
    ) async {
      final host = await openAtLast(tester, RepeatMode.all);
      expect(host.h.c.queueState.current, 5);
      await swipeNext(tester, host);
      expect(host.h.c.queueState.current, 0);
    });

    testWidgets('repeat all reshuffled: a left swipe starts a new pass', (
      tester,
    ) async {
      final host = await openAtLast(tester, RepeatMode.allShuffled);
      final lastId = host.h.c.queueState.currentItem!.entryId;
      await swipeNext(tester, host);
      final q = host.h.c.queueState;
      expect(q.current, 0);
      expect(q.shuffled, isTrue);
      expect(q.items.first.entryId, isNot(lastId));
    });

    testWidgets('repeat off: a left swipe at the last entry bounces back', (
      tester,
    ) async {
      final host = await openAtLast(tester, RepeatMode.off);
      await swipeNext(tester, host);
      expect(host.h.c.queueState.current, 5);
    });
  });

  group('the cover swipe at the first entry', () {
    Future<UiHost> openAtFirst(WidgetTester tester, RepeatMode repeat) async {
      final host = await _open(tester);
      await host.run(tester, () => host.h.c.setRepeat(repeat));
      await host.letStreamsArrive(tester);
      return host;
    }

    Future<void> swipePrevious(WidgetTester tester, UiHost host) async {
      await tester.runAsync(() async {
        await tester.timedDrag(
          find.byType(CoverSwiper),
          const Offset(200, 0),
          const Duration(milliseconds: 400),
        );
        await host.h.settle();
      });
      await tester.pump(const Duration(seconds: 1));
      await host.letStreamsArrive(tester);
    }

    testWidgets('repeat all: a right swipe goes to the last entry', (
      tester,
    ) async {
      final host = await openAtFirst(tester, RepeatMode.all);
      expect(host.h.c.queueState.current, 0);
      await swipePrevious(tester, host);
      expect(host.h.c.queueState.current, 5);
    });

    testWidgets('repeat all reshuffled: a right swipe bounces back', (
      tester,
    ) async {
      final host = await openAtFirst(tester, RepeatMode.allShuffled);
      await swipePrevious(tester, host);
      expect(host.h.c.queueState.current, 0);
    });
  });
}
