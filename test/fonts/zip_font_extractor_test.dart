import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/fonts/data/zip_font_extractor.dart';

import '../plugins/fixtures/zip_builders.dart';

Uint8List _zip(Map<String, Object> entries) => buildZip(entries);

void main() {
  final font = Uint8List.fromList([0, 1, 0, 0, 9]);

  test('keeps fonts and the licence, flat, and ignores other files', () {
    final out = extractFontZip(
      _zip({
        'Lora/': '',
        'Lora/static/Lora-Regular.ttf': font,
        'Lora/static/Lora-Bold.OTF': font,
        'Lora/OFL.txt': 'licence text',
        'Lora/README.md': 'readme',
        '__MACOSX/x.bin': 'junk',
      }),
    );
    expect(out.keys.toSet(), {'Lora-Regular.ttf', 'Lora-Bold.OTF', 'OFL.txt'});
    expect(out['Lora-Regular.ttf'], font);
    expect(utf8.decode(out['OFL.txt']!), 'licence text');
  });

  test('a LICENSE file is kept too', () {
    final out = extractFontZip(_zip({'a.ttf': font, 'LICENSE.txt': 'apache'}));
    expect(out.keys.toSet(), {'a.ttf', 'LICENSE.txt'});
  });

  for (final bad in ['../x.ttf', 'a/../../x.ttf', '/abs.ttf', 'C:x.ttf']) {
    test('refuses the path $bad', () {
      expect(
        () => extractFontZip(_zip({bad: font, 'ok.ttf': font})),
        throwsA(isA<FontZipException>()),
      );
    });
  }

  test('refuses two files with one name', () {
    expect(
      () => extractFontZip(_zip({'a/F.ttf': font, 'b/F.ttf': font})),
      throwsA(isA<FontZipException>()),
    );
    expect(
      () => extractFontZip(_zip({'a/F.ttf': font, 'b/f.TTF': font})),
      throwsA(isA<FontZipException>()),
    );
  });

  test('refuses a zip with no font', () {
    expect(
      () => extractFontZip(_zip({'OFL.txt': 'x', 'readme.md': 'y'})),
      throwsA(isA<FontZipException>()),
    );
  });

  test('refuses bytes that are not a zip', () {
    expect(
      () => extractFontZip(Uint8List.fromList([1, 2, 3, 4])),
      throwsA(isA<FontZipException>()),
    );
  });

  test('refuses files that add up to more than the zip cap', () {
    final big = Uint8List(maxFontZipBytes ~/ 2 + 1024);
    expect(
      () => extractFontZip(_zip({'a.ttf': big, 'b.otf': big})),
      throwsA(
        isA<FontZipException>().having(
          (e) => e.message,
          'message',
          contains('too large'),
        ),
      ),
    );
  });

  test('refuses an entry whose unpacked size is not the declared one', () {
    final zip = _zip({'a.ttf': Uint8List.fromList(List.filled(64, 7))});
    final data = ByteData.sublistView(zip);
    // Lie about the uncompressed size in the central directory entry
    // (signature 0x02014b50, size field at +24) and the local header (+22).
    for (var i = 0; i + 30 < zip.length; i++) {
      if (data.getUint32(i, Endian.little) == 0x02014b50) {
        data.setUint32(i + 24, 128, Endian.little);
      } else if (data.getUint32(i, Endian.little) == 0x04034b50) {
        data.setUint32(i + 22, 128, Endian.little);
      }
    }
    expect(
      () => extractFontZip(zip),
      throwsA(
        isA<FontZipException>().having(
          (e) => e.message,
          'message',
          contains('does not match'),
        ),
      ),
    );
  });
}
