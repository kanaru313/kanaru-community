import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/fonts/domain/font_setting.dart';

void main() {
  test('key and default', () {
    expect(fontSetting.key, 'app.font');
    expect(fontSetting.defaultValue, 'nunito');
  });

  test('decode accepts a valid id', () {
    expect(fontSetting.decode('inter'), 'inter');
  });

  test('decode rejects invalid ids and non-strings', () {
    for (final bad in <Object?>['../x', '', 3, null, 'a b']) {
      expect(
        () => fontSetting.decode(bad),
        throwsFormatException,
        reason: '$bad',
      );
    }
  });
}
