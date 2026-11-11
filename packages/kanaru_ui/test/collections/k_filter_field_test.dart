import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

void main() {
  late TextEditingController controller;
  setUp(() => controller = TextEditingController());
  tearDown(() => controller.dispose());

  Widget field({ValueChanged<String>? onChanged, VoidCallback? onClose}) =>
      Align(
        alignment: Alignment.topCenter,
        child: KFilterField(
          controller: controller,
          hint: 'Filter songs',
          closeTooltip: 'Close filter',
          onChanged: onChanged,
          onClose: onClose ?? () {},
        ),
      );

  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('renders hint and icons ($name)', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(
        host(field(), brightness: brightness, textScale: scale),
      );
      expect(find.text('Filter songs'), findsOneWidget);
      expect(find.byIcon(KIcons.filter), findsOneWidget);
      expect(find.byIcon(KIcons.close), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('is 48 tall and focused on open', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(field()));
    await tester.pump();
    expect(tester.getSize(find.byType(KFilterField)).height, 48);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
  });

  testWidgets('typing reports the text', (tester) async {
    useWindow(tester, const Size(400, 800));
    final seen = <String>[];
    await tester.pumpWidget(host(field(onChanged: seen.add)));
    await tester.enterText(find.byType(TextField), 'vu');
    expect(seen, ['vu']);
  });

  testWidgets('the cross clears the text and closes', (tester) async {
    useWindow(tester, const Size(400, 800));
    var closed = 0;
    await tester.pumpWidget(host(field(onClose: () => closed++)));
    await tester.enterText(find.byType(TextField), 'vu');
    await tester.tap(find.byIcon(KIcons.close));
    expect(controller.text, '');
    expect(closed, 1);
  });

  testWidgets('Esc clears the text and closes', (tester) async {
    useWindow(tester, const Size(1300, 800));
    var closed = 0;
    await tester.pumpWidget(host(field(onClose: () => closed++)));
    await tester.enterText(find.byType(TextField), 'vu');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(controller.text, '');
    expect(closed, 1);
  });
}
