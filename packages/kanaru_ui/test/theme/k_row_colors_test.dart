import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('fill is white 5 % on dark and black 4.5 % on light', () {
    expect(
      KRowColors.fill(Brightness.dark),
      Colors.white.withValues(alpha: 0.05),
    );
    expect(
      KRowColors.fill(Brightness.light),
      Colors.black.withValues(alpha: 0.045),
    );
  });

  test('playing gradient runs start to end over the theme containers', () {
    final scheme = buildKanaruTheme(brightness: Brightness.dark).colorScheme;
    final g = KRowColors.playingGradient(scheme);
    expect(g.colors, [
      scheme.primaryContainer,
      scheme.primaryContainer,
      scheme.tertiaryContainer,
    ]);
    expect(g.stops, [0, 0.25, 1]);
    expect(g.begin, AlignmentDirectional.centerStart);
    expect(g.end, AlignmentDirectional.centerEnd);
    // Mirrors with the cover in right-to-left.
    expect(g.begin.resolve(TextDirection.rtl), Alignment.centerRight);
    expect(g.begin.resolve(TextDirection.ltr), Alignment.centerLeft);
  });

  test('secondary text on a playing or selected row is 85 %', () {
    expect(KRowColors.containerSoftAlpha, 0.85);
  });
}
