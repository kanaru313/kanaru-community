import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import 'support/host.dart';

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('playing animates, paused shows pause glyph ($name)', (tester) async {
      await tester.pumpWidget(host(
        const KEqualizerIcon(playing: true),
        brightness: brightness,
        textScale: scale,
      ));
      expect(find.byIcon(KIcons.pause), findsNothing);
      expect(tester.hasRunningAnimations, isTrue);

      await tester.pumpWidget(host(
        const KEqualizerIcon(playing: false),
        brightness: brightness,
        textScale: scale,
      ));
      expect(find.byIcon(KIcons.pause), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });
  }

  testWidgets('reduced motion draws still bars', (tester) async {
    await tester.pumpWidget(host(
      const KEqualizerIcon(playing: true),
      reduceMotion: true,
    ));
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.byIcon(KIcons.pause), findsNothing);
  });
}
