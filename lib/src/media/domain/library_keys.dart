import 'dart:convert';

import 'package:kanaru/src/foundation/ids/stable_uid.dart';
import 'package:kanaru/src/foundation/text/text_fold.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

/// Bump when any function below changes; the scanner rewrites keys of rows
/// with `tracks.keys_version` < this.
const int libraryKeysVersion = 1;

final RegExp _whitespace = RegExp(r'\s+');
final RegExp _controls = RegExp(r'[\x00-\x1F\x7F]');

/// Grouping key: control characters become spaces, then NFC, lower case,
/// trimmed, inner whitespace collapsed; accents KEPT (Vietnamese "Hà" and "Ha" are different artists).
String groupKey(String name) {
  // Precomposed form makes "ũ" typed as u + U+0303 equal the single code point.
  return unorm
      .nfc(name.replaceAll(_controls, ' '))
      .toLowerCase()
      .trim()
      .replaceAll(_whitespace, ' ');
}

/// Search form: [groupKey] + diacritics folded, for FTS columns and the
/// in-list filter.
String searchForm(String text) => foldDiacritics(groupKey(text));

/// Sort form: [searchForm]; a leading "the "/"a " is NOT removed, digits as-is.
String sortForm(String text) => searchForm(text);

/// Album artist key used for grouping: album_artist, else first track artist,
/// else '' ("Unknown"). Returned raw; callers apply [groupKey].
String albumArtistKeyFor({String? albumArtist, required List<String> artists}) {
  final aa = albumArtist?.trim();
  if (aa != null && aa.isNotEmpty) return aa;
  for (final a in artists) {
    if (a.trim().isNotEmpty) return a.trim();
  }
  return '';
}

/// Every ISO 639-1 two-letter code, and the 20 ISO 639-2/B bibliographic codes
/// that differ from their ISO 639-3 code, mapped to ISO 639-3. Where a 639-1
/// code covers a macrolanguage the macrolanguage code is used (`zh` to `zho`,
/// `ar` to `ara`). `bh` (a collective with no 639-3 code) is not mapped, so it
/// is unknown. Terminologic codes ("deu") and every other three-letter code
/// pass through [languageKey] unchanged.
/// Exposed for tests.
const Map<String, String> languageCodeTable = {
  'aa': 'aar',
  'ab': 'abk',
  'ae': 'ave',
  'af': 'afr',
  'ak': 'aka',
  'am': 'amh',
  'an': 'arg',
  'ar': 'ara',
  'as': 'asm',
  'av': 'ava',
  'ay': 'aym',
  'az': 'aze',
  'ba': 'bak',
  'be': 'bel',
  'bg': 'bul',
  'bi': 'bis',
  'bm': 'bam',
  'bn': 'ben',
  'bo': 'bod',
  'br': 'bre',
  'bs': 'bos',
  'ca': 'cat',
  'ce': 'che',
  'ch': 'cha',
  'co': 'cos',
  'cr': 'cre',
  'cs': 'ces',
  'cu': 'chu',
  'cv': 'chv',
  'cy': 'cym',
  'da': 'dan',
  'de': 'deu',
  'dv': 'div',
  'dz': 'dzo',
  'ee': 'ewe',
  'el': 'ell',
  'en': 'eng',
  'eo': 'epo',
  'es': 'spa',
  'et': 'est',
  'eu': 'eus',
  'fa': 'fas',
  'ff': 'ful',
  'fi': 'fin',
  'fj': 'fij',
  'fo': 'fao',
  'fr': 'fra',
  'fy': 'fry',
  'ga': 'gle',
  'gd': 'gla',
  'gl': 'glg',
  'gn': 'grn',
  'gu': 'guj',
  'gv': 'glv',
  'ha': 'hau',
  'he': 'heb',
  'hi': 'hin',
  'ho': 'hmo',
  'hr': 'hrv',
  'ht': 'hat',
  'hu': 'hun',
  'hy': 'hye',
  'hz': 'her',
  'ia': 'ina',
  'id': 'ind',
  'ie': 'ile',
  'ig': 'ibo',
  'ii': 'iii',
  'ik': 'ipk',
  'io': 'ido',
  'is': 'isl',
  'it': 'ita',
  'iu': 'iku',
  'ja': 'jpn',
  'jv': 'jav',
  'ka': 'kat',
  'kg': 'kon',
  'ki': 'kik',
  'kj': 'kua',
  'kk': 'kaz',
  'kl': 'kal',
  'km': 'khm',
  'kn': 'kan',
  'ko': 'kor',
  'kr': 'kau',
  'ks': 'kas',
  'ku': 'kur',
  'kv': 'kom',
  'kw': 'cor',
  'ky': 'kir',
  'la': 'lat',
  'lb': 'ltz',
  'lg': 'lug',
  'li': 'lim',
  'ln': 'lin',
  'lo': 'lao',
  'lt': 'lit',
  'lu': 'lub',
  'lv': 'lav',
  'mg': 'mlg',
  'mh': 'mah',
  'mi': 'mri',
  'mk': 'mkd',
  'ml': 'mal',
  'mn': 'mon',
  'mr': 'mar',
  'ms': 'msa',
  'mt': 'mlt',
  'my': 'mya',
  'na': 'nau',
  'nb': 'nob',
  'nd': 'nde',
  'ne': 'nep',
  'ng': 'ndo',
  'nl': 'nld',
  'nn': 'nno',
  'no': 'nor',
  'nr': 'nbl',
  'nv': 'nav',
  'ny': 'nya',
  'oc': 'oci',
  'oj': 'oji',
  'om': 'orm',
  'or': 'ori',
  'os': 'oss',
  'pa': 'pan',
  'pi': 'pli',
  'pl': 'pol',
  'ps': 'pus',
  'pt': 'por',
  'qu': 'que',
  'rm': 'roh',
  'rn': 'run',
  'ro': 'ron',
  'ru': 'rus',
  'rw': 'kin',
  'sa': 'san',
  'sc': 'srd',
  'sd': 'snd',
  'se': 'sme',
  'sg': 'sag',
  'si': 'sin',
  'sk': 'slk',
  'sl': 'slv',
  'sm': 'smo',
  'sn': 'sna',
  'so': 'som',
  'sq': 'sqi',
  'sr': 'srp',
  'ss': 'ssw',
  'st': 'sot',
  'su': 'sun',
  'sv': 'swe',
  'sw': 'swa',
  'ta': 'tam',
  'te': 'tel',
  'tg': 'tgk',
  'th': 'tha',
  'ti': 'tir',
  'tk': 'tuk',
  'tl': 'tgl',
  'tn': 'tsn',
  'to': 'ton',
  'tr': 'tur',
  'ts': 'tso',
  'tt': 'tat',
  'tw': 'twi',
  'ty': 'tah',
  'ug': 'uig',
  'uk': 'ukr',
  'ur': 'urd',
  'uz': 'uzb',
  've': 'ven',
  'vi': 'vie',
  'vo': 'vol',
  'wa': 'wln',
  'wo': 'wol',
  'xh': 'xho',
  'yi': 'yid',
  'yo': 'yor',
  'za': 'zha',
  'zh': 'zho',
  'zu': 'zul',
  // ISO 639-2/B bibliographic codes.
  'alb': 'sqi',
  'arm': 'hye',
  'baq': 'eus',
  'bur': 'mya',
  'chi': 'zho',
  'cze': 'ces',
  'dut': 'nld',
  'fre': 'fra',
  'geo': 'kat',
  'ger': 'deu',
  'gre': 'ell',
  'ice': 'isl',
  'mac': 'mkd',
  'mao': 'mri',
  'may': 'msa',
  'per': 'fas',
  'rum': 'ron',
  'slo': 'slk',
  'tib': 'bod',
  'wel': 'cym',
};

/// Codes that mean "no language": undetermined, no linguistic content,
/// multiple languages.
const Set<String> _noLanguage = {'und', 'zxx', 'mul'};

final RegExp _threeLetters = RegExp(r'^[a-z]{3}$');

/// `language` column key: ISO 639-3, lower case. [raw] is trimmed and lower
/// cased; a two-letter ISO 639-1 code or a bibliographic ISO 639-2/B code of a
/// common language is mapped to its ISO 639-3 code, any other three-letter
/// code is kept. `und`, `zxx`, `mul`, empty and anything else give null
/// (unknown, shown as "Chưa rõ").
String? languageKey(String? raw) {
  final code = raw?.trim().toLowerCase();
  if (code == null || code.isEmpty) return null;
  final mapped = languageCodeTable[code] ?? code;
  if (_noLanguage.contains(mapped) || !_threeLetters.hasMatch(mapped)) {
    return null;
  }
  return mapped;
}

/// `song_key` column: stable across re-scans and tag-case changes.
String songKey({required String title, required List<String> artists}) {
  final first = artists.firstWhere(
    (a) => a.trim().isNotEmpty,
    orElse: () => '',
  );
  return stableHashHex([groupKey(title), groupKey(first)], 16);
}

/// Route-safe id of a [groupKey] string: base64url(utf8), no padding.
String encodeKey(String key) =>
    base64Url.encode(utf8.encode(key)).replaceAll('=', '');

/// Inverse of [encodeKey]; null when [id] is not the canonical encoding of a
/// valid UTF-8 string (padding, wrong alphabet and non-minimal forms rejected).
String? decodeKey(String id) {
  try {
    final padded = id.padRight((id.length + 3) ~/ 4 * 4, '=');
    final raw = utf8.decode(base64Url.decode(padded));
    return encodeKey(raw) == id ? raw : null;
  } on FormatException {
    return null;
  }
}

bool _canonical(String part) => groupKey(part) == part;

/// Album key for grouping, both parts through [groupKey]. Null when the album
/// is empty: such tracks store NULL in `album_title_key`/`album_artist_key`.
AlbumKey? albumKeyFor({
  String? album,
  String? albumArtist,
  required List<String> artists,
}) {
  final title = groupKey(album ?? '');
  if (title.isEmpty) return null;
  return AlbumKey(
    groupKey(albumArtistKeyFor(albumArtist: albumArtist, artists: artists)),
    title,
  );
}

class AlbumKey {
  AlbumKey(this.artistKey, this.titleKey)
    : assert(
        !artistKey.contains('\u0000') && !titleKey.contains('\u0000'),
        'album key parts must not contain NUL',
      );

  final String artistKey;
  final String titleKey;

  /// Route-safe id: base64url(utf8('$artistKey\u0000$titleKey')), no padding.
  String encode() => encodeKey('$artistKey\u0000$titleKey');

  static AlbumKey? decode(String id) {
    final raw = decodeKey(id);
    if (raw == null) return null;
    final i = raw.indexOf('\u0000');
    if (i < 0) return null;
    final artist = raw.substring(0, i), title = raw.substring(i + 1);
    if (title.contains('\u0000') || !_canonical(artist) || !_canonical(title)) {
      return null;
    }
    return AlbumKey(artist, title);
  }

  @override
  bool operator ==(Object other) =>
      other is AlbumKey &&
      other.artistKey == artistKey &&
      other.titleKey == titleKey;

  @override
  int get hashCode => Object.hash(artistKey, titleKey);

  @override
  String toString() => 'AlbumKey($artistKey, $titleKey)';
}

class ArtistKey {
  ArtistKey(this.key)
    : assert(!key.contains('\u0000'), 'artist key must not contain NUL');

  final String key;

  String encode() => encodeKey(key);

  static ArtistKey? decode(String id) {
    final raw = decodeKey(id);
    if (raw == null || raw.contains('\u0000') || !_canonical(raw)) return null;
    return ArtistKey(raw);
  }

  @override
  bool operator ==(Object other) => other is ArtistKey && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'ArtistKey($key)';
}
