import '../../../foundation/text/text_fold.dart';

final _chunk = RegExp(r'\d+|\D+');
final _leadingZeros = RegExp(r'^0+');

/// A name prepared for natural ordering: folded and split once, so sorting a
/// long list compares ready keys instead of folding both names on every
/// comparison. Orders the way a person reads: digit runs by value ("2" before
/// "10"), text without case or diacritics, and only then the raw strings so
/// the order is total. Digit runs of any length are compared without parsing.
class NaturalKey implements Comparable<NaturalKey> {
  NaturalKey(this.raw)
    : _chunks = [
        for (final m in _chunk.allMatches(foldDiacritics(raw))) _Chunk(m[0]!),
      ];

  final String raw;
  final List<_Chunk> _chunks;

  @override
  int compareTo(NaturalKey other) {
    final a = _chunks, b = other._chunks;
    final n = a.length < b.length ? a.length : b.length;
    for (var i = 0; i < n; i++) {
      final x = a[i], y = b[i];
      final c = x.isDigits && y.isDigits
          ? x.compareDigits(y)
          : x.text.compareTo(y.text);
      if (c != 0) return c;
    }
    if (a.length != b.length) return a.length.compareTo(b.length);
    return raw.compareTo(other.raw);
  }
}

class _Chunk {
  _Chunk(this.text)
    : isDigits = text.codeUnitAt(0) >= 0x30 && text.codeUnitAt(0) <= 0x39,
      digits = text.replaceFirst(_leadingZeros, '');

  final String text;
  final bool isDigits;

  /// [text] without leading zeros (only read for digit chunks).
  final String digits;

  int compareDigits(_Chunk o) => digits.length != o.digits.length
      ? digits.length.compareTo(o.digits.length)
      : digits.compareTo(o.digits);
}

final Map<String, NaturalKey> _naturalKeys = {};

/// [NaturalKey] of [name], remembered across sorts so large directory trees
/// do not fold and split strings repeatedly on every UI notification or scan update.
NaturalKey naturalKeyOf(String name) {
  final hit = _naturalKeys[name];
  if (hit != null) return hit;
  if (_naturalKeys.length > 50000) _naturalKeys.clear();
  return _naturalKeys[name] = NaturalKey(name);
}

/// Compares two names in natural order; for a long list sort by [naturalKeyOf]
/// built once per name instead.
int naturalCompare(String a, String b) =>
    naturalKeyOf(a).compareTo(naturalKeyOf(b));
