import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_color_utilities/material_color_utilities.dart'
    show Cam16, Hct;
import 'package:material_ui/material_ui.dart';

double _dist(Color a, Color b) =>
    Cam16.fromInt(a.toARGB32()).distance(Cam16.fromInt(b.toARGB32()));

double _contrast(Color a, Color b) {
  final la = a.computeLuminance() + 0.05;
  final lb = b.computeLuminance() + 0.05;
  return la > lb ? la / lb : lb / la;
}

ColorScheme _theme(Brightness b, [Color seed = kanaruSeed]) =>
    buildKanaruTheme(brightness: b, seed: seed).colorScheme;

ColorScheme _plain(Color seed, Brightness b) => ColorScheme.fromSeed(
  seedColor: seed,
  brightness: b,
  dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
);

void main() {
  const red = Color(0xFFC62828);
  const blue = Color(0xFF1E88E5);

  group('default seed, dark', () {
    final plain = _plain(kanaruSeed, Brightness.dark);
    final scheme = _theme(Brightness.dark);

    test('error is apart from primary, tone 65, same hue', () {
      expect(scheme.error, isNot(plain.error));
      expect(_dist(scheme.primary, scheme.error), greaterThanOrEqualTo(7));
      final hct = Hct.fromInt(scheme.error.toARGB32());
      expect(hct.tone, closeTo(65, 1));
      final hue = Hct.fromInt(plain.error.toARGB32()).hue;
      expect((hct.hue - hue).abs(), lessThan(2));
    });

    test('other roles keep the Material 3 values', () {
      expect(scheme.primary, plain.primary);
      expect(scheme.onError, plain.onError);
      expect(scheme.errorContainer, plain.errorContainer);
    });

    test('error is readable on its own on-colour and on the surface', () {
      expect(
        _contrast(scheme.error, scheme.onError),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(scheme.error, scheme.surface),
        greaterThanOrEqualTo(4.5),
      );
    });
  });

  test('default seed, light keeps the Material 3 error', () {
    expect(
      _theme(Brightness.light).error,
      _plain(kanaruSeed, Brightness.light).error,
    );
  });

  test('red seed in dark gets a distinct error', () {
    final scheme = _theme(Brightness.dark, red);
    expect(scheme.error, isNot(_plain(red, Brightness.dark).error));
    expect(_dist(scheme.primary, scheme.error), greaterThanOrEqualTo(7));
  });

  test('blue seed keeps the Material 3 error in both themes', () {
    expect(
      _theme(Brightness.dark, blue).error,
      _plain(blue, Brightness.dark).error,
    );
    expect(
      _theme(Brightness.light, blue).error,
      _plain(blue, Brightness.light).error,
    );
  });

  test('sweep over seeds: error stays apart from primary in both themes', () {
    for (var hue = 0; hue < 360; hue += 3) {
      for (final chroma in [30.0, 60.0, 90.0]) {
        final seed = Color(Hct.from(hue.toDouble(), chroma, 50).toInt());
        for (final b in Brightness.values) {
          final scheme = _theme(b, seed);
          final d = _dist(scheme.primary, scheme.error);
          expect(
            d,
            greaterThanOrEqualTo(7),
            reason: '$b hue $hue chroma $chroma: $d',
          );
        }
      }
    }
  });
}
