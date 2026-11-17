import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/playback/ui/track_cover.dart';
import 'package:kanaru/src/playback/domain/audio_engine.dart';
import 'package:kanaru/src/playback/domain/play_intent.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/ui/mini_player.dart';
import 'package:kanaru/src/playback/ui/mini_player_body.dart';
import 'package:kanaru/src/playback/ui/mini_seek_band.dart';
import 'package:kanaru/src/playback/ui/play_pause_button.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/ui_host.dart';
import '../../support/icon_button_finders.dart';

Widget _player(List<String> events) => Align(
  alignment: Alignment.bottomCenter,
  child: MiniPlayer(
    onOpen: () => events.add('open'),
    onOpenQueue: () => events.add('queue'),
  ),
);

void main() {
  testWidgets('shows nothing without a current track', (tester) async {
    await pumpWithPlayer(tester, _player([]), play: false);
    expect(find.byType(MiniSeekBand), findsNothing);
    expect(find.byType(PlayPauseButton), findsNothing);
  });

  for (final (name, brightness, scale) in [
    ('light', Brightness.light, 1.0),
    ('dark', Brightness.dark, 1.0),
    ('text 150%', Brightness.light, 1.5),
  ]) {
    testWidgets('shows title, controls and progress ($name)', (tester) async {
      await pumpWithPlayer(
        tester,
        _player([]),
        brightness: brightness,
        textScale: scale,
      );
      expect(find.text('T0'), findsOneWidget);
      expect(find.byType(PlayPauseButton), findsOneWidget);
      expect(find.byType(MiniSeekBand), findsOneWidget);
      expect(byIconButton('Next'), findsOneWidget);
    });
  }

  testWidgets('Play is a large glyph and Next a medium one, no 48 dp boxes', (
    tester,
  ) async {
    await pumpWithPlayer(tester, _player([]));
    final play = tester.widget<KIconButton>(byIconButton('Pause'));
    final next = tester.widget<KIconButton>(byIconButton('Next'));
    expect(play.size, KIconSize.lg);
    expect(next.size, KIconSize.md);
    expect(
      tester.getSize(byIconButton('Pause')),
      const Size(KIconSize.lg + 16, KIconSize.lg),
    );
    expect(
      tester.getSize(byIconButton('Next')),
      const Size(KIconSize.md + 16, KIconSize.md),
    );
  });

  for (final scale in [1.5, 2.0]) {
    testWidgets('title uses the song row size and fits at text scale $scale', (
      tester,
    ) async {
      await pumpWithPlayer(tester, _player([]), textScale: scale);
      final title = tester.widget<Text>(find.text('T0'));
      expect(title.style?.fontSize, KMediaCardMetrics.titleSize);
      expect(title.style?.fontWeight, FontWeight.w600);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('placeholder seed of a track with an album is its album key', (
    tester,
  ) async {
    final host = await pumpWithPlayer(tester, _player([]), play: false);
    await host.run(tester, () async {
      await host.h.db
          .update(host.h.db.tracks)
          .write(
            const TracksCompanion(
              albumArtistKey: Value('artist'),
              albumTitleKey: Value('album'),
            ),
          );
      await host.h.play();
    });
    await host.letStreamsArrive(tester);
    final cover = tester.widget<TrackCover>(find.byType(TrackCover));
    expect(cover.seed, AlbumKey('artist', 'album').encode());
  });

  Finder card() => find.byWidgetPredicate(
    (w) => w is SizedBox && w.height == MiniPlayer.height,
  );

  testWidgets('card is 72 dp high with a 56 dp cover of the row radius', (
    tester,
  ) async {
    await pumpWithPlayer(tester, _player([]));
    expect(MiniPlayer.height, 72);
    expect(tester.getSize(card()).height, 72);
    final cover = tester.widget<TrackCover>(find.byType(TrackCover));
    expect(cover.dimension, KMediaCard.coverSize);
    expect(cover.radius, KMediaCard.coverRadius);
  });

  for (final scale in [1.5, 2.0, 3.0]) {
    testWidgets('title and artist stay in a 72 dp card at text scale $scale', (
      tester,
    ) async {
      final host = await pumpWithPlayer(
        tester,
        _player([]),
        play: false,
        textScale: scale,
      );
      await host.run(tester, () async {
        await host.h.db.customStatement(
          "UPDATE tracks SET artist = 'Art' WHERE title = 'T0'",
        );
        await host.h.play();
      });
      await host.letStreamsArrive(tester);
      expect(tester.takeException(), isNull);
      expect(tester.getSize(card()).height, 72);
      final cardRect = tester.getRect(card());
      expect(
        tester.getRect(find.text('T0')).top,
        greaterThanOrEqualTo(cardRect.top),
      );
      expect(
        tester.getRect(find.text('Art')).bottom,
        lessThanOrEqualTo(cardRect.bottom),
      );
      final shown = MediaQuery.textScalerOf(tester.element(find.text('T0')));
      expect(
        shown.scale(100) / 100,
        lessThanOrEqualTo(
          MiniPlayerBody.maxTextScale(MiniPlayer.height) + 1e-9,
        ),
      );
    });
  }

  testWidgets('tap on the gap between the text and Pause opens Now Playing', (
    tester,
  ) async {
    final events = <String>[];
    await pumpWithPlayer(tester, _player(events));
    final pause = tester.getTopLeft(byIconButton('Pause'));
    await tester.tapAt(Offset(pause.dx - 6, pause.dy + 10));
    await tester.pump();
    expect(events, ['open']);
  });

  testWidgets('tapping Pause only pauses, it does not open Now Playing', (
    tester,
  ) async {
    final events = <String>[];
    final host = await pumpWithPlayer(tester, _player(events));
    await host.tap(tester, byIconButton('Pause'));
    expect(events, isEmpty);
    expect(host.h.c.intent, PlayIntent.paused);
  });

  testWidgets('holding Pause leaves the card untouched', (tester) async {
    final events = <String>[];
    await pumpWithPlayer(tester, _player(events));
    final gesture = await tester.startGesture(
      tester.getCenter(byIconButton('Pause')),
    );
    await tester.pump(const Duration(milliseconds: 100));
    final scale = tester.widget<AnimatedScale>(
      find.descendant(
        of: find.byType(KPressable),
        matching: find.byType(AnimatedScale),
      ),
    );
    expect(scale.scale, 1);
    await tester.pump(const Duration(milliseconds: 700));
    await gesture.up();
    await tester.pump();
    expect(events, isEmpty);
  });

  testWidgets(
    'a tap with a second finger opens Now Playing while Pause is held',
    (tester) async {
      final events = <String>[];
      final host = await pumpWithPlayer(tester, _player(events));
      final first = await tester.startGesture(
        tester.getCenter(byIconButton('Pause')),
      );
      final second = await tester.startGesture(
        tester.getCenter(find.text('T0')),
        pointer: 2,
      );
      await tester.pump(const Duration(milliseconds: 100));
      await second.up();
      await tester.pump();
      expect(events, ['open']);
      // Releasing Pause starts controller (database) work that needs real
      // time: release in the real zone, as UiHost.tap does.
      await host.run(tester, first.up);
      await tester.pump(const Duration(milliseconds: 700));
      expect(events, ['open']);
    },
  );

  testWidgets('holding the card with a second finger opens the queue once, '
      'from that finger only', (tester) async {
    final events = <String>[];
    final host = await pumpWithPlayer(tester, _player(events));
    final first = await tester.startGesture(
      tester.getCenter(byIconButton('Pause')),
    );
    // Finger 1 alone for longer than the long-press time: no queue.
    await tester.pump(const Duration(milliseconds: 700));
    expect(events, isEmpty);
    final second = await tester.startGesture(
      tester.getCenter(find.text('T0')),
      pointer: 2,
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(events, isEmpty);
    await tester.pump(const Duration(milliseconds: 200));
    expect(events, ['queue']);
    await second.up();
    // Releasing Pause starts controller (database) work that needs real
    // time: release in the real zone, as UiHost.tap does.
    await host.run(tester, first.up);
    await tester.pump(const Duration(milliseconds: 700));
    expect(events, ['queue']);
  });

  testWidgets('tap opens Now Playing', (tester) async {
    final events = <String>[];
    await pumpWithPlayer(tester, _player(events));
    await tester.tapAt(tester.getCenter(find.text('T0')));
    await tester.pump();
    expect(events, ['open']);
  });

  testWidgets('swipe up more than 30 dp opens, less does not', (tester) async {
    final events = <String>[];
    await pumpWithPlayer(tester, _player(events));
    await tester.dragFrom(
      tester.getCenter(find.text('T0')),
      const Offset(0, -20),
    );
    await tester.pump();
    expect(events, isEmpty);
    await tester.dragFrom(
      tester.getCenter(find.text('T0')),
      const Offset(0, -80),
    );
    await tester.pump();
    expect(events, ['open']);
  });

  testWidgets('Enter opens when focused', (tester) async {
    final events = <String>[];
    await pumpWithPlayer(tester, _player(events));
    // The card is the first focusable thing; Tab reaches it.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(events, ['open']);
  });

  testWidgets(
    'long press 500 ms opens the queue with a haptic, not Now Playing',
    (tester) async {
      final events = <String>[];
      final haptics = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpWithPlayer(tester, _player(events));
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('T0')),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(events, isEmpty);
      await tester.pump(const Duration(milliseconds: 150));
      expect(events, ['queue']);
      expect(haptics, isNotEmpty);
      await gesture.up();
      await tester.pump();
      expect(events, ['queue']);
    },
  );

  testWidgets('a 10 dp move cancels the long press', (tester) async {
    final events = <String>[];
    await pumpWithPlayer(tester, _player(events));
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('T0')),
    );
    await gesture.moveBy(const Offset(0, 12));
    await tester.pump(const Duration(milliseconds: 700));
    expect(events, isNot(contains('queue')));
    await gesture.up();
    await tester.pump();
  });

  testWidgets('Play/Pause toggles the player', (tester) async {
    final host = await pumpWithPlayer(tester, _player([]));
    expect(host.h.c.intent, PlayIntent.playing); // playTracks started it
    await host.tap(tester, byIconButton('Pause'));
    expect(host.h.c.intent, PlayIntent.paused);
    expect(byIconButton('Play'), findsOneWidget);
    await host.tap(tester, byIconButton('Play'));
    expect(host.h.c.intent, PlayIntent.playing);
    expect(byIconButton('Pause'), findsOneWidget);
  });

  testWidgets('Next moves to the second track', (tester) async {
    final host = await pumpWithPlayer(tester, _player([]));
    await host.tap(tester, byIconButton('Next'));
    expect(host.h.c.queueState.currentItem?.trackId, host.h.tracks[1]);
    expect(find.text('T1'), findsOneWidget);
  });

  testWidgets('holding Play does not open the queue', (tester) async {
    final events = <String>[];
    await pumpWithPlayer(tester, _player(events));
    final gesture = await tester.startGesture(
      tester.getCenter(byIconButton('Pause')),
    );
    await tester.pump(const Duration(milliseconds: 700));
    await gesture.up();
    await tester.pump();
    expect(events, isNot(contains('queue')));
  });

  testWidgets('semantics offer open and queue as actions', (tester) async {
    final events = <String>[];
    final handle = tester.ensureSemantics();
    await pumpWithPlayer(tester, _player(events));
    final data = tester
        .getSemantics(
          find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.label == 'Player',
          ),
        )
        .getSemanticsData();
    final labels = [
      for (final id in data.customSemanticsActionIds!)
        CustomSemanticsAction.getAction(id)!.label,
    ];
    expect(labels, containsAll(['Open Now Playing', 'Queue']));
    handle.dispose();
  });

  group('drags on the card', () {
    const total = Duration(seconds: 200);

    Future<void> loaded(WidgetTester tester, UiHost host) async {
      await host.run(
        tester,
        () async => host.h.engine.emit(EngineLoaded(host.h.loadedToken, total)),
      );
      await host.letStreamsArrive(tester);
    }

    Rect band(WidgetTester tester) => tester.getRect(find.byType(MiniSeekBand));

    Future<Duration> position(WidgetTester tester, UiHost host) async =>
        (await tester.runAsync(() => host.h.c.position.first))!.position;

    bool sought(UiHost host) =>
        host.h.engine.commands.any((c) => c.startsWith('seek:'));

    testWidgets('a horizontal drag on the body opens nothing', (tester) async {
      final events = <String>[];
      final host = await pumpWithPlayer(tester, _player(events));
      final g = await tester.startGesture(tester.getCenter(find.text('T0')));
      await g.moveBy(const Offset(12, 0));
      await tester.pump();
      await g.up();
      await tester.pump();
      expect(events, isEmpty, reason: 'the arena is won, the tap is not');
      expect(host.h.c.queueState.current, 0);
    });

    testWidgets('a 6 dp wobble is still a tap', (tester) async {
      final events = <String>[];
      await pumpWithPlayer(tester, _player(events));
      final g = await tester.startGesture(tester.getCenter(find.text('T0')));
      await g.moveBy(const Offset(6, 0));
      await g.up();
      await tester.pump();
      expect(events, ['open']);
    });

    testWidgets('a drag in the band seeks by where it ends', (tester) async {
      final events = <String>[];
      final host = await pumpWithPlayer(tester, _player(events));
      await loaded(tester, host);
      final b = band(tester);
      final g = await tester.startGesture(Offset(b.left + 96, b.center.dy));
      await g.moveBy(const Offset(60, 0));
      await host.run(tester, g.up);
      final fraction = 156 / b.width;
      expect(
        (await position(tester, host)).inMilliseconds,
        closeTo(total.inMilliseconds * fraction, total.inMilliseconds * 0.01),
      );
      expect(events, isEmpty);
    });

    testWidgets('a vertical drag that starts in the band still seeks', (
      tester,
    ) async {
      final events = <String>[];
      final host = await pumpWithPlayer(tester, _player(events));
      await loaded(tester, host);
      final b = band(tester);
      final g = await tester.startGesture(Offset(b.left + 192, b.center.dy));
      await g.moveBy(const Offset(0, -40));
      await host.run(tester, g.up);
      expect(
        (await position(tester, host)).inMilliseconds,
        closeTo(total.inMilliseconds / 2, total.inMilliseconds * 0.01),
      );
      expect(events, isEmpty, reason: 'not a swipe up');
    });

    testWidgets('a tap on the band opens Now Playing and does not seek', (
      tester,
    ) async {
      final events = <String>[];
      final host = await pumpWithPlayer(tester, _player(events));
      await loaded(tester, host);
      final b = band(tester);
      await tester.tapAt(Offset(b.left + 300, b.center.dy));
      await tester.pump();
      expect(events, ['open']);
      expect(sought(host), isFalse);
    });

    testWidgets('a track that cannot seek: a band drag moves the card', (
      tester,
    ) async {
      final events = <String>[];
      final host = await pumpWithPlayer(tester, _player(events));
      final b = band(tester);
      final g = await tester.startGesture(Offset(b.left + 96, b.center.dy));
      await g.moveBy(const Offset(0, -50));
      await g.up();
      await tester.pump();
      expect(events, ['open'], reason: 'a swipe up, as anywhere on the card');
      expect(sought(host), isFalse);
    });

    testWidgets('the track changing mid-drag drops the seek', (tester) async {
      final host = await pumpWithPlayer(tester, _player([]));
      await loaded(tester, host);
      final b = band(tester);
      final g = await tester.startGesture(Offset(b.left + 96, b.center.dy));
      await g.moveBy(const Offset(60, 0));
      await host.run(tester, host.h.c.next);
      await host.run(tester, g.up);
      expect(sought(host), isFalse);
    });

    testWidgets('a cancelled band drag does not seek', (tester) async {
      final host = await pumpWithPlayer(tester, _player([]));
      await loaded(tester, host);
      final b = band(tester);
      final g = await tester.startGesture(Offset(b.left + 96, b.center.dy));
      await g.moveBy(const Offset(60, 0));
      await host.run(tester, g.cancel);
      expect(sought(host), isFalse);
    });

    testWidgets('a drag that starts on Pause does not seek', (tester) async {
      final events = <String>[];
      final host = await pumpWithPlayer(tester, _player(events));
      await loaded(tester, host);
      final g = await tester.startGesture(
        tester.getCenter(byIconButton('Pause')),
      );
      await g.moveBy(const Offset(-60, 0));
      await host.run(tester, g.up);
      expect(sought(host), isFalse);
      expect(events, isEmpty);
    });

    testWidgets('holding in the band opens the queue', (tester) async {
      final events = <String>[];
      final host = await pumpWithPlayer(tester, _player(events));
      await loaded(tester, host);
      final b = band(tester);
      final g = await tester.startGesture(Offset(b.left + 96, b.center.dy));
      await tester.pump(const Duration(milliseconds: 600));
      expect(events, ['queue']);
      await g.up();
      await tester.pump();
      expect(events, ['queue']);
      expect(sought(host), isFalse);
    });

    testWidgets('a touch in the system gesture inset is not taken, a mouse '
        'is', (tester) async {
      final events = <String>[];
      await pumpWithPlayer(
        tester,
        Align(
          alignment: Alignment.bottomCenter,
          child: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(systemGestureInsets: const EdgeInsets.only(left: 30)),
              child: MiniPlayer(
                onOpen: () => events.add('open'),
                onOpenQueue: () => events.add('queue'),
              ),
            ),
          ),
        ),
      );
      final card = tester.getRect(find.byType(MiniPlayer));
      final start = Offset(card.left + 12, card.center.dy - 8);
      // The touch is declined: its upward drag is no swipe up.
      final touch = await tester.startGesture(start);
      await touch.moveBy(const Offset(0, -60));
      await touch.up();
      await tester.pump();
      expect(events, isEmpty);
      // The same place with a mouse is an ordinary swipe up.
      final mouse = await tester.startGesture(
        start,
        kind: PointerDeviceKind.mouse,
      );
      await mouse.moveBy(const Offset(0, -60));
      await mouse.up();
      await tester.pump();
      expect(events, ['open']);
    });

    testWidgets('semantics: increase seeks 5 s on the band slider', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final host = await pumpWithPlayer(tester, _player([]));
      await loaded(tester, host);
      await host.run(
        tester,
        () async => tester.semantics.increase(
          find.semantics.byLabel('Playback position'),
        ),
      );
      expect(await position(tester, host), const Duration(seconds: 5));
      handle.dispose();
    });
  });
}
