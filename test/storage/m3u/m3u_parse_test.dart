import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/storage/domain/m3u/m3u_limits.dart';
import 'package:kanaru/src/storage/domain/m3u/m3u_parse.dart';

M3uParse parse(String s) => parseM3u(Uint8List.fromList(utf8.encode(s)));
List<String> texts(M3uParse p) => p.entries.map((e) => e.text).toList();

void main() {
  group('line ends', () {
    for (final (name, sep) in [('LF', '\n'), ('CRLF', '\r\n'), ('CR', '\r')]) {
      test('$name separated', () {
        expect(texts(parse('/a$sep/b$sep/c')), ['/a', '/b', '/c']);
        expect(texts(parse('/a$sep/b$sep')), ['/a', '/b']);
      });
    }

    test('mixed ends', () {
      expect(texts(parse('/a\r\n/b\n/c\r/d')), ['/a', '/b', '/c', '/d']);
    });

    test('text is raw and untrimmed', () {
      expect(parse('  /a b.mp3 \n').entries.single.text, '  /a b.mp3 ');
    });
  });

  group('skipped lines', () {
    test('blank, whitespace and comment lines are skipped but counted', () {
      final p = parse('#EXTM3U\n\n   \n# note\n/a\n/b');
      expect(p.entries.map((e) => e.line), [5, 6]);
    });
  });

  group('EXTINF', () {
    M3uExtInf? first(String s) => parse(s).entries.first.extinf;

    test('duration, artist and title', () {
      final x = first('#EXTINF:123,A - B\n/a')!;
      expect((x.durationMs, x.artist, x.title), (123000, 'A', 'B'));
    });

    test('-1 duration and title only', () {
      final x = first('#EXTINF:-1,Title\n/a')!;
      expect((x.durationMs, x.artist, x.title), (null, null, 'Title'));
    });

    test('attributes are ignored', () {
      final x = first('#EXTINF:12 tvg-id="x",T\n/a')!;
      expect((x.durationMs, x.title), (12000, 'T'));
    });

    test('a comma inside a quoted attribute does not split the label', () {
      final x = first('#EXTINF:5 tvg-name="a,b",Song\n/a')!;
      expect((x.durationMs, x.title), (5000, 'Song'));
    });

    test('invalid duration is null', () {
      final x = first('#EXTINF:abc,T\n/a')!;
      expect((x.durationMs, x.title), (null, 'T'));
    });

    test('control and bidi characters in the label become spaces', () {
      final x = first('#EXTINF:1,A\t\u202EB\n/a')!;
      expect(x.title, 'A  B');
    });

    test('empty label gives null title', () {
      expect(first('#EXTINF:1,   \n/a')!.title, isNull);
    });

    test('only the first " - " splits', () {
      final x = first('#EXTINF:1,A - B - C\n/a')!;
      expect((x.artist, x.title), ('A', 'B - C'));
    });

    test('a path line without EXTINF has none', () {
      expect(parse('/a').entries.single.extinf, isNull);
    });

    test('EXTINF applies to the next path line only', () {
      final p = parse('#EXTINF:1,T\n/a\n/b');
      expect(p.entries[0].extinf?.title, 'T');
      expect(p.entries[1].extinf, isNull);
    });

    test('EXTINF with no following path is dropped', () {
      expect(parse('/a\n#EXTINF:1,T\n').entries.single.extinf, isNull);
    });

    test('two EXTINF in a row: the last wins', () {
      expect(
        parse('#EXTINF:1,One\n#EXTINF:2,Two\n/a').entries.single.extinf!.title,
        'Two',
      );
    });

    test('a comment between EXTINF and path keeps the EXTINF', () {
      expect(parse('#EXTINF:1,T\n# c\n/a').entries.single.extinf?.title, 'T');
    });
  });

  group('limits', () {
    String lineOf(int bytes) => '/${'a' * (bytes - 1)}';

    test('4096 bytes is fine, 4097 is tooLong', () {
      final p = parse(
        '${lineOf(m3uMaxLineBytes)}\n${lineOf(m3uMaxLineBytes + 1)}',
      );
      expect(p.entries.map((e) => e.tooLong), [false, true]);
    });

    test('line length counts bytes, not characters', () {
      // 2049 two-byte characters: 2049 chars but 4098 bytes.
      final p = parse('/${'é' * 2048}\n/${'é' * 2047}');
      expect(p.entries.map((e) => e.tooLong), [true, false]);
    });

    test('a too long comment is skipped, not reported', () {
      expect(parse('#${'a' * 5000}\n/a').entries.single.text, '/a');
    });

    test('50000 path lines are not truncated, 50001 are', () {
      final ok = parse(List.filled(m3uMaxPathLines, '/a').join('\n'));
      expect((ok.entries.length, ok.truncated), (m3uMaxPathLines, false));
      final cut = parse(List.filled(m3uMaxPathLines + 1, '/a').join('\n'));
      expect((cut.entries.length, cut.truncated), (m3uMaxPathLines, true));
    });

    test('50000 lines parse quickly', () {
      final bytes = Uint8List.fromList(
        utf8.encode(
          List.generate(
            50000,
            (i) => '#EXTINF:1,A - T$i\n/m/$i.mp3',
          ).join('\n'),
        ),
      );
      final sw = Stopwatch()..start();
      final p = parseM3u(bytes);
      expect(p.entries.length, 50000);
      // Sanity check against quadratic cost, not a speed gate: the bound is
      // generous so a loaded machine does not flake it.
      expect(sw.elapsedMilliseconds, lessThan(30000));
    });
  });

  group('EXTINF numbers and tag', () {
    int? ms(String d) => parse('#EXTINF:$d,T\n/a').entries.single.extinf!.durationMs;

    test('fractional seconds round to milliseconds', () {
      expect(ms('12.5'), 12500);
    });

    test('zero, negative, hex, exponent and overflow are unknown', () {
      for (final d in ['0', '-5', '0x10', '1e3', '1e300', '9223372036854775807']) {
        expect(ms(d), isNull, reason: d);
      }
    });

    test('seven days is accepted, more is not', () {
      expect(ms('604800'), 604800000);
      expect(ms('604801'), isNull);
    });

    test('the tag is matched in any case', () {
      final x = parse('#extinf:7,A - B\n/a').entries.single.extinf!;
      expect((x.durationMs, x.artist, x.title), (7000, 'A', 'B'));
    });

    test('an unbalanced quote falls back to the first comma', () {
      final x = parse('#EXTINF:5 tvg-name="a,Song\n/a').entries.single.extinf!;
      expect((x.durationMs, x.title), (5000, 'Song'));
    });
  });

  group('through parseM3u', () {
    test('BOM with CRLF', () {
      final p = parseM3u(Uint8List.fromList(
        [0xEF, 0xBB, 0xBF, ...utf8.encode('#EXTM3U\r\n/a\r\n/b\r\n')],
      ));
      expect(texts(p), ['/a', '/b']);
      expect(p.entries.map((e) => e.line), [2, 3]);
    });

    test('an ANSI EXTINF does not garble UTF-8 paths', () {
      final p = parseM3u(Uint8List.fromList([
        ...utf8.encode('/m/Đêm.mp3\n'),
        ...ascii.encode('#EXTINF:1,'), 0x93, 0x41, 0x94,
        ...utf8.encode('\n/m/Việt.mp3'),
      ]));
      expect(texts(p), ['/m/Đêm.mp3', '/m/Việt.mp3']);
      expect(p.entries[1].extinf!.title, '\u201CA\u201D');
    });

    test('a too long entry keeps its line number and a clean preview', () {
      final p = parse('/a\n/${'Việt' * 2000}');
      final e = p.entries[1];
      expect((e.line, e.tooLong), (2, true));
      expect(e.text, startsWith('/Việt'));
      expect(e.text, isNot(contains('Ã')));
      expect(utf8.encode(e.text).length, lessThanOrEqualTo(m3uMaxLineBytes));
    });

    for (final little in [true, false]) {
      test('UTF-16 ${little ? 'LE' : 'BE'} with a BOM', () {
        final units = '#EXTINF:3,Đ - T😀\r\n/m/Việt😀.mp3\r\n/b'.codeUnits;
        final bytes = <int>[
          little ? 0xFF : 0xFE,
          little ? 0xFE : 0xFF,
          for (final u in units) ...(little ? [u & 255, u >> 8] : [u >> 8, u & 255]),
        ];
        final p = parseM3u(Uint8List.fromList(bytes));
        expect(texts(p), ['/m/Việt😀.mp3', '/b']);
        expect(p.entries.first.extinf!.artist, 'Đ');
        expect(p.entries.first.extinf!.title, 'T😀');
      });
    }
  });
}
