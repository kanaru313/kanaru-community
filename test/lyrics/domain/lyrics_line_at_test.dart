import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/lrc_parser.dart';
import 'package:kanaru/src/lyrics/domain/lyrics.dart';

Duration _ms(int ms) => Duration(milliseconds: ms);

void main() {
  final lyrics = parseLyricsText(
    '[00:01.00]a\n[00:02.00]b\n[00:02.00]c\n[00:05.00]d',
    LyricsOrigin.lrc,
  )!;

  test('before the first line is -1', () {
    expect(lyrics.lineAt(Duration.zero), -1);
    expect(lyrics.lineAt(_ms(999)), -1);
  });

  test('the last line started at or before the position', () {
    expect(lyrics.lineAt(_ms(1000)), 0);
    expect(lyrics.lineAt(_ms(1999)), 0);
    expect(lyrics.lineAt(_ms(2000)), 2, reason: 'equal times: the later one');
    expect(lyrics.lineAt(_ms(4999)), 2);
    expect(lyrics.lineAt(const Duration(hours: 1)), 3);
  });

  test('plain lyrics have no current line', () {
    final plain = parseLyricsText('one\ntwo', LyricsOrigin.tag)!;
    expect(plain.lineAt(const Duration(hours: 1)), -1);
  });

  test('value equality covers lines and words', () {
    final a = parseLyricsText('[00:01.00]<00:01.00>a', LyricsOrigin.lrc)!;
    final b = parseLyricsText('[00:01.00]<00:01.00>a', LyricsOrigin.lrc)!;
    final c = parseLyricsText('[00:01.00]a', LyricsOrigin.lrc)!;
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(c));
  });
}
