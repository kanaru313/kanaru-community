import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';

/// ISO 639-1 code of each language whatlang can report (ISO 639-3 code).
const _iso1 = {
  'afr': 'af',
  'aka': 'ak',
  'amh': 'am',
  'ara': 'ar',
  'aze': 'az',
  'bel': 'be',
  'ben': 'bn',
  'bul': 'bg',
  'cat': 'ca',
  'ces': 'cs',
  'cmn': 'zh',
  'cym': 'cy',
  'dan': 'da',
  'deu': 'de',
  'ell': 'el',
  'eng': 'en',
  'epo': 'eo',
  'est': 'et',
  'fin': 'fi',
  'fra': 'fr',
  'guj': 'gu',
  'heb': 'he',
  'hin': 'hi',
  'hrv': 'hr',
  'hun': 'hu',
  'hye': 'hy',
  'ind': 'id',
  'ita': 'it',
  'jav': 'jv',
  'jpn': 'ja',
  'kan': 'kn',
  'kat': 'ka',
  'khm': 'km',
  'kor': 'ko',
  'lat': 'la',
  'lav': 'lv',
  'lit': 'lt',
  'mal': 'ml',
  'mar': 'mr',
  'mkd': 'mk',
  'mya': 'my',
  'nep': 'ne',
  'nld': 'nl',
  'nob': 'nb',
  'ori': 'or',
  'pan': 'pa',
  'pes': 'fa',
  'pol': 'pl',
  'por': 'pt',
  'ron': 'ro',
  'rus': 'ru',
  'sin': 'si',
  'slk': 'sk',
  'slv': 'sl',
  'sna': 'sn',
  'spa': 'es',
  'srp': 'sr',
  'swe': 'sv',
  'tam': 'ta',
  'tel': 'te',
  'tgl': 'tl',
  'tha': 'th',
  'tuk': 'tk',
  'tur': 'tr',
  'ukr': 'uk',
  'urd': 'ur',
  'uzb': 'uz',
  'vie': 'vi',
  'yid': 'yi',
  'zul': 'zu',
};

void main() {
  final fixture = jsonDecode(
    File('rust/crates/kanaru_media/tests/tags_fixtures/whatlang_codes.json')
        .readAsStringSync(),
  ) as Map<String, dynamic>;

  test('the fixture lists every language with a 639-1 code known here', () {
    expect(fixture.keys.toSet(), _iso1.keys.toSet());
  });

  test('a detected language groups with the same language tagged in 639-1', () {
    for (final entry in fixture.entries) {
      final mapped = entry.value as String;
      expect(mapped, matches(RegExp(r'^[a-z]{3}$')), reason: entry.key);
      final detected = languageKey(mapped);
      expect(detected, isNotNull, reason: entry.key);
      final tagged = languageKey(_iso1[entry.key]);
      expect(tagged, isNotNull, reason: '${entry.key} has no 639-1 mapping');
      expect(detected, tagged, reason: '${entry.key} -> $mapped');
    }
  });

  test('the codes whatlang reports unmapped are macrolanguage-safe', () {
    expect(fixture['cmn'], 'zho');
    expect(fixture['pes'], 'fas');
  });
}
