import 'dart:convert';
import 'dart:typed_data';

import 'm3u_decode.dart';
import 'm3u_limits.dart';
import 'm3u_text.dart';

/// The `#EXTINF` data written before a path line.
class M3uExtInf {
  const M3uExtInf({this.durationMs, this.artist, this.title});

  /// Null when the duration is unknown (`-1`, `0`, not a plain decimal, over 7 days).
  final int? durationMs;
  final String? artist;
  final String? title;
}

/// One path line. [line] counts from 1 in the file, skipped lines included.
/// [text] is the raw line, untrimmed (for a [tooLong] line only its start).
class M3uEntry {
  const M3uEntry({
    required this.line,
    required this.text,
    this.extinf,
    this.tooLong = false,
  });

  final int line;
  final String text;
  final M3uExtInf? extinf;
  final bool tooLong;
}

/// The path lines of a file, in order, and whether [m3uMaxPathLines] cut it.
class M3uParse {
  const M3uParse({required this.entries, required this.truncated});

  final List<M3uEntry> entries;
  final bool truncated;
}

const _extInfTag = '#EXTINF:';
final _decimal = RegExp(r'^[0-9]+(\.[0-9]+)?$');

/// Longest duration believed, in seconds (7 days).
const _maxSeconds = 7 * 24 * 3600;

/// Parses the bytes of an M3U file. Blank lines and `#` lines are skipped
/// (still counted); an `#EXTINF` belongs to the next path line only (the last
/// one wins when several come in a row). A top-level function so it can run
/// in `Isolate.run`.
///
/// The line limit counts raw bytes; for a UTF-16 file (BOM) it counts the
/// bytes after conversion to UTF-8. The caller enforces [m3uMaxBytes] before
/// calling.
M3uParse parseM3u(Uint8List input) {
  final bytes = _utf16ToUtf8(input);
  final entries = <M3uEntry>[];
  var number = 0;
  var truncated = false;
  M3uExtInf? pending;
  for (final raw in iterateM3uLines(bytes)) {
    number++;
    final tooLong = raw.length > m3uMaxLineBytes;
    // A huge line is decoded from its start only, never in full.
    final text = decodeM3uLine(tooLong ? _preview(raw) : raw);
    if (!tooLong && _isExtInf(text)) {
      pending = _parseExtInf(text.substring(_extInfTag.length));
      continue;
    }
    if (text.trim().isEmpty || text.startsWith('#')) continue;
    if (entries.length == m3uMaxPathLines) {
      truncated = true;
      break;
    }
    entries.add(
      M3uEntry(line: number, text: text, extinf: pending, tooLong: tooLong),
    );
    pending = null;
  }
  return M3uParse(entries: entries, truncated: truncated);
}

/// The first [m3uMaxLineBytes] bytes of [raw], cut back to a whole UTF-8
/// character.
Uint8List _preview(Uint8List raw) {
  var end = m3uMaxLineBytes;
  while (end > 0 && (raw[end] & 0xC0) == 0x80) {
    end--;
  }
  return Uint8List.sublistView(raw, 0, end);
}

bool _isExtInf(String text) =>
    text.length >= _extInfTag.length &&
    text.substring(0, _extInfTag.length).toLowerCase() == _extInfTag.toLowerCase();

/// A file that starts with a UTF-16 byte order mark is converted to UTF-8 so
/// the line rules stay the same; anything else is returned as is.
Uint8List _utf16ToUtf8(Uint8List bytes) {
  if (bytes.length < 2) return bytes;
  final little = bytes[0] == 0xFF && bytes[1] == 0xFE;
  if (!little && !(bytes[0] == 0xFE && bytes[1] == 0xFF)) return bytes;
  final units = <int>[
    for (var i = 2; i + 1 < bytes.length; i += 2)
      little ? bytes[i] | (bytes[i + 1] << 8) : (bytes[i] << 8) | bytes[i + 1],
  ];
  return Uint8List.fromList(utf8.encode(String.fromCharCodes(units)));
}

/// `<seconds>[ attrs],<label>`; the label is split on its first ` - `.
M3uExtInf _parseExtInf(String body) {
  var comma = _firstUnquotedComma(body);
  if (comma < 0) comma = body.indexOf(',');
  final header = comma < 0 ? body : body.substring(0, comma);
  final label = comma < 0 ? '' : _clean(body.substring(comma + 1));
  final token = header.trim().split(RegExp(r'\s')).first;
  // Plain decimal only: no hex, exponent or sign.
  final seconds = _decimal.hasMatch(token) ? double.tryParse(token) : null;
  final durationMs =
      seconds == null || seconds <= 0 || seconds > _maxSeconds
      ? null
      : (seconds * 1000).round();
  String? artist;
  String? title = label.isEmpty ? null : label;
  final split = label.indexOf(' - ');
  if (split >= 0) {
    artist = _orNull(label.substring(0, split));
    title = _orNull(label.substring(split + 3));
  }
  return M3uExtInf(durationMs: durationMs, artist: artist, title: title);
}

/// Index of the first `,` outside double quotes (attribute values such as
/// `tvg-name="a,b"` may hold commas), or -1.
int _firstUnquotedComma(String text) {
  var quoted = false;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (c == '"') {
      quoted = !quoted;
    } else if (c == ',' && !quoted) {
      return i;
    }
  }
  return -1;
}

String _clean(String text) => text.replaceAll(m3uUnsafeTextChars, ' ').trim();

String? _orNull(String text) {
  final t = text.trim();
  return t.isEmpty ? null : t;
}
