import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/online/domain/contract/item_ref.dart';

void main() {
  test('round trips', () {
    for (final id in ['a/b', '100%', 'ä 日本', 'plain', 'a?b#c', 'x y']) {
      final e = encodeItemId(id);
      expect(e, isNot(contains('/')));
      expect(decodeItemId(e), id);
    }
  });

  test('other spellings are refused', () {
    expect(decodeItemId('a%2fb'), isNull);
    expect(decodeItemId('a+b'), isNull);
    expect(decodeItemId('a/b'), isNull);
    expect(decodeItemId('%61'), isNull);
    expect(decodeItemId('a%2Fb'), 'a/b');
  });

  test('empty and broken encodings are refused', () {
    expect(decodeItemId(''), isNull);
    expect(decodeItemId('%E0%A4%A'), isNull);
    expect(decodeItemId('%'), isNull);
  });

  test('an id with an unpaired surrogate is found; pairs are fine', () {
    for (final id in ['\ud800', 'a\udc00', '\ud800\ud800', '\udc00\ud800']) {
      expect(hasUnpairedSurrogate(id), isTrue, reason: '${id.codeUnits}');
    }
    for (final id in ['', 'abc', '😀', 'a😀b😀']) {
      expect(hasUnpairedSurrogate(id), isFalse, reason: id);
      expect(decodeItemId(encodeItemId(id)), id.isEmpty ? isNull : id);
    }
  });

  test('isUrlShapedId', () {
    expect(isUrlShapedId('https://x.y/a'), isTrue);
    expect(isUrlShapedId('file:///etc/passwd'), isTrue);
    expect(isUrlShapedId('//x.y'), isTrue);
    expect(isUrlShapedId('a/b'), isFalse);
    expect(isUrlShapedId('dQw4w9WgXcQ'), isFalse);
    expect(isUrlShapedId('a//b'), isFalse);
  });
}
