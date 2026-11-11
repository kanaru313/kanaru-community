import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/browse/language_names.dart';

void main() {
  test('known codes', () {
    final vie = languageNameOf('vie')!;
    expect(vie.native, 'Tiếng Việt');
    expect(vie.en, 'Vietnamese');
    expect(languageNameOf('jpn')!.vi, 'Tiếng Nhật');
    expect(languageNameOf('ENG')!.native, 'English');
  });

  test('detector Mandarin code', () {
    expect(languageNameOf('cmn')!.native, '中文');
  });

  test('unknown code is null', () {
    expect(languageNameOf('xxx'), isNull);
    expect(languageNameOf(''), isNull);
  });

  test('every listed code from the spec is present with non-empty names', () {
    const codes =
        'vie eng jpn kor zho fra deu spa ita por rus tha ind msa hin '
        'ara tur nld swe pol ukr ces ell heb fil tgl khm lao mya ben tam tel '
        'urd fas hun ron dan fin nor nob cat lat';
    for (final c in codes.split(' ')) {
      final n = languageNameOf(c);
      expect(n, isNotNull, reason: c);
      expect(n!.native, isNotEmpty);
      expect(n.en, isNotEmpty);
      expect(n.vi, isNotEmpty);
    }
  });
}
