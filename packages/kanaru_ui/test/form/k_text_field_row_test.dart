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

  testWidgets('a long value at 200 % stays one line high, helper visible', (
    tester,
  ) async {
    useWindow(tester, const Size(360, 800));
    Widget at(String text) {
      controller.text = text;
      return host(
        KTextFieldRow(label: 'URL', controller: controller, helper: 'Gợi ý'),
        textScale: 2,
      );
    }

    await tester.pumpWidget(at('https://a.b'));
    final short = tester.getSize(find.byType(TextField)).height;
    await tester.pumpWidget(at('https://example.com/${'a' * 200}'));
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(TextField)).height, short);
    expect(find.text('Gợi ý'), findsOneWidget);
  });

  group('maxLength counter', () {
    Widget counted({
      int max = 20,
      String? helper,
      String? error,
      String? warning,
      double textScale = 1.0,
    }) => host(
      Padding(
        padding: const EdgeInsets.all(16),
        child: KTextFieldRow(
          label: 'Hướng dẫn',
          controller: controller,
          helper: helper,
          error: error,
          warning: warning,
          maxLength: max,
        ),
      ),
      textScale: textScale,
    );

    testWidgets('shows n / max and follows typing', (tester) async {
      await tester.pumpWidget(counted());
      expect(find.text('0 / 20'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump();
      expect(find.text('3 / 20'), findsOneWidget);
    });

    testWidgets('typing and paste stop at the limit', (tester) async {
      await tester.pumpWidget(counted(max: 5));
      await tester.enterText(find.byType(TextField), 'abcdefghij');
      await tester.pump();
      expect(controller.text, 'abcde');
      expect(find.text('5 / 5'), findsOneWidget);
    });

    testWidgets('digits are grouped', (tester) async {
      await tester.pumpWidget(counted(max: 2000));
      expect(find.text('0 / 2,000'), findsOneWidget);
    });

    testWidgets('helper is left of the counter on the same line', (
      tester,
    ) async {
      await tester.pumpWidget(counted(helper: 'Chữ trợ giúp'));
      final h = tester.getRect(find.text('Chữ trợ giúp'));
      final c = tester.getRect(find.text('0 / 20'));
      expect(h.right, lessThan(c.left));
      expect((h.center.dy - c.center.dy).abs(), lessThan(4));
    });

    testWidgets('the framework counter is hidden', (tester) async {
      await tester.pumpWidget(counted());
      expect(find.text('0/20'), findsNothing);
    });

    testWidgets('full keeps the normal counter colour', (tester) async {
      await tester.pumpWidget(counted(max: 3));
      final scheme = Theme.of(tester.element(find.byType(TextField)))
          .colorScheme;
      Color? colour() => tester.widget<Text>(find.text('0 / 3')).style?.color;
      final empty = colour();
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump();
      expect(tester.widget<Text>(find.text('3 / 3')).style?.color, empty);
      expect(empty, scheme.onSurfaceVariant);
    });

    testWidgets('an error replaces the whole line, counter included', (
      tester,
    ) async {
      await tester.pumpWidget(
        counted(helper: 'Chữ trợ giúp', error: 'Biến không có'),
      );
      expect(find.text('Biến không có'), findsOneWidget);
      expect(find.text('Chữ trợ giúp'), findsNothing);
      expect(find.text('0 / 20'), findsNothing);
    });

    testWidgets('a warning is its own line under helper and counter', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        counted(helper: 'Chữ trợ giúp', warning: 'Gần đầy'),
      );
      expect(find.text('Gần đầy'), findsOneWidget);
      expect(find.text('Chữ trợ giúp'), findsOneWidget);
      expect(find.text('0 / 20'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Gần đầy')).dy,
        greaterThan(tester.getBottomLeft(find.text('0 / 20')).dy - 1),
      );
      expect(
        tester.getSemantics(find.text('Gần đầy')),
        isSemantics(label: 'Gần đầy', isLiveRegion: true),
      );
      final scheme = Theme.of(tester.element(find.byType(TextField)))
          .colorScheme;
      final decoration = tester
          .widget<TextField>(find.byType(TextField))
          .decoration!;
      expect(
        (decoration.enabledBorder! as OutlineInputBorder).borderSide.color,
        scheme.tertiary,
      );
      handle.dispose();
    });

    testWidgets('an error replaces the warning too', (tester) async {
      await tester.pumpWidget(counted(warning: 'Gần đầy', error: 'Lỗi'));
      expect(find.text('Lỗi'), findsOneWidget);
      expect(find.text('Gần đầy'), findsNothing);
      expect(find.text('0 / 20'), findsNothing);
    });

    testWidgets('200 % text with a long helper has no overflow', (
      tester,
    ) async {
      useWindow(tester, const Size(360, 900));
      await tester.pumpWidget(
        counted(
          max: 2000,
          helper:
              'Chữ trên chip của ô nhập chat, hiện cho mọi cuộc trò chuyện.',
          textScale: 2.0,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('0 / 2,000'), findsOneWidget);
    });

    testWidgets('without maxLength nothing changes', (tester) async {
      await tester.pumpWidget(field());
      expect(find.textContaining(' / '), findsNothing);
      expect(find.text('Dán đường dẫn'), findsOneWidget);
    });

    test('maxLength must be positive', () {
      expect(
        () => KTextFieldRow(controller: controller, hint: 'h', maxLength: 0),
        throwsAssertionError,
      );
    });
  });
}
