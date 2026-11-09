import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('tap and long press fire ($name)', (tester) async {
      var taps = 0, longs = 0;
      await tester.pumpWidget(host(
        Center(
          child: KPressable(
            onTap: () => taps++,
            onLongPress: () => longs++,
            child: const Padding(padding: EdgeInsets.all(16), child: Text('tile')),
          ),
        ),
        brightness: brightness,
        textScale: scale,
      ));
      await tester.tap(find.text('tile'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.longPress(find.text('tile'));
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(longs, 1);
    });
  }

  testWidgets('Enter activates a focused pressable', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(KPressable(onTap: () => taps++, child: const Text('tile'))));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('long press gives haptic feedback', (tester) async {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') calls.add(call.arguments as String? ?? "");
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.pumpWidget(host(KPressable(
      onLongPress: () {},
      child: const Text('tile'),
    )));
    await tester.longPress(find.text('tile'));
    await tester.pumpAndSettle();
    expect(calls, contains('HapticFeedbackType.selectionClick'));
  });
}
