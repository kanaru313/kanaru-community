import 'package:flutter/semantics.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/playback/ui/track_cover.dart';
import 'package:kanaru/src/playback/domain/play_intent.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/ui/mini_player.dart';
import 'package:kanaru/src/playback/ui/mini_player_body.dart';
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
    expect(find.byType(KProgressLine), findsNothing);
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
      expect(find.byType(KProgressLine), findsOneWidget);
      expect(tester.getSize(find.byType(KProgressLine)).height, 2);
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
}
