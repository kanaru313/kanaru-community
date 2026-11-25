import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_card.dart';
import 'package:kanaru/src/media/domain/cover_colors.dart';
import 'package:kanaru/src/media/domain/track_info.dart';
import 'package:kanaru/src/playback/domain/audio_engine.dart';
import 'package:kanaru/src/playback/domain/repeat_mode.dart';
import 'package:kanaru/src/playback/state/playing_cover_colors.dart';
import 'package:kanaru/src/playback/state/playback_settings_providers.dart';
import 'package:kanaru/src/playback/state/track_info_providers.dart';
import 'package:kanaru/src/playback/ui/flight_source.dart';
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

/// What the page shows for the playing track, whatever its id. [shape]
/// can change mid-test; invalidate [trackInfoProvider] to show the new one.
/// A null result is a track without info (its row is gone). [stream], when
/// set, replaces the shape (a read still loading, or one that failed).
class _SwitchableInfo {
  TrackInfo? Function(TrackInfo base) shape = _full;
  Stream<TrackInfo?> Function()? stream;

  Override get override => trackInfoProvider.overrideWith(
    (ref, id) =>
        stream?.call() ??
        Stream.value(
          shape(
            TrackInfo(
              id: id,
              title: 'Song',
              status: TrackAvailability.present,
              relPath: 'song.flac',
            ),
          ),
        ),
  );
}

final _longTitle = '${'A very long song title ' * 4}end';
final _longArtist = '${'Artist ' * 20}end';

/// A full tag set with a 200-character album.
TrackInfo _full(TrackInfo b) => TrackInfo(
  id: b.id,
  title: _longTitle,
  status: b.status,
  relPath: b.relPath,
  artist: _longArtist,
  album: 'A' * 200,
  format: 'FLAC',
  sampleRate: 44100,
  bitrate: 900,
  playCount: 12,
);

/// Info without artist, album or format.
TrackInfo _bare(TrackInfo b) => b;

/// Only an artist.
TrackInfo _artistOnly(TrackInfo b) => TrackInfo(
  id: b.id,
  title: b.title,
  status: b.status,
  relPath: b.relPath,
  artist: 'Art',
);

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
      expect(tester.getSize(find.byType(NowPlayingSeekSlot)).height, 56);
      expect(
        tester.getSize(find.byType(NowPlayingButtonRow)).height,
        nowPlayingButtonRowHeight,
      );
      expect(tester.getSize(find.byType(PlayPauseButton)).width, 72);
      expect(tester.getSize(find.byType(NowPlayingHeader)).height, 56);
    });
  }

  group('nothing moves between songs', () {
    Map<String, Offset> positions(WidgetTester tester) {
      Offset at(Finder f) => tester.getTopLeft(f.first);
      return {
        'cover': at(find.byType(CoverSwiper)),
        'seek': at(find.byType(NowPlayingSeekSlot)),
        'controls': at(find.byType(PlayPauseButton)),
        'buttons': at(find.byType(NowPlayingButtonRow)),
        'lyrics card': at(find.byType(LyricsCard)),
        'info card': at(find.byType(TrackInfoCard)),
        'info card end': tester.getBottomLeft(find.byType(TrackInfoCard)),
      };
    }

    for (final scale in [1.0, 2.0]) {
      testWidgets('tags, missing parts and unknown info at text ×$scale', (
        tester,
      ) async {
        final info = _SwitchableInfo();
        final host = await _open(
          tester,
          textScale: scale,
          overrides: [info.override],
        );
        expect(tester.takeException(), isNull);
        final full = positions(tester);
        final album = find.descendant(
          of: find.byType(TrackInfoCard),
          matching: find.textContaining('A' * 200),
        );
        expect(album, findsOneWidget);
        // Each is one ellipsized line, not a block wrapped and clipped.
        for (final long in [
          find.text(_longTitle),
          find.text(_longArtist),
          album,
        ]) {
          expect(
            tester.renderObject<RenderParagraph>(long.first).didExceedMaxLines,
            isTrue,
          );
        }
        final cases = <String, TrackInfo? Function(TrackInfo)>{
          'no info (track row gone)': (_) => null,
          'no artist, album or format': _bare,
          'artist only': _artistOnly,
          'full tags again': _full,
        };
        for (final MapEntry(key: name, value: shape) in cases.entries) {
          info.shape = shape;
          host.container.invalidate(trackInfoProvider);
          await tester.pump();
          await host.letStreamsArrive(tester);
          expect(tester.takeException(), isNull, reason: name);
          // The new shape is on screen, not the first one.
          expect(album, shape == _full ? findsOneWidget : findsNothing);
          expect(positions(tester), full, reason: name);
        }
        expect(tester.getSize(find.byType(NowPlayingSeekSlot)).height, 56);
      });
    }
  });

  group('the info card skeleton', () {
    final cases = <String, (Stream<TrackInfo?> Function(), bool)>{
      // Never emits: the read is still running.
      'while the info loads': (() => Stream<TrackInfo?>.multi((_) {}), true),
      // An Error is not retried, so no retry timer outlives the test.
      'when reading the info failed': (
        () => Stream<TrackInfo?>.error(StateError('read failed')),
        false,
      ),
      'when the track has no info': (() => Stream.value(null), false),
    };
    for (final MapEntry(key: name, value: (stream, skeleton))
        in cases.entries) {
      testWidgets('${skeleton ? 'shows' : 'does not show'} skeleton $name, '
          'at the height of a loaded card', (tester) async {
        final info = _SwitchableInfo()..stream = stream;
        final host = await _open(tester, overrides: [info.override]);
        final skeletons = find.descendant(
          of: find.byType(TrackInfoCard),
          matching: find.byType(KSkeletonLine),
        );
        expect(skeletons, skeleton ? findsNWidgets(2) : findsNothing);
        final height = tester.getSize(find.byType(TrackInfoCard)).height;
        expect(tester.takeException(), isNull);
        info.stream = null;
        host.container.invalidate(trackInfoProvider);
        await tester.pump();
        await host.letStreamsArrive(tester);
        expect(skeletons, findsNothing);
        expect(
          find.descendant(
            of: find.byType(TrackInfoCard),
            matching: find.textContaining('A' * 200),
          ),
          findsOneWidget,
        );
        expect(tester.getSize(find.byType(TrackInfoCard)).height, height);
      });
    }
  });

  group('the queue flight text starts on the title', () {
    Rect flightText(WidgetTester tester) => tester
        .widget<MobileNowPlaying>(find.byType(MobileNowPlaying))
        .flight
        .rectOf(FlightPiece.text)!;

    testWidgets('a song without an artist: the title line only', (
      tester,
    ) async {
      final info = _SwitchableInfo()..shape = _bare;
      await _open(tester, overrides: [info.override]);
      final title = tester.getRect(find.text('Song'));
      final rect = flightText(tester);
      // The flying text centres the title alone in this rect, so its y at
      // t = 0 is the page title's y.
      expect(rect.top, closeTo(title.top, 0.5));
      expect(rect.center.dy, closeTo(title.center.dy, 0.5));
      expect(
        rect.right,
        lessThanOrEqualTo(tester.getTopLeft(find.byType(FavoriteButton)).dx),
      );
    });

    testWidgets('a song with an artist: title and artist lines', (
      tester,
    ) async {
      final info = _SwitchableInfo()..shape = _artistOnly;
      await _open(tester, overrides: [info.override]);
      final title = tester.getRect(find.text('Song'));
      final artist = tester.getRect(
        // The info card below shows it too.
        find.text('Art').first,
      );
      final rect = flightText(tester);
      expect(rect.top, closeTo(title.top, 0.5));
      expect(rect.bottom, closeTo(artist.bottom, 0.5));
    });
  });

  testWidgets('the heart hides while the queue flies the text, then shows', (
    tester,
  ) async {
    await _open(tester);
    double heartOpacity() => tester
        .widget<Opacity>(
          find
              .ancestor(
                of: find.descendant(
                  of: find.byType(MobileNowPlaying),
                  matching: find.byType(FavoriteButton),
                ),
                matching: find.byType(Opacity),
              )
              .first,
        )
        .opacity;
    expect(heartOpacity(), 1);
    final row = find.byType(NowPlayingButtonRow);
    await tester.tap(
      find.descendant(of: row, matching: find.byIcon(KIcons.queueMusic)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      tester
          .widget<MobileNowPlaying>(find.byType(MobileNowPlaying))
          .flight
          .hidden
          .value,
      isTrue,
    );
    expect(heartOpacity(), 0);
    await tester.binding.handlePopRoute();
    // The sheet flies the pieces home, then its route is disposed.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(MobileNowPlaying), findsOneWidget);
    expect(heartOpacity(), 1);
  });

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
