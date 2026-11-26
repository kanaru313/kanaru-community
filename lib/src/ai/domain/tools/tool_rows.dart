import 'dart:convert';

import '../text/text_sanitizer.dart';
import 'tool_env.dart';

/// Largest tool result the model gets, in UTF-8 bytes.
const int toolResultMaxBytes = 16 * 1024;

/// Most characters of one cell; longer text is cut with an ellipsis.
const int _cellMaxRunes = 200;

/// One cell of a row. Text comes from tags or the model's own earlier turns,
/// so it is untrusted: control, bidi and zero-width characters are removed,
/// then `\`, `|`, CR and LF are escaped so a cell can never end itself or
/// start a new row.
String escapeCell(String? value) {
  if (value == null) return '';
  var text = sanitizeText(value, keepLineBreaks: true);
  if (text.runes.length > _cellMaxRunes) {
    text = '${clipRunes(text, _cellMaxRunes - 1)}…';
  }
  return text
      .replaceAll(r'\', r'\\')
      .replaceAll('|', r'\|')
      .replaceAll('\r', r'\r')
      .replaceAll('\n', r'\n');
}

/// `a|b|c` from escaped cells; a null cell is empty.
String joinRow(Iterable<Object?> cells) =>
    cells.map((c) => c == null ? '' : escapeCell('$c')).join('|');

/// `id|title|artist|album|year`.
String trackRowText(TrackRow t) =>
    joinRow([t.id, t.title, t.artist, t.album, t.year]);

/// A list result: [rows] (already formatted, never cut), the [total] of the
/// whole list and the [offset] of its first row. When the encoded result
/// would pass [maxBytes], only the first rows that fit are kept and the
/// result says `"truncated": true` with the `nextOffset` to ask for next.
/// [head] adds fixed fields (they come first and always stay).
String listResult({
  required List<String> rows,
  required int total,
  required int offset,
  Map<String, Object?> head = const {},
  int maxBytes = toolResultMaxBytes,
}) {
  String encode(int n) => jsonEncode({
    ...head,
    'total': total,
    'offset': offset,
    'items': rows.sublist(0, n),
    if (n < rows.length) 'truncated': true,
    if (n < rows.length) 'nextOffset': offset + n,
  });

  var n = rows.length;
  if (utf8.encode(encode(n)).length <= maxBytes) return encode(n);
  // Binary search for the most rows that fit; at least one so the model can
  // always move on.
  var low = 1;
  var high = n - 1;
  while (low < high) {
    final mid = (low + high + 1) >> 1;
    if (utf8.encode(encode(mid)).length <= maxBytes) {
      low = mid;
    } else {
      high = mid - 1;
    }
  }
  n = rows.isEmpty ? 0 : low;
  return encode(n);
}
