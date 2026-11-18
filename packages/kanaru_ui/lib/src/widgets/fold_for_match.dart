/// Text folding for the filter of the multi picker. The app's search folds with
/// `foldDiacritics` (NFD, drop combining marks, đ to d, lower case); this
/// package cannot import it, so the same result is produced by a table over the
/// Latin letters that decompose canonically (Latin-1, Latin Extended-A/B,
/// Vietnamese). Keep it in step with that function when its coverage changes.
String foldForMatch(String text) {
  final out = StringBuffer();
  for (final rune in text.runes) {
    if (rune >= 0x300 && rune <= 0x36f) continue; // combining marks
    final c = String.fromCharCode(rune).toLowerCase();
    out.write(_folded[c] ?? c);
  }
  return out.toString();
}

/// Matcher for [query]: folds and splits it once. True for a haystack that
/// contains every whitespace-separated token after folding; an empty query
/// matches everything.
bool Function(String) foldedMatcher(String query) {
  final tokens = foldForMatch(query)
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList(growable: false);
  if (tokens.isEmpty) return (_) => true;
  return (haystack) {
    final folded = foldForMatch(haystack);
    return tokens.every(folded.contains);
  };
}

// Base letter first, then every lower-case letter that folds to it.
const _groups = [
  'aàáâãäåāăąǎǟǡǻȁȃȧḁạảấầẩẫậắằẳẵặ',
  'cçćĉċč',
  'dďđ',
  'eèéêëēĕėęěȅȇȩḕḗẹẻẽếềểễệ',
  'gĝğġģǧǵ',
  'hĥ',
  'iìíîïĩīĭįǐȉȋḯịỉ',
  'jĵ',
  'kķǩ',
  'lĺļľ',
  'nñńņňǹ',
  'oòóôõöōŏőơǒǫǭȍȏȯọỏốồổỗộớờởỡợ',
  'rŕŗřȑȓ',
  'sśŝşšș',
  'tţťț',
  'uùúûüũūŭůűųưǔǖǘǚǜȕȗụủứừửữự',
  'wŵ',
  'yýÿŷỳỵỷỹ',
  'zźżž',
];

final Map<String, String> _folded = {
  for (final group in _groups)
    for (final rune in group.runes.skip(1)) String.fromCharCode(rune): group[0],
};
