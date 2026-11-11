import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:kanaru/src/playback/domain/play_intent.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/ui/mini_player.dart';
import 'package:kanaru/src/playback/ui/play_pause_button.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/ui_host.dart';

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
      expect(find.byTooltip('Next'), findsOneWidget);
    });
  }

  testWidgets('tap opens Now Playing', (tester) async {
    final events = <String>[];
    await pumpWithPlayer(tester, _player(events));
    await tester.tap(find.text('T0'));
    await tester.pump();
    expect(events, ['open']);
  });

  testWidgets('swipe up more than 30 dp opens, less does not', (tester) async {
    final events = <String>[];
    await pumpWithPlayer(tester, _player(events));
    await tester.drag(find.text('T0'), const Offset(0, -20));
    await tester.pump();
    expect(events, isEmpty);
    await tester.drag(find.text('T0'), const Offset(0, -80));
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
    await host.tap(tester, find.byTooltip('Pause'));
    expect(host.h.c.intent, PlayIntent.paused);
    expect(find.byTooltip('Play'), findsOneWidget);
    await host.tap(tester, find.byTooltip('Play'));
    expect(host.h.c.intent, PlayIntent.playing);
    expect(find.byTooltip('Pause'), findsOneWidget);
  });

  testWidgets('Next moves to the second track', (tester) async {
    final host = await pumpWithPlayer(tester, _player([]));
    await host.tap(tester, find.byTooltip('Next'));
    expect(host.h.c.queueState.currentItem?.trackId, host.h.tracks[1]);
    expect(find.text('T1'), findsOneWidget);
  });

  testWidgets('holding Play does not open the queue', (tester) async {
    final events = <String>[];
    await pumpWithPlayer(tester, _player(events));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byTooltip('Pause')),
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
