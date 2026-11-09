/// Fractional order keys: strings that sort (by code unit, as SQLite
/// `ORDER BY` on text does) in the order of the list they place, so inserting
/// between two rows needs one new key and no renumbering.
///
/// A port of rocicorp/fractional-indexing (CC0) with base62 digits
/// `0-9A-Za-z` in ASCII order. A key is an integer part (head letter `a`-`z`
/// or `A`-`Z` that gives its length) plus an optional fraction that never
/// ends in `0`. There is no rebalancing and no repair of malformed keys:
/// they throw [ArgumentError].
library;

const _digits =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
const _smallestInteger = 'A00000000000000000000000000';
const _zero = '0';

/// A key that sorts strictly between [a] and [b]. `null` stands for the
/// start (for [a]) or the end (for [b]) of the list.
///
/// Throws [ArgumentError] when a key is malformed or [a] is not less than
/// [b].
String generateKeyBetween(String? a, String? b) {
  if (a != null) _validateOrderKey(a);
  if (b != null) _validateOrderKey(b);
  if (a != null && b != null && a.compareTo(b) >= 0) {
    throw ArgumentError('$a >= $b');
  }
  if (a == null) {
    if (b == null) return 'a$_zero';
    final ib = _integerPart(b);
    final fb = b.substring(ib.length);
    if (ib == _smallestInteger) return ib + _midpoint('', fb);
    if (ib.compareTo(b) < 0) return ib;
    final res = _decrementInteger(ib);
    if (res == null) throw ArgumentError('Cannot go below $b');
    return res;
  }
  if (b == null) {
    final ia = _integerPart(a);
    final fa = a.substring(ia.length);
    final i = _incrementInteger(ia);
    return i ?? ia + _midpoint(fa, null);
  }
  final ia = _integerPart(a);
  final fa = a.substring(ia.length);
  final ib = _integerPart(b);
  final fb = b.substring(ib.length);
  if (ia == ib) return ia + _midpoint(fa, fb);
  final i = _incrementInteger(ia);
  if (i == null) throw ArgumentError('Cannot increment $ia');
  if (i.compareTo(b) < 0) return i;
  return ia + _midpoint(fa, null);
}

/// [n] ascending keys that all sort strictly between [a] and [b] (`null`
/// means open end). The keys stay short: they are spread by halving.
List<String> generateNKeysBetween(String? a, String? b, int n) {
  if (n < 0) throw RangeError.value(n, 'n', 'Must not be negative');
  if (n == 0) return [];
  if (n == 1) return [generateKeyBetween(a, b)];
  if (a == null || b == null) {
    // Open end: walk away from the bound one key at a time.
    var c = generateKeyBetween(a, b);
    final result = [c];
    for (var i = 0; i < n - 1; i++) {
      c = b == null ? generateKeyBetween(c, b) : generateKeyBetween(a, c);
      result.add(c);
    }
    return b == null ? result : result.reversed.toList();
  }
  final mid = n ~/ 2;
  final c = generateKeyBetween(a, b);
  return [
    ...generateNKeysBetween(a, c, mid),
    c,
    ...generateNKeysBetween(c, b, n - mid - 1),
  ];
}

/// A fraction strictly between [a] and [b] (both fractions, [a] empty means
/// zero, [b] null means one).
String _midpoint(String a, String? b) {
  if (b != null && a.compareTo(b) >= 0) throw ArgumentError('$a >= $b');
  if (a.endsWith(_zero) || (b != null && b.endsWith(_zero))) {
    throw ArgumentError('Trailing zero');
  }
  if (b != null) {
    // Skip the common prefix; a missing digit in [a] counts as zero.
    var n = 0;
    while ((n < a.length ? a[n] : _zero) == (n < b.length ? b[n] : null)) {
      n++;
    }
    if (n > 0) {
      return b.substring(0, n) + _midpoint(_from(a, n), b.substring(n));
    }
  }
  final digitA = a.isNotEmpty ? _digits.indexOf(a[0]) : 0;
  final digitB = b != null ? _digits.indexOf(b[0]) : _digits.length;
  if (digitB - digitA > 1) {
    // Round half up, like Math.round in the original.
    return _digits[(digitA + digitB + 1) ~/ 2];
  }
  if (b != null && b.length > 1) return b.substring(0, 1);
  return _digits[digitA] + _midpoint(_from(a, 1), null);
}

int _integerLength(String head) {
  final c = head.codeUnitAt(0);
  if (c >= 0x61 && c <= 0x7a) return c - 0x61 + 2;
  if (c >= 0x41 && c <= 0x5a) return 0x5a - c + 2;
  throw ArgumentError('Invalid order key head: $head');
}

void _validateInteger(String integer) {
  if (integer.length != _integerLength(integer[0])) {
    throw ArgumentError('Invalid integer part of order key: $integer');
  }
}

String _integerPart(String key) {
  final length = _integerLength(key[0]);
  if (length > key.length) throw ArgumentError('Invalid order key: $key');
  return key.substring(0, length);
}

void _validateOrderKey(String key) {
  if (key.isEmpty) throw ArgumentError('Invalid order key: empty');
  if (key.split('').any((c) => !_digits.contains(c))) {
    throw ArgumentError('Invalid order key: $key');
  }
  if (key == _smallestInteger) throw ArgumentError('Invalid order key: $key');
  final i = _integerPart(key);
  final f = key.substring(i.length);
  if (f.endsWith(_zero)) throw ArgumentError('Invalid order key: $key');
}

/// The next integer part, or null at the very end of the range.
String? _incrementInteger(String x) {
  _validateInteger(x);
  final head = x[0];
  final digs = x.substring(1).split('');
  var carry = true;
  for (var i = digs.length - 1; carry && i >= 0; i--) {
    final d = _digits.indexOf(digs[i]) + 1;
    if (d == _digits.length) {
      digs[i] = _digits[0];
    } else {
      digs[i] = _digits[d];
      carry = false;
    }
  }
  if (carry) {
    if (head == 'Z') return 'a$_zero';
    if (head == 'z') return null;
    final h = String.fromCharCode(head.codeUnitAt(0) + 1);
    if (h.compareTo('a') > 0) {
      digs.add(_zero);
    } else {
      digs.removeLast();
    }
    return h + digs.join();
  }
  return head + digs.join();
}

/// The previous integer part, or null at the very start of the range.
String? _decrementInteger(String x) {
  _validateInteger(x);
  final head = x[0];
  final digs = x.substring(1).split('');
  final last = _digits[_digits.length - 1];
  var borrow = true;
  for (var i = digs.length - 1; borrow && i >= 0; i--) {
    final d = _digits.indexOf(digs[i]) - 1;
    if (d == -1) {
      digs[i] = last;
    } else {
      digs[i] = _digits[d];
      borrow = false;
    }
  }
  if (borrow) {
    if (head == 'a') return 'Z$last';
    if (head == 'A') return null;
    final h = String.fromCharCode(head.codeUnitAt(0) - 1);
    if (h.compareTo('Z') < 0) {
      digs.add(last);
    } else {
      digs.removeLast();
    }
    return h + digs.join();
  }
  return head + digs.join();
}

/// `s.substring(start)` that gives an empty string past the end, like
/// JavaScript `slice`.
String _from(String s, int start) =>
    start >= s.length ? '' : s.substring(start);
