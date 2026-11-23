import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/fonts/domain/font_header_parser.dart';
import 'package:kanaru/src/fonts/domain/font_label.dart';

import 'support/font_bytes.dart';

NameRecord _n(int platform, int id, String text) =>
    (platform: platform, id: id, text: text);

void main() {
  group('parseFontHeader', () {
    test('reads a real TrueType file', () {
      final header = parseFontHeader(nunitoBytes())!;
      expect(header.family, 'Nunito');
      expect(header.isCff, isFalse);
    });

    test('accepts OpenType CFF and flags it', () {
      final header = parseFontHeader(otf([_n(3, 1, 'Cff Face')]))!;
      expect(header.family, 'Cff Face');
      expect(header.isCff, isTrue);
    });

    test('accepts the Apple "true" magic', () {
      expect(
        parseFontHeader(ttf([_n(3, 1, 'Apple')], magic: 0x74727565)),
        isNotNull,
      );
    });

    test('refuses a TrueType collection', () {
      expect(parseFontHeader(ttf([_n(3, 1, 'X')], magic: 0x74746366)), isNull);
    });

    test('refuses other data and short input', () {
      expect(parseFontHeader(Uint8List(0)), isNull);
      expect(parseFontHeader(Uint8List(11)), isNull);
      expect(
        parseFontHeader(Uint8List.fromList(List.filled(64, 0x41))),
        isNull,
      );
    });

    test('refuses a file missing a required table', () {
      final names = nameTable([_n(3, 1, 'X')]);
      final filler = Uint8List(8);
      expect(
        parseFontHeader(
          sfnt(0x00010000, {'cmap': filler, 'glyf': filler, 'loca': filler}),
        ),
        isNull,
        reason: 'no name',
      );
      expect(
        parseFontHeader(
          sfnt(0x00010000, {'name': names, 'glyf': filler, 'loca': filler}),
        ),
        isNull,
        reason: 'no cmap',
      );
      expect(
        parseFontHeader(
          sfnt(0x00010000, {'name': names, 'cmap': filler, 'glyf': filler}),
        ),
        isNull,
        reason: 'glyf without loca',
      );
      expect(
        parseFontHeader(sfnt(0x00010000, {'name': names, 'cmap': filler})),
        isNull,
        reason: 'no outlines',
      );
    });

    test('refuses a truncated file', () {
      final full = nunitoBytes();
      expect(parseFontHeader(Uint8List.sublistView(full, 0, 100)), isNull);
      expect(
        parseFontHeader(Uint8List.sublistView(full, 0, full.length ~/ 2)),
        isNull,
      );
    });

    test('refuses a table directory that runs past the end', () {
      final bytes = Uint8List(12);
      ByteData.sublistView(bytes)
        ..setUint32(0, 0x00010000)
        ..setUint16(4, 500);
      expect(parseFontHeader(bytes), isNull);
    });

    test('prefers name ID 16 over ID 1', () {
      final bytes = ttf([_n(3, 1, 'Family Bold'), _n(3, 16, 'Family')]);
      expect(parseFontHeader(bytes)!.family, 'Family');
    });

    test('prefers Windows, then Unicode, then Macintosh records', () {
      expect(
        parseFontHeader(
          ttf([_n(1, 1, 'Mac'), _n(0, 1, 'Uni'), _n(3, 1, 'Win')]),
        )!.family,
        'Win',
      );
      expect(
        parseFontHeader(ttf([_n(1, 1, 'Mac'), _n(0, 1, 'Uni')]))!.family,
        'Uni',
      );
      expect(parseFontHeader(ttf([_n(1, 1, 'Mac')]))!.family, 'Mac');
    });

    test('a file without a readable name is still a font', () {
      final header = parseFontHeader(ttf([_n(3, 2, 'Regular')]))!;
      expect(header.family, isNull);
    });

    test('a hostile name is cleaned', () {
      final header = parseFontHeader(
        ttf([_n(3, 1, '\u202Eevil\u0000 Face\u0007')]),
      )!;
      expect(header.family, 'evil Face');
    });
  });

  group('sanitizeFontLabel', () {
    test('strips control and bidi characters', () {
      expect(sanitizeFontLabel('a\u0000b\u007Fc\u0085d'), 'abcd');
      expect(
        sanitizeFontLabel('\u200Ex\u200F\u202A\u202B\u202C\u202D\u202Ey'),
        'xy',
      );
      expect(sanitizeFontLabel('\u2066p\u2067q\u2068r\u2069'), 'pqr');
    });

    test('collapses whitespace and trims', () {
      expect(sanitizeFontLabel('  My \t\n  Font  '), 'My Font');
    });

    test('replaces lone surrogates, keeps pairs', () {
      expect(sanitizeFontLabel('a\uD800b'), 'a�b');
      expect(sanitizeFontLabel('a\uDC00'), 'a�');
      expect(sanitizeFontLabel('😀'), '😀');
    });

    test('caps the length at 64 characters', () {
      expect(sanitizeFontLabel('x' * 100).length, 64);
      expect(sanitizeFontLabel('😀' * 100).runes.length, 64);
    });

    test('nothing readable gives an empty string', () {
      expect(sanitizeFontLabel('\u0000\u202E \t'), isEmpty);
    });
  });

  test('fontFileStem drops only a font extension', () {
    expect(fontFileStem('My.Font.TTF'), 'My.Font');
    expect(fontFileStem('a.otf'), 'a');
    expect(fontFileStem('notes.txt'), 'notes.txt');
  });
}
