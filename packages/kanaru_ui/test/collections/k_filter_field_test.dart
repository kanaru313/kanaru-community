import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

void main() {
  late TextEditingController controller;
  setUp(() => controller = TextEditingController());
  tearDown(() => controller.dispose());

  Widget field({
    ValueChanged<String>? onChanged,
    VoidCallback? onClose,
    bool autofocus = true,
  }) => Align(
    alignment: Alignment.topCenter,
    child: KFilterField(
      controller: controller,
      hint: 'Filter songs',
      closeTooltip: 'Close filter',
      onChanged: onChanged,
      autofocus: autofocus,
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

  testWidgets('autofocus: false leaves the keyboard alone', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(field(autofocus: false)));
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isFalse,
    );
  });

  testWidgets('the cross reports the empty text before it closes', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 800));
    final log = <String>[];
    await tester.pumpWidget(
      host(
        field(
          onChanged: (v) => log.add('changed:"$v"'),
          onClose: () => log.add('closed'),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'vu');
    log.clear();
    await tester.tap(find.byIcon(KIcons.close));
    expect(log, ['changed:""', 'closed']);
  });

  testWidgets('Esc reports the empty text too', (tester) async {
    useWindow(tester, const Size(1300, 800));
    final seen = <String>[];
    await tester.pumpWidget(host(field(onChanged: seen.add)));
    await tester.enterText(find.byType(TextField), 'vu');
    seen.clear();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(seen, ['']);
  });

  group('persistent', () {
    final clearButton = find.byWidgetPredicate(
      (w) => w is Tooltip && w.message == 'Xoá',
    );
    Widget persistent(VoidCallback onClose) => Align(
      alignment: Alignment.topCenter,
      child: KFilterField(
        controller: controller,
        hint: 'Tìm plugin',
        closeTooltip: 'Xoá',
        autofocus: false,
        persistent: true,
        onClose: onClose,
      ),
    );

    testWidgets('clear shows only with text and never closes', (tester) async {
      useWindow(tester, const Size(400, 800));
      var closed = 0;
      await tester.pumpWidget(host(persistent(() => closed++)));
      expect(clearButton, findsNothing);
      await tester.enterText(find.byType(TextField), 'ab');
      await tester.pump();
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pump();
      expect(controller.text, isEmpty);
      expect(clearButton, findsNothing);
      expect(closed, 0);
    });

    testWidgets('Esc clears the text without closing', (tester) async {
      useWindow(tester, const Size(400, 800));
      var closed = 0;
      await tester.pumpWidget(host(persistent(() => closed++)));
      await tester.enterText(find.byType(TextField), 'ab');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(controller.text, isEmpty);
      expect(closed, 0);
    });

    testWidgets('is a filled pill on surfaceContainerHighest', (tester) async {
      useWindow(tester, const Size(400, 800));
      await tester.pumpWidget(host(persistent(() {})));
      final decoration = tester
          .widget<TextField>(find.byType(TextField))
          .decoration!;
      final scheme = Theme.of(tester.element(find.byType(TextField)))
          .colorScheme;
      expect(decoration.filled, isTrue);
      expect(decoration.fillColor, scheme.surfaceContainerHighest);
    });
  });
}
