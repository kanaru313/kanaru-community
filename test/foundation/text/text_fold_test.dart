import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/text/text_fold.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

void main() {
  group('foldDiacritics', () {
    test('Vietnamese alphabet', () {
      expect(
        foldDiacritics('àáảãạ ăằắẳẵặ âầấẩẫậ èéẻẽẹ êềếểễệ ìíỉĩị'),
        'aaaaa aaaaaa aaaaaa eeeee eeeeee iiiii',
      );
      expect(
        foldDiacritics('òóỏõọ ôồốổỗộ ơờớởỡợ ùúủũụ ưừứửữự ỳýỷỹỵ'),
        'ooooo oooooo oooooo uuuuu uuuuuu yyyyy',
      );
      expect(foldDiacritics('Đặng Đình Ơn Ư'), 'dang dinh on u');
    });
    test('combining and precomposed input fold equally', () {
      expect(foldDiacritics('Vũ'), foldDiacritics('Vũ'));
      expect(foldDiacritics('Vũ'), 'vu');
    });
    test('Latin-1 and unchanged scripts', () {
      expect(foldDiacritics('Café Ångström Müller'), 'cafe angstrom muller');
      expect(foldDiacritics('東京 ひらがな'), '東京 ひらがな');
      expect(foldDiacritics(''), '');
    });
  });

  group('foldedContains', () {
    test('matches every token, folded', () {
      expect(foldedContains('Vũ Cát Tường', 'vu'), isTrue);
      expect(foldedContains('Vũ Cát Tường', 'cat  tuong'), isTrue);
      expect(foldedContains('Vũ Cát Tường', 'vu x'), isFalse);
    });
    test('empty query matches', () {
      expect(foldedContains('abc', '  '), isTrue);
    });
    test('matcher folds the query once', () {
      final m = foldedMatcher('  Đức  19 ');
      expect(m('Track 19 duc'), isTrue);
      expect(m('Track 20 duc'), isFalse);
      expect(foldedMatcher('')('anything'), isTrue);
    });
    test('20k all-Vietnamese titles', () {
      final titles = List.generate(
        20000,
        (i) => 'Bài hát số $i của Đức Phúc và Hồ Quỳnh Hương ${i * 7}',
      );
      int run() {
        final m = foldedMatcher('duc 19');
        return titles.where(m).length;
      }

      run(); // warm-up
      // Minimum of several runs measures the algorithm, not machine load.
      var best = 1 << 30;
      var n = 0;
      for (var i = 0; i < 5; i++) {
        final sw = Stopwatch()..start();
        n = run();
        sw.stop();
        best = min(best, sw.elapsedMilliseconds);
      }
      // ignore: avoid_print
      print('20k vietnamese filter (best of 5): $best ms');
      expect(n, greaterThan(0));
      expect(best, lessThan(150));
    });
  });

  group('fast fold equals reference', () {
    String slow(String s) => unorm
        .nfc(unorm.nfd(s).replaceAll(RegExp('[\u0300-\u036f]'), ''))
        .replaceAll('đ', 'd')
        .replaceAll('Đ', 'D')
        .toLowerCase();

    test('every code point U+0080-U+1FFF', () {
      for (var c = 0x80; c < 0x2000; c++) {
        final ch = String.fromCharCode(c);
        expect(
          foldDiacritics(ch),
          slow(ch),
          reason: 'U+${c.toRadixString(16)}',
        );
        expect(foldDiacritics('a${ch}b'), slow('a${ch}b'));
      }
    });
    test('every non-surrogate BMP unit U+0080-U+FFFF', () {
      for (var c = 0x80; c <= 0xffff; c++) {
        if (c >= 0xd800 && c <= 0xdfff) continue;
        final s = 'a${String.fromCharCode(c)}b';
        expect(foldDiacritics(s), slow(s), reason: 'U+${c.toRadixString(16)}');
      }
    });
    test('seeded random mixed strings', () {
      final rnd = Random(42);
      const pieces = [
        'Việt',
        'ĐỨC',
        'u\u0303',
        '東京',
        'ひらが',
        'が',
        '😀',
        '\u{20000}',
        '\u{10400}',
        'Å',
        '\u212b',
        ' ',
        'abc',
        'ǅ',
        '한글',
        'ＡＢＣ',
        '\u2000',
      ];
      for (var i = 0; i < 2000; i++) {
        final s = List.generate(
          1 + rnd.nextInt(8),
          (_) => pieces[rnd.nextInt(pieces.length)],
        ).join();
        expect(foldDiacritics(s), slow(s), reason: s);
      }
    });
    test('NFD and NFC Vietnamese strings, kana, jamo', () {
      for (final s in [
        'Nguyễn Văn Ưu Đặng',
        'Hồ Quỳnh Hương',
        unorm.nfd('Trịnh Công Sơn ĐỨC'),
        'がぎぐ ガギグ',
        '\u1112\u1161\u11ab',
        'ǅ 😀 𐐀 İstanbul',
      ]) {
        expect(foldDiacritics(s), slow(s), reason: s);
      }
    });
    test('unchanged input is returned as is', () {
      const s = 'already folded 東京';
      expect(identical(foldDiacritics(s), s), isTrue);
    });
  });
}
