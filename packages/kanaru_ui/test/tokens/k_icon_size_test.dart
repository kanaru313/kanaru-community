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
}
