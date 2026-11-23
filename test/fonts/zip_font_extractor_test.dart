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
}
