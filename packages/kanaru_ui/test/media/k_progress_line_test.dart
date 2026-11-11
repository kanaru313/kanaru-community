import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../support/host.dart';

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('draws a 2 dp line ($name)', (tester) async {
      await tester.pumpWidget(
        host(
          const KProgressLine(value: 0.5),
          brightness: brightness,
          textScale: scale,
        ),
      );
      expect(tester.getSize(find.byType(KProgressLine)).height, 2);
      final fill = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(fill.widthFactor, 0.5);
    });
  }

  testWidgets('clamps out-of-range and NaN values', (tester) async {
    for (final (value, expected) in [
      (-1.0, 0.0),
      (2.0, 1.0),
      (double.nan, 0.0),
    ]) {
      await tester.pumpWidget(host(KProgressLine(value: value)));
      expect(
        tester
            .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
            .widthFactor,
        expected,
      );
    }
  });
}
