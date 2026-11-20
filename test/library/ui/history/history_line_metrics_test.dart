import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/ui/history/history_line_metrics.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

/// The text theme the app resolves (the sizes come from the app's theme).
Future<TextTheme> _theme(WidgetTester tester) async {
  late TextTheme theme;
  await tester.pumpWidget(
    MaterialApp(
      theme: buildKanaruTheme(brightness: Brightness.light),
      home: Builder(
        builder: (context) {
          theme = Theme.of(context).textTheme;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return theme;
}

double _line(TextStyle? s, double scale) =>
    (s!.fontSize! * scale * HistoryLineMetrics.lineHeight).ceilToDouble();

void main() {
  testWidgets('a row is a media card slot, the older-year line the same', (
    tester,
  ) async {
    final theme = await _theme(tester);
    for (final scale in [1.0, 1.5, 2.0]) {
      final m = HistoryLineMetrics.of(theme, TextScaler.linear(scale));
      expect(m.row, KMediaCard.extentOf(TextScaler.linear(scale)));
      expect(m.footer, m.row);
    }
  });

  testWidgets('the day bar is two scaled text lines plus fixed padding', (
    tester,
  ) async {
    final theme = await _theme(tester);
    for (final scale in [1.0, 2.0]) {
      final expected =
          2 * HistoryLineMetrics.dayBarPadding +
          _line(theme.titleSmall, scale) +
          _line(theme.bodySmall, scale);
      final m = HistoryLineMetrics.of(theme, TextScaler.linear(scale));
      expect(m.dayBar, closeTo(expected, 0.001));
    }
  });

  testWidgets(
    'at the default scale the bar is a whole 57 dp, at 2.0 it grows',
    (tester) async {
      final theme = await _theme(tester);
      final one = HistoryLineMetrics.of(theme, TextScaler.noScaling).dayBar;
      final two = HistoryLineMetrics.of(
        theme,
        const TextScaler.linear(2),
      ).dayBar;
      expect(one, 57);
      expect(two, two.roundToDouble());
      expect(two, greaterThan(one * 1.5));
    },
  );
}
