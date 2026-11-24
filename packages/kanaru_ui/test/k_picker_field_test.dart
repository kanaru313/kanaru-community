import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

Widget _field({VoidCallback? onTap}) => KPickerField(
  title: const Text('Gemini 2.5 Flash'),
  subtitle: 'Nhanh, rẻ',
  semanticLabel: 'Model: Gemini 2.5 Flash',
  onTap: onTap ?? () {},
);

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('one button node named after the field ($name)', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        host(_field(), brightness: brightness, textScale: scale),
      );
      expect(
        tester.getSemantics(find.text('Gemini 2.5 Flash')),
        isSemantics(
          label: 'Model: Gemini 2.5 Flash',
          isButton: true,
          hasTapAction: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
        ),
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets('tap opens; tinted card with value and subtitle', (tester) async {
    var opened = 0;
    await tester.pumpWidget(host(_field(onTap: () => opened++)));
    await tester.tap(find.text('Gemini 2.5 Flash'));
    expect(opened, 1);
    expect(find.text('Nhanh, rẻ'), findsOneWidget);
    final scheme = Theme.of(tester.element(find.byType(KPickerField)))
        .colorScheme;
    final box = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(KPickerField),
            matching: find.byType(DecoratedBox),
          ),
        )
        .first;
    expect(
      (box.decoration as ShapeDecoration).color,
      scheme.secondaryContainer,
    );
  });
}
