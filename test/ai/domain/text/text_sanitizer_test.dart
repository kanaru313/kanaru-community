import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/text/text_sanitizer.dart';

void main() {
  test('removes controls, bidi and zero-width characters', () {
    const dirty = 'a\u0000b\u0007c\u202Ed\u2066e\u200Bf\u200Dg\uFEFFh\u0085i\u007Fj';
    expect(sanitizeText(dirty), 'abcdefgh ij');
  });

  test('line breaks become one space, or one LF when kept', () {
    const text = 'a\r\nb\rc\nd\u2028e\tf';
    expect(sanitizeText(text), 'a b c d e f');
    expect(sanitizeText(text, keepLineBreaks: true), 'a\nb\nc\nd\ne\tf');
  });

  test('keeps text in other scripts and emoji', () {
    const text = 'Đừng làm trái tim anh đau 🎵 こんにちは';
    expect(sanitizeText(text), text);
  });

  test('a lone surrogate becomes the replacement character', () {
    final lone = String.fromCharCodes([0x61, 0xD83C, 0x62]);
    expect(sanitizeText(lone), 'a�b');
  });

  test('clipRunes never splits a surrogate pair', () {
    expect(clipRunes('a🎵b', 2), 'a🎵');
    expect(clipRunes('abc', 5), 'abc');
    expect(clipRunes('abc', 0), '');
  });
}
