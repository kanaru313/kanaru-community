import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/src/widgets/k_clock_progress.dart';
import 'package:material_ui/material_ui.dart';

import 'support/fit.dart';
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
  testWidgets('number size follows what the text is, per shell', (
    tester,
  ) async {
    // figure, long clock (also 600+ minutes), words (bold).
    const cases = [
      ('23:41', 57.0, 45.0, FontWeight.w400),
      ('3', 57.0, 45.0, FontWeight.w400),
      ('2:05:09', 45.0, 36.0, FontWeight.w400),
      ('12:00:00', 45.0, 36.0, FontWeight.w400),
      ('album này', 36.0, 28.0, FontWeight.w700),
      ('bài này', 36.0, 28.0, FontWeight.w700),
    ];
    for (final (text, touch, desktop, weight) in cases) {
      for (final (size, want) in [
        (const Size(400, 800), touch),
        (const Size(1400, 900), desktop),
      ]) {
        useWindow(tester, size);
        await tester.pumpWidget(host(_clock(big: text)));
        await tester.pump();
        final style = tester.widget<Text>(find.text(text)).style!;
        expect(style.fontSize, want, reason: '$text at $size');
        expect(style.fontWeight, weight, reason: '$text weight');
      }
    }
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

  testWidgets(
    'segments: left ones full from the left, current drains, played empty',
    (tester) async {
      await tester.pumpWidget(
        host(_clock(segments: (count: 5, done: 2, currentFraction: 0.4))),
      );
      expect(_painter(tester).fills, [1.0, 1.0, 0.4, 0.0, 0.0]);
    },
  );

  testWidgets('segments: last track playing and nothing left', (tester) async {
    await tester.pumpWidget(
      host(_clock(segments: (count: 3, done: 2, currentFraction: 0.7))),
    );
    expect(_painter(tester).fills, [0.7, 0.0, 0.0]);
    await tester.pumpWidget(
      host(_clock(segments: (count: 3, done: 3, currentFraction: 0.7))),
    );
    expect(_painter(tester).fills, [0.0, 0.0, 0.0]);
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
      expectTextsFit(tester, find.byType(KClockProgress));
    });
  }

  for (final width in [320.0, 1400.0]) {
    for (final big in [
      '23:41',
      '2:05:09',
      '12:00:00',
      'album này',
      'bài này',
    ]) {
      testWidgets('200 % text, "$big", width $width: never clipped', (
        tester,
      ) async {
        useWindow(tester, Size(width, 900));
        await tester.pumpWidget(host(_clock(big: big), textScale: 2.0));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expectTextsFit(tester, find.byType(KClockProgress));
        expect(
          tester.getRect(find.text(big)).width,
          lessThanOrEqualTo(width - 32 + 0.5),
          reason: 'the number stays inside the 16 dp page padding',
        );
      });
    }
  }

  testWidgets('number grows with the scale up to 1.4 x only', (tester) async {
    useWindow(tester, const Size(1400, 900));
    Future<double> height(double scale) async {
      await tester.pumpWidget(host(_clock(), textScale: scale));
      await tester.pump();
      return tester.getSize(find.text('23:41')).height;
    }

    final one = await height(1.0);
    expect(await height(1.4), closeTo(one * 1.4, 1.5));
    expect(await height(2.0), closeTo(one * 1.4, 1.5));
  });

  testWidgets('reduced motion renders the same', (tester) async {
    useWindow(tester, const Size(320, 640));
    await tester.pumpWidget(
      host(_clock(big: 'hàng đợi'), textScale: 2.0, reduceMotion: true),
    );
    expect(tester.takeException(), isNull);
    expectTextsFit(tester, find.byType(KClockProgress));
  });

  testWidgets('leading and trailing sit on the number line, 16 dp away', (
    tester,
  ) async {
    useWindow(tester, const Size(400, 600));
    await tester.pumpWidget(
      host(
        KClockProgress(
          label: 'Ngủ sau',
          bigText: '23:41',
          statusLabel: 'Ngủ sau 24 phút',
          leading: const SizedBox(key: Key('l'), width: 48, height: 48),
          trailing: const SizedBox(key: Key('t'), width: 48, height: 48),
        ),
      ),
    );
    final l = tester.getRect(find.byKey(const Key('l')));
    final t = tester.getRect(find.byKey(const Key('t')));
    final number = tester.getRect(find.text('23:41'));
    expect(number.left - l.right, greaterThanOrEqualTo(16));
    expect(t.left - number.right, greaterThanOrEqualTo(16));
    expect(l.center.dy, closeTo(t.center.dy, 0.5));
    expect(l.center.dy, closeTo(number.center.dy, 1));
  });

  testWidgets('a lone end text is centred under the bar', (tester) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 300,
          child: KClockProgress(
            label: 'Ngủ sau',
            bigText: '23:41',
            statusLabel: 'Ngủ sau 24 phút',
            fraction: 0.5,
            endText: 'Dừng lúc 23:40',
          ),
        ),
      ),
    );
    final box = tester.getRect(find.byType(KClockProgress));
    final text = tester.getCenter(find.text('Dừng lúc 23:40'));
    expect(text.dx, closeTo(box.center.dx, 1));
  });
}
