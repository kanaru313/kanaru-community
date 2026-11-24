import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/translation/translation_language.dart';

void main() {
  test('sameLanguage ignores case and region, merges Chinese scripts', () {
    expect(sameLanguage('en-US', 'EN'), isTrue);
    expect(sameLanguage('pt_BR', 'pt'), isTrue);
    expect(sameLanguage('zh-Hans', 'zh-Hant'), isTrue);
    expect(sameLanguage('iw', 'he'), isTrue);
    expect(sameLanguage('ja', 'ko'), isFalse);
  });

  test('dominantSource weighs by source length', () {
    expect(
      dominantSource({
        'a long line here': 'en',
        'x': 'ja',
        'y': 'ja',
        'z': null,
      }),
      'en',
    );
    expect(dominantSource({'ab': 'ja', 'cd': 'en'}), 'ja');
    expect(dominantSource({'a': null}), isNull);
    expect(dominantSource({}), isNull);
  });

  test('rtl set and appTarget', () {
    expect(rtlLanguages, {'ar', 'he', 'fa'});
    expect(appTarget('vi'), 'vi');
    expect(appTarget('en-GB'), 'en');
    expect(appTarget('fr'), 'en');
  });
}
