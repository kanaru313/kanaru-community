import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/seek_bar_style.dart';
import 'package:kanaru/src/screens/settings/ui/appearance/seek_bar_previews.dart';

void main() {
  for (final style in SeekBarStyle.values) {
    testWidgets('the ${style.name} preview draws and schedules no frames', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: SeekStylePreview(style: style),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      final size = tester.getSize(find.byType(SeekStylePreview));
      expect(size.width, 300);
      expect(size.height, greaterThan(0));
      expect(
        tester.binding.hasScheduledFrame,
        isFalse,
        reason: 'a settings preview must stay still',
      );
    });
  }

  testWidgets('a preview takes no input and has no semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: SeekStylePreview(style: SeekBarStyle.bars),
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel(RegExp('.+')), findsNothing);
    handle.dispose();
  });
}
