import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/platform/domain/setting.dart';

enum _Color { red, green }

void main() {
  test('returns the member with that name', () {
    expect(enumByName(_Color.values, 'green'), _Color.green);
  });

  test('throws FormatException for an unknown name or a non-string', () {
    expect(() => enumByName(_Color.values, 'blue'), throwsFormatException);
    expect(() => enumByName(_Color.values, 'Red'), throwsFormatException);
    expect(() => enumByName(_Color.values, 1), throwsFormatException);
    expect(() => enumByName(_Color.values, null), throwsFormatException);
  });
}
