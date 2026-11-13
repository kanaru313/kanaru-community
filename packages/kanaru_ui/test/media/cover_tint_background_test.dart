import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/host.dart';

const _red = [Color(0xFFFF0000), Color(0xFFCC0000)];
const _green = [Color(0xFF00FF00), Color(0xFF00CC00)];

Finder get _layers => find.descendant(
  of: find.byType(CoverTintBackground),
  matching: find.byType(DecoratedBox),
);

Finder get _baseBox => find.descendant(
  of: find.byType(CoverTintBackground),
  matching: find.byType(ColoredBox),
);

LinearGradient _gradient(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(_layers);
  return (box.decoration as BoxDecoration).gradient! as LinearGradient;
}

Widget _tint(
  List<Color>? palette, {
  bool loading = false,
  bool fadeIn = false,
  double strength = 1,
  Color? base,
  bool reduceMotion = false,
  Brightness brightness = Brightness.light,
  double scale = 1,
  Widget child = const Text('child'),
}) => host(
  CoverTintBackground(
    palette: palette,
    loading: loading,
    fadeIn: fadeIn,
    strength: strength,
    base: base,
    child: child,
  ),
  reduceMotion: reduceMotion,
  brightness: brightness,
  textScale: scale,
);

void main() {
  test('the transition is 300 ms', () {
    expect(coverTintTransition, const Duration(milliseconds: 300));
  });

  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('paints a diagonal gradient of 4 stops ($name)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _tint(_red, brightness: brightness, scale: scale),
      );
      await tester.pumpAndSettle();
      final g = _gradient(tester);
      expect(g.begin, Alignment.topLeft);
      expect(g.end, Alignment.bottomRight);
      expect(g.colors, hasLength(maxGradientStops));
      expect(g.colors.first.a, greaterThan(0));
      expect(find.text('child'), findsOneWidget);
    });
  }

  testWidgets('no bottom fade: the last stop is not the surface', (
    tester,
  ) async {
    await tester.pumpWidget(_tint(_red));
    await tester.pumpAndSettle();
    final surface = Theme.of(tester.element(find.text('child')))
        .colorScheme
        .surface;
    expect(_gradient(tester).colors.last, isNot(surface));
    expect(_gradient(tester).colors.last.a, greaterThan(0));
  });

  testWidgets('the gradient layer sits in a RepaintBoundary', (tester) async {
    await tester.pumpWidget(_tint(_red));
    expect(
      find.ancestor(of: _layers, matching: find.byType(RepaintBoundary)),
      findsWidgets,
    );
  });

  testWidgets('base is painted under the gradient, default is the surface', (
    tester,
  ) async {
    const base = Color(0xFF123456);
    await tester.pumpWidget(_tint(_red, base: base));
    expect(tester.widget<ColoredBox>(_baseBox).color, base);
    await tester.pumpWidget(_tint(_red));
    final surface = Theme.of(tester.element(find.text('child')))
        .colorScheme
        .surface;
    expect(tester.widget<ColoredBox>(_baseBox).color, surface);
  });

  testWidgets('a new palette moves over time, not at once', (tester) async {
    await tester.pumpWidget(_tint(_red));
    await tester.pumpAndSettle();
    final before = _gradient(tester).colors.first;
    await tester.pumpWidget(_tint(_green));
    await tester.pump();
    await tester.pump(coverTintTransition ~/ 2);
    final mid = _gradient(tester).colors.first;
    await tester.pumpAndSettle();
    final after = _gradient(tester).colors.first;
    expect(mid, isNot(before));
    expect(mid, isNot(after));
  });

  testWidgets('losing the colours fades alpha only, keeping the hue', (
    tester,
  ) async {
    await tester.pumpWidget(_tint(_red));
    await tester.pumpAndSettle();
    final tinted = _gradient(tester).colors.first;
    await tester.pumpWidget(_tint(null));
    await tester.pump();
    await tester.pump(coverTintTransition ~/ 2);
    final mid = _gradient(tester).colors.first;
    expect(mid.a, lessThan(tinted.a));
    expect(mid.a, greaterThan(0));
    expect(mid.r, closeTo(tinted.r, 0.001));
    expect(mid.g, closeTo(tinted.g, 0.001));
    expect(mid.b, closeTo(tinted.b, 0.001));
    await tester.pumpAndSettle();
    expect(_gradient(tester).colors.first.a, 0);
  });

  testWidgets('reduced motion jumps at once', (tester) async {
    await tester.pumpWidget(_tint(_red, reduceMotion: true));
    await tester.pumpWidget(_tint(_green, reduceMotion: true));
    await tester.pump();
    final instant = _gradient(tester).colors.first;
    await tester.pumpAndSettle();
    expect(_gradient(tester).colors.first, instant);
    expect(instant.g, greaterThan(instant.r));
  });

  testWidgets('a brightness switch restarts at the new stops', (tester) async {
    Widget themed(Brightness b) => host(
      Theme(
        data: buildKanaruTheme(brightness: b),
        child: const CoverTintBackground(palette: _red, child: Text('child')),
      ),
    );
    await tester.pumpWidget(themed(Brightness.light));
    await tester.pumpAndSettle();
    final light = _gradient(tester).colors;
    await tester.pumpWidget(themed(Brightness.dark));
    await tester.pump();
    final first = _gradient(tester).colors;
    // At once the dark stops, not a glide from the light ones.
    expect(first, isNot(light));
    await tester.pumpAndSettle();
    expect(_gradient(tester).colors, first);
  });

  testWidgets('the child is not rebuilt by the tween', (tester) async {
    var builds = 0;
    final child = Builder(
      builder: (context) {
        builds++;
        return const Text('child');
      },
    );
    await tester.pumpWidget(_tint(_red, child: child));
    await tester.pumpAndSettle();
    final seen = builds;
    await tester.pumpWidget(_tint(_green, child: child));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(builds, seen);
  });

  testWidgets('strength scales alpha on the next frame, keeping the tween', (
    tester,
  ) async {
    await tester.pumpWidget(_tint(_red));
    await tester.pumpAndSettle();
    final full = _gradient(tester).colors;
    await tester.pumpWidget(_tint(_red, strength: 0.5));
    await tester.pump();
    final half = _gradient(tester).colors;
    for (var i = 0; i < full.length; i++) {
      expect(half[i].a, closeTo(full[i].a * 0.5, 0.01));
      expect(half[i].r, closeTo(full[i].r, 0.001));
    }
    // Mid colour tween: a strength change does not restart it.
    await tester.pumpWidget(_tint(_green, strength: 0.5));
    await tester.pump();
    await tester.pump(coverTintTransition ~/ 2);
    final mid = _gradient(tester).colors.first;
    await tester.pumpWidget(_tint(_green, strength: 1));
    await tester.pump();
    final after = _gradient(tester).colors.first;
    expect(after.g, closeTo(mid.g, 0.05));
    expect(after.a, greaterThan(mid.a));
  });

  testWidgets('fadeIn draws nothing before the first palette, then fades', (
    tester,
  ) async {
    await tester.pumpWidget(_tint(null, fadeIn: true));
    expect(_layers, findsNothing);
    expect(find.text('child'), findsOneWidget);
    await tester.pumpWidget(_tint(_red, fadeIn: true));
    await tester.pump();
    expect(_gradient(tester).colors.first.a, 0);
    await tester.pump(coverTintTransition ~/ 2);
    final mid = _gradient(tester).colors.first.a;
    await tester.pumpAndSettle();
    final end = _gradient(tester).colors.first.a;
    expect(mid, greaterThan(0));
    expect(mid, lessThan(end));
  });

  testWidgets('fadeIn with a palette from the start still fades in', (
    tester,
  ) async {
    await tester.pumpWidget(_tint(_red, fadeIn: true));
    await tester.pump();
    expect(_gradient(tester).colors.first.a, 0);
    await tester.pumpAndSettle();
    expect(_gradient(tester).colors.first.a, greaterThan(0));
  });

  testWidgets('palette A, loading, then B: never disappears, tweens A to B', (
    tester,
  ) async {
    await tester.pumpWidget(_tint(_red, fadeIn: true));
    await tester.pumpAndSettle();
    final a = _gradient(tester).colors.first;
    await tester.pumpWidget(_tint(null, loading: true, fadeIn: true));
    await tester.pump(coverTintTransition);
    expect(_gradient(tester).colors.first, a);
    await tester.pumpWidget(_tint(_green, fadeIn: true));
    await tester.pump();
    await tester.pump(coverTintTransition ~/ 2);
    final mid = _gradient(tester).colors.first;
    expect(mid.a, greaterThan(0));
    expect(mid, isNot(a));
    await tester.pumpAndSettle();
    final b = _gradient(tester).colors.first;
    expect(b, isNot(mid));
    expect(b.g, greaterThan(b.r));
  });

  testWidgets('a settled null after a palette fades out', (tester) async {
    await tester.pumpWidget(_tint(_red, fadeIn: true));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_tint(null, fadeIn: true));
    await tester.pumpAndSettle();
    expect(_gradient(tester).colors.first.a, 0);
  });

  testWidgets('no palette without fadeIn is a flat base', (tester) async {
    await tester.pumpWidget(_tint(null));
    await tester.pumpAndSettle();
    final surface = Theme.of(tester.element(find.text('child')))
        .colorScheme
        .surface;
    expect(tester.widget<ColoredBox>(_baseBox).color, surface);
    expect(_gradient(tester).colors.every((c) => c.a == 0), isTrue);
  });

  for (final fadeIn in [true, false]) {
    testWidgets('palette, settled none, then loading stays untinted '
        '(fadeIn: $fadeIn)', (tester) async {
      await tester.pumpWidget(_tint(_red, fadeIn: fadeIn));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_tint(null, fadeIn: fadeIn));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_tint(null, loading: true, fadeIn: fadeIn));
      await tester.pump();
      await tester.pump(coverTintTransition ~/ 2);
      expect(_gradient(tester).colors.every((c) => c.a == 0), isTrue);
    });
  }

  testWidgets('fadeIn: palette A, settled none, then B tweens in', (
    tester,
  ) async {
    await tester.pumpWidget(_tint(_red, fadeIn: true));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_tint(null, fadeIn: true));
    await tester.pumpAndSettle();
    expect(_gradient(tester).colors.first.a, 0);
    await tester.pumpWidget(_tint(_green, fadeIn: true));
    await tester.pump();
    await tester.pump(coverTintTransition ~/ 2);
    final mid = _gradient(tester).colors.first;
    await tester.pumpAndSettle();
    final end = _gradient(tester).colors.first;
    expect(mid.a, greaterThan(0));
    expect(mid.a, lessThan(end.a));
  });
}
