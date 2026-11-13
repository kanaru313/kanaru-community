import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/play_intent.dart';
import 'package:kanaru/src/playback/ui/queue/queue_list.dart';
import 'package:kanaru/src/playback/ui/queue/queue_row.dart';
import 'package:kanaru/src/playback/ui/queue/queue_row_hooks.dart';
import 'package:kanaru/src/playback/ui/queue/queue_swipe_remove.dart';
import 'package:kanaru/src/shell/ui/playback_notice_listener.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/controller_harness.dart' show ctx;
import '../../support/ui_host.dart';
import 'queue_test_support.dart';

/// Drags [finder] sideways by [fraction] of its width and lets go.
Future<void> _swipe(
  WidgetTester tester,
  Finder finder,
  double fraction, {
  PointerDeviceKind kind = PointerDeviceKind.touch,
}) async {
  final width = tester.getSize(find.byType(QueueSwipeRemove).first).width;
  final g = await tester.startGesture(tester.getCenter(finder), kind: kind);
  await g.moveBy(Offset(width * fraction / 2, 0));
  await g.moveBy(Offset(width * fraction / 2, 0));
  await tester.pump();
  await g.up();
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget _swipeRow(
  List<String> events, {
  bool removes = true,
  bool throws = false,
}) => QueueSwipeRemove(
  onRemove: () async {
    events.add('removed');
    if (throws) throw StateError('the chain failed');
    return removes;
  },
  child: const SizedBox(height: 60, child: Center(child: Text('row'))),
);

/// Runs the remove action of the row showing [title], as a swipe would.
Future<void> _removeRow(WidgetTester tester, UiHost host, String title) async {
  final row = tester.widget<QueueRow>(
    find.ancestor(of: find.text(title), matching: find.byType(QueueRow)),
  );
  await host.run(tester, () async => row.onRemove());
  await host.letStreamsArrive(tester);
}

void main() {
  group('swipe', () {
    testWidgets('39 % bounces back, 41 % removes', (tester) async {
      final events = <String>[];
      await pumpFakeQueue(tester, _swipeRow(events), view: fakeView(1));
      await _swipe(tester, find.text('row'), 0.39);
      expect(events, isEmpty);
      expect(tester.getTopLeft(find.text('row')).dx, closeTo(180, 40));
      await _swipe(tester, find.text('row'), 0.41);
      expect(events, ['removed']);
    });

    testWidgets('a short swipe leaves no delete icon behind', (tester) async {
      final events = <String>[];
      await pumpFakeQueue(tester, _swipeRow(events), view: fakeView(1));
      await _swipe(tester, find.text('row'), 0.2);
      await tester.pumpAndSettle();
      expect(events, isEmpty);
      expect(find.byIcon(KIcons.delete), findsNothing);
    });

    testWidgets('both directions remove', (tester) async {
      final events = <String>[];
      await pumpFakeQueue(tester, _swipeRow(events), view: fakeView(1));
      await _swipe(tester, find.text('row'), -0.6);
      expect(events, ['removed']);
    });

    testWidgets('the row fades and a red delete icon shows, no red fill', (
      tester,
    ) async {
      await pumpFakeQueue(tester, _swipeRow([]), view: fakeView(1));
      final g = await tester.startGesture(tester.getCenter(find.text('row')));
      await g.moveBy(const Offset(120, 0));
      await tester.pump();
      final fade = tester.widget<Opacity>(
        find.ancestor(of: find.text('row'), matching: find.byType(Opacity)),
      );
      expect(fade.opacity, lessThan(1));
      final icon = tester.widget<Icon>(find.byIcon(KIcons.delete));
      expect(
        icon.color,
        Theme.of(tester.element(find.text('row'))).colorScheme.error,
      );
      final filled = find.descendant(
        of: find.byType(QueueSwipeRemove),
        matching: find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color.a > 0,
        ),
      );
      expect(filled, findsNothing);
      await g.cancel();
    });

    testWidgets('the icon grows past the threshold', (tester) async {
      await pumpFakeQueue(tester, _swipeRow([]), view: fakeView(1));
      final g = await tester.startGesture(tester.getCenter(find.text('row')));
      await g.moveBy(const Offset(100, 0));
      await tester.pump(const Duration(milliseconds: 300));
      double scale() =>
          tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;
      expect(scale(), 1);
      await g.moveBy(const Offset(100, 0));
      await tester.pump(const Duration(milliseconds: 300));
      expect(scale(), greaterThan(1));
      await g.cancel();
    });

    testWidgets('comes back when nothing was removed', (tester) async {
      final events = <String>[];
      await pumpFakeQueue(
        tester,
        _swipeRow(events, removes: false),
        view: fakeView(1),
      );
      await _swipe(tester, find.text('row'), 0.6);
      await tester.pump(const Duration(seconds: 1));
      expect(events, ['removed']);
      expect(tester.getTopLeft(find.text('row')).dx, closeTo(180, 40));
    });

    testWidgets('comes back, and takes drags again, when the removal fails', (
      tester,
    ) async {
      final events = <String>[];
      await pumpFakeQueue(
        tester,
        _swipeRow(events, throws: true),
        view: fakeView(1),
      );
      await _swipe(tester, find.text('row'), 0.6);
      await tester.pump(const Duration(seconds: 1));
      // The failure is reported, not thrown into the zone.
      expect(tester.takeException(), isA<StateError>());
      expect(events, ['removed']);
      expect(tester.getTopLeft(find.text('row')).dx, closeTo(180, 40));
      // Not stuck: a second swipe reaches the callback again.
      await _swipe(tester, find.text('row'), 0.6);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isA<StateError>());
      expect(events, ['removed', 'removed']);
    });

    testWidgets('a trackpad pan is ignored', (tester) async {
      final events = <String>[];
      await pumpFakeQueue(tester, _swipeRow(events), view: fakeView(1));
      await _swipe(
        tester,
        find.text('row'),
        0.8,
        kind: PointerDeviceKind.trackpad,
      );
      expect(events, isEmpty);
    });

    testWidgets('a mouse drag removes (desktop)', (tester) async {
      final events = <String>[];
      await pumpFakeQueue(tester, _swipeRow(events), view: fakeView(1));
      await _swipe(
        tester,
        find.text('row'),
        0.6,
        kind: PointerDeviceKind.mouse,
      );
      expect(events, ['removed']);
    });
  });

  group('removing from the list', () {
    const list = QueueList(size: QueueRowSize.mobile);

    testWidgets('shows the toast and Undo restores order', (tester) async {
      final host = await pumpWithPlayer(tester, list);
      final before = [for (final i in host.h.c.queueState.items) i.entryId];
      await _removeRow(tester, host, 'T2');
      expect(host.h.c.queueState.length, 5);
      expect(find.text('Removed “T2”'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      await host.tap(tester, find.text('Undo'));
      final after = [for (final i in host.h.c.queueState.items) i.entryId];
      expect(after, before);
    });

    testWidgets('a mouse swipe starting on the ♥ removes a desktop row', (
      tester,
    ) async {
      final host = await pumpWithPlayer(
        tester,
        QueueList(
          size: QueueRowSize.desktop,
          menu: (context, item, info, at, {viaKeyboard = false}) {},
          favorite: (context, item) =>
              IconButton(onPressed: () {}, icon: const Icon(KIcons.heart)),
        ),
        size: const Size(1280, 800),
      );
      await tester.runAsync(() async {
        await _swipe(
          tester,
          find.descendant(
            of: find.byType(QueueRow).at(2),
            matching: find.byIcon(KIcons.heart),
          ),
          0.6,
          kind: PointerDeviceKind.mouse,
        );
        await host.h.settle();
      });
      await tester.pump();
      await host.letStreamsArrive(tester);
      expect(host.h.c.queueState.length, 5);
      expect(find.text('Removed “T2”'), findsOneWidget);
    });

    testWidgets(
      'swiping a real row removes it, from the title, the ⋮ or the ♥',
      (tester) async {
        final host = await pumpWithPlayer(
          tester,
          QueueList(
            size: QueueRowSize.mobile,
            menu: (context, item, info, at, {viaKeyboard = false}) {},
            favorite: (context, item) =>
                IconButton(onPressed: () {}, icon: const Icon(KIcons.heart)),
          ),
        );
        // The swipe starts controller work: run it in the real zone.
        Future<void> swipe(Finder f) async {
          await tester.runAsync(() async {
            await _swipe(tester, f, 0.6);
            await host.h.settle();
          });
          await tester.pump();
          await host.letStreamsArrive(tester);
        }

        await swipe(find.text('T2'));
        expect(host.h.c.queueState.length, 5);
        expect(find.text('Removed “T2”'), findsOneWidget);
        final more = find.descendant(
          of: find.byType(QueueRow).at(2),
          matching: find.byIcon(KIcons.moreVert),
        );
        await swipe(more);
        expect(host.h.c.queueState.length, 4);
        // A swipe that starts on the ♥ removes as well.
        await swipe(
          find.descendant(
            of: find.byType(QueueRow).at(2),
            matching: find.byIcon(KIcons.heart),
          ),
        );
        expect(host.h.c.queueState.length, 3);
      },
    );

    testWidgets('Undo inside the 4 s window brings the row back', (
      tester,
    ) async {
      final host = await pumpWithPlayer(tester, list);
      final before = [for (final i in host.h.c.queueState.items) i.entryId];
      await _removeRow(tester, host, 'T2');
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Undo'), findsOneWidget);
      await host.tap(tester, find.text('Undo'));
      expect([for (final i in host.h.c.queueState.items) i.entryId], before);
    });

    testWidgets('left alone, the toast and its Undo go after 5 s', (
      tester,
    ) async {
      final host = await pumpWithPlayer(tester, list);
      await _removeRow(tester, host, 'T3');
      expect(find.text('Undo'), findsOneWidget);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      // The exit animation needs one more frame after the timer fired.
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SnackBar), findsNothing);
      expect(find.text('Undo'), findsNothing);
      expect(host.h.c.queueState.length, 5);
    });

    testWidgets('removing the current row while paused stays paused', (
      tester,
    ) async {
      final host = await pumpWithPlayer(tester, list);
      await host.run(tester, host.h.c.pause);
      await _removeRow(tester, host, 'T0');
      expect(host.h.c.intent, PlayIntent.paused);
      expect(host.h.c.queueState.currentItem, isNotNull);
      expect(host.h.c.queueState.length, 5);
    });

    testWidgets('removing the only row calls onEmptied', (tester) async {
      var emptied = 0;
      final host = await pumpWithPlayer(
        tester,
        QueueList(size: QueueRowSize.mobile, onEmptied: () => emptied++),
        play: false,
      );
      await host.run(
        tester,
        () => host.h.c.playTracks([host.h.tracks.first], context: ctx),
      );
      await host.letStreamsArrive(tester);
      await _removeRow(tester, host, 'T0');
      expect(emptied, 1);
      expect(host.h.c.queueState.length, 0);
      expect(host.h.c.intent, PlayIntent.stopped);
    });

    testWidgets('undo after the queue advanced keeps the new current', (
      tester,
    ) async {
      final host = await pumpWithPlayer(tester, list);
      await _removeRow(tester, host, 'T4');
      await host.run(tester, host.h.c.next);
      final now = host.h.c.queueState.currentItem!.entryId;
      await tester.pump(const Duration(milliseconds: 500));
      await host.tap(tester, find.text('Undo'));
      expect(host.h.c.queueState.length, 6);
      expect(host.h.c.queueState.currentItem!.entryId, now);
    });

    testWidgets('with the notice listener mounted there is still one toast', (
      tester,
    ) async {
      final host = await pumpWithPlayer(
        tester,
        const PlaybackNoticeListener(child: list),
      );
      await tester.pump();
      await _removeRow(tester, host, 'T3');
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Removed “T3”'), findsOneWidget);
      expect(host.h.notices, isEmpty);
    });

    testWidgets('the removal raises one toast and no player notice', (
      tester,
    ) async {
      final host = await pumpWithPlayer(tester, list);
      await _removeRow(tester, host, 'T3');
      expect(find.byType(SnackBar), findsOneWidget);
      expect(host.h.notices, isEmpty);
    });
  });
}
