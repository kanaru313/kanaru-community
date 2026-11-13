import 'dart:ui' show GestureSettings, PointerDeviceKind;

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:kanaru_ui/src/widgets/k_swipe_actions_strip.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

const _rowKey = ValueKey('row');
const _width = 400.0;

/// The row that moves; its left edge is the swipe offset.
const Widget _row = SizedBox(
  key: _rowKey,
  height: 60,
  child: Center(child: Text('row')),
);

double _dx(WidgetTester tester) => tester.getTopLeft(find.byKey(_rowKey)).dx;

Future<void> _pumpRow(
  WidgetTester tester,
  Widget Function(Widget row) wrap,
) async {
  useWindow(tester, const Size(_width, 800));
  await tester.pumpWidget(host(wrap(_row)));
}

Widget _remove(
  Future<bool> Function() onRemove, {
  bool enabled = true,
  Widget row = _row,
}) => KSwipeActions.remove(
  label: 'Remove',
  onRemove: onRemove,
  enabled: enabled,
  child: row,
);

KSwipeAction _action(String label, List<String> log) => KSwipeAction(
  icon: KIcons.heart,
  label: label,
  onTrigger: () => log.add(label),
);

/// Drags the row by [dx] in two steps and lets go; settles the animation.
Future<void> _swipe(
  WidgetTester tester,
  double dx, {
  PointerDeviceKind kind = PointerDeviceKind.touch,
  double from = _width / 2,
}) async {
  final g = await tester.startGesture(Offset(from, 30), kind: kind);
  await g.moveBy(Offset(dx / 2, 0));
  await g.moveBy(Offset(dx / 2, 0));
  await tester.pump();
  await g.up();
  await tester.pumpAndSettle();
}

void main() {
  group('remove', () {
    testWidgets('50 % springs back, 72 % removes', (tester) async {
      final calls = <String>[];
      await _pumpRow(
        tester,
        (r) => _remove(() async {
          calls.add('removed');
          return true;
        }, row: r),
      );
      await _swipe(tester, _width * 0.5);
      expect(calls, isEmpty);
      expect(_dx(tester), 0);
      expect(find.byIcon(KIcons.delete), findsNothing);
      await _swipe(tester, _width * 0.72);
      expect(calls, ['removed']);
      // Removed: the row stays out until its list drops it.
      expect(_dx(tester), _width);
    });

    testWidgets('a fling at 30 % removes nothing', (tester) async {
      var calls = 0;
      await _pumpRow(
        tester,
        (r) => _remove(() async {
          calls++;
          return true;
        }, row: r),
      );
      await tester.fling(find.byKey(_rowKey), const Offset(120, 0), 4000);
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(_dx(tester), 0);
    });

    testWidgets('travel counts from the pointer-down point', (tester) async {
      var calls = 0;
      await _pumpRow(
        tester,
        (r) => _remove(() async {
          calls++;
          return true;
        }, row: r),
      );
      // Starts mid-row: 70 % of the width is still reachable, row clamped.
      await _swipe(tester, _width * 0.7 + 2, from: 150);
      expect(calls, 1);
    });

    testWidgets('both directions remove', (tester) async {
      var calls = 0;
      await _pumpRow(
        tester,
        (r) => _remove(() async {
          calls++;
          return true;
        }, row: r),
      );
      await _swipe(tester, -_width * 0.8);
      expect(calls, 1);
      expect(_dx(tester), -_width);
    });

    testWidgets('the strip shows a red delete icon and no fill', (
      tester,
    ) async {
      await _pumpRow(tester, (r) => _remove(() async => true, row: r));
      final g = await tester.startGesture(const Offset(200, 30));
      await g.moveBy(const Offset(120, 0));
      await tester.pump();
      final icon = tester.widget<Icon>(find.byIcon(KIcons.delete));
      expect(
        icon.color,
        Theme.of(tester.element(find.byKey(_rowKey))).colorScheme.error,
      );
      expect(
        find.descendant(
          of: find.byType(KSwipeStrip),
          matching: find.byType(ColoredBox),
        ),
        findsNothing,
      );
      await g.cancel();
    });

    for (final (name, removes, throws) in [
      ('false', false, false),
      ('a throw', false, true),
    ]) {
      testWidgets('comes back and takes drags again on $name', (tester) async {
        var calls = 0;
        await _pumpRow(
          tester,
          (r) => _remove(() async {
            calls++;
            if (throws) throw StateError('failed');
            return removes;
          }, row: r),
        );
        await _swipe(tester, _width * 0.8);
        if (throws) expect(tester.takeException(), isA<StateError>());
        expect(calls, 1);
        expect(_dx(tester), 0);
        await _swipe(tester, _width * 0.8);
        if (throws) expect(tester.takeException(), isA<StateError>());
        expect(calls, 2);
      });
    }

    List<String> recordHaptics(WidgetTester tester) {
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
      return haptics;
    }

    testWidgets('ticks once on reaching 70 % on mobile', (tester) async {
      final haptics = recordHaptics(tester);
      await _pumpRow(tester, (r) => _remove(() async => false, row: r));
      final g = await tester.startGesture(const Offset(100, 30));
      await g.moveBy(const Offset(200, 0));
      expect(haptics, isEmpty);
      await g.moveBy(const Offset(100, 0));
      await g.moveBy(const Offset(20, 0));
      expect(haptics, ['HapticFeedbackType.selectionClick']);
      await g.cancel();
    });

    testWidgets('does not tick on desktop', (tester) async {
      final haptics = recordHaptics(tester);
      await _pumpRow(tester, (r) => _remove(() async => false, row: r));
      final g = await tester.startGesture(const Offset(100, 30));
      await g.moveBy(const Offset(320, 0));
      expect(haptics, isEmpty);
      await g.cancel();
    }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
  });

  group('capped', () {
    testWidgets('travel is capped; past the trigger runs the action once', (
      tester,
    ) async {
      final log = <String>[];
      await _pumpRow(
        tester,
        (r) => KSwipeActions.capped(start: _action('fav', log), child: r),
      );
      final g = await tester.startGesture(const Offset(100, 30));
      await g.moveBy(const Offset(160, 0));
      await g.moveBy(const Offset(160, 0));
      await tester.pump();
      // 30 % of 400, below the 140 dp limit.
      expect(_dx(tester), lessThanOrEqualTo(120));
      expect(_dx(tester), greaterThan(80));
      await g.up();
      await tester.pumpAndSettle();
      expect(log, ['fav']);
      expect(_dx(tester), 0);
    });

    testWidgets('the cap never passes 140 dp on a wide row', (tester) async {
      useWindow(tester, const Size(1000, 800));
      await tester.pumpWidget(
        host(KSwipeActions.capped(start: _action('fav', []), child: _row)),
      );
      final g = await tester.startGesture(const Offset(100, 30));
      await g.moveBy(const Offset(400, 0));
      await tester.pump();
      expect(_dx(tester), lessThanOrEqualTo(140));
      await g.cancel();
    });

    testWidgets('below the trigger does nothing', (tester) async {
      final log = <String>[];
      await _pumpRow(
        tester,
        (r) => KSwipeActions.capped(start: _action('fav', log), child: r),
      );
      await _swipe(tester, 60);
      expect(log, isEmpty);
      expect(_dx(tester), 0);
    });

    testWidgets('a fling below the trigger does nothing', (tester) async {
      final log = <String>[];
      await _pumpRow(
        tester,
        (r) => KSwipeActions.capped(start: _action('fav', log), child: r),
      );
      await tester.fling(find.byKey(_rowKey), const Offset(50, 0), 4000);
      await tester.pumpAndSettle();
      expect(log, isEmpty);
    });

    testWidgets('a side without an action stays put but claims the drag', (
      tester,
    ) async {
      final log = <String>[];
      var outer = 0;
      await _pumpRow(
        tester,
        (r) => GestureDetector(
          onHorizontalDragUpdate: (_) => outer++,
          child: KSwipeActions.capped(start: _action('fav', log), child: r),
        ),
      );
      final g = await tester.startGesture(const Offset(300, 30));
      await g.moveBy(const Offset(-100, 0));
      await g.moveBy(const Offset(-100, 0));
      await tester.pump();
      expect(_dx(tester), 0);
      expect(find.byType(KSwipeStrip), findsNothing);
      await g.up();
      await tester.pumpAndSettle();
      expect(log, isEmpty);
      expect(outer, 0);
    });

    testWidgets('the strip has a fill, the icon and a label below it', (
      tester,
    ) async {
      await _pumpRow(
        tester,
        (r) => KSwipeActions.capped(end: _action('Pin', []), child: r),
      );
      final g = await tester.startGesture(const Offset(300, 30));
      await g.moveBy(const Offset(-100, 0));
      await tester.pump();
      expect(find.text('Pin'), findsOneWidget);
      expect(
        tester.getCenter(find.byIcon(KIcons.heart)).dy,
        lessThan(tester.getCenter(find.text('Pin')).dy),
      );
      expect(
        find.descendant(
          of: find.byType(KSwipeStrip),
          matching: find.byType(ColoredBox),
        ),
        findsOneWidget,
      );
      await g.cancel();
    });
  });

  group('no flicker', () {
    /// Pumps frame by frame, checking the invariants of every frame.
    Future<void> watch(
      WidgetTester tester, {
      required double side,
      int frames = 80,
    }) async {
      for (var i = 0; i < frames; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final dx = _dx(tester);
        expect(
          dx * side,
          greaterThanOrEqualTo(0),
          reason: 'offset changed sign',
        );
        final strip = find.byType(KSwipeStrip);
        if (dx == 0) {
          expect(strip, findsNothing, reason: 'strip left at rest');
        } else if (strip.evaluate().isNotEmpty) {
          final r = tester.getRect(strip);
          expect(r.width, closeTo(dx.abs(), 0.01));
          // On the side the row moved away from.
          if (side > 0) {
            expect(r.left, 0);
          } else {
            expect(r.right, _width);
          }
        }
      }
    }

    for (final side in [1.0, -1.0]) {
      testWidgets('release below the trigger, side $side', (tester) async {
        await _pumpRow(
          tester,
          (r) => KSwipeActions.capped(
            start: _action('a', []),
            end: _action('b', []),
            child: r,
          ),
        );
        final g = await tester.startGesture(const Offset(200, 30));
        await g.moveBy(Offset(side * 60, 0));
        await tester.pump();
        await g.up();
        await watch(tester, side: side);
        expect(_dx(tester), 0);
      });

      testWidgets('fast fling back toward zero, side $side', (tester) async {
        await _pumpRow(
          tester,
          (r) => KSwipeActions.capped(
            start: _action('a', []),
            end: _action('b', []),
            child: r,
          ),
        );
        final g = await tester.startGesture(const Offset(200, 30));
        await g.moveBy(Offset(side * 70, 0));
        await tester.pump(const Duration(milliseconds: 16));
        // Back across zero in a few frames, then let go.
        for (var i = 0; i < 4; i++) {
          await g.moveBy(Offset(-side * 45, 0));
          await watch(tester, side: side, frames: 1);
        }
        await g.up();
        await watch(tester, side: side);
        expect(_dx(tester), 0);
      });

      testWidgets('remove: half swipe and release, side $side', (tester) async {
        await _pumpRow(tester, (r) => _remove(() async => true, row: r));
        final g = await tester.startGesture(const Offset(200, 30));
        await g.moveBy(Offset(side * 150, 0));
        await tester.pump();
        await g.up();
        await watch(tester, side: side);
        expect(_dx(tester), 0);
      });
    }
  });

  group('device slop', () {
    void useSlop(WidgetTester tester) {
      tester.view.gestureSettings = const GestureSettings(physicalTouchSlop: 8);
      addTearDown(tester.view.resetGestureSettings);
    }

    testWidgets('a row inside a horizontal PageView wins the drag', (
      tester,
    ) async {
      useSlop(tester);
      useWindow(tester, const Size(_width, 800));
      final log = <String>[];
      final controller = PageController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        host(
          PageView(
            controller: controller,
            children: [
              KSwipeActions.capped(start: _action('fav', log), child: _row),
              const SizedBox(),
            ],
          ),
        ),
      );
      final g = await tester.startGesture(const Offset(100, 30));
      for (var i = 0; i < 12; i++) {
        await g.moveBy(const Offset(10, 0));
        expect(controller.page, 0);
      }
      await g.up();
      await tester.pumpAndSettle();
      expect(log, ['fav']);
    });

    testWidgets('a swipe 30 degrees off horizontal removes in a list', (
      tester,
    ) async {
      useSlop(tester);
      useWindow(tester, const Size(_width, 800));
      var calls = 0;
      await tester.pumpWidget(
        host(
          ListView(
            children: [
              _remove(() async {
                calls++;
                return true;
              }, row: _row),
              const SizedBox(height: 2000),
            ],
          ),
        ),
      );
      final g = await tester.startGesture(const Offset(50, 30));
      for (var i = 0; i < 40; i++) {
        await g.moveBy(const Offset(9, -5));
      }
      await g.up();
      await tester.pumpAndSettle();
      expect(calls, 1);
    });
  });

  group('release and regrab', () {
    testWidgets('remount mid slide-out still calls onRemove once', (
      tester,
    ) async {
      var calls = 0;
      Widget build(Key key) => host(
        KSwipeActions.remove(
          key: key,
          label: 'Remove',
          onRemove: () async {
            calls++;
            return true;
          },
          child: _row,
        ),
      );
      useWindow(tester, const Size(_width, 800));
      await tester.pumpWidget(build(const ValueKey('a')));
      final g = await tester.startGesture(const Offset(100, 30));
      await g.moveBy(const Offset(150, 0));
      await g.moveBy(const Offset(150, 0));
      await g.up();
      await tester.pump(const Duration(milliseconds: 40));
      await tester.pumpWidget(build(const ValueKey('b')));
      await tester.pumpAndSettle();
      expect(calls, 1);
    });

    testWidgets('a trigger that throws still leaves the row at rest', (
      tester,
    ) async {
      await _pumpRow(
        tester,
        (r) => KSwipeActions.capped(
          start: KSwipeAction(
            icon: KIcons.heart,
            label: 'x',
            onTrigger: () => throw StateError('boom'),
          ),
          child: r,
        ),
      );
      await _swipe(tester, 150);
      expect(tester.takeException(), isA<StateError>());
      expect(_dx(tester), 0);
    });

    testWidgets('regrabbing past the trigger does not jump the row', (
      tester,
    ) async {
      await _pumpRow(
        tester,
        (r) => KSwipeActions.capped(start: _action('a', []), child: r),
      );
      final g = await tester.startGesture(const Offset(100, 30));
      await g.moveBy(const Offset(100, 0));
      await g.moveBy(const Offset(100, 0));
      await g.up();
      await tester.pump(const Duration(milliseconds: 30));
      final before = _dx(tester);
      expect(before, greaterThan(90));
      final g2 = await tester.startGesture(const Offset(100, 30));
      await g2.moveBy(const Offset(19, 0));
      await tester.pump();
      expect(_dx(tester), greaterThanOrEqualTo(before - 1));
      await g2.cancel();
    });
  });

  group('strip content is centred', () {
    const tall = SizedBox(
      key: _rowKey,
      width: double.infinity,
      height: 88,
      child: Text('row'),
    );

    /// Union of the icon (and label) rects. Drags stay below the trigger: past
    /// it the icon scales up around its centre.
    Rect content(WidgetTester tester, {required bool label}) {
      var r = tester.getRect(find.byType(Icon).last);
      if (label) r = r.expandToInclude(tester.getRect(find.byType(Text).last));
      return r;
    }

    Future<void> check(
      WidgetTester tester,
      Widget Function(Widget row) wrap,
      double drag, {
      required bool label,
    }) async {
      await _pumpRow(tester, wrap);
      final g = await tester.startGesture(Offset(drag > 0 ? 100 : 300, 30));
      await g.moveBy(Offset(drag, 0));
      await tester.pump();
      final strip = tester.getRect(find.byType(KSwipeStrip));
      final c = content(tester, label: label);
      expect(c.center.dy, closeTo(strip.center.dy, 0.5));
      expect(c.center.dx, closeTo(strip.center.dx, 0.5));
      expect(c.left, greaterThanOrEqualTo(strip.left));
      expect(c.right, lessThanOrEqualTo(strip.right));
      await g.cancel();
    }

    testWidgets('capped, swipe right', (tester) async {
      await check(
        tester,
        (_) => KSwipeActions.capped(start: _action('Info', []), child: tall),
        70,
        label: true,
      );
    });

    testWidgets('capped, swipe left', (tester) async {
      await check(
        tester,
        (_) => KSwipeActions.capped(end: _action('Info', []), child: tall),
        -70,
        label: true,
      );
    });

    testWidgets('remove strip', (tester) async {
      await check(
        tester,
        (_) => _remove(() async => true, row: tall),
        150,
        label: false,
      );
    });
  });

  group('enabled', () {
    testWidgets('toggling keeps the child state', (tester) async {
      useWindow(tester, const Size(_width, 800));
      Widget build(bool enabled) => host(
        KSwipeActions.capped(
          enabled: enabled,
          start: _action('a', []),
          child: const _Counter(),
        ),
      );
      await tester.pumpWidget(build(true));
      await tester.tap(find.byType(_Counter));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
      await tester.pumpWidget(build(false));
      expect(find.text('1'), findsOneWidget);
      await tester.pumpWidget(build(true));
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('disabled: no drag, no callbacks', (tester) async {
      final log = <String>[];
      await _pumpRow(
        tester,
        (r) => KSwipeActions.capped(
          enabled: false,
          start: _action('a', log),
          child: r,
        ),
      );
      await _swipe(tester, 200);
      expect(log, isEmpty);
      expect(_dx(tester), 0);
    });

    testWidgets('disabled: an outer drag is not claimed', (tester) async {
      var outer = 0;
      await _pumpRow(
        tester,
        (r) => GestureDetector(
          onHorizontalDragUpdate: (_) => outer++,
          child: KSwipeActions.capped(
            enabled: false,
            start: _action('a', []),
            child: r,
          ),
        ),
      );
      await _swipe(tester, 200);
      expect(outer, greaterThan(0));
    });
  });

  group('semantics', () {
    Set<String> actions(WidgetTester tester) {
      final data = tester.getSemantics(find.byKey(_rowKey)).getSemanticsData();
      return {
        for (final id in data.customSemanticsActionIds ?? <int>[])
          CustomSemanticsAction.getAction(id)!.label!,
      };
    }

    testWidgets('capped: one action per side, gone when disabled', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      Widget build(bool enabled) => host(
        KSwipeActions.capped(
          enabled: enabled,
          start: _action('Like', []),
          end: _action('Pin', []),
          child: _row,
        ),
      );
      await tester.pumpWidget(build(true));
      expect(actions(tester), {'Like', 'Pin'});
      await tester.pumpWidget(build(false));
      expect(actions(tester), isEmpty);
      handle.dispose();
    });

    testWidgets('remove: the action runs the removal', (tester) async {
      final handle = tester.ensureSemantics();
      var calls = 0;
      await _pumpRow(
        tester,
        (r) => _remove(() async {
          calls++;
          return true;
        }, row: r),
      );
      expect(actions(tester), {'Remove'});
      final id = CustomSemanticsAction.getIdentifier(
        const CustomSemanticsAction(label: 'Remove'),
      );
      tester.semantics.performAction(
        find.semantics.byAction(SemanticsAction.customAction),
        SemanticsAction.customAction,
        args: id,
      );
      await tester.pumpAndSettle();
      expect(calls, 1);
      handle.dispose();
    });
  });

  group('pointers', () {
    testWidgets('a mouse click with 2 px of jitter is still a tap', (
      tester,
    ) async {
      var taps = 0;
      await _pumpRow(
        tester,
        (r) => KSwipeActions.capped(
          start: _action('a', []),
          child: GestureDetector(onTap: () => taps++, child: r),
        ),
      );
      final g = await tester.startGesture(
        const Offset(200, 30),
        kind: PointerDeviceKind.mouse,
      );
      await g.moveBy(const Offset(2, 0));
      await g.up();
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(_dx(tester), 0);
    });

    testWidgets('a mouse drag past the slop swipes', (tester) async {
      var calls = 0;
      await _pumpRow(
        tester,
        (r) => _remove(() async {
          calls++;
          return true;
        }, row: r),
      );
      await _swipe(tester, _width * 0.8, kind: PointerDeviceKind.mouse);
      expect(calls, 1);
    });

    testWidgets('a trackpad pan is ignored', (tester) async {
      var calls = 0;
      await _pumpRow(
        tester,
        (r) => _remove(() async {
          calls++;
          return true;
        }, row: r),
      );
      await _swipe(tester, _width * 0.8, kind: PointerDeviceKind.trackpad);
      expect(calls, 0);
      expect(_dx(tester), 0);
    });
  });
}

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int n = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => setState(() => n++),
    child: SizedBox(height: 60, child: Center(child: Text('$n'))),
  );
}
