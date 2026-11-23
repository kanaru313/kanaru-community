import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/fonts/domain/app_font.dart';
import 'package:kanaru/src/fonts/domain/builtin_fonts.dart';

void main() {
  group('isValidFontId', () {
    test('accepts letters, digits, underscore and dash', () {
      expect(isValidFontId('nunito'), isTrue);
      expect(isValidFontId('custom_my-font_1a2b3c4d'), isTrue);
      expect(isValidFontId('a' * 128), isTrue);
    });

    test('rejects traversal, separators, empty, null and too long', () {
      for (final bad in ['', '..', '../x', 'a/b', r'a\b', 'a.b', 'a b', 'é']) {
        expect(isValidFontId(bad), isFalse, reason: bad);
      }
      expect(isValidFontId(null), isFalse);
      expect(isValidFontId('a' * 129), isFalse);
    });

    test('rejects a trailing newline', () {
      expect(isValidFontId('nunito\n'), isFalse);
    });
  });

  group('appFontFor', () {
    test('built-ins', () {
      expect(appFontFor('nunito').family, 'Nunito');
      expect(appFontFor('inter').family, 'Inter');
      expect(appFontFor('system').family, 'sans-serif');
    });

    test('custom id maps to its own family', () {
      final f = appFontFor('custom_my_font_1a2b3c4d');
      expect(f.kind, AppFontKind.custom);
      expect(f.family, 'custom_my_font_1a2b3c4d');
      expect(f.label, 'my font');
    });

    test('catalog entry is found', () {
      final f = appFontFor('lora');
      expect(f.kind, AppFontKind.catalog);
      expect(f.family, 'Lora');
    });

    test('unknown or invalid ids give the default', () {
      expect(appFontFor('nope').id, defaultFontId);
      expect(appFontFor('../x').id, defaultFontId);
    });
  });
}
