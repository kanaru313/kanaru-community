import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/lrc_parser.dart';
import 'package:kanaru/src/lyrics/domain/lyrics.dart';

Duration _ms(int ms) => Duration(milliseconds: ms);

Lyrics? _parse(String text) => parseLyricsText(text, LyricsOrigin.lrc);

void main() {
  group('time tags', () {
    test('every fraction length and separator', () {
      final lyrics = _parse(
        '[00:01]a\n[00:02.5]b\n[00:03.25]c\n[00:04.125]d\n[00:05:50]e\n'
        '[100:00.00]f',
      )!;
      expect(lyrics.synced, isTrue);
      expect(lyrics.lines, [
        LyricLine(_ms(1000), 'a'),
        LyricLine(_ms(2500), 'b'),
        LyricLine(_ms(3250), 'c'),
        LyricLine(_ms(4125), 'd'),
        LyricLine(_ms(5500), 'e'),
        LyricLine(const Duration(minutes: 100), 'f'),
      ]);
    });

    test('.5 is tenths, .05 hundredths, .005 milliseconds', () {
      final lyrics = _parse('[00:01.5]a\n[00:02.05]b\n[00:03.005]c')!;
      expect(lyrics.lines.map((l) => l.time), [
        _ms(1500),
        _ms(2050),
        _ms(3005),
      ]);
    });

    test('several tags on one line repeat it, sorted by time', () {
      final lyrics = _parse('[00:10.00][00:01.00]Chorus\n[00:05.00]Verse')!;
      expect(lyrics.lines, [
        LyricLine(_ms(1000), 'Chorus'),
        LyricLine(_ms(5000), 'Verse'),
        LyricLine(_ms(10000), 'Chorus'),
      ]);
    });

    test('equal times keep the file order', () {
      final lyrics = _parse('[00:01.00]first\n[00:01.00]second')!;
      expect(lyrics.lines.map((l) => l.text), ['first', 'second']);
    });

    test('timed blank lines stay (as gaps), untimed lines go', () {
      final lyrics = _parse('stray\n[00:01.00]\n[00:02.00]  sung  ')!;
      expect(lyrics.lines, [
        LyricLine(_ms(1000), ''),
        LyricLine(_ms(2000), 'sung'),
      ]);
      expect(lyrics.lines.first.isGap, isTrue);
    });

    test('stacked tags may be separated by spaces', () {
      final lyrics = _parse('[00:01.00] [00:03.00]  Twice')!;
      expect(lyrics.lines, [
        LyricLine(_ms(1000), 'Twice'),
        LyricLine(_ms(3000), 'Twice'),
      ]);
    });

    test('blank timed lines alone leave the untimed text as plain', () {
      final lyrics = _parse('[00:01.00]\nHello')!;
      expect(lyrics.synced, isFalse);
      expect(lyrics.lines.single.text, 'Hello');
    });

    test('only blank timed lines is no lyrics', () {
      expect(_parse('[00:01.00]\n[00:02.00]  \n[ar:Someone]'), isNull);
    });

    test('CRLF and CR line ends', () {
      final lyrics = _parse('[00:01.00]a\r\n[00:02.00]b\r[00:03.00]c')!;
      expect(lyrics.lines.map((l) => l.text), ['a', 'b', 'c']);
    });
  });

  group('word timings', () {
    test('fill words and strip the tags from the text', () {
      final lyrics = _parse('[00:10.00]<00:10.00>Hel<00:10.50>lo')!;
      final line = lyrics.lines.single;
      expect(line.text, 'Hello');
      expect(line.words, [
        LyricWord(_ms(10000), 'Hel'),
        LyricWord(_ms(10500), 'lo'),
      ]);
    });

    test('a line without word tags has no words', () {
      expect(_parse('[00:01.00]plain')!.lines.single.words, isEmpty);
    });

    test('offset shifts the words too, clamped at zero', () {
      final lyrics = _parse('[00:01.00]<00:01.00>a<00:01.80>b\n[offset:1000]')!;
      expect(lyrics.lines.single.time, Duration.zero);
      expect(lyrics.lines.single.words, [
        LyricWord(Duration.zero, 'a'),
        LyricWord(_ms(800), 'b'),
      ]);
    });

    test('a repeated line keeps words on its first time only', () {
      final lyrics = _parse('[00:05.00][00:01.00]<00:05.00>a<00:05.50>b')!;
      expect(lyrics.lines[0].time, _ms(1000));
      expect(lyrics.lines[0].words, isEmpty);
      expect(lyrics.lines[1].time, _ms(5000));
      expect(lyrics.lines[1].words, hasLength(2));
    });

    test('angle brackets that are not times stay text', () {
      expect(
        _parse('[00:01.00]<3 you> <00:xx>')!.lines.single.text,
        '<3 you> <00:xx>',
      );
    });
  });

  group('meta tags', () {
    test('are skipped', () {
      final lyrics = _parse(
        '[ar:Artist]\n[ti:Title]\n[al:Album]\n[by:me]\n[length: 03:20]\n'
        '[re:tool]\n[ve:1.0]\n[00:01.00]line',
      )!;
      expect(lyrics.lines, [LyricLine(_ms(1000), 'line')]);
    });

    test('a positive offset makes lines earlier, wherever it stands', () {
      final lyrics = _parse('[00:01.00]a\n[00:02.00]b\n[offset:+500]')!;
      expect(lyrics.lines.map((l) => l.time), [_ms(500), _ms(1500)]);
    });

    test('a negative offset makes lines later; below zero is zero', () {
      expect(
        _parse('[offset:-250]\n[00:01.00]a')!.lines.single.time,
        _ms(1250),
      );
      expect(
        _parse('[offset:2000]\n[00:01.00]a')!.lines.single.time,
        Duration.zero,
      );
    });

    test('a broken offset is ignored', () {
      expect(_parse('[offset:abc]\n[00:01.00]a')!.lines.single.time, _ms(1000));
    });
  });

  group('plain lyrics', () {
    test('lines kept as they are, blank edges trimmed', () {
      final lyrics = _parse('\n\n[ar:Someone]\nFirst line\n\n  Second  \n\n')!;
      expect(lyrics.synced, isFalse);
      expect(lyrics.lines.map((l) => l.text), ['First line', '', '  Second']);
      expect(lyrics.lineAt(const Duration(minutes: 1)), -1);
    });

    test('bracketed section names stay, with or without a colon', () {
      final lyrics = _parse(
        '[Chorus]\nLa la\n[Intro: Drake]\n[Verse 2: Someone]',
      )!;
      expect(lyrics.lines.map((l) => l.text), [
        '[Chorus]',
        'La la',
        '[Intro: Drake]',
        '[Verse 2: Someone]',
      ]);
    });

    test('meta keys match in any case', () {
      expect(
        _parse('[AR:Someone]\n[Ti:Song]\nWords')!.lines.single.text,
        'Words',
      );
    });

    test('nothing to show gives null', () {
      expect(_parse(''), isNull);
      expect(_parse('  \n \r\n'), isNull);
      expect(_parse('[ar:Only meta]\n[ti:Tags]'), isNull);
    });
  });

  test('keeps at most the line cap', () {
    final text = List.generate(
      maxLyricLines + 10,
      (i) => '[00:01.00]$i',
    ).join('\n');
    expect(_parse(text)!.lines, hasLength(maxLyricLines));
  });

  test('the origin is passed through', () {
    expect(
      parseLyricsText('words', LyricsOrigin.tag)!.origin,
      LyricsOrigin.tag,
    );
  });
}
