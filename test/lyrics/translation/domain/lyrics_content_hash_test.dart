import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/lyrics.dart';
import 'package:kanaru/src/lyrics/domain/translation/lyrics_content_hash.dart';

void main() {
  test('same words, other timestamps and gaps: same hash', () {
    final a = [
      const LyricLine(Duration(seconds: 1), 'one'),
      const LyricLine(Duration(seconds: 2), ''),
      const LyricLine(Duration(seconds: 3), 'two'),
    ];
    final b = [
      const LyricLine(Duration(seconds: 9), 'one'),
      const LyricLine(Duration(seconds: 12), 'two'),
    ];
    expect(lyricsContentHash(a), lyricsContentHash(b));
    expect(lyricsContentHash(a), matches(RegExp(r'^[0-9a-f]{64}$')));
  });

  test('any text change changes the hash', () {
    const a = [
      LyricLine(Duration.zero, 'one'),
      LyricLine(Duration.zero, 'two'),
    ];
    const b = [
      LyricLine(Duration.zero, 'one'),
      LyricLine(Duration.zero, 'twp'),
    ];
    const c = [
      LyricLine(Duration.zero, 'two'),
      LyricLine(Duration.zero, 'one'),
    ];
    expect(lyricsContentHash(a), isNot(lyricsContentHash(b)));
    expect(lyricsContentHash(a), isNot(lyricsContentHash(c)));
  });
}
