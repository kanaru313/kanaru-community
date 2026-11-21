import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/lrc_parser.dart';
import 'package:kanaru/src/lyrics/domain/lyrics.dart';

Lyrics? _parse(String text) => parseLyricsText(text, LyricsOrigin.lrc);

void main() {
  test('a 1 MiB row of time tags parses in linear time', () {
    final row = '[0:0]' * ((1 << 20) ~/ 5);
    final watch = Stopwatch()..start();
    final lyrics = _parse('${row}x');
    watch.stop();
    expect(watch.elapsedMilliseconds, lessThan(300));
    expect(lyrics, isNotNull);
    expect(lyrics!.textLength, lessThanOrEqualTo(maxLyricsTextChars));
  });

  test('a row keeps at most the tag cap of lines', () {
    final row = '${'[00:01.00]' * 150}text';
    expect(_parse(row)!.lines, hasLength(maxTimeTagsPerRow));
  });

  test('tags past the cap stay in the text', () {
    final lyrics = _parse('${'[00:01.00]' * maxTimeTagsPerRow}[00:02.00]tail')!;
    expect(lyrics.lines.first.text, '[00:02.00]tail');
  });

  test('expansion of a long line stops at the text cap', () {
    final long = 'a' * (900 * 1024);
    final lyrics = _parse('${'[00:01.00]' * 100}$long')!;
    expect(lyrics.textLength, lessThanOrEqualTo(maxLyricsTextChars));
    expect(lyrics.lines, hasLength(1));
  });

  test('many rows stop at the text cap', () {
    final line = 'b' * 1000;
    final text = List.generate(3000, (i) => '[00:01.00]$line').join('\n');
    final lyrics = _parse(text)!;
    expect(lyrics.textLength, lessThanOrEqualTo(maxLyricsTextChars));
    expect(lyrics.lines.length, lessThan(3000));
  });

  test('plain text stops at the text cap too', () {
    final line = 'c' * 1000;
    final lyrics = _parse(List.filled(3000, line).join('\n'))!;
    expect(lyrics.synced, isFalse);
    expect(lyrics.textLength, lessThanOrEqualTo(maxLyricsTextChars));
  });

  test('after the text cap is hit every later line is dropped', () {
    final big = 'a' * (900 * 1024);
    final timed = _parse(
      '[00:01.00]$big\n[00:02.00]${'b' * (200 * 1024)}\n[00:03.00]short',
    )!;
    expect(timed.lines.map((l) => l.time.inSeconds), [1]);
    final plain = _parse('$big\n${'b' * (200 * 1024)}\nshort')!;
    expect(plain.lines, hasLength(1));
  });

  test('hitting the plain cap keeps later synced lines', () {
    final big = 'a' * (900 * 1024);
    final lyrics = _parse(
      '$big\n${'b' * (200 * 1024)}\n[00:01.00]hi\n[00:02.00]there',
    )!;
    expect(lyrics.synced, isTrue);
    expect(lyrics.lines.map((l) => l.text), ['hi', 'there']);
  });
}
