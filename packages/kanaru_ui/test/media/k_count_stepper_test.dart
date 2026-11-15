import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/finders.dart';
import '../support/host.dart';

void main() {
  bool enabled(WidgetTester tester, Key key) =>
      tester.widget<KIconButton>(find.byKey(key)).onPressed != null;

  Widget stepper(int value, List<int> seen, {bool on = true}) => host(
    KCountStepper(
      value: value,
      enabled: on,
      onChanged: seen.add,
      decreaseTooltip: 'fewer',
      increaseTooltip: 'more',
    ),
  );

  testWidgets('steps by one in both directions', (tester) async {
    final seen = <int>[];
    await tester.pumpWidget(stepper(5, seen));
    await tester.tap(byIconButton('more'));
    await tester.tap(byIconButton('fewer'));
    expect(seen, [6, 4]);
  });

  testWidgets('minus is dimmed at 1, plus at 99', (tester) async {
    final seen = <int>[];
    await tester.pumpWidget(stepper(1, seen));
    expect(enabled(tester, KCountStepper.decreaseKey), isFalse);
    expect(enabled(tester, KCountStepper.increaseKey), isTrue);
    await tester.tap(find.byKey(KCountStepper.decreaseKey));
    expect(seen, isEmpty);
    await tester.pumpWidget(stepper(99, seen));
    expect(enabled(tester, KCountStepper.increaseKey), isFalse);
    expect(enabled(tester, KCountStepper.decreaseKey), isTrue);
    await tester.tap(find.byKey(KCountStepper.increaseKey));
    expect(seen, isEmpty);
  });

  testWidgets('both are dimmed while disabled', (tester) async {
    final seen = <int>[];
    await tester.pumpWidget(stepper(50, seen, on: false));
    expect(enabled(tester, KCountStepper.decreaseKey), isFalse);
    expect(enabled(tester, KCountStepper.increaseKey), isFalse);
  });

  testWidgets('each button is the small icon plus its padding', (tester) async {
    final seen = <int>[];
    await tester.pumpWidget(stepper(5, seen));
    for (final key in [KCountStepper.decreaseKey, KCountStepper.increaseKey]) {
      expect(
        tester.getSize(find.byKey(key)),
        const Size(KIconSize.sm + 2 * KSpace.x2, KIconSize.sm),
      );
    }
    await tester.tap(find.byKey(KCountStepper.increaseKey));
    await tester.pump(const Duration(milliseconds: 300));
    expect(seen, [6]);
  });

  testWidgets('idle colour is onSurfaceVariant unless a colour is given', (
    tester,
  ) async {
    await tester.pumpWidget(stepper(5, []));
    Color glyph() => tester
        .widget<Icon>(
          find.descendant(
            of: find.byKey(KCountStepper.increaseKey),
            matching: find.byType(Icon),
          ),
        )
        .color!;
    final scheme = Theme.of(tester.element(find.byType(KCountStepper)))
        .colorScheme;
    expect(glyph(), scheme.onSurfaceVariant);
    await tester.pumpWidget(
      host(
        KCountStepper(
          value: 5,
          color: const Color(0xFF123456),
          onChanged: (_) {},
          decreaseTooltip: 'fewer',
          increaseTooltip: 'more',
        ),
      ),
    );
    expect(glyph(), const Color(0xFF123456));
  });
}
