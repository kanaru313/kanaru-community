import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/lyrics/domain/lyrics.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_display_prefs.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_line.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

final _fill = find.byKey(lyricsLineFillKey);

Future<ValueNotifier<int>> _pump(
  WidgetTester tester, {
  LyricsDim dim = LyricsDim.light,
  String text = 'Hello',
  bool disableAnimations = false,
}) async {
  final active = ValueNotifier<int>(-1);
  addTearDown(active.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildKanaruTheme(brightness: Brightness.light),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(disableAnimations: disableAnimations),
        child: app!,
      ),
      home: Scaffold(
        body: LyricsLine(
          index: 0,
          line: LyricLine(Duration.zero, text),
          active: active,
          onTap: () {},
          size: 25,
          dim: dim,
          align: LyricsAlign.start,
        ),
      ),
    ),
  );
  return active;
}

Color? _fillColor(WidgetTester tester) {
  final box = tester.widget<AnimatedContainer>(_fill).decoration;
  return (box! as BoxDecoration).color;
}

void main() {
  for (final dim in LyricsDim.values) {
    testWidgets('fill follows the current state with dim ${dim.name}', (
      tester,
    ) async {
      final active = await _pump(tester, dim: dim);
      final onSurface = Theme.of(tester.element(_fill)).colorScheme.onSurface;
      expect(_fillColor(tester)!.a, 0);
      active.value = 0;
      await tester.pumpAndSettle();
      expect(_fillColor(tester), onSurface.withValues(alpha: 0.08));
      active.value = 1;
      await tester.pumpAndSettle();
      expect(_fillColor(tester)!.a, 0);
    });
  }

  testWidgets('the fill has the medium radius', (tester) async {
    await _pump(tester);
    final box =
        tester.widget<AnimatedContainer>(_fill).decoration! as BoxDecoration;
    expect(box.borderRadius, KRadius.md);
  });

  testWidgets('a line keeps its height when it becomes current', (
    tester,
  ) async {
    final active = await _pump(tester);
    final before = tester.getSize(_fill);
    active.value = 0;
    await tester.pumpAndSettle();
    expect(tester.getSize(_fill), before);
  });

  testWidgets('animations off: the fill changes in one frame', (tester) async {
    final active = await _pump(tester, disableAnimations: true);
    active.value = 0;
    await tester.pump();
    await tester.pump();
    expect(_fillColor(tester)!.a, closeTo(0.08, 0.001));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('the current gap line is filled too', (tester) async {
    final active = await _pump(tester, text: '');
    active.value = 0;
    // The current gap pulses forever: pump past the fill animation.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(_fillColor(tester)!.a, closeTo(0.08, 0.001));
  });
}
