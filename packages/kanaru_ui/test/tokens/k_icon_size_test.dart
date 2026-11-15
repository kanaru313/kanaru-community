import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

void main() {
  test('icon sizes have the scale values', () {
    expect(
      [
        KIconSize.xs,
        KIconSize.sm,
        KIconSize.md,
        KIconSize.lg,
        KIconSize.xl,
        KIconSize.hero,
      ],
      [16, 20, 24, 32, 40, 48],
    );
  });

  test('icon sizes grow strictly', () {
    final sizes = [
      KIconSize.xs,
      KIconSize.sm,
      KIconSize.md,
      KIconSize.lg,
      KIconSize.xl,
      KIconSize.hero,
    ];
    for (var i = 1; i < sizes.length; i++) {
      expect(sizes[i], greaterThan(sizes[i - 1]));
    }
  });

  test('press fade lasts 200 ms', () {
    expect(KMotion.press, const Duration(milliseconds: 200));
  });

  group('KText', () {
    final styles = <String, (TextStyle, double, FontWeight?)>{
      'coverTitle': (KText.coverTitle, 22, FontWeight.w700),
      'coverTitleLarge': (KText.coverTitleLarge, 26, FontWeight.w700),
      'coverArtist': (KText.coverArtist, 15, null),
      'stripTitle': (KText.stripTitle, 16, FontWeight.w700),
      'stripArtist': (KText.stripArtist, 13, null),
      'miniTitle': (KText.miniTitle, 14, FontWeight.w600),
      'miniArtist': (KText.miniArtist, 12, null),
    };
    styles.forEach((name, spec) {
      final (style, size, weight) = spec;
      test('$name holds size and weight only', () {
        expect(style.fontSize, size);
        expect(style.fontWeight, weight);
        expect(style.color, isNull);
        expect(style.height, isNull);
        expect(style.fontFamily, isNull);
      });
    });

    test('strip styles lerp to the cover styles', () {
      final mid = TextStyle.lerp(KText.stripTitle, KText.coverTitle, 0.5)!;
      expect(mid.fontSize, 19);
    });
  });
}
