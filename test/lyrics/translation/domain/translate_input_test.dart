import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/translation/translate_input.dart';

void main() {
  test('input has lines, target and song, nothing else', () {
    final input = buildTranslateInput(
      ['a', 'b'],
      'vi',
      song: const SongContext(title: 'T', artist: 'A'),
      allLines: ['a', 'b', 'c'],
    );
    expect(input, {
      'lines': ['a', 'b'],
      'to': 'vi',
      'song': {'title': 'T', 'artist': 'A', 'lyrics': 'a\nb\nc'},
    });
  });

  test('unknown song gives empty strings; lyrics default to the lines', () {
    final input = buildTranslateInput(['a'], 'en');
    expect(input['song'], {'title': '', 'artist': '', 'lyrics': 'a'});
  });

  test('lyrics are capped at 20000 units without cutting a surrogate', () {
    final text = '${'a' * 19999}\u{1F600}more';
    final song = buildTranslateInput([text], 'en')['song']! as Map;
    final lyrics = song['lyrics'] as String;
    expect(lyrics.length, 19999);
    expect(lyrics.codeUnits.last, 0x61);
    final plain = buildTranslateInput(['b' * 30000], 'en')['song']! as Map;
    expect((plain['lyrics'] as String).length, 20000);
  });
}
