import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('default family is Nunito', () {
    final t = buildKanaruTheme(brightness: Brightness.light);
    expect(t.textTheme.bodyMedium!.fontFamily, contains('Nunito'));
  });

  test('fontFamily parameter reaches the text theme', () {
    final t = buildKanaruTheme(
      brightness: Brightness.dark,
      fontFamily: 'Inter',
    );
    expect(t.textTheme.bodyMedium!.fontFamily, contains('Inter'));
    expect(t.textTheme.titleLarge!.fontFamily, contains('Inter'));
  });
}
