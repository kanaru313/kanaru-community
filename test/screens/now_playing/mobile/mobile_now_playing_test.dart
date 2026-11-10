import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/playback/domain/repeat_mode.dart';
import 'package:kanaru/src/playback/ui/play_pause_button.dart';
import 'package:kanaru/src/playback/ui/transport_buttons.dart';
import 'package:kanaru/src/screens/now_playing/ui/favorite_button.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/cover_swiper.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/lyrics_card_placeholder.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/mobile_now_playing.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/now_playing_button_row.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/now_playing_header.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/track_info_card.dart';
import 'package:kanaru/src/screens/now_playing/ui/now_playing_page.dart';
import 'package:kanaru/src/screens/now_playing/ui/now_playing_seek_slot.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart' hide RepeatMode;

import '../../../playback/support/ui_host.dart';

final _routes = <RouteBase>[
  GoRoute(
    path: '/now-playing',
    builder: (context, state) => const NowPlayingPage(),
  ),
];

/// A host whose home page is a stand-in, with Now Playing pushed on top.
Future<UiHost> _open(WidgetTester tester, {Size? size}) async {
  final host = await pumpWithPlayer(
    tester,
    const Center(child: Text('home page')),
    routes: _routes,
    size: size ?? const Size(390, 844),
  );
  host.router!.push('/now-playing');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await host.letStreamsArrive(tester);
  return host;
}

String _location(UiHost host) =>
    host.router!.routerDelegate.currentConfiguration.last.matchedLocation;

void main() {
  testWidgets('opens at the top of the page', (tester) async {
    await _open(tester);
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    expect(scroll.position.pixels, 0);
    expect(find.byType(MobileNowPlaying), findsOneWidget);
  });

  testWidgets('the header shows position over the source line', (tester) async {
    await _open(tester);
    expect(find.text('1/6'), findsOneWidget);
    // The harness plays "songs" without a label.
    expect(find.text('Songs'), findsOneWidget);
  });

  testWidgets('the chevron closes the page', (tester) async {
    final host = await _open(tester);
    await tester.tap(find.byTooltip('Minimise'));
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
        y(find.byType(LyricsCardPlaceholder)),
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
    final ai = tester.widget<IconButton>(
      find.descendant(
        of: row,
        matching: find.widgetWithIcon(IconButton, KIcons.ai),
      ),
    );
    expect(ai.onPressed, isNull);
  });

  testWidgets('the lyrics card is dimmed, "Coming soon" and not tappable', (
    tester,
  ) async {
    await _open(tester);
    await tester.scrollUntilVisible(
      find.byType(LyricsCardPlaceholder),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Coming soon'), findsWidgets);
    expect(
      tester
          .widget<Opacity>(
            find.descendant(
              of: find.byType(LyricsCardPlaceholder),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      lessThan(1),
    );
    expect(
      find.descendant(
        of: find.byType(LyricsCardPlaceholder),
        matching: find.byType(InkWell),
      ),
      findsNothing,
    );
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

    testWidgets('repeat off: a left swipe at the last entry bounces back', (
      tester,
    ) async {
      final host = await openAtLast(tester, RepeatMode.off);
      await swipeNext(tester, host);
      expect(host.h.c.queueState.current, 5);
    });
  });
}
