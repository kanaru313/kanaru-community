import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

void main() {
  testWidgets('enabled: taps, full width, at least the touch target tall', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        Column(
          key: const Key('col'),
          children: [KPromptButton(label: 'Say hi', onTap: () => taps++)],
        ),
      ),
    );
    await tester.tap(find.text('Say hi'));
    expect(taps, 1);
    final size = tester.getSize(find.byType(KPromptButton));
    expect(size.height, greaterThanOrEqualTo(KLayout.minTarget));
    expect(size.width, tester.getSize(find.byKey(const Key('col'))).width);
  });

  testWidgets('disabled: inert, reason shown and spoken', (tester) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      host(
        KPromptButton(
          label: 'Lyrics',
          reason: 'No song playing',
          enabled: false,
          onTap: () => taps++,
        ),
      ),
    );
    await tester.tap(find.text('Lyrics'), warnIfMissed: false);
    expect(taps, 0);
    expect(find.text('No song playing'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Lyrics. No song playing')),
      isSemantics(isButton: true, isEnabled: false),
    );
    semantics.dispose();
  });
}
