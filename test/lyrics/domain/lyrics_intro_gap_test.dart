import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/lyrics.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_intro_gap.dart';

Lyrics _synced(Duration first, {String text = 'a', bool synced = true}) =>
    Lyrics(
      lines: [LyricLine(first, text), const LyricLine(Duration(seconds: 60), 'b')],
      synced: synced,
      origin: LyricsOrigin.lrc,
    );

void main() {
  test('a first line at 30.87 s gets a gap at zero before it', () {
    final out = withIntroGap(_synced(const Duration(milliseconds: 30870)));
    expect(out.lines.length, 3);
    expect(out.lines.first, const LyricLine(Duration.zero, ''));
    expect(out.lineAt(const Duration(seconds: 10)), 0);
    expect(out.lineAt(const Duration(milliseconds: 30870)), 1);
    expect(out.synced, isTrue);
    expect(out.origin, LyricsOrigin.lrc);
  });

  test('exactly 5 s adds it, 4.9 s does not', () {
    expect(withIntroGap(_synced(introGapThreshold)).lines.length, 3);
    final early = _synced(const Duration(milliseconds: 4900));
    expect(withIntroGap(early), same(early));
  });

  test('a first line that is a gap, or plain lyrics, stay as they are', () {
    final gap = _synced(const Duration(seconds: 20), text: '');
    expect(withIntroGap(gap), same(gap));
    final plain = _synced(const Duration(seconds: 20), synced: false);
    expect(withIntroGap(plain), same(plain));
  });
}
