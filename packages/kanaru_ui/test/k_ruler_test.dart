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
}
