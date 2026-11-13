import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/library/state/browse/selection_providers.dart';
import 'package:kanaru/src/library/ui/selection/selection_panel.dart';
import 'package:kanaru/src/media/domain/cover_colors.dart';
import 'package:kanaru/src/media/domain/track_info.dart';
import 'package:kanaru/src/playback/state/playing_cover_colors.dart';
import 'package:kanaru/src/playback/state/track_info_providers.dart';
import 'package:kanaru/src/playback/ui/flight_source.dart';
import 'package:kanaru/src/playback/ui/mini_player.dart';
import 'package:kanaru/src/playback/ui/queue/queue_row.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/mobile_now_playing.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/queue_sheet.dart';
import 'package:kanaru/src/screens/now_playing/ui/mobile/queue_strip.dart';
import 'package:kanaru/src/screens/now_playing/ui/now_playing_page.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../playback/support/controller_harness.dart' show ctx;
import '../../../playback/support/ui_host.dart';

final _routes = <RouteBase>[
  GoRoute(
    path: '/now-playing',
    builder: (context, state) => const NowPlayingPage(),
  ),
];

Future<void> _frames(WidgetTester tester, [int n = 8]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Now Playing with the queue sheet open on top of it.
Future<UiHost> _openFromNowPlaying(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
  bool withArtist = false,
  List<Override> overrides = const [],
}) async {
  final host = await pumpWithPlayer(
    tester,
    const Text('home'),
    routes: _routes,
    size: size,
    textScale: textScale,
    overrides: [
      ...overrides,
      if (withArtist)
        trackInfoProvider.overrideWith(
          (ref, id) => Stream.value(
            TrackInfo(
              id: id,
              title: 'A Song',
              artist: 'An Artist',
              status: TrackAvailability.present,
              relPath: 'a.mp3',
            ),
          ),
        ),
    ],
  );
  host.router!.push('/now-playing');
  await tester.pump();
  await _frames(tester, 5);
  await host.letStreamsArrive(tester);
  await tester.tap(find.byTooltip('Queue'));
  await tester.pump();
  await _frames(tester);
  await host.letStreamsArrive(tester);
  return host;
}

Finder get _sheet => find.byType(QueueSheetPage);

void main() {
  testWidgets('the tint takes the playing cover palette', (tester) async {
    await _openFromNowPlaying(
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
      find.descendant(of: _sheet, matching: find.byType(CoverTintBackground)),
    );
    expect(tint.palette, const [Color(0xFFFF0000), Color(0xFF0000FF)]);
    expect(tint.loading, isFalse);
  });

  testWidgets('a pending cover leaves the tint loading, not faded out', (
    tester,
  ) async {
    await _openFromNowPlaying(
      tester,
      overrides: [
        playingCoverColorsProvider.overrideWithValue(
          const PlayingCoverColorsPending(),
        ),
      ],
    );
    final tint = tester.widget<CoverTintBackground>(
      find.descendant(of: _sheet, matching: find.byType(CoverTintBackground)),
    );
    expect(tint.palette, isNull);
    expect(tint.loading, isTrue);
  });

  for (final (size, scale) in [
    (const Size(390, 844), 1.0),
    (const Size(360, 640), 1.0),
    (const Size(360, 640), 1.3),
  ]) {
    testWidgets(
      'opening the sheet lays out without overflow at $size, ×$scale',
      (tester) async {
        await _openFromNowPlaying(
          tester,
          size: size,
          textScale: scale,
          withArtist: true,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('the Queue button opens the sheet over Now Playing', (
    tester,
  ) async {
    await _openFromNowPlaying(tester);
    expect(_sheet, findsOneWidget);
    expect(find.byType(MobileNowPlaying), findsOneWidget);
    expect(find.byType(QueueRow), findsWidgets);
    expect(find.text('Queue'), findsWidgets);
    await _frames(tester, 3);
  });

  testWidgets('the strip holds the cover (72), the title and two buttons', (
    tester,
  ) async {
    await _openFromNowPlaying(tester);
    final cover = tester.getRect(find.byType(StripCover));
    expect(cover.size, const Size.square(72));
    expect(cover.left, 16);
    final play = tester.getRect(find.byType(StripPlay));
    expect(play.size, const Size.square(56));
    final next = tester.getRect(find.byType(StripNext));
    expect(next.size, const Size.square(48));
    expect(
      find.descendant(of: find.byType(StripText), matching: find.text('T0')),
      findsOneWidget,
    );
    await _frames(tester, 3);
  });

  testWidgets('the sheet has a fixed height from below the strip', (
    tester,
  ) async {
    await _openFromNowPlaying(tester);
    final strip = tester.getRect(find.byType(StripCover));
    final head = tester.getTopLeft(find.text('Queue').last);
    expect(head.dy, greaterThan(strip.bottom));
    final sheet = tester.getRect(
      find.descendant(of: _sheet, matching: find.byType(Material)).at(1),
    );
    expect(sheet.bottom, 844);
    await _frames(tester, 3);
  });

  testWidgets('the originals on Now Playing are hidden while the sheet is up', (
    tester,
  ) async {
    await _openFromNowPlaying(tester);
    final hosts = find
        .byType(FlightPieceHost)
        .evaluate()
        .map((e) => e.widget as FlightPieceHost);
    expect(hosts.length, 4);
    for (final h in hosts) {
      expect(h.source.hidden.value, isTrue);
    }
    final hiddenOpacity = find.descendant(
      of: find.byType(FlightPieceHost).first,
      matching: find.byType(Opacity),
    );
    expect(tester.widget<Opacity>(hiddenOpacity.first).opacity, 0);
    await tester.binding.handlePopRoute();
    await tester.pump();
    await _frames(tester);
    for (final h in hosts) {
      expect(h.source.hidden.value, isFalse);
    }
    expect(tester.widget<Opacity>(hiddenOpacity.first).opacity, 1);
    await _frames(tester, 3);
  });

  testWidgets('mid-flight the cover is between its two places', (tester) async {
    final host = await pumpWithPlayer(
      tester,
      const Text('home'),
      routes: _routes,
      size: const Size(390, 844),
    );
    host.router!.push('/now-playing');
    await tester.pump();
    await _frames(tester, 5);
    await host.letStreamsArrive(tester);
    final big = tester.getRect(
      find
          .descendant(
            of: find.byType(FlightPieceHost).first,
            matching: find.byType(SizedBox),
          )
          .first,
    );
    await tester.tap(find.byTooltip('Queue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    final mid = tester.getRect(find.byType(StripCover));
    expect(mid.width, lessThan(big.width));
    expect(mid.width, greaterThan(72));
    await _frames(tester);
    expect(tester.getRect(find.byType(StripCover)).width, 72);
  });

  testWidgets('Back closes the sheet first, then Now Playing', (tester) async {
    final host = await _openFromNowPlaying(tester);
    await tester.binding.handlePopRoute();
    await tester.pump();
    await _frames(tester);
    expect(_sheet, findsNothing);
    expect(find.byType(MobileNowPlaying), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump();
    await _frames(tester);
    expect(find.byType(MobileNowPlaying), findsNothing);
    expect(
      host.router!.routerDelegate.currentConfiguration.last.matchedLocation,
      '/',
    );
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Back collapses the open selection panel, then closes the sheet, '
      'the selection kept', (tester) async {
    final host = await _openFromNowPlaying(tester);
    final selection = host.container.read(librarySelectionProvider.notifier);
    selection.toggle(host.h.tracks[1]);
    await tester.pump();
    selection.setExpanded(true);
    await tester.pump();
    await _frames(tester);
    expect(host.container.read(librarySelectionProvider).expanded, isTrue);
    expect(find.byType(SelectionPanel), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump();
    await _frames(tester);
    expect(_sheet, findsOneWidget);
    expect(host.container.read(librarySelectionProvider).expanded, isFalse);

    await tester.binding.handlePopRoute();
    await tester.pump();
    await _frames(tester);
    expect(_sheet, findsNothing);
    expect(find.byType(MobileNowPlaying), findsOneWidget);
    expect(host.container.read(librarySelectionProvider).ids, [
      host.h.tracks[1],
    ]);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('the chevron closes the sheet', (tester) async {
    await _openFromNowPlaying(tester);
    await tester.tap(find.byTooltip('Minimise').last);
    await tester.pump();
    await _frames(tester);
    expect(_sheet, findsNothing);
    expect(find.byType(MobileNowPlaying), findsOneWidget);
    await _frames(tester, 3);
  });

  testWidgets('a tap on the strip cover closes the sheet', (tester) async {
    await _openFromNowPlaying(tester);
    await tester.tap(find.byType(StripCover));
    await tester.pump();
    await _frames(tester);
    expect(_sheet, findsNothing);
    await _frames(tester, 3);
  });

  testWidgets('a tap on the strip title closes the sheet', (tester) async {
    await _openFromNowPlaying(tester);
    await tester.tap(find.byType(StripText), warnIfMissed: false);
    await tester.pump();
    await _frames(tester);
    expect(_sheet, findsNothing);
    await _frames(tester, 3);
  });

  testWidgets('a tap on the empty strip (the scrim) closes the sheet', (
    tester,
  ) async {
    await _openFromNowPlaying(tester);
    await tester.tapAt(const Offset(200, 8));
    await tester.pump();
    await _frames(tester);
    expect(_sheet, findsNothing);
    await _frames(tester, 3);
  });

  Future<void> pullHead(WidgetTester tester, double dy) async {
    final grip = tester.getCenter(find.byType(Material).last);
    final head = tester.getCenter(find.text('Queue').last);
    final g = await tester.startGesture(Offset(head.dx, head.dy));
    await g.moveBy(Offset(0, dy));
    await tester.pump();
    await g.up();
    await tester.pump();
    await _frames(tester, 10);
    // keep the unused variable honest
    expect(grip, isNotNull);
  }

  testWidgets('a 99 dp pull on the head returns to open', (tester) async {
    await _openFromNowPlaying(tester);
    await pullHead(tester, 99);
    expect(_sheet, findsOneWidget);
    expect(tester.getRect(find.byType(StripCover)).width, closeTo(72, 0.01));
    await _frames(tester, 3);
  });

  testWidgets('a 101 dp pull on the head closes the sheet', (tester) async {
    await _openFromNowPlaying(tester);
    await pullHead(tester, 101);
    expect(_sheet, findsNothing);
    expect(find.byType(MobileNowPlaying), findsOneWidget);
    await _frames(tester, 3);
  });

  testWidgets('the sheet keeps its height with a single entry', (tester) async {
    final host = await pumpWithPlayer(
      tester,
      const Text('home'),
      routes: _routes,
      size: const Size(390, 844),
      play: false,
    );
    await host.run(
      tester,
      () => host.h.c.playTracks([host.h.tracks.first], context: ctx),
    );
    final context = tester.element(find.text('home'));
    showQueueSheet(context, from: FlightSource());
    await tester.pump();
    await _frames(tester);
    await host.letStreamsArrive(tester);
    expect(find.byType(QueueRow), findsOneWidget);
    // The head is right under the strip, the footer buttons at the bottom.
    expect(tester.getTopLeft(find.text('Queue').last).dy, lessThan(200));
    expect(
      tester.getBottomLeft(find.byIcon(KIcons.shuffle)).dy,
      greaterThan(760),
    );
    await _frames(tester, 3);
  });

  testWidgets('scrolling the list does not move the sheet', (tester) async {
    await _openFromNowPlaying(tester);
    final before = tester.getTopLeft(find.text('Queue').last);
    await tester.drag(find.byType(QueueRow).first, const Offset(0, 200));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getTopLeft(find.text('Queue').last), before);
    await _frames(tester, 3);
  });

  testWidgets('removing the only entry closes the sheet and the page', (
    tester,
  ) async {
    final host = await pumpWithPlayer(
      tester,
      const Text('home'),
      routes: _routes,
      size: const Size(390, 844),
      play: false,
    );
    await host.run(
      tester,
      () => host.h.c.playTracks([host.h.tracks.first], context: ctx),
    );
    host.router!.push('/now-playing');
    await tester.pump();
    await _frames(tester, 5);
    await host.letStreamsArrive(tester);
    await tester.tap(find.byTooltip('Queue'));
    await tester.pump();
    await _frames(tester);
    await host.letStreamsArrive(tester);
    final row = tester.widget<QueueRow>(find.byType(QueueRow).first);
    await host.run(tester, () async => row.onRemove());
    await host.letStreamsArrive(tester);
    await _frames(tester);
    expect(_sheet, findsNothing);
    expect(find.byType(MobileNowPlaying), findsNothing);
    expect(
      host.router!.routerDelegate.currentConfiguration.last.matchedLocation,
      '/',
    );
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a source that is not on screen makes the pieces fade in', (
    tester,
  ) async {
    final host = await pumpWithPlayer(
      tester,
      const Text('home'),
      routes: _routes,
      size: const Size(390, 844),
    );
    // A source whose keys are mounted nowhere.
    final orphan = FlightSource();
    addTearDown(orphan.dispose);
    final context = tester.element(find.text('home'));
    showQueueSheet(context, from: orphan);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final opacities = find.descendant(
      of: find.byType(KSharedFlight),
      matching: find.byType(Opacity),
    );
    expect(tester.widget<Opacity>(opacities.first).opacity, lessThan(1));
    await _frames(tester);
    expect(tester.widget<Opacity>(opacities.first).opacity, 1);
    expect(host, isNotNull);
    await _frames(tester, 3);
  });

  testWidgets(
    'a long press on the mini player opens the sheet on that screen',
    (tester) async {
      final source = FlightSource();
      addTearDown(source.dispose);
      late BuildContext screen;
      final host = await pumpWithPlayer(
        tester,
        Builder(
          builder: (context) {
            screen = context;
            return Align(
              alignment: Alignment.bottomCenter,
              child: MiniPlayer(
                flight: source,
                onOpen: () {},
                onOpenQueue: () => showQueueSheet(context, from: source),
              ),
            );
          },
        ),
        size: const Size(390, 844),
      );
      final g = await tester.startGesture(tester.getCenter(find.text('T0')));
      await tester.pump(const Duration(milliseconds: 600));
      await g.up();
      await tester.pump();
      await _frames(tester);
      expect(_sheet, findsOneWidget);
      expect(find.byType(MobileNowPlaying), findsNothing);
      // Its originals are hidden; Back flies the pieces home.
      expect(source.hidden.value, isTrue);
      await tester.binding.handlePopRoute();
      await tester.pump();
      await _frames(tester);
      expect(_sheet, findsNothing);
      expect(source.hidden.value, isFalse);
      expect(screen.mounted, isTrue);
      expect(host, isNotNull);
      await _frames(tester, 3);
    },
  );

  testWidgets('reduced motion: the sheet does not slide', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final host = await pumpWithPlayer(
      tester,
      const Text('home'),
      routes: _routes,
      size: const Size(390, 844),
    );
    host.router!.push('/now-playing');
    await tester.pump();
    await _frames(tester, 5);
    await host.letStreamsArrive(tester);
    await tester.tap(find.byTooltip('Queue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // The sheet is at its final place at once (the route animation is
    // instant too); it never slides up from the bottom.
    final top = tester.getTopLeft(find.byType(QueueRow).first).dy;
    await _frames(tester);
    expect(tester.getTopLeft(find.byType(QueueRow).first).dy, top);
  });
}
