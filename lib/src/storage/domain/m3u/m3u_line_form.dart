import 'dart:convert';

import 'm3u_limits.dart';

/// Why a path line cannot be a local file.
enum M3uLineProblem {
  /// A URL with a scheme other than `file` (`http://`, `rtsp://`, ...).
  uri,

  /// A `file:` URI with a remote host, query, fragment, user info, port, a
  /// bad escape or no absolute path.
  badFileUri,

  /// A Windows path (`C:\Music\a.mp3`): its drive means nothing here.
  driveLetter,

  /// The line holds a NUL character.
  nul,

  /// The line is longer than [m3uMaxLineBytes].
  tooLong,
}

/// What a path line says about where the file is. Pure text: whether the file
/// exists is decided later against the file system.
sealed class M3uLineForm {
  const M3uLineForm();
}

/// An absolute path (also the decoded path of a `file:` URI).
final class M3uAbsolute extends M3uLineForm {
  const M3uAbsolute(this.path);
  final String path;
}

/// A path relative to the folder of the M3U file. [backslashAlt] is the same
/// text with `\` as `/`, set only when the text holds `\` and no `/` (a
/// Windows relative line such as `Rock\a.mp3`); try it after the literal.
final class M3uRelative extends M3uLineForm {
  const M3uRelative(this.path, {this.backslashAlt});
  final String path;
  final String? backslashAlt;
}

/// A line that cannot be a local file.
final class M3uRejected extends M3uLineForm {
  const M3uRejected(this.problem);
  final M3uLineProblem problem;
}

final _drive = RegExp(r'^[A-Za-z]:[\\/]');
final _scheme = RegExp(r'^[A-Za-z][A-Za-z0-9+.\-]*://');
final _fileScheme = RegExp(r'^file:', caseSensitive: false);

/// Sorts [line] (not trimmed) into its form; see [M3uLineForm].
M3uLineForm classifyM3uLine(String line) {
  if (line.contains('\u0000')) return const M3uRejected(M3uLineProblem.nul);
  // The byte limit is checked on raw bytes by the parser (`M3uEntry.tooLong`);
  // this cheap guard only stops text that cannot fit in any encoding.
  if (line.length > m3uMaxLineBytes) {
    return const M3uRejected(M3uLineProblem.tooLong);
  }
  if (_drive.hasMatch(line)) {
    return const M3uRejected(M3uLineProblem.driveLetter);
  }
  if (_fileScheme.hasMatch(line)) return _fileUri(line);
  if (_scheme.hasMatch(line)) return const M3uRejected(M3uLineProblem.uri);
  if (line.startsWith('/')) return M3uAbsolute(line);
  final alt = line.contains('\\') && !line.contains('/')
      ? line.replaceAll('\\', '/')
      : null;
  return M3uRelative(line, backslashAlt: alt);
}

M3uLineForm _fileUri(String line) {
  const bad = M3uRejected(M3uLineProblem.badFileUri);
  // Split by hand: Uri.parse rewrites bad escapes and `file:name` into a
  // valid absolute URI, hiding exactly what must be rejected.
  var rest = line.substring('file:'.length);
  if (rest.startsWith('//')) {
    rest = rest.substring(2);
    final slash = rest.indexOf('/');
    final authority = slash < 0 ? rest : rest.substring(0, slash);
    // A user info or port holds `@` or `:`; any host but this machine is
    // remote.
    if (authority.isNotEmpty && authority.toLowerCase() != 'localhost') {
      return bad;
    }
    rest = slash < 0 ? '' : rest.substring(slash);
  }
  if (rest.contains('?') || rest.contains('#')) return bad;
  final String path;
  try {
    path = _decodeUriPath(rest);
  } on FormatException {
    return bad;
  }
  if (path.contains('\u0000')) return const M3uRejected(M3uLineProblem.nul);
  if (!path.startsWith('/')) return bad;
  if (_drive.hasMatch(path.substring(1))) {
    return const M3uRejected(M3uLineProblem.driveLetter);
  }
  return M3uAbsolute(path);
}

/// Percent-decodes [text] as UTF-8. `%XX` is one byte; any other character
/// (raw non-ASCII included, as some players write it) is its UTF-8 bytes.
/// Throws [FormatException] for a bad escape or invalid UTF-8.
String _decodeUriPath(String text) {
  final bytes = <int>[];
  final runes = text.runes.toList();
  for (var i = 0; i < runes.length; i++) {
    if (runes[i] != 0x25) {
      bytes.addAll(utf8.encode(String.fromCharCode(runes[i])));
      continue;
    }
    if (i + 2 >= runes.length) throw const FormatException('escape');
    final hi = _hex(runes[i + 1]);
    final lo = _hex(runes[i + 2]);
    if (hi < 0 || lo < 0) throw const FormatException('escape');
    bytes.add(hi * 16 + lo);
    i += 2;
  }
  return utf8.decode(bytes);
}

int _hex(int c) {
  if (c >= 0x30 && c <= 0x39) return c - 0x30;
  if (c >= 0x41 && c <= 0x46) return c - 0x41 + 10;
  if (c >= 0x61 && c <= 0x66) return c - 0x61 + 10;
  return -1;
}
