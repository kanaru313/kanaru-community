import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/finders.dart';
import '../support/host.dart';

void main() {
  late TextEditingController controller;
  setUp(() => controller = TextEditingController());
  tearDown(() => controller.dispose());

  group('KNumberSpec', () {
    const spec = KNumberSpec(
      decreaseTooltip: 'Giảm',
      increaseTooltip: 'Tăng',
      onStepped: _ignore,
      min: 0,
      max: 1,
      step: 0.1,
    );

    test('steps inside the bounds without float noise', () {
      expect(spec.stepped('0.2', 1), '0.3');
      expect(spec.stepped('0.9', 1), '1');
      expect(spec.stepped('1', 1), isNull);
      expect(spec.stepped('0', -1), isNull);
      expect(spec.stepped('5', -1), '1');
    });

    test('text that is not a number jumps to a valid value', () {
      expect(spec.canStep('', -1), isTrue);
      expect(spec.stepped('abc', 1), '0.1');
      expect(spec.stepped('1e999', 1), '0.1');
    });

    test('format is safe for huge, negative and whole values', () {
      expect(spec.format(1e9 + 1), '1000000001');
      expect(spec.format(1e300), isNotEmpty);
      expect(spec.format(-2.5), '-2.5');
      expect(spec.format(-0.0), '0');
      expect(spec.format(0.1 + 0.2), '0.3');
      expect(spec.format(double.infinity), 'Infinity');
      expect(spec.stepped('1e300', -1), isNotNull);
      const big = KNumberSpec(
        decreaseTooltip: '-',
        increaseTooltip: '+',
        onStepped: _ignore,
        integer: true,
      );
      expect(big.stepped('1000000000', 1), '1000000001');
      expect(big.stepped('-1000000000', -1), '-1000000001');
      expect(big.stepped('1e300', 1), isNull); // no change at that magnitude
    });

    test('integer rounds and filters', () {
      const whole = KNumberSpec(
        decreaseTooltip: '-',
        increaseTooltip: '+',
        onStepped: _ignore,
        integer: true,
      );
      expect(whole.stepped('4.4', 1), '5');
      expect(whole.stepped('-1', -1), '-2');
    });
  });

  Widget number({
    KNumberSpec? spec,
    bool enabled = true,
    ValueChanged<String>? onStepped,
  }) => host(
    Padding(
      padding: const EdgeInsets.all(16),
      child: KTextFieldRow(
        label: 'Số',
        controller: controller,
        enabled: enabled,
        number:
            spec ??
            KNumberSpec(
              decreaseTooltip: 'Giảm',
              increaseTooltip: 'Tăng',
              onStepped: onStepped ?? (_) {},
              min: 0,
              max: 10,
            ),
      ),
    ),
  );

  bool enabledButton(WidgetTester tester, String tooltip) =>
      tester.widget<KIconButton>(byIconButton(tooltip)).onPressed != null;

  testWidgets('each tap on + / − writes and reports the new value', (
    tester,
  ) async {
    final seen = <String>[];
    controller.text = '5';
    await tester.pumpWidget(number(onStepped: seen.add));
    await tester.tap(byIconButton('Tăng'));
    await tester.pump();
    expect(controller.text, '6');
    await tester.tap(byIconButton('Giảm'));
    await tester.tap(byIconButton('Giảm'));
    await tester.pump();
    expect(controller.text, '4');
    expect(seen, ['6', '5', '4']);
  });

  testWidgets('the button at its bound is disabled and follows the text', (
    tester,
  ) async {
    controller.text = '10';
    await tester.pumpWidget(number());
    expect(enabledButton(tester, 'Tăng'), isFalse);
    expect(enabledButton(tester, 'Giảm'), isTrue);
    controller.text = '0';
    await tester.pump();
    expect(enabledButton(tester, 'Tăng'), isTrue);
    expect(enabledButton(tester, 'Giảm'), isFalse);
  });

  testWidgets('arrow keys step the focused field', (tester) async {
    final seen = <String>[];
    controller.text = '5';
    await tester.pumpWidget(number(onStepped: seen.add));
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(seen, ['6', '5', '4']);
    expect(controller.text, '4');
  });

  testWidgets('a locked number field cannot step', (tester) async {
    controller.text = '5';
    await tester.pumpWidget(number(enabled: false));
    expect(enabledButton(tester, 'Tăng'), isFalse);
    expect(enabledButton(tester, 'Giảm'), isFalse);
  });

  testWidgets('typing keeps only number characters', (tester) async {
    await tester.pumpWidget(number());
    await tester.enterText(find.byType(TextField), 'a1.5e-x');
    expect(controller.text, '1.5e-');
    await tester.pumpWidget(
      number(
        spec: KNumberSpec(
          decreaseTooltip: 'Giảm',
          increaseTooltip: 'Tăng',
          onStepped: (_) {},
          integer: true,
        ),
      ),
    );
    controller.clear();
    await tester.enterText(find.byType(TextField), '1.5');
    expect(controller.text, '15');
  });

  testWidgets('multiline: rows lines, Enter is a line break', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(
      host(KTextFieldRow(label: 'Prompt', controller: controller, rows: 3)),
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.minLines, 3);
    expect(field.maxLines, 3);
    expect(field.keyboardType, TextInputType.multiline);
    expect(field.textInputAction, TextInputAction.newline);
    expect(
      tester.getSize(find.byType(TextField)).height,
      greaterThan(KTextFieldRow.height * 1.5),
    );
  });

  testWidgets('multiline grows on desktop only', (tester) async {
    useWindow(tester, const Size(1400, 900));
    await tester.pumpWidget(
      host(KTextFieldRow(label: 'Prompt', controller: controller, rows: 3)),
    );
    expect(tester.widget<TextField>(find.byType(TextField)).maxLines, 9);
  });

  testWidgets('required adds a star to the label', (tester) async {
    await tester.pumpWidget(
      host(
        KTextFieldRow(label: 'Key', controller: controller, isRequired: true),
      ),
    );
    expect(find.text('Key *'), findsOneWidget);
  });

  testWidgets('invalid draws the error outline without an error line', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        KTextFieldRow(
          label: 'Key',
          helper: 'Gợi ý',
          controller: controller,
          invalid: true,
        ),
      ),
    );
    final scheme = Theme.of(tester.element(find.byType(TextField))).colorScheme;
    final decoration = tester
        .widget<TextField>(find.byType(TextField))
        .decoration!;
    expect(
      (decoration.enabledBorder as OutlineInputBorder).borderSide.color,
      scheme.error,
    );
    expect(decoration.errorText, isNull);
    expect(find.text('Gợi ý'), findsOneWidget);
  });

  testWidgets('dense is 48 dp high', (tester) async {
    await tester.pumpWidget(
      host(KTextFieldRow(hint: 'URL', controller: controller, dense: true)),
    );
    expect(tester.getSize(find.byType(TextField)).height, 48);
  });

  testWidgets('helper keeps its line breaks', (tester) async {
    await tester.pumpWidget(
      host(
        KTextFieldRow(label: 'A', helper: 'one\ntwo', controller: controller),
      ),
    );
    expect(find.text('one\ntwo'), findsOneWidget);
  });
}

void _ignore(String _) {}
