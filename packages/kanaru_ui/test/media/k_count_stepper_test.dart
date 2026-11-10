import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

void main() {
  bool enabled(WidgetTester tester, Key key) =>
      tester.widget<IconButton>(find.byKey(key)).onPressed != null;

  Widget stepper(
    int value,
    List<int> seen, {
    bool on = true,
  }) => host(
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
    await tester.tap(find.byTooltip('more'));
    await tester.tap(find.byTooltip('fewer'));
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

  testWidgets('keeps 48 dp touch height', (tester) async {
    await tester.pumpWidget(stepper(5, []));
    expect(tester.getSize(find.byKey(KCountStepper.increaseKey)).height, 48);
  });
}
