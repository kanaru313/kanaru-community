import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:kanaru_ui/src/widgets/k_ruler_painter.dart';
import 'package:material_ui/material_ui.dart';

import 'support/finders.dart';
import 'support/host.dart';

Widget _ruler({
  int value = 45,
  int min = 1,
  int max = 180,
  int labelEvery = 15,
  ValueChanged<int>? onChanged,
  VoidCallback? onSubmit,
  bool autofocus = false,
  String Function(int)? tickLabel,
}) => Center(
  child: KRuler(
    min: min,
    max: max,
    value: value,
    majorEvery: labelEvery == 1 ? 1 : 5,
    labelEvery: labelEvery,
    onChanged: onChanged ?? (_) {},
    onSubmit: onSubmit,
    autofocus: autofocus,
    semanticLabel: 'Số phút',
    valueLabel: (v) => '$v phút',
    tickLabel: tickLabel,
  ),
);

KRulerPainter _painter(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((c) => c.painter)
    .whereType<KRulerPainter>()
    .single;

double _position(WidgetTester tester) => _painter(tester).position;

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('lays out at 320 without overflow ($name)', (tester) async {
      useWindow(tester, const Size(320, 600));
      await tester.pumpWidget(
        host(_ruler(), brightness: brightness, textScale: scale),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('height 72 on touch, 60 on desktop', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_ruler()));
    expect(tester.getSize(find.byType(KRuler)).height, 72);
    useWindow(tester, const Size(1300, 800));
    await tester.pumpWidget(host(_ruler()));
    expect(tester.getSize(find.byType(KRuler)).height, 60);
  });

  testWidgets('slider semantics: value, increase, decrease', (tester) async {
    final semantics = tester.ensureSemantics();
    final changes = <int>[];
    await tester.pumpWidget(host(_ruler(onChanged: changes.add)));
    final node = tester.getSemantics(find.byType(KRuler));
    expect(
      node,
      isSemantics(
        label: 'Số phút',
        value: '45 phút',
        increasedValue: '46 phút',
        decreasedValue: '44 phút',
        isSlider: true,
        hasIncreaseAction: true,
        hasDecreaseAction: true,
      ),
    );
    tester.semantics.performAction(
      find.semantics.byLabel('Số phút'),
      SemanticsAction.increase,
    );
    tester.semantics.performAction(
      find.semantics.byLabel('Số phút'),
      SemanticsAction.decrease,
    );
    expect(changes, [46, 44]);
    semantics.dispose();
  });

  testWidgets('dragging left raises the value, right lowers it, clamped', (
    tester,
  ) async {
    final changes = <int>[];
    await tester.pumpWidget(host(_ruler(onChanged: changes.add)));
    final g = await tester.startGesture(tester.getCenter(find.byType(KRuler)));
    await g.moveBy(const Offset(-40, 0));
    await g.moveBy(const Offset(-40, 0));
    await g.up();
    expect(changes, isNotEmpty);
    expect(changes.last, greaterThan(45));
    changes.clear();
    final g2 = await tester.startGesture(tester.getCenter(find.byType(KRuler)));
    await g2.moveBy(const Offset(60, 0));
    await g2.moveBy(const Offset(3000, 0));
    await g2.up();
    expect(changes.last, 1);
    expect(changes.every((v) => v >= 1 && v <= 180), isTrue);
  });

  testWidgets('left / right keys step by one, Enter submits', (tester) async {
    final changes = <int>[];
    var submitted = 0;
    await tester.pumpWidget(
      host(
        _ruler(
          onChanged: changes.add,
          onSubmit: () => submitted++,
          autofocus: true,
        ),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(changes, [46, 44]);
    expect(submitted, 1);
  });

  testWidgets('no step past either end', (tester) async {
    final changes = <int>[];
    await tester.pumpWidget(
      host(_ruler(value: 180, onChanged: changes.add, autofocus: true)),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(changes, isEmpty);
  });

  testWidgets('off-range value sits at the nearest end and is not changed', (
    tester,
  ) async {
    final changes = <int>[];
    await tester.pumpWidget(host(_ruler(value: 240, onChanged: changes.add)));
    expect(_position(tester), 180);
    expect(changes, isEmpty);
    await tester.pumpWidget(host(_ruler(value: 0, onChanged: changes.add)));
    await tester.pumpAndSettle();
    expect(_position(tester), 1);
    expect(changes, isEmpty);
  });

  testWidgets('off-range value: left key steps from the end', (tester) async {
    final changes = <int>[];
    await tester.pumpWidget(
      host(_ruler(value: 240, onChanged: changes.add, autofocus: true)),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(changes, [179]);
  });

  testWidgets('off-range value: the key pointing further out changes nothing', (
    tester,
  ) async {
    final changes = <int>[];
    await tester.pumpWidget(
      host(_ruler(value: 240, onChanged: changes.add, autofocus: true)),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(changes, isEmpty, reason: 'increase must never lower 240 to 180');
    await tester.pumpWidget(
      host(_ruler(value: -5, onChanged: changes.add, autofocus: true)),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(changes, isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(changes, [2], reason: 'inward key steps from the end');
  });

  testWidgets('arrow at an end is consumed, not passed to a parent', (
    tester,
  ) async {
    var parent = 0;
    await tester.pumpWidget(
      host(
        Focus(
          onKeyEvent: (_, e) {
            if (e is KeyDownEvent) parent++;
            return KeyEventResult.ignored;
          },
          child: _ruler(value: 180, autofocus: true),
        ),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(parent, 0);
  });

  testWidgets('tick labels come from the caller formatter', (tester) async {
    await tester.pumpWidget(host(_ruler()));
    expect(_painter(tester).tickLabel(75), '75');
    await tester.pumpWidget(
      host(_ruler(tickLabel: (v) => '${v ~/ 60}:${v % 60}')),
    );
    expect(_painter(tester).tickLabel(75), '1:15');
    expect(tester.takeException(), isNull);
  });

  testWidgets('semantics: focusable, focused only while it has focus', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(host(_ruler()));
    expect(
      tester.getSemantics(find.byType(KRuler)),
      isSemantics(isSlider: true, isFocusable: true, isFocused: false),
    );
    await tester.pumpWidget(host(_ruler(autofocus: true)));
    await tester.pump();
    expect(
      tester.getSemantics(find.byType(KRuler)),
      isSemantics(isSlider: true, isFocusable: true, isFocused: true),
    );
    semantics.dispose();
  });

  testWidgets('one label per unit mode (tracks)', (tester) async {
    await tester.pumpWidget(
      host(_ruler(value: 3, min: 1, max: 20, labelEvery: 1)),
    );
    expect(_position(tester), 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard focus rings the marker', (tester) async {
    useKeyboardHighlight();
    await tester.pumpWidget(host(_ruler(autofocus: true)));
    await tester.pump();
    expect(tester.widget<KFocusRing>(find.byType(KFocusRing)).visible, isTrue);
  });

  testWidgets('reduced motion: builds and responds', (tester) async {
    final changes = <int>[];
    await tester.pumpWidget(
      host(_ruler(onChanged: changes.add, autofocus: true), reduceMotion: true),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(changes, [46]);
  });

  testWidgets('a fling settles on a tick, onChanged ascending integers', (
    tester,
  ) async {
    final changes = <int>[];
    await tester.pumpWidget(host(_ruler(onChanged: changes.add)));
    await tester.fling(find.byType(KRuler), const Offset(-200, 0), 1500);
    await tester.pumpAndSettle();
    expect(changes, isNotEmpty);
    expect(changes.every((v) => v > 45 && v <= 180), isTrue);
    for (var i = 1; i < changes.length; i++) {
      expect(changes[i], greaterThan(changes[i - 1]));
    }
    expect(_position(tester), changes.last.toDouble());
    expect(changes.last, greaterThan(50), reason: 'it kept its momentum');
  });

  testWidgets('drag end animates to the nearest tick', (tester) async {
    await tester.pumpWidget(host(_ruler()));
    final g = await tester.startGesture(tester.getCenter(find.byType(KRuler)));
    await g.moveBy(
      const Offset(-20, 0),
    ); // past the touch slop, a few ticks at 8 dp
    await g.moveBy(const Offset(-4, 0));
    await g.up();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pumpAndSettle();
    final p = _position(tester);
    expect(p, p.roundToDouble());
    expect(p, greaterThan(45));
  });

  testWidgets('an outside value change animates, then centres', (tester) async {
    final changes = <int>[];
    await tester.pumpWidget(host(_ruler(onChanged: changes.add)));
    await tester.pumpWidget(host(_ruler(value: 90, onChanged: changes.add)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_position(tester), inExclusiveRange(45, 90));
    await tester.pumpAndSettle();
    expect(_position(tester), 90);
    expect(changes, isEmpty, reason: 'no echo');
  });

  testWidgets('reduced motion: an outside change jumps', (tester) async {
    await tester.pumpWidget(host(_ruler(), reduceMotion: true));
    await tester.pumpWidget(host(_ruler(value: 90), reduceMotion: true));
    await tester.pump();
    expect(_position(tester), 90);
  });

  testWidgets('an off-range value parks at the end and does not echo', (
    tester,
  ) async {
    final changes = <int>[];
    await tester.pumpWidget(host(_ruler(value: 240, onChanged: changes.add)));
    await tester.pumpWidget(host(_ruler(value: 300, onChanged: changes.add)));
    await tester.pumpAndSettle();
    expect(_position(tester), 180);
    expect(changes, isEmpty);
  });

  testWidgets('haptic tick per step for a touch pointer only (not by width)', (
    tester,
  ) async {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (c) async {
        if (c.method == 'HapticFeedback.vibrate') calls.add('${c.arguments}');
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(host(_ruler()));
    await tester.drag(find.byType(KRuler), const Offset(-40, 0));
    await tester.pumpAndSettle();
    expect(calls, isNotEmpty);
    calls.clear();
    await tester.pumpWidget(host(_ruler(value: 45)));
    final g = await tester.startGesture(
      tester.getCenter(find.byType(KRuler)),
      kind: PointerDeviceKind.mouse,
    );
    await g.moveBy(const Offset(-40, 0));
    await g.up();
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
  });

  group('sync with an outside value', () {
    testWidgets('two quick outside changes end centred on the last', (
      tester,
    ) async {
      final changes = <int>[];
      await tester.pumpWidget(host(_ruler(onChanged: changes.add)));
      await tester.pumpWidget(host(_ruler(value: 50, onChanged: changes.add)));
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pumpWidget(host(_ruler(value: 55, onChanged: changes.add)));
      await tester.pumpAndSettle();
      expect(_position(tester), 55);
      expect(changes, isEmpty);
    });

    testWidgets('repeated arrow keys end centred on the final value', (
      tester,
    ) async {
      await tester.pumpWidget(host(_Owner(autofocus: true)));
      await tester.pump();
      for (var i = 0; i < 5; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump(const Duration(milliseconds: 40));
      }
      await tester.pumpAndSettle();
      expect(_position(tester), 50);
    });

    testWidgets('min / max / tick change: parked on the value, then fling '
        'rests on an integer without drift', (tester) async {
      final key = GlobalKey<_OwnerState>();
      await tester.pumpWidget(host(_Owner(key: key, value: 10)));
      key.currentState!.setRange(min: 1, max: 20, labelEvery: 1);
      await tester.pumpAndSettle();
      expect(_position(tester), 10);
      final seen = <int>[];
      key.currentState!.listen = seen.add;
      await tester.fling(find.byType(KRuler), const Offset(-120, 0), 800);
      await tester.pumpAndSettle();
      final p = _position(tester);
      expect(p, p.roundToDouble());
      expect(key.currentState!.value, p.round());
      expect(p, greaterThan(10));
      // and back to minutes (tick 8): same rule.
      key.currentState!.setRange(min: 1, max: 180, labelEvery: 15);
      await tester.pumpAndSettle();
      expect(_position(tester), p.round().toDouble());
      await tester.fling(find.byType(KRuler), const Offset(120, 0), 800);
      await tester.pumpAndSettle();
      final q = _position(tester);
      expect(q, q.roundToDouble());
      expect(key.currentState!.value, q.round());
    });

    for (final v in [300.0, 1500.0, 4000.0, 10000.0]) {
      testWidgets('fling at $v px/s rests on an integer, no overshoot', (
        tester,
      ) async {
        final changes = <int>[];
        await tester.pumpWidget(host(_ruler(onChanged: changes.add)));
        await tester.fling(find.byType(KRuler), const Offset(-200, 0), v);
        await tester.pumpAndSettle();
        final p = _position(tester);
        expect(p, p.roundToDouble());
        expect(p, lessThanOrEqualTo(180));
        if (changes.isNotEmpty) expect(changes.last, p.round());
      });
    }

    testWidgets('a fling into max stops at max, never past it', (tester) async {
      final changes = <int>[];
      await tester.pumpWidget(host(_ruler(value: 170, onChanged: changes.add)));
      await tester.fling(find.byType(KRuler), const Offset(-300, 0), 8000);
      await tester.pumpAndSettle();
      expect(_position(tester), 180);
      expect(changes.every((c) => c <= 180), isTrue);
      expect(changes.last, 180);
    });

    testWidgets('a mouse drag moves the ruler', (tester) async {
      final changes = <int>[];
      await tester.pumpWidget(host(_ruler(onChanged: changes.add)));
      final g = await tester.startGesture(
        tester.getCenter(find.byType(KRuler)),
        kind: PointerDeviceKind.mouse,
      );
      await g.moveBy(const Offset(-80, 0));
      await g.up();
      await tester.pumpAndSettle();
      expect(changes, isNotEmpty);
      expect(_position(tester), changes.last.toDouble());
    });
  });
}

/// Holds the value like a parent does: the ruler reports into it.
class _Owner extends StatefulWidget {
  const _Owner({super.key, this.value = 45, this.autofocus = false});
  final int value;
  final bool autofocus;
  @override
  State<_Owner> createState() => _OwnerState();
}

class _OwnerState extends State<_Owner> {
  late int value = widget.value;
  int min = 1;
  int max = 180;
  int labelEvery = 15;
  void Function(int)? listen;

  void setRange({
    required int min,
    required int max,
    required int labelEvery,
  }) => setState(() {
    this.min = min;
    this.max = max;
    this.labelEvery = labelEvery;
  });

  @override
  Widget build(BuildContext context) => _ruler(
    value: value,
    min: min,
    max: max,
    labelEvery: labelEvery,
    autofocus: widget.autofocus,
    onChanged: (v) {
      listen?.call(v);
      setState(() => value = v);
    },
  );
}
