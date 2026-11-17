import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../support/host.dart';

const _total = Duration(seconds: 100);

Widget _bar({
  Duration position = const Duration(seconds: 20),
  Duration? duration = _total,
  Object? track,
  required List<Duration> seeks,
  List<String>? events,
}) => SizedBox(
  width: 200,
  child: KSeekBar(
    position: position,
    duration: duration,
    track: track,
    onSeek: seeks.add,
    onSeekStart: () => events?.add('start'),
    onSeekEnd: () => events?.add('end'),
    semanticLabel: 'Position',
    semanticValue: '0:20 of 1:40',
  ),
);

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('renders in $name', (tester) async {
      await tester.pumpWidget(
        host(
          Center(child: _bar(seeks: [])),
          brightness: brightness,
          textScale: scale,
        ),
      );
      expect(find.byType(KSeekBar), findsOneWidget);
      expect(tester.getSize(find.byType(KSeekBar)).height, KSeekBar.hitHeight);
    });
  }

  testWidgets('tap seeks to the tapped fraction', (tester) async {
    final seeks = <Duration>[];
    final events = <String>[];
    await tester.pumpWidget(
      host(
        Center(
          child: _bar(seeks: seeks, events: events),
        ),
      ),
    );
    final box = tester.getRect(find.byType(KSeekBar));
    await tester.tapAt(Offset(box.left + 150, box.center.dy));
    expect(seeks, [const Duration(seconds: 75)]);
    expect(events, ['start', 'end']);
  });

  testWidgets('drag follows the finger and seeks once on release', (
    tester,
  ) async {
    final seeks = <Duration>[];
    final events = <String>[];
    await tester.pumpWidget(
      host(
        Center(
          child: _bar(seeks: seeks, events: events),
        ),
      ),
    );
    final box = tester.getRect(find.byType(KSeekBar));
    final gesture = await tester.startGesture(
      Offset(box.left + 40, box.center.dy),
    );
    await gesture.moveBy(const Offset(60, 0));
    await tester.pump();
    expect(seeks, isEmpty);
    expect(events, ['start']);
    await gesture.up();
    await tester.pump();
    expect(seeks, hasLength(1));
    expect(seeks.single.inSeconds, inInclusiveRange(48, 52));
    expect(events, ['start', 'end']);
  });

  testWidgets('a drag that outlives its track does not seek the next one', (
    tester,
  ) async {
    final seeks = <Duration>[];
    final events = <String>[];
    await tester.pumpWidget(
      host(
        Center(
          child: _bar(track: 1, seeks: seeks, events: events),
        ),
      ),
    );
    final box = tester.getRect(find.byType(KSeekBar));
    final drag = await tester.startGesture(
      Offset(box.left + 40, box.center.dy),
    );
    await drag.moveBy(const Offset(60, 0));
    await tester.pump();
    // Track changes mid-drag (even with a known duration on the new track).
    await tester.pumpWidget(
      host(
        Center(
          child: _bar(
            track: 2,
            position: Duration.zero,
            duration: const Duration(seconds: 200),
            seeks: seeks,
            events: events,
          ),
        ),
      ),
    );
    await drag.moveBy(const Offset(40, 0));
    await drag.up();
    await tester.pump();
    expect(seeks, isEmpty);
    expect(events, ['start', 'end']);

    // The bar is not stuck: the next drag on the new track seeks.
    final again = await tester.startGesture(
      Offset(box.left + 50, box.center.dy),
    );
    await again.moveBy(const Offset(50, 0));
    await again.up();
    await tester.pump();
    expect(seeks, [const Duration(seconds: 100)]);
  });

  testWidgets('arrow keys step 5 s and clamp at both ends', (tester) async {
    final seeks = <Duration>[];
    await tester.pumpWidget(
      host(
        Center(
          child: _bar(position: const Duration(seconds: 3), seeks: seeks),
        ),
      ),
    );
    await tester.tap(find.byType(KSeekBar));
    await tester.pump();
    seeks.clear();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(seeks, [const Duration(seconds: 8), Duration.zero]);
  });

  testWidgets('without a duration it ignores input and shows no thumb', (
    tester,
  ) async {
    final seeks = <Duration>[];
    await tester.pumpWidget(
      host(Center(child: _bar(duration: null, seeks: seeks))),
    );
    await tester.tap(find.byType(KSeekBar));
    await tester.pump();
    expect(seeks, isEmpty);
  });

  testWidgets('semantics: slider with label, value and actions', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final seeks = <Duration>[];
    await tester.pumpWidget(host(Center(child: _bar(seeks: seeks))));
    final node = tester.getSemantics(find.byType(KSeekBar));
    expect(node.label, 'Position');
    expect(node.value, '0:20 of 1:40');
    tester.semantics.increase(find.semantics.byLabel('Position'));
    expect(seeks, [const Duration(seconds: 25)]);
    handle.dispose();
  });

  testWidgets('hover grows the track', (tester) async {
    await tester.pumpWidget(host(Center(child: _bar(seeks: []))));
    double trackHeight() => tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .first
        .constraints!
        .maxHeight;
    expect(trackHeight(), KSeekBar.trackHeight);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.byType(KSeekBar)));
    await tester.pump(const Duration(milliseconds: 200));
    expect(trackHeight(), KSeekBar.trackHeightActive);
  });

  group('KSeekGestureArea options', () {
    /// A bare area, 200 dp wide and 16 high, that records the state it draws.
    Widget area({
      Duration? duration = _total,
      required List<Duration> seeks,
      required List<KSeekState> states,
      bool seekOnTap = true,
      bool anyDirection = false,
    }) => Center(
      child: SizedBox(
        width: 200,
        child: KSeekGestureArea(
          position: const Duration(seconds: 20),
          duration: duration,
          height: 16,
          seekOnTap: seekOnTap,
          anyDirection: anyDirection,
          semanticLabel: 'Position',
          semanticValue: '0:20 of 1:40',
          onSeek: seeks.add,
          builder: (context, state) {
            states.add(state);
            return const SizedBox.expand();
          },
        ),
      ),
    );

    testWidgets('seekOnTap false: a tap falls to the ancestor', (tester) async {
      final seeks = <Duration>[];
      var taps = 0;
      await tester.pumpWidget(
        host(
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => taps++,
            child: area(seeks: seeks, states: [], seekOnTap: false),
          ),
        ),
      );
      await tester.tap(find.byType(KSeekGestureArea));
      await tester.pump();
      expect(seeks, isEmpty);
      expect(taps, 1);
    });

    testWidgets('anyDirection: a vertical drag seeks by x on release', (
      tester,
    ) async {
      final seeks = <Duration>[];
      await tester.pumpWidget(
        host(area(seeks: seeks, states: [], anyDirection: true)),
      );
      final box = tester.getRect(find.byType(KSeekGestureArea));
      final gesture = await tester.startGesture(
        Offset(box.left + 40, box.center.dy),
      );
      await gesture.moveBy(const Offset(0, -30));
      await gesture.moveBy(const Offset(20, 0));
      expect(seeks, isEmpty);
      await gesture.up();
      expect(seeks, [const Duration(seconds: 30)]);
    });

    testWidgets('anyDirection: the lock distance is the touch slop', (
      tester,
    ) async {
      final seeks = <Duration>[];
      await tester.pumpWidget(
        host(
          MediaQuery(
            data: const MediaQueryData(
              gestureSettings: DeviceGestureSettings(touchSlop: 8),
            ),
            child: area(seeks: seeks, states: [], anyDirection: true),
          ),
        ),
      );
      final box = tester.getRect(find.byType(KSeekGestureArea));
      final gesture = await tester.startGesture(
        Offset(box.left + 40, box.center.dy),
      );
      await gesture.moveBy(const Offset(0, 10));
      await tester.pump();
      await gesture.up();
      expect(seeks, hasLength(1), reason: '10 dp is past an 8 dp slop');
    });

    testWidgets('anyDirection without a duration leaves the drag to the '
        'ancestor', (tester) async {
      final seeks = <Duration>[];
      var ancestorDrags = 0;
      await tester.pumpWidget(
        host(
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanUpdate: (_) => ancestorDrags++,
            child: area(
              duration: null,
              seeks: seeks,
              states: [],
              anyDirection: true,
            ),
          ),
        ),
      );
      final box = tester.getRect(find.byType(KSeekGestureArea));
      final gesture = await tester.startGesture(
        Offset(box.left + 40, box.center.dy),
      );
      await gesture.moveBy(const Offset(0, -40));
      await gesture.up();
      expect(ancestorDrags, greaterThan(0));
      expect(seeks, isEmpty);
    });

    for (final anyDirection in [false, true]) {
      testWidgets('a cancelled touch after the drag started never seeks '
          '(anyDirection $anyDirection)', (tester) async {
        final seeks = <Duration>[];
        final events = <String>[];
        await tester.pumpWidget(
          host(
            Center(
              child: SizedBox(
                width: 200,
                child: KSeekGestureArea(
                  position: Duration.zero,
                  duration: _total,
                  height: 16,
                  anyDirection: anyDirection,
                  onSeek: seeks.add,
                  onSeekEnd: () => events.add('end'),
                  builder: (context, state) => const SizedBox.expand(),
                ),
              ),
            ),
          ),
        );
        final box = tester.getRect(find.byType(KSeekGestureArea));
        final gesture = await tester.startGesture(
          Offset(box.left + 40, box.center.dy),
        );
        await gesture.moveBy(const Offset(60, 0));
        await gesture.cancel();
        await tester.pump();
        expect(seeks, isEmpty);
        expect(events, ['end'], reason: 'the drag is over');
      });
    }

    testWidgets('dragging is true only while dragging', (tester) async {
      final states = <KSeekState>[];
      await tester.pumpWidget(host(area(seeks: [], states: states)));
      expect(states.last.dragging, isFalse);
      final box = tester.getRect(find.byType(KSeekGestureArea));
      final gesture = await tester.startGesture(
        Offset(box.left + 40, box.center.dy),
      );
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();
      expect(states.last.dragging, isTrue);
      expect(states.last.active, isTrue);
      await gesture.up();
      await tester.pump();
      expect(states.last.dragging, isFalse);
    });

    testWidgets('a hover is active but not dragging', (tester) async {
      final states = <KSeekState>[];
      await tester.pumpWidget(host(area(seeks: [], states: states)));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(
        location: tester.getCenter(find.byType(KSeekGestureArea)),
      );
      await tester.pump();
      expect(states.last.active, isTrue);
      expect(states.last.dragging, isFalse);
    });

    testWidgets('the slider is disabled without a duration', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(area(duration: null, seeks: [], states: [])),
      );
      expect(
        tester.getSemantics(find.byType(KSeekGestureArea)),
        isSemantics(isSlider: true, hasEnabledState: true, isEnabled: false),
      );
      await tester.pumpWidget(host(area(seeks: [], states: [])));
      expect(
        tester.getSemantics(find.byType(KSeekGestureArea)),
        isSemantics(
          isSlider: true,
          hasEnabledState: true,
          isEnabled: true,
          hasIncreaseAction: true,
          hasDecreaseAction: true,
        ),
      );
      handle.dispose();
    });
  });
}
