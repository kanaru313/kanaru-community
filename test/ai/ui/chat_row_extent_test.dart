import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/ui/chat_row_extent.dart';
import 'package:material_ui/material_ui.dart';

/// Shrinks large sizes the way Android 14 font scaling does: not linear.
class _NonLinearScaler extends TextScaler {
  const _NonLinearScaler();

  @override
  double scale(double fontSize) => fontSize * 0.5 + 10;

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => 1;

  @override
  TextScaler clamp({double minScaleFactor = 0, double maxScaleFactor = 1e9}) =>
      this;

  @override
  bool operator ==(Object other) => other is _NonLinearScaler;

  @override
  int get hashCode => 1;
}

Future<double> _measure(
  WidgetTester tester,
  double Function(BuildContext) of,
) async {
  late double value;
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(textScaler: _NonLinearScaler()),
        child: Builder(
          builder: (context) {
            value = of(context);
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  return value;
}

void main() {
  testWidgets('a text row is the scaled size times the line height', (
    tester,
  ) async {
    // scale(12) = 16; 16 * 1.5 = 24, plus 8. (Scaling the product would give
    // scale(18) = 19 instead.)
    final extent = await _measure(
      tester,
      (c) => chatTextRowExtent(c, const TextStyle(fontSize: 12, height: 1.5)),
    );
    expect(extent, 32);
  });

  testWidgets('a song row grows by its two scaled lines past the cover', (
    tester,
  ) async {
    late TextTheme theme;
    final extent = await _measure(tester, (c) {
      theme = Theme.of(c).textTheme;
      return chatSongRowExtent(c, cover: 10, vertical: 6);
    });
    double line(TextStyle? s) =>
        ((s!.fontSize! * 0.5) + 10) * (s.height ?? 1.4);
    expect(
      extent,
      closeTo(line(theme.bodyMedium) + line(theme.bodySmall) + 12, 1e-9),
    );
  });
}
