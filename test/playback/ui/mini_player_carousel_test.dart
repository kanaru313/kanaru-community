import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/playback_notice.dart';
import 'package:kanaru/src/playback/domain/repeat_mode.dart';
import 'package:kanaru/src/playback/ui/flight_source.dart';
import 'package:kanaru/src/playback/ui/mini_carousel_math.dart';
import 'package:kanaru/src/playback/ui/mini_player.dart';
import 'package:kanaru/src/playback/ui/mini_player_carousel.dart';
import 'package:kanaru/src/playback/ui/track_cover.dart';

import '../support/ui_host.dart';

Widget _player(
  List<String> events, {
  FlightSource? flight,
  bool reduce = false,
}) {
  final player = Align(
    alignment: Alignment.bottomCenter,
    child: MiniPlayer(
      flight: flight,
      onOpen: () => events.add('open'),
      onOpenQueue: () => events.add('queue'),
    ),
  );
  if (!reduce) return player;
  return Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: player,
    ),
  );
}

/// The queue position of the current entry, read from the controller.
int? _current(UiHost host) => host.h.c.queueState.current;

double _width(WidgetTester tester) =>
    tester.getSize(find.byType(MiniPlayerCarousel)).width;

Offset _grab(WidgetTester tester) =>
    tester.getCenter(find.byType(MiniPlayerCarousel));

/// Lets the slide and the controller finish.
Future<void> _settle(WidgetTester tester, UiHost host) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await host.letStreamsArrive(tester);
  await tester.pump(const Duration(seconds: 1));
  await host.letStreamsArrive(tester);
}

/// A drag of [dx] over [ms] in [steps] moves, released in the real zone so
/// the command it starts can finish.
Future<void> _swipe(
  WidgetTester tester,
  UiHost host,
  double dx, {
  int ms = 400,
  int steps = 8,
}) async {
  final g = await tester.startGesture(_grab(tester));
  for (var i = 1; i <= steps; i++) {
    await g.moveBy(
      Offset(dx / steps, 0),
      timeStamp: Duration(milliseconds: ms * i ~/ steps),
    );
  }
  await host.run(tester, () => g.up(timeStamp: Duration(milliseconds: ms + 1)));
  await _settle(tester, host);
}

void main() {
  group('rubberBand', () {
    test('zero stays zero and the sign follows the drag', () {
      expect(miniRubberBand(0), 0);
      expect(miniRubberBand(50), greaterThan(0));
      expect(miniRubberBand(-50), -miniRubberBand(50));
    });

    test('grows, but tends to 40', () {
      var last = 0.0;
      for (final d in <double>[10, 40, 120, 400, 2000]) {
        final v = miniRubberBand(d);
        expect(v, greaterThan(last));
        expect(v, lessThanOrEqualTo(miniCarouselResist));
        last = v;
      }
      expect(miniRubberBand(2000), closeTo(40, 0.01));
    });
  });

  group('threshold', () {
    const w = 300.0;
    final cases = <(String, double, double, bool)>[
      ('slow, a third and a bit', -101, 0, true),
      ('slow, short of a third', -99, 0, false),
      ('fast fling the same way', -30, -0.6, true),
      ('fast but not enough', -30, -0.4, false),
      ('fast fling the other way', -30, 0.9, false),
      ('right, a third', 120, 0, true),
    ];
    for (final (name, dx, vx, commits) in cases) {
      test(name, () => expect(miniCarouselCommits(dx, vx, w), commits));
    }
  });

  group('swipes', () {
    testWidgets('left past a third goes to the next entry', (tester) async {
      final host = await pumpWithPlayer(tester, _player([]));
      await _swipe(tester, host, -_width(tester) * 0.4);
      expect(_current(host), 1);
      expect(find.text('T1'), findsOneWidget);
      expect(find.text('T0'), findsNothing);
    });

    testWidgets('left short of a third and slow springs back', (tester) async {
      final host = await pumpWithPlayer(tester, _player([]));
      await _swipe(tester, host, -_width(tester) * 0.2);
      expect(_current(host), 0);
      expect(find.text('T0'), findsOneWidget);
    });

    testWidgets('a fast fling over a short distance changes track', (
      tester,
    ) async {
      final host = await pumpWithPlayer(tester, _player([]));
      await _swipe(tester, host, -30, ms: 24, steps: 3);
      expect(_current(host), 1);
    });

    testWidgets('right goes to the previous entry', (tester) async {
      final host = await pumpWithPlayer(tester, _player([]));
      await host.run(tester, host.h.c.next);
      await host.letStreamsArrive(tester);
      await _swipe(tester, host, _width(tester) * 0.4);
      expect(_current(host), 0);
    });

    testWidgets('the neighbour peeks in while dragging', (tester) async {
      final host = await pumpWithPlayer(tester, _player([]));
      final area = tester.getRect(find.byType(MiniPlayerCarousel));
      final g = await tester.startGesture(_grab(tester));
      await g.moveBy(Offset(-area.width * 0.5, 0));
      await tester.pump();
      // The neighbour's title comes from the database.
      await host.letStreamsArrive(tester);
      expect(find.text('T0'), findsOneWidget);
      expect(
        tester.getRect(find.text('T1')).left,
        lessThan(area.right),
        reason: 'T1 is coming in from the right',
      );
      await g.moveBy(Offset(area.width * 1.0, 0));
      await tester.pump();
      expect(
        tester.getRect(find.text('T1')).left,
        greaterThanOrEqualTo(area.right),
        reason: 'nothing before the first: it only stretches',
      );
      await host.run(tester, g.up);
      await _settle(tester, host);
      expect(_current(host), 0);
    });

    testWidgets('the last entry, left: stays, says the queue ended', (
      tester,
    ) async {
      final host = await pumpWithPlayer(tester, _player([]));
      await host.run(
        tester,
        () => host.h.c.playEntry(host.h.c.queueState.items.last.entryId),
      );
      await host.letStreamsArrive(tester);
      await _swipe(tester, host, -_width(tester) * 0.4);
      expect(_current(host), 5);
      expect(host.h.notices.whereType<QueueEnd>(), hasLength(1));
    });

    testWidgets('the first entry, right: restarts it and says so', (
      tester,
    ) async {
      final host = await pumpWithPlayer(tester, _player([]));
      await _swipe(tester, host, _width(tester) * 0.4);
      expect(_current(host), 0);
      expect(host.h.notices.whereType<FirstTrack>(), hasLength(1));
      expect(host.h.engine.commands.last, startsWith('seek:0'));
    });

    testWidgets('the first entry, a short wobble right: springs back, no '
        'command', (tester) async {
      final host = await pumpWithPlayer(tester, _player([]));
      await _swipe(tester, host, _width(tester) * 0.2);
      expect(_current(host), 0);
      expect(host.h.notices, isEmpty);
      expect(
        host.h.engine.commands.where((c) => c.startsWith('seek:0')),
        isEmpty,
      );
    });

    testWidgets('the first entry, a short fast fling right: restarts it', (
      tester,
    ) async {
      final host = await pumpWithPlayer(tester, _player([]));
      await _swipe(tester, host, _width(tester) * 0.2, ms: 40, steps: 4);
      expect(host.h.notices.whereType<FirstTrack>(), hasLength(1));
    });

    testWidgets('the last entry, a short wobble left: no notice', (
      tester,
    ) async {
      final host = await pumpWithPlayer(tester, _player([]));
      await host.run(
        tester,
        () => host.h.c.playEntry(host.h.c.queueState.items.last.entryId),
      );
      await host.letStreamsArrive(tester);
      await _swipe(tester, host, -_width(tester) * 0.2);
      expect(_current(host), 5);
      expect(host.h.notices, isEmpty);
    });

    testWidgets('towards a missing neighbour the entry changing under the '
        'finger runs no command', (tester) async {
      final host = await pumpWithPlayer(tester, _player([]));
      final g = await tester.startGesture(_grab(tester));
      await g.moveBy(Offset(_width(tester) * 0.2, 0));
      await g.moveBy(Offset(_width(tester) * 0.2, 0));
      await host.run(tester, host.h.c.next);
      await host.letStreamsArrive(tester);
      await host.run(tester, g.up);
      await _settle(tester, host);
      expect(_current(host), 1, reason: 'no Previous on the new entry');
      expect(host.h.notices, isEmpty);
    });

    testWidgets('repeat all: left at the last goes to the first, right at '
        'the first goes to the last', (tester) async {
      final host = await pumpWithPlayer(tester, _player([]));
      await host.run(tester, () => host.h.c.setRepeat(RepeatMode.all));
      await _swipe(tester, host, _width(tester) * 0.4);
      expect(_current(host), 5);
      expect(host.h.notices, isEmpty);
      await _swipe(tester, host, -_width(tester) * 0.4);
      expect(_current(host), 0);
    });

    testWidgets('repeat all shuffled: left at the last starts a new pass, '
        'the entry coming in is not named yet', (tester) async {
      final host = await pumpWithPlayer(tester, _player([]));
      await host.run(tester, () async {
        await host.h.c.setRepeat(RepeatMode.allShuffled);
        await host.h.c.playEntry(host.h.c.queueState.items.last.entryId);
      });
      await host.letStreamsArrive(tester);
      final lastId = host.h.c.queueState.currentItem!.entryId;
      final area = tester.getRect(find.byType(MiniPlayerCarousel));
      final g = await tester.startGesture(_grab(tester));
      await g.moveBy(Offset(-area.width * 0.4, 0));
      await g.moveBy(Offset(-area.width * 0.1, 0));
      await tester.pump();
      await host.letStreamsArrive(tester);
      // The first entry of the new pass is unknown: only a bare cover peeks
      // in, no title from the old order.
      // Previous (T4), the current entry and a bare cover for the unknown one.
      expect(
        find.descendant(
          of: find.byType(MiniPlayerCarousel),
          matching: find.byType(TrackCover),
        ),
        findsNWidgets(3),
      );
      final shown = host.h.order().last;
      for (var i = 0; i < host.h.tracks.length; i++) {
        final title = find.text('T$i');
        if (title.evaluate().isEmpty || i == shown) continue;
        final rect = tester.getRect(title);
        final inView = rect.right > area.left && rect.left < area.right;
        expect(inView, isFalse, reason: 'T$i is named in view');
      }
      await host.run(tester, g.up);
      await _settle(tester, host);
      expect(_current(host), 0);
      expect(host.h.c.queueState.items.first.entryId, isNot(lastId));
    });

    testWidgets('repeat all shuffled: right at the first restarts it', (
      tester,
    ) async {
      final host = await pumpWithPlayer(tester, _player([]));
      await host.run(tester, () => host.h.c.setRepeat(RepeatMode.allShuffled));
      final order = host.h.order();
      await _swipe(tester, host, _width(tester) * 0.4);
      expect(_current(host), 0);
      expect(host.h.order(), order);
      expect(host.h.notices.whereType<FirstTrack>(), hasLength(1));
    });

    testWidgets('the entry changing under the finger drops the swipe', (
      tester,
    ) async {
      final host = await pumpWithPlayer(tester, _player([]));
      final g = await tester.startGesture(_grab(tester));
      await g.moveBy(Offset(-_width(tester) * 0.2, 0));
      await g.moveBy(Offset(-_width(tester) * 0.2, 0));
      // A headset button moves on while the finger is down.
      await host.run(tester, host.h.c.next);
      await host.letStreamsArrive(tester);
      await host.run(tester, g.up);
      await _settle(tester, host);
      expect(_current(host), 1, reason: 'one step, not two');
    });

    testWidgets('a cancelled drag changes nothing', (tester) async {
      final host = await pumpWithPlayer(tester, _player([]));
      final g = await tester.startGesture(_grab(tester));
      await g.moveBy(Offset(-_width(tester) * 0.5, 0));
      await host.run(tester, g.cancel);
      await _settle(tester, host);
      expect(_current(host), 0);
      expect(find.text('T0'), findsOneWidget);
    });

    testWidgets('while sliding, only the current body hosts flight pieces', (
      tester,
    ) async {
      final flight = FlightSource();
      addTearDown(flight.dispose);
      final host = await pumpWithPlayer(tester, _player([], flight: flight));
      Finder hosts() => find.descendant(
        of: find.byType(MiniPlayerCarousel),
        matching: find.byType(FlightPieceHost),
      );
      expect(hosts(), findsNWidgets(2));
      final g = await tester.startGesture(_grab(tester));
      await g.moveBy(Offset(-_width(tester) * 0.5, 0));
      await tester.pump();
      expect(hosts(), findsNWidgets(2), reason: 'cover and text, no copies');
      expect(tester.takeException(), isNull);
      await host.run(tester, g.up);
      await tester.pump(const Duration(milliseconds: 100));
      expect(hosts(), findsNWidgets(2));
      await _settle(tester, host);
      expect(_current(host), 1);
      expect(flight.rectOf(FlightPiece.cover), isNotNull);
      expect(flight.rectOf(FlightPiece.text), isNotNull);
    });

    testWidgets('with the queue sheet up the card does not move', (
      tester,
    ) async {
      final flight = FlightSource();
      addTearDown(flight.dispose);
      final host = await pumpWithPlayer(tester, _player([], flight: flight));
      flight.setHidden(true);
      await tester.pump();
      await _swipe(tester, host, -_width(tester) * 0.5);
      expect(_current(host), 0);
    });

    testWidgets('reduced motion: the track changes after one pump', (
      tester,
    ) async {
      final host = await pumpWithPlayer(tester, _player([], reduce: true));
      final g = await tester.startGesture(_grab(tester));
      await g.moveBy(Offset(-_width(tester) * 0.5, 0));
      await host.run(tester, g.up);
      await host.letStreamsArrive(tester);
      await tester.pump();
      expect(_current(host), 1);
      expect(find.text('T1'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('leaving the tree in the middle of a slide is clean', (
      tester,
    ) async {
      final host = await pumpWithPlayer(tester, _player([]));
      final g = await tester.startGesture(_grab(tester));
      await g.moveBy(Offset(-_width(tester) * 0.5, 0));
      await host.run(tester, g.up);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
    });
  });
}
