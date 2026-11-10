import '../../../foundation/text/text_fold.dart';

final _chunk = RegExp(r'\d+|\D+');
final _leadingZeros = RegExp(r'^0+');

/// Orders names the way a person reads them: digit runs by value ("2" before
/// "10"), text without case or diacritics, and only then the raw strings so
/// the order is total. Digit runs of any length are compared without parsing.
int naturalCompare(String a, String b) {
  final ca = _chunk.allMatches(foldDiacritics(a)).map((m) => m[0]!).toList();
  final cb = _chunk.allMatches(foldDiacritics(b)).map((m) => m[0]!).toList();
  final n = ca.length < cb.length ? ca.length : cb.length;
  for (var i = 0; i < n; i++) {
    final x = ca[i], y = cb[i];
    final xd = _isDigit(x), yd = _isDigit(y);
    final int c;
    if (xd && yd) {
      c = _compareDigits(x, y);
    } else {
      c = x.compareTo(y);
    }
    if (c != 0) return c;
  }
  if (ca.length != cb.length) return ca.length.compareTo(cb.length);
  return a.compareTo(b);
}

bool _isDigit(String s) => s.codeUnitAt(0) >= 0x30 && s.codeUnitAt(0) <= 0x39;

int _compareDigits(String x, String y) {
  final xs = x.replaceFirst(_leadingZeros, '');
  final ys = y.replaceFirst(_leadingZeros, '');
  if (xs.length != ys.length) return xs.length.compareTo(ys.length);
  return xs.compareTo(ys);
}
