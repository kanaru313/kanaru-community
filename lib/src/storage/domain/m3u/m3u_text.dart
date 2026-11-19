import 'package:characters/characters.dart';

import 'm3u_limits.dart';

/// Control characters (C0 and C1), direction marks, overrides and isolates,
/// and line / paragraph separators: text from or for an
/// M3U file shows them as spaces, so it cannot hide or reorder what it says.
final m3uUnsafeTextChars = RegExp(
  r'[\u0000-\u001f\u007f-\u009f\u061c\u200e\u200f\u2028\u2029'
  r'\u202a-\u202e\u2066-\u2069]',
);

final _extension = RegExp(r'\.m3u8?$', caseSensitive: false);

/// The playlist name for the M3U file called [fileName]: one `.m3u` / `.m3u8`
/// (any case) dropped, unsafe characters as spaces, trimmed, cut to
/// [m3uNameMaxLength] graphemes without splitting one. Empty when nothing is
/// left; the caller supplies the default name.
String m3uPlaylistName(String fileName) {
  final stem = fileName.replaceFirst(_extension, '');
  final cleaned = stem.replaceAll(m3uUnsafeTextChars, ' ').trim();
  return cleaned.characters.take(m3uNameMaxLength).toString().trim();
}
