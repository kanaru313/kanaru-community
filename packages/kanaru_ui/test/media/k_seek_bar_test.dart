import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:kanaru_ui/src/widgets/media/flat_effects_painter.dart';
import 'package:kanaru_ui/src/widgets/media/flat_geometry.dart';

import '../support/host.dart';
import '../support/paint_probe.dart';

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

  group('default flat look', () {
    FlatSeekPainter painter(WidgetTester tester) => tester
        .widgetList<CustomPaint>(
          find.descendant(
            of: find.byType(KSeekBar),
            matching: find.byType(CustomPaint),
          ),
        )
        .map((c) => c.painter)
        .whereType<FlatSeekPainter>()
        .single;

    testWidgets('hover grows the track', (tester) async {
      await tester.pumpWidget(host(Center(child: _bar(seeks: []))));
      expect(painter(tester).thickness, KSeekBar.trackHeight);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: tester.getCenter(find.byType(KSeekBar)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(painter(tester).thickness, KSeekBar.trackHeightActive);
    });

    testWidgets('the bar keeps the default look and never schedules a frame', (
      tester,
    ) async {
      await tester.pumpWidget(host(Center(child: _bar(seeks: []))));
      await tester.pump(const Duration(milliseconds: 200));
      expect(painter(tester).look, const KFlatLook());
      expect(painter(tester).clock, isNull);
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('the played part slides over 120 ms, the thumb jumps', (
      tester,
    ) async {
      Widget at(int seconds) => host(
        Center(
          child: _bar(
            seeks: [],
            position: Duration(seconds: seconds),
          ),
        ),
      );
      await tester.pumpWidget(at(20));
      await tester.pumpWidget(at(60));
      await tester.pump();
      expect(painter(tester).progress, closeTo(0.6, 1e-9));
      await tester.pump(const Duration(milliseconds: 60));
      final mid = painter(tester).playedProgress!;
      expect(mid, inExclusiveRange(0.2, 0.6));
      await tester.pump(const Duration(milliseconds: 100));
      expect(painter(tester).playedProgress, closeTo(0.6, 1e-9));
      expect(tester.binding.transientCallbackCount, 0);
    });

    test('geometry: 4 dp track, played part, 4 x 16 thumb kept inside', () {
      const size = Size(200, 24);
      final g = FlatGeometry(size: size, progress: 0.2, thickness: 4);
      expect(g.track, const Rect.fromLTWH(0, 10, 200, 4));
      expect(g.played, const Rect.fromLTWH(0, 10, 40, 4));
      expect(g.barX, 40);
      expect(
        FlatGeometry(size: size, progress: 0, thickness: 4).barX,
        2,
        reason: 'the thumb never leaves the track',
      );
      expect(FlatGeometry(size: size, progress: 1, thickness: 4).barX, 198);
      // Active: 6 dp, same centre line.
      expect(
        FlatGeometry(size: size, progress: 0.2, thickness: 6).track,
        const Rect.fromLTWH(0, 9, 200, 6),
      );
    });

    testWidgets('pixels: 4 dp track at 24 %, played, 4 x 16 thumb', (
      tester,
    ) async {
      final probe = await PaintProbe.of(
        tester,
        FlatSeekPainter(
          progress: 0.2,
          thickness: 4,
          look: const KFlatLook(),
          primary: const Color(0xFF3355CC),
          tertiary: const Color(0xFFCC5533),
          surface: const Color(0xFFFFFFFF),
          showThumb: true,
          cache: FlatPaintCache(),
        ),
        const Size(200, 24),
      );
      expect(probe.alpha(150, 12), closeTo(0.24 * 255, 2));
      expect(probe.alpha(150, 9), 0);
      expect(probe.alpha(150, 14), 0);
      expect(probe.alpha(20, 10), 255);
      expect(probe.alpha(20, 9), 0);
      expect(probe.alpha(40, 5), 255, reason: 'thumb top, 16 tall');
      expect(probe.alpha(40, 3), 0);
      expect(probe.alpha(37, 4), 0);
    });
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
