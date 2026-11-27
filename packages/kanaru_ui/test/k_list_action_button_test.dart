import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

Widget _button({VoidCallback? onPressed, String? hint}) => KListActionButton(
  label: 'Cuộc trò chuyện mới',
  icon: KIcons.add,
  shortcutHint: hint,
  onPressed: onPressed,
);

void main() {
  testWidgets('reads as an enabled button named by its label and taps', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(host(_button(onPressed: () => taps++)));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Cuộc trò chuyện mới')),
      isSemantics(
        isButton: true,
        isFocusable: true,
        hasEnabledState: true,
        isEnabled: true,
      ),
    );
    await tester.tap(find.text('Cuộc trò chuyện mới'));
    expect(taps, 1);
    semantics.dispose();
  });

  testWidgets('onPressed null = disabled: no tap, reported disabled', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(host(_button()));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Cuộc trò chuyện mới')),
      isSemantics(
        isButton: true,
        isFocusable: false,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    await tester.tap(find.text('Cuộc trò chuyện mới'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('shows the shortcut hint only when given', (tester) async {
    await tester.pumpWidget(host(_button()));
    expect(find.text('Ctrl+Shift+O'), findsNothing);
    await tester.pumpWidget(host(_button(hint: 'Ctrl+Shift+O')));
    expect(find.text('Ctrl+Shift+O'), findsOneWidget);
  });

  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('layout: inset by 8, at least 48 tall, full width ($name)', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          _button(onPressed: () {}, hint: 'Ctrl+Shift+O'),
          brightness: brightness,
          textScale: scale,
        ),
      );
      final box = tester.getRect(
        find.descendant(
          of: find.byType(KListActionButton),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final screen = tester.getRect(find.byType(Scaffold));
      expect(box.height, greaterThanOrEqualTo(KLayout.minTarget));
      expect(box.left - screen.left, KSpace.x2);
      expect(screen.right - box.right, KSpace.x2);
      expect(tester.takeException(), isNull);
    });
  }
}
