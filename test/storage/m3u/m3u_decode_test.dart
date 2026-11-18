import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/storage/domain/m3u/m3u_decode.dart';

Uint8List b(List<int> v) => Uint8List.fromList(v);

void main() {
  group('splitM3uLines', () {
    test('drops a UTF-8 BOM and splits on LF', () {
      final lines = splitM3uLines(
        b([0xEF, 0xBB, 0xBF, ...utf8.encode('a\nb')]),
      );
      expect(lines.map(utf8.decode), ['a', 'b']);
    });

    test('empty input and BOM only give no lines', () {
      expect(splitM3uLines(b([])), isEmpty);
      expect(splitM3uLines(b([0xEF, 0xBB, 0xBF])), isEmpty);
    });

    test('pure ASCII with a trailing newline has no empty last line', () {
      expect(splitM3uLines(b(ascii.encode('x\ny\n'))).length, 2);
    });

    test('keeps blank lines between content', () {
      final lines = splitM3uLines(b(ascii.encode('a\r\n\r\nb')));
      expect(lines.map(utf8.decode), ['a', '', 'b']);
    });
  });

  group('decodeM3uLine', () {
    test('valid UTF-8 is read as UTF-8', () {
      expect(decodeM3uLine(b(utf8.encode('Nhạc Việt.mp3'))), 'Nhạc Việt.mp3');
    });

    test('invalid UTF-8 falls back to Windows-1252', () {
      expect(decodeM3uLine(b([0x80])), '\u20AC');
      expect(decodeM3uLine(b([0x93, 0x41, 0x94])), '\u201CA\u201D');
      expect(decodeM3uLine(b([0xE9])), 'é');
    });

    test('bytes Windows-1252 leaves undefined keep their code point', () {
      expect(
        decodeM3uLine(b([0x81, 0x8D, 0x8F, 0x90, 0x9D])),
        '\u0081\u008D\u008F\u0090\u009D',
      );
    });

    test('NUL is kept for the classifier', () {
      expect(decodeM3uLine(b([0x61, 0x00, 0x62])), 'a\u0000b');
    });

    test('one ANSI line does not garble UTF-8 lines around it', () {
      final bytes = b([
        ...utf8.encode('/m/Đêm Việt.mp3\n'),
        ...[0x23, 0x45, 0x58, 0x54, 0x49, 0x4E, 0x46, 0x3A, 0x31, 0x2C, 0x93],
        ...utf8.encode('\n/m/Tiếng.mp3'),
      ]);
      final lines = splitM3uLines(bytes).map(decodeM3uLine).toList();
      expect(lines[0], '/m/Đêm Việt.mp3');
      expect(lines[1], '#EXTINF:1,\u201C');
      expect(lines[2], '/m/Tiếng.mp3');
    });
  });
}
