import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

Widget _region(List<Offset?> opened, {bool longPressOpens = true}) => Center(
      child: KContextRegion(
        longPressOpens: longPressOpens,
        onOpen: opened.add,
        child: TextButton(onPressed: () {}, child: const Text('row')),
      ),
    );

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('right click opens with the pointer position ($name)', (tester) async {
      final opened = <Offset?>[];
      await tester.pumpWidget(host(_region(opened), brightness: brightness, textScale: scale));
      await tester.tap(find.text('row'), buttons: kSecondaryMouseButton);
      await tester.pump();
      expect(opened, hasLength(1));
      expect(opened.single, isNotNull);
    });
  }

  testWidgets('long press opens by default', (tester) async {
    final opened = <Offset?>[];
    await tester.pumpWidget(host(_region(opened)));
    await tester.longPress(find.text('row'));
    expect(opened, hasLength(1));
  });

  testWidgets('longPressOpens false ignores long press', (tester) async {
    final opened = <Offset?>[];
    await tester.pumpWidget(host(_region(opened, longPressOpens: false)));
    await tester.longPress(find.text('row'));
    expect(opened, isEmpty);
  });

  testWidgets('Menu key and Shift+F10 open with a null position', (tester) async {
    final opened = <Offset?>[];
    await tester.pumpWidget(host(_region(opened)));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab); // focus the button inside
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
    expect(opened, [null]);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.f10);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(opened, [null, null]);

    await tester.sendKeyEvent(LogicalKeyboardKey.f10); // without Shift: ignored
    expect(opened, hasLength(2));
  });
}
