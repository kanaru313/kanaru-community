import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../support/host.dart';

LinearGradient _gradient(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byType(CoverTintBackground),
      matching: find.byType(DecoratedBox),
    ),
  );
  return (box.decoration as BoxDecoration).gradient! as LinearGradient;
}

Widget _tint(
  Color? a,
  Color? b, {
  bool reduceMotion = false,
  Brightness brightness = Brightness.light,
  double scale = 1,
}) => host(
  CoverTintBackground(first: a, second: b, child: const Text('child')),
  reduceMotion: reduceMotion,
  brightness: brightness,
  textScale: scale,
);

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('paints a gradient that ends in the surface ($name)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _tint(Colors.red, Colors.blue, brightness: brightness, scale: scale),
      );
      await tester.pumpAndSettle();
      final surface = Theme.of(tester.element(find.text('child')))
          .colorScheme
          .surface;
      final g = _gradient(tester);
      expect(g.colors.last, surface);
      expect(g.colors.first, isNot(surface));
      expect(find.text('child'), findsOneWidget);
    });
  }

  testWidgets('tints are darker than the cover colours', (tester) async {
    await tester.pumpWidget(
      _tint(const Color(0xFFFF0000), const Color(0xFF0000FF)),
    );
    await tester.pumpAndSettle();
    final g = _gradient(tester);
    expect(HSLColor.fromColor(g.colors[0]).lightness, lessThan(0.5));
  });

  testWidgets('a new colour moves over time, not at once', (tester) async {
    await tester.pumpWidget(_tint(Colors.red, Colors.red));
    await tester.pumpAndSettle();
    final before = _gradient(tester).colors.first;
    await tester.pumpWidget(_tint(Colors.green, Colors.green));
    await tester.pump(const Duration(milliseconds: 350));
    final mid = _gradient(tester).colors.first;
    await tester.pumpAndSettle();
    final after = _gradient(tester).colors.first;
    expect(mid, isNot(before));
    expect(mid, isNot(after));
  });

  testWidgets('losing the colours fades alpha only, keeping the hue', (
    tester,
  ) async {
    await tester.pumpWidget(_tint(Colors.red, Colors.red));
    await tester.pumpAndSettle();
    final tinted = _gradient(tester).colors.first;
    await tester.pumpWidget(_tint(null, null));
    await tester.pump(const Duration(milliseconds: 350));
    final mid = _gradient(tester).colors.first;
    // Between tinted and surface along one line: red channel never leaves the
    // range of the two ends (no detour through another hue).
    final surface = Theme.of(tester.element(find.text('child')))
        .colorScheme
        .surface;
    for (final channel in [
      (Color c) => c.r,
      (Color c) => c.g,
      (Color c) => c.b,
    ]) {
      final lo = channel(tinted) < channel(surface)
          ? channel(tinted)
          : channel(surface);
      final hi = channel(tinted) > channel(surface)
          ? channel(tinted)
          : channel(surface);
      expect(channel(mid), inInclusiveRange(lo - 0.01, hi + 0.01));
    }
    await tester.pumpAndSettle();
    expect(_gradient(tester).colors.first, surface);
  });

  testWidgets('reduced motion jumps at once', (tester) async {
    await tester.pumpWidget(_tint(Colors.red, Colors.red, reduceMotion: true));
    await tester.pumpWidget(
      _tint(Colors.green, Colors.green, reduceMotion: true),
    );
    await tester.pump();
    final instant = _gradient(tester).colors.first;
    await tester.pumpAndSettle();
    expect(_gradient(tester).colors.first, instant);
  });
}
