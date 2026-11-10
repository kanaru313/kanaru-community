import 'package:unorm_dart/unorm_dart.dart' as unorm;

final RegExp _combiningMarks = RegExp('[̀-ͯ]');
final RegExp _whitespace = RegExp(r'\s+');

/// Reference fold: NFD, drop combining marks (U+0300-U+036F), NFC (keeps kana
/// dakuten), map đ/Đ to d/D, lower case.
String _slowFold(String s) {
  final stripped = unorm.nfd(s).replaceAll(_combiningMarks, '');
  return unorm
      .nfc(stripped)
      .replaceAll('đ', 'd')
      .replaceAll('Đ', 'D')
      .toLowerCase();
}

/// Folded value of every single code unit U+0080-U+1FFF, built on first use
/// from [_slowFold]. Null = the unit has no standalone fold (lone mark etc.).
const int _tableEnd = 0x2000;
List<String>? _table;

List<String> _buildTable() => List<String>.generate(
  _tableEnd,
  (i) => i < 0x80 ? '' : _slowFold(String.fromCharCode(i)),
  growable: false,
);

/// Code units that combine with neighbours: a per-unit table is not valid.
bool _composes(int u) =>
    (u >= 0x1100 && u <= 0x11ff) ||
    (u >= 0x1ab0 && u <= 0x1aff) ||
    (u >= 0x1dc0 && u <= 0x1dff) ||
    (u >= 0x20d0 && u <= 0x20ff) ||
    u == 0x3099 ||
    u == 0x309a ||
    (u >= 0xfe20 && u <= 0xfe2f);

/// Units >= U+2000 where folding is at most a lower-casing (no decomposition).
bool _isCaseOnly(int u) =>
    (u >= 0xac00 && u <= 0xd7a3) ||
    (u >= 0x4e00 && u <= 0x9fff) ||
    (u >= 0x3400 && u <= 0x4dbf) ||
    (u >= 0x3041 && u <= 0x30ff) ||
    (u >= 0xff00 && u <= 0xffef);

/// NFD -> drop combining marks (U+0300-U+036F) -> NFC -> map đ/Đ to d/D ->
/// lower case. "Vũ Cát Tường" becomes "vu cat tuong"; CJK is unchanged and
/// kana keep their dakuten. Single pass with a lookup table; returns [s]
/// itself when nothing changes.
String foldDiacritics(String s) {
  final table = _table ??= _buildTable();
  StringBuffer? out;
  var changed = false;
  for (var i = 0; i < s.length; i++) {
    final u = s.codeUnitAt(i);
    String? rep;
    if (u < 0x80) {
      if (u >= 0x41 && u <= 0x5a) rep = String.fromCharCode(u + 32);
    } else if (u >= 0x300 && u <= 0x36f) {
      rep = '';
    } else if (u < _tableEnd && !_composes(u)) {
      final t = table[u];
      if (t.length != 1 || t.codeUnitAt(0) != u) rep = t;
    } else if (_composes(u) || (u >= 0xd800 && u <= 0xdfff)) {
      // Needs neighbours (jamo, marks, surrogate pairs): use the reference.
      return _slowFold(s);
    } else if (!_isCaseOnly(u)) {
      // Blocks with compatibility or normalisation mappings: reference path.
      return _slowFold(s);
    } else {
      final c = String.fromCharCode(u).toLowerCase();
      if (c.length != 1 || c.codeUnitAt(0) != u) rep = c;
    }
    if (rep != null && out == null) {
      out = StringBuffer()..write(s.substring(0, i));
      changed = true;
    }
    if (out != null) out.write(rep ?? String.fromCharCode(u));
  }
  return changed ? out.toString() : s;
}

/// Matcher for [query]: folds and splits it once. True for a haystack that
/// contains every token after folding; an empty query matches everything.
bool Function(String) foldedMatcher(String query) {
  final tokens = foldDiacritics(query)
      .split(_whitespace)
      .where((t) => t.isNotEmpty)
      .toList(growable: false);
  if (tokens.isEmpty) return (_) => true;
  return (haystack) {
    final folded = foldDiacritics(haystack);
    for (final t in tokens) {
      if (!folded.contains(t)) return false;
    }
    return true;
  };
}

/// True if [haystack] contains every whitespace-separated token of [query]
/// after folding ("vu" matches "Vũ").
bool foldedContains(String haystack, String query) =>
    foldedMatcher(query)(haystack);
