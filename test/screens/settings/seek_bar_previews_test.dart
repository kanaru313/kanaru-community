import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/screens/settings/ui/appearance/seek_bar_previews.dart';

void main() {
  testWidgets('every waveform bar has a visible size', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: WaveformSeekPreview())),
      ),
    );
    final bars = find.descendant(
      of: find.byType(WaveformSeekPreview),
      matching: find.byType(DecoratedBox),
    );
    expect(bars, findsNWidgets(44));
    for (final bar in bars.evaluate()) {
      final size = tester.getSize(find.byWidget(bar.widget));
      expect(size.width, greaterThan(0));
      expect(size.height, greaterThan(0));
    }
  });
}
