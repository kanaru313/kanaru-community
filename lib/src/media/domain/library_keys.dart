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
