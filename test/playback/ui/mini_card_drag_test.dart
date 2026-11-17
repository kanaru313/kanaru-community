import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/ui/mini_card_drag.dart';

class _Log {
  final events = <String>[];
  Offset? lastEnd;
  Offset? velocity;
}

/// A 200 x 100 box with the recognizer and a tap handler under it, like the
/// card: the tap must lose exactly when the drag locks.
Widget _card(_Log log, {bool Function(PointerDownEvent)? declines}) => Center(
  child: SizedBox(
    width: 200,
    height: 100,
    child: RawGestureDetector(
      gestures: {
        MiniCardDragRecognizer:
            GestureRecognizerFactoryWithHandlers<MiniCardDragRecognizer>(
              () => MiniCardDragRecognizer(declines: declines ?? (_) => false),
              (r) {
                r
                  ..onLock = (l) {
                    log.events.add('lock ${l.name}');
                  }
                  ..onUpdate = (_) {
                    log.events.add('update');
                  }
                  ..onEnd = (total, v) {
                    log.events.add('end');
                    log.lastEnd = total;
                    log.velocity = v;
                  }
                  ..onCancel = () {
                    log.events.add('cancel');
                  };
              },
            ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => log.events.add('tap'),
        child: const SizedBox.expand(),
      ),
    ),
  ),
);

void main() {
  group('lockOf', () {
    final cases = <(Offset, MiniDragLock?)>[
      (Offset.zero, null),
      (const Offset(9, 0), null),
      (const Offset(0, -9.9), null),
      (const Offset(6, 6), null),
      (const Offset(10, 0), MiniDragLock.x),
      (const Offset(-12, 3), MiniDragLock.x),
      (const Offset(0, -10), MiniDragLock.up),
      (const Offset(4, -12), MiniDragLock.up),
      (const Offset(0, 10), MiniDragLock.down),
      (const Offset(-4, 12), MiniDragLock.down),
      // A diagonal that is not wider than tall is vertical.
      (const Offset(8, 8), MiniDragLock.down),
      (const Offset(8, -8), MiniDragLock.up),
    ];
    for (final (d, lock) in cases) {
      test('$d -> $lock', () => expect(lockOf(d), lock));
    }

    test('the slop is a parameter', () {
      expect(lockOf(const Offset(6, 0), slop: 5), MiniDragLock.x);
    });
  });

  testWidgets('a drag past the slop locks, beats the tap and reports the end', (
    tester,
  ) async {
    final log = _Log();
    await tester.pumpWidget(MaterialApp(home: _card(log)));
    final g = await tester.startGesture(
      tester.getCenter(find.byType(SizedBox).last),
    );
    await g.moveBy(const Offset(6, 0));
    expect(log.events, isEmpty, reason: 'under the slop');
    await g.moveBy(const Offset(8, 0));
    expect(log.events, ['lock x', 'update']);
    await g.up();
    expect(log.events, ['lock x', 'update', 'end']);
    expect(log.lastEnd, const Offset(14, 0));
    expect(log.events, isNot(contains('tap')));
  });

  testWidgets('released under the slop it gives up and the tap wins', (
    tester,
  ) async {
    final log = _Log();
    await tester.pumpWidget(MaterialApp(home: _card(log)));
    final g = await tester.startGesture(
      tester.getCenter(find.byType(SizedBox).last),
    );
    await g.moveBy(const Offset(6, 0));
    await g.up();
    expect(log.events, ['tap']);
  });

  testWidgets('a declined pointer is left alone, a drag then is no lock', (
    tester,
  ) async {
    final log = _Log();
    await tester.pumpWidget(
      MaterialApp(home: _card(log, declines: (_) => true)),
    );
    final g = await tester.startGesture(
      tester.getCenter(find.byType(SizedBox).last),
    );
    await g.moveBy(const Offset(40, 0));
    await g.up();
    expect(log.events, isNot(contains('lock x')));
    expect(log.events, isNot(contains('end')));
  });

  testWidgets('a second finger is ignored while the first one is down', (
    tester,
  ) async {
    final log = _Log();
    await tester.pumpWidget(MaterialApp(home: _card(log)));
    final c = tester.getCenter(find.byType(SizedBox).last);
    final first = await tester.startGesture(c);
    final second = await tester.startGesture(
      c + const Offset(20, 0),
      pointer: 2,
    );
    await second.moveBy(const Offset(0, 40));
    await second.up();
    expect(log.events, isEmpty, reason: 'only the first finger counts');
    await first.moveBy(const Offset(0, 30));
    await first.up();
    expect(log.events.where((e) => e.startsWith('lock')), ['lock down']);
    expect(log.lastEnd, const Offset(0, 30));
  });

  testWidgets('a cancel after the lock reports a cancel, not an end', (
    tester,
  ) async {
    final log = _Log();
    await tester.pumpWidget(MaterialApp(home: _card(log)));
    final g = await tester.startGesture(
      tester.getCenter(find.byType(SizedBox).last),
    );
    await g.moveBy(const Offset(0, -30));
    await g.cancel();
    expect(log.events.last, 'cancel');
    expect(log.events, isNot(contains('end')));
  });

  testWidgets('a cancel before the lock is silent', (tester) async {
    final log = _Log();
    await tester.pumpWidget(MaterialApp(home: _card(log)));
    final g = await tester.startGesture(
      tester.getCenter(find.byType(SizedBox).last),
    );
    await g.moveBy(const Offset(3, 0));
    await g.cancel();
    expect(log.events, isEmpty);
  });

  testWidgets('a fast drag reports its release velocity in px per ms', (
    tester,
  ) async {
    final log = _Log();
    await tester.pumpWidget(MaterialApp(home: _card(log)));
    final g = await tester.startGesture(
      tester.getCenter(find.byType(SizedBox).last),
    );
    for (var i = 0; i < 5; i++) {
      await g.moveBy(
        const Offset(-20, 0),
        timeStamp: Duration(milliseconds: 16 * (i + 1)),
      );
    }
    await g.up(timeStamp: const Duration(milliseconds: 90));
    // 20 px per 16 ms = 1.25 px/ms to the left.
    expect(log.velocity!.dx, closeTo(-1.25, 0.2));
    expect(log.velocity!.dy.abs(), lessThan(0.01));
  });

  testWidgets('a new touch after a finished drag starts clean', (tester) async {
    final log = _Log();
    await tester.pumpWidget(MaterialApp(home: _card(log)));
    final c = tester.getCenter(find.byType(SizedBox).last);
    await tester.dragFrom(c, const Offset(30, 0));
    log.events.clear();
    await tester.tapAt(c);
    expect(log.events, ['tap']);
  });
}
