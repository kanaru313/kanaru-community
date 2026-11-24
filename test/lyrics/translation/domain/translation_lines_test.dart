import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/lyrics.dart';
import 'package:kanaru/src/lyrics/domain/translation/translation_lines.dart';
import 'package:kanaru/src/plugins/domain/package/translate_spec.dart';

LyricLine l(String t) => LyricLine(Duration.zero, t);

void main() {
  test('unique lines: chorus once, blanks dropped, first-seen order', () {
    expect(uniqueLineTexts([l('a'), l(''), l(' b '), l('a'), l('b'), l('c')]), [
      'a',
      'b',
      'c',
    ]);
  });

  test('chunks by line count and chars, order kept', () {
    final lines = [for (var i = 0; i < 25; i++) 'x$i'];
    final chunks = chunkLines(
      lines,
      const TranslateSpec(languages: ['vi'], maxLines: 10),
    );
    expect(chunks.map((c) => c.length), [10, 10, 5]);
    expect(chunks.expand((c) => c), lines);
  });

  test('a long line is alone in its chunk', () {
    final long = 'y' * 1500;
    final chunks = chunkLines([
      'a',
      long,
      'b',
    ], const TranslateSpec(languages: ['vi'], maxChars: 1000));
    expect(chunks, [
      ['a'],
      [long],
      ['b'],
    ]);
  });

  test('caps flag too many lines, chars or chunks', () {
    const spec = TranslateSpec(languages: ['vi'], maxLines: 10);
    final many = [for (var i = 0; i < 1001; i++) 'a$i'];
    expect(exceedsTranslationCaps(many, chunkLines(many, spec)), isTrue);
    final chunky = [for (var i = 0; i < 250; i++) 'a$i'];
    expect(chunkLines(chunky, spec).length, 25);
    expect(exceedsTranslationCaps(chunky, chunkLines(chunky, spec)), isTrue);
    final chars = ['z' * 12000, 'z' * 9000];
    expect(exceedsTranslationCaps(chars, chunkLines(chars, spec)), isTrue);
    final ok = ['a', 'b'];
    expect(exceedsTranslationCaps(ok, chunkLines(ok, spec)), isFalse);
  });
}
