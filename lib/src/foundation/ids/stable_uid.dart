import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Separator between the parts that are hashed. A unit separator cannot
/// appear in paths, names or urls in practice, so `['a', 'bc']` and
/// `['ab', 'c']` hash differently.
const _partSeparator = '\x1f';

/// The first [length] hex characters of the SHA-256 of [parts] joined with
/// the unit separator (`\x1f`), encoded as UTF-8.
///
/// Deterministic: two devices hashing the same parts get the same string.
/// [length] must be between 1 and 64.
String stableHashHex(List<String> parts, int length) {
  if (length < 1 || length > 64) {
    throw RangeError.range(length, 1, 64, 'length');
  }
  final digest = sha256.convert(utf8.encode(parts.join(_partSeparator)));
  return digest.toString().substring(0, length);
}

/// A deterministic row uid: `'<prefix>:'` plus 16 hex characters of
/// [stableHashHex] over [parts].
///
/// Used for rows with a natural key, so two offline devices that create the
/// same row end up with the same uid. Compute it once when the row is
/// created; never recompute it when the natural key later changes.
String stableUid(String prefix, List<String> parts) =>
    '$prefix:${stableHashHex(parts, 16)}';
