import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/src/widgets/k_clock_progress.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

Widget _clock({
  String big = '23:41',
  double fraction = 0.5,
  KClockSegments? segments,
  bool held = false,
}) => Padding(
  padding: const EdgeInsets.all(16),
  child: KClockProgress(
    label: 'Ngủ sau',
    bigText: big,
    statusLabel: 'Ngủ sau 24 phút',
    fraction: fraction,
    segments: segments,
    startText: 'Đặt 45 phút',
    endText: 'Dừng lúc 23:40',
    held: held,
  ),
);

ClockBarPainter _painter(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(KClockProgress),
      matching: find.byType(CustomPaint),
    ),
  );
  return paint.painter! as ClockBarPainter;
}

void main() {
  test('number size by shell and length', () {
    expect(KClockProgress.numberSize(desktop: false, length: 5), 57);
    expect(KClockProgress.numberSize(desktop: false, length: 7), 45);
    expect(KClockProgress.numberSize(desktop: false, length: 9), 36);
    expect(KClockProgress.numberSize(desktop: true, length: 4), 45);
    expect(KClockProgress.numberSize(desktop: true, length: 7), 36);
    expect(KClockProgress.numberSize(desktop: true, length: 9), 28);
  });

  testWidgets('fraction is clamped and NaN is 0', (tester) async {
    for (final (input, want) in [
      (1.7, 1.0),
      (-3.0, 0.0),
      (double.nan, 0.0),
      (0.25, 0.25),
    ]) {
      await tester.pumpWidget(host(_clock(fraction: input)));
      expect(_painter(tester).fills, [want]);
    }
  });

  testWidgets('segments: played empty, current drains, rest full', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(_clock(segments: (count: 5, done: 2, currentFraction: 0.4))),
    );
    expect(_painter(tester).fills, [0.0, 0.0, 0.4, 1.0, 1.0]);
  });

  testWidgets('held: number 55 %, bar outline', (tester) async {
    await tester.pumpWidget(host(_clock()));
    final scheme = Theme.of(tester.element(find.byType(KClockProgress)))
        .colorScheme;
    expect(_painter(tester).fill, scheme.primary);
    await tester.pumpWidget(host(_clock(held: true)));
    expect(_painter(tester).fill, scheme.outline);
    final num = tester.widget<Text>(find.text('23:41'));
    expect(num.style!.color!.a, closeTo(0.55, 0.01));
  });

  testWidgets('big number is not in semantics; hidden status is, not live', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(_clock()));
    expect(find.bySemanticsLabel('23:41'), findsNothing);
    final status = tester.getSemantics(
      find.bySemanticsLabel('Ngủ sau 24 phút'),
    );
    expect(status.flagsCollection.isLiveRegion, isFalse);
    handle.dispose();
  });

  testWidgets('number is 57 on touch, 45 on desktop', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_clock()));
    expect(tester.widget<Text>(find.text('23:41')).style!.fontSize, 57);
    useWindow(tester, const Size(1400, 900));
    await tester.pumpWidget(host(_clock()));
    await tester.pump();
    expect(tester.widget<Text>(find.text('23:41')).style!.fontSize, 45);
  });

  for (final v in hostVariants) {
    testWidgets('renders in ${v.$1} at 320 width', (tester) async {
      useWindow(tester, const Size(320, 640));
      await tester.pumpWidget(
        host(
          _clock(big: '2:05:09'),
          brightness: v.$2,
          textScale: v.$3,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('200 % text, long number and reduced motion do not overflow', (
    tester,
  ) async {
    useWindow(tester, const Size(320, 640));
    await tester.pumpWidget(
      host(_clock(big: 'hàng đợi'), textScale: 2.0, reduceMotion: true),
    );
    expect(tester.takeException(), isNull);
  });
}
