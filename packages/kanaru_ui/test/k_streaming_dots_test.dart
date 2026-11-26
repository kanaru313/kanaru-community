import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

double _dotY(WidgetTester tester, int i) => tester
    .getTopLeft(
      find.descendant(
        of: find.byKey(KStreamingDots.dotKey(i)),
        matching: find.byType(Container),
      ),
    )
    .dy;

void main() {
  testWidgets('animates by default', (tester) async {
    await tester.pumpWidget(host(const KStreamingDots(label: 'Đang trả lời')));
    final rest = _dotY(tester, 0);
    await tester.pump(KMotion.streamingDots * 0.25);
    expect(_dotY(tester, 0), lessThan(rest - 4));
    await tester.pump(KMotion.streamingDots * 0.25);
    expect(_dotY(tester, 0), closeTo(rest, 0.01));
    // The dots rise in turn: when the first is up the last has not started.
    await tester.pump(KMotion.streamingDots * 0.75);
    expect(_dotY(tester, 2), closeTo(rest, 0.01));
  });

  testWidgets('static when disableAnimations', (tester) async {
    await tester.pumpWidget(
      host(const KStreamingDots(label: 'Đang trả lời'), reduceMotion: true),
    );
    final before = [for (var i = 0; i < 3; i++) _dotY(tester, i)];
    await tester.pump(KMotion.streamingDots * 0.25);
    expect([for (var i = 0; i < 3; i++) _dotY(tester, i)], before);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('keeps its phase across a rebuild', (tester) async {
    await tester.pumpWidget(host(const KStreamingDots(label: 'Đang trả lời')));
    await tester.pump(KMotion.streamingDots * 0.25);
    final up = _dotY(tester, 0);
    await tester.pumpWidget(host(const KStreamingDots(label: 'Đang trả lời')));
    expect(_dotY(tester, 0), closeTo(up, 0.01));
  });

  testWidgets('is a live status with the given label and keeps size at 200 %', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(const KStreamingDots(label: 'Đang trả lời'), textScale: 2.0),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Đang trả lời')),
      isSemantics(label: 'Đang trả lời', isLiveRegion: true),
    );
    expect(
      tester.getSize(find.byKey(KStreamingDots.dotKey(0))),
      const Size(6, 6),
    );
    handle.dispose();
  });
}
