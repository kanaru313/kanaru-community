/// Orders strings by code point, the way SQLite's BINARY collation does (it
/// compares UTF-8 bytes). Dart's `String.compareTo` compares UTF-16 code
/// units, which differs for characters above U+FFFF (an emoji sorts before
/// U+E000..U+FFFF there, after them in SQL). Lists ordered partly in SQL and
/// partly in Dart use this so both give the same order.
int compareCodePoints(String a, String b) {
  final n = a.length < b.length ? a.length : b.length;
  for (var i = 0; i < n; i++) {
    final x = a.codeUnitAt(i), y = b.codeUnitAt(i);
    if (x == y) continue;
    // A surrogate is half of a code point above U+FFFF: it sorts after every
    // unit below it and above U+E000..U+FFFF.
    final xs = x >= 0xD800 && x <= 0xDFFF;
    final ys = y >= 0xD800 && y <= 0xDFFF;
    if (xs != ys) return xs ? 1 : -1;
    return x < y ? -1 : 1;
  }
  return a.length.compareTo(b.length);
}
