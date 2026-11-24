import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/lyrics.dart';
import 'package:kanaru/src/lyrics/domain/translation/translation_alignment.dart';

LyricLine l(String t) => LyricLine(Duration.zero, t);

void main() {
  test('translation found by trimmed source text', () {
    expect(translationFor(l(' hello '), {'hello': ' xin chao '}), 'xin chao');
  });

  test('null for gaps, missing, empty and echoed text', () {
    expect(translationFor(l(''), {'': 'x'}), isNull);
    expect(translationFor(l('a'), {}), isNull);
    expect(translationFor(l('a'), {'a': '  '}), isNull);
    expect(
      translationFor(l('Hello  World'), {'Hello  World': 'hello world'}),
      isNull,
    );
  });
}
