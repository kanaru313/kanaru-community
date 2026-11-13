import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  const extremes = <String, Color>{
    'white': Color(0xFFFFFFFF),
    'pale yellow': Color(0xFFFFFFB0),
    'black': Color(0xFF000000),
    'deep blue': Color(0xFF000080),
    'red': Color(0xFFFF0000),
    'green': Color(0xFF00FF00),
    'blue': Color(0xFF0000FF),
  };

  for (final brightness in Brightness.values) {
    final scheme = buildKanaruTheme(brightness: brightness).colorScheme;
    for (final e in extremes.entries) {
      for (final palette in [
        [e.value],
        [e.value, e.value],
      ]) {
        test(
          '${e.key} x${palette.length} keeps both text colours readable (${brightness.name})',
          () {
            final stops = readableGradientStops(
              palette,
              base: scheme.surface,
              onSurface: scheme.onSurface,
              onSurfaceVariant: scheme.onSurfaceVariant,
              brightness: brightness,
            );
            for (final stop in stops) {
              final blend = Color.alphaBlend(stop, scheme.surface);
              expect(
                _contrast(scheme.onSurface, blend),
                greaterThanOrEqualTo(4.5),
              );
              expect(
                _contrast(scheme.onSurfaceVariant, blend),
                greaterThanOrEqualTo(4.5),
              );
            }
          },
        );
      }
    }

    test(
      'contrast is measured against base, not the surface (${brightness.name})',
      () {
        final base = scheme.surfaceContainerLow;
        final stops = readableGradientStops(
          [Colors.red, Colors.blue],
          base: base,
          onSurface: scheme.onSurface,
          onSurfaceVariant: scheme.onSurfaceVariant,
          brightness: brightness,
        );
        for (final stop in stops) {
          final blend = Color.alphaBlend(stop, base);
          expect(
            _contrast(scheme.onSurfaceVariant, blend),
            greaterThanOrEqualTo(4.5),
          );
        }
      },
    );
  }

  List<Color> stopsOf(
    List<Color> palette, [
    Brightness brightness = Brightness.dark,
  ]) {
    final s = buildKanaruTheme(brightness: brightness).colorScheme;
    return readableGradientStops(
      palette,
      base: s.surface,
      onSurface: s.onSurface,
      onSurfaceVariant: s.onSurfaceVariant,
      brightness: brightness,
    );
  }

  for (final (brightness, darker) in [
    (Brightness.dark, true),
    (Brightness.light, false),
  ]) {
    test('one colour gives itself and a shade toward the surface '
        '(${brightness.name})', () {
      const input = Color(0xFF4080C0);
      final stops = stopsOf([input], brightness);
      expect(stops, hasLength(2));
      expect(stops.first.r, input.r);
      expect(stops.first.g, input.g);
      expect(stops.first.b, input.b);
      final hsl = [
        for (final c in stops) HSLColor.fromColor(c.withValues(alpha: 1)),
      ];
      expect(
        hsl[1].lightness,
        darker ? lessThan(hsl[0].lightness) : greaterThan(hsl[0].lightness),
      );
      expect(hsl[1].hue, closeTo(hsl[0].hue, 1));
    });
  }

  test('six colours give at most four stops', () {
    final stops = stopsOf([for (var i = 0; i < 6; i++) Color(0xFF102030 + i)]);
    expect(stops, hasLength(maxGradientStops));
    expect(maxGradientStops, 4);
  });

  test('an empty palette gives two transparent stops', () {
    final stops = stopsOf(const []);
    expect(stops, hasLength(2));
    expect(stops.every((c) => c.a == 0), isTrue);
  });

  test('a readable colour keeps the starting tint', () {
    // Dark theme starts at 0.45: a dark cover colour needs no lowering.
    final stops = stopsOf([const Color(0xFF101010), const Color(0xFF101010)]);
    expect(stops.first.a, closeTo(0.45, 0.001));
  });
}
