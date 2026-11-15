import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:kanaru_ui/src/widgets/k_check_mark_painter.dart';

Widget _host(
  KCheckState s, {
  bool noAnim = false,
  KCheckMarkStyle style = KCheckMarkStyle.surface,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: noAnim),
    child: Center(
      child: KCheckMark(state: s, style: style),
    ),
  ),
);

KCheckMarkPainter _painter(WidgetTester t) {
  final cp = t.widget<CustomPaint>(
    find.descendant(
      of: find.byType(KCheckMark),
      matching: find.byType(CustomPaint),
    ),
  );
  return cp.painter! as KCheckMarkPainter;
}

void main() {
  testWidgets('colours come from the app theme (follows the playing cover)', (
    t,
  ) async {
    const seed = Color(0xFF2E7D32);
    final scheme = ColorScheme.fromSeed(seedColor: seed);
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: scheme),
        home: const Center(child: KCheckMark(state: KCheckState.on)),
      ),
    );
    expect(_painter(t).discColor, scheme.primary);
    expect(_painter(t).tickColor, scheme.onPrimary);
  });

  testWidgets('first build on paints final state, no animation, no pulse', (
    t,
  ) async {
    await t.pumpWidget(_host(KCheckState.on));
    expect(t.hasRunningAnimations, isFalse);
    expect(_painter(t).pulse, isFalse);
    expect(_painter(t).progress.value, 1);
  });

  testWidgets('off -> on runs ~480 ms with pulse and settles', (t) async {
    await t.pumpWidget(_host(KCheckState.off));
    await t.pumpWidget(_host(KCheckState.on));
    expect(_painter(t).pulse, isTrue);
    await t.pump(const Duration(milliseconds: 400));
    expect(t.hasRunningAnimations, isTrue);
    await t.pump(const Duration(milliseconds: 100));
    expect(t.hasRunningAnimations, isFalse);
    expect(_painter(t).progress.value, 1);
  });

  testWidgets('on -> off runs ~220 ms', (t) async {
    await t.pumpWidget(_host(KCheckState.on));
    await t.pumpWidget(_host(KCheckState.off));
    await t.pump(const Duration(milliseconds: 150));
    expect(t.hasRunningAnimations, isTrue);
    await t.pump(const Duration(milliseconds: 100));
    expect(t.hasRunningAnimations, isFalse);
    expect(_painter(t).progress.value, 0);
  });

  testWidgets('disableAnimations jumps to end state', (t) async {
    await t.pumpWidget(_host(KCheckState.off, noAnim: true));
    await t.pumpWidget(_host(KCheckState.on, noAnim: true));
    expect(t.hasRunningAnimations, isFalse);
    expect(_painter(t).progress.value, 1);
    expect(_painter(t).pulse, isFalse);
  });

  testWidgets('on -> partial -> on keeps the disc', (t) async {
    await t.pumpWidget(_host(KCheckState.on));
    await t.pumpWidget(_host(KCheckState.partial));
    await t.pump(const Duration(milliseconds: 100));
    expect(_painter(t).progress.value, 1);
    await t.pump(const Duration(milliseconds: 200));
    expect(_painter(t).morph.value, 1);
    await t.pumpWidget(_host(KCheckState.on));
    await t.pump(const Duration(milliseconds: 300));
    expect(_painter(t).progress.value, 1);
    expect(_painter(t).morph.value, 0);
    expect(t.hasRunningAnimations, isFalse);
  });

  testWidgets('shouldRepaint false for identical inputs', (t) async {
    await t.pumpWidget(_host(KCheckState.on));
    final a = _painter(t);
    final b = KCheckMarkPainter(
      progress: a.progress,
      morph: a.morph,
      reversing: a.reversing,
      pulse: a.pulse,
      ringColor: a.ringColor,
      discColor: a.discColor,
      tickColor: a.tickColor,
    );
    expect(b.shouldRepaint(a), isFalse);
  });

  testWidgets('disposed mid-animation without ticker leak', (t) async {
    await t.pumpWidget(_host(KCheckState.off));
    await t.pumpWidget(_host(KCheckState.on));
    await t.pump(const Duration(milliseconds: 100));
    await t.pumpWidget(const SizedBox());
    expect(t.hasRunningAnimations, isFalse);
  });

  group('plain style', () {
    testWidgets('paints the tick only, in primary, with no pulse', (t) async {
      await t.pumpWidget(_host(KCheckState.off, style: KCheckMarkStyle.plain));
      await t.pumpWidget(_host(KCheckState.on, style: KCheckMarkStyle.plain));
      final p = _painter(t);
      expect(p.tickOnly, isTrue);
      expect(p.pulse, isFalse);
      final cs = Theme.of(t.element(find.byType(KCheckMark))).colorScheme;
      expect(p.tickColor, cs.primary);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });

    testWidgets('on -> partial -> off settles without error', (t) async {
      for (final s in [KCheckState.on, KCheckState.partial, KCheckState.off]) {
        await t.pumpWidget(_host(s, style: KCheckMarkStyle.plain));
        await t.pumpAndSettle();
      }
      expect(t.takeException(), isNull);
    });

    testWidgets('surface style still paints ring and disc', (t) async {
      await t.pumpWidget(_host(KCheckState.on));
      expect(_painter(t).tickOnly, isFalse);
    });
  });

  testWidgets('toggling off mid-animation reverses from the current value', (
    t,
  ) async {
    await t.pumpWidget(_host(KCheckState.off));
    await t.pumpWidget(_host(KCheckState.on));
    await t.pump(const Duration(milliseconds: 120));
    final mid = _painter(t).progress.value;
    expect(mid, inInclusiveRange(0.1, 0.9));
    await t.pumpWidget(_host(KCheckState.off));
    expect(_painter(t).progress.value, closeTo(mid, 0.02));
    var last = _painter(t).progress.value;
    for (var i = 0; i < 4; i++) {
      await t.pump(const Duration(milliseconds: 10));
      final v = _painter(t).progress.value;
      expect(v, lessThan(last));
      last = v;
    }
    await t.pumpAndSettle();
    expect(_painter(t).progress.value, 0);
  });
}
