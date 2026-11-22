import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

void main() {
  late TextEditingController controller;
  setUp(() => controller = TextEditingController());
  tearDown(() => controller.dispose());

  Widget field({
    String? helper = 'Dán đường dẫn',
    String? error,
    bool enabled = true,
    ValueChanged<String>? onSubmitted,
  }) => host(
    Padding(
      padding: const EdgeInsets.all(16),
      child: KTextFieldRow(
        label: 'URL repository',
        controller: controller,
        hint: 'https://…',
        helper: helper,
        error: error,
        enabled: enabled,
        keyboard: TextInputType.url,
        onSubmitted: onSubmitted,
      ),
    ),
  );

  testWidgets('helper shows without an error', (tester) async {
    await tester.pumpWidget(field());
    expect(find.text('Dán đường dẫn'), findsOneWidget);
    expect(find.text('URL repository'), findsOneWidget);
    expect(
      tester.getSize(find.byType(TextField)).height,
      greaterThanOrEqualTo(KTextFieldRow.height),
    );
  });

  testWidgets('error replaces the helper, never both', (tester) async {
    await tester.pumpWidget(field(error: 'URL không hợp lệ'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('URL không hợp lệ'), findsOneWidget);
    expect(find.text('Dán đường dẫn'), findsNothing);
    await tester.pumpWidget(field());
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('URL không hợp lệ'), findsNothing);
    expect(find.text('Dán đường dẫn'), findsOneWidget);
  });

  testWidgets('enabled false ignores typing', (tester) async {
    await tester.pumpWidget(field(enabled: false));
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    await tester.tap(find.byType(TextField), warnIfMissed: false);
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isFalse,
    );
  });

  testWidgets('Enter submits the text', (tester) async {
    final seen = <String>[];
    await tester.pumpWidget(field(onSubmitted: seen.add));
    await tester.enterText(find.byType(TextField), 'https://a.b/p.json');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(seen, ['https://a.b/p.json']);
  });

  testWidgets('long text at 200 % does not overflow', (tester) async {
    useWindow(tester, const Size(360, 800));
    controller.text = 'https://example.com/${'a' * 200}';
    await tester.pumpWidget(
      host(
        KTextFieldRow(label: 'URL', controller: controller, helper: 'Gợi ý'),
        textScale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
