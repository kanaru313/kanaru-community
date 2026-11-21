import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/lrc_word_tags.dart';
import 'package:kanaru/src/lyrics/domain/lyrics.dart';

Duration _ms(int ms) => Duration(milliseconds: ms);

void main() {
  const line = Duration(seconds: 10);

  test('text before the first tag starts at the line time', () {
    expect(splitWordTags('Hi <00:11.00>there', lineTime: line), [
      LyricWord(line, 'Hi '),
      LyricWord(_ms(11000), 'there'),
    ]);
  });

  test('every fraction length and the colon form', () {
    expect(
      splitWordTags(
        '<00:01.5>a<00:02.25>b<00:03.125>c<00:04:50>d',
        lineTime: line,
      ),
      [
        LyricWord(_ms(1500), 'a'),
        LyricWord(_ms(2250), 'b'),
        LyricWord(_ms(3125), 'c'),
        LyricWord(_ms(4500), 'd'),
      ],
    );
  });

  test('empty words are dropped, a trailing tag adds nothing', () {
    expect(splitWordTags('<00:01.00><00:02.00>x<00:03.00>', lineTime: line), [
      LyricWord(_ms(2000), 'x'),
    ]);
  });

  test('stripWordTags removes only time tags', () {
    expect(stripWordTags('a<00:01.00>b <i> <1:2>c'), 'ab <i> c');
    expect(hasWordTags('no tags <i>'), isFalse);
    expect(hasWordTags('x<00:01>y'), isTrue);
  });
}
