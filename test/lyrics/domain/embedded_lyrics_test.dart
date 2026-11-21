import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/embedded_lyrics.dart';
import 'package:kanaru/src/lyrics/domain/lyrics.dart';

void main() {
  const sylt = [LyricLine(Duration(seconds: 1), 'sylt')];

  test('SYLT lines win over the text', () {
    final lyrics = lyricsFromTag(
      const EmbeddedLyrics(text: '[00:05.00]text', synced: sylt),
    )!;
    expect(lyrics.synced, isTrue);
    expect(lyrics.lines, sylt);
    expect(lyrics.origin, LyricsOrigin.tag);
  });

  test('LRC text in the tag is synced', () {
    final lyrics = lyricsFromTag(const EmbeddedLyrics(text: '[00:05.00]hi'))!;
    expect(lyrics.synced, isTrue);
    expect(lyrics.lines.single.text, 'hi');
  });

  test('plain text in the tag is plain', () {
    expect(lyricsFromTag(const EmbeddedLyrics(text: 'a\nb'))!.synced, isFalse);
  });

  test('blank text, no tag and an empty tag are null', () {
    expect(lyricsFromTag(const EmbeddedLyrics(text: '  \n')), isNull);
    expect(lyricsFromTag(null), isNull);
    expect(lyricsFromTag(const EmbeddedLyrics()), isNull);
  });
}
