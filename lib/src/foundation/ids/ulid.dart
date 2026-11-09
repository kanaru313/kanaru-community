import 'dart:math';

/// Crockford base32: digits and letters without I, L, O, U.
const _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

/// A ULID is 26 characters: 48-bit timestamp (10 chars), 80 random bits
/// (16 chars). The first character is at most `7` so the value fits 128 bits.
final _ulidPattern = RegExp(r'^[0-7][0-9A-HJKMNP-TV-Z]{25}$');

/// Whether [value] is a well-formed uppercase ULID.
bool isUlid(String value) => _ulidPattern.hasMatch(value);

/// A new ULID: [nowMs] (default: now, epoch milliseconds, below 2^48)
/// followed by 80 random bits from [random] (default [Random.secure]).
///
/// Ids made in different milliseconds sort by creation time; ids made in the
/// same millisecond are ordered randomly.
String newUlid({int? nowMs, Random? random}) {
  final ms = nowMs ?? DateTime.now().millisecondsSinceEpoch;
  if (ms < 0 || ms >= 1 << 48) {
    throw RangeError.range(ms, 0, (1 << 48) - 1, 'nowMs');
  }
  final rng = random ?? Random.secure();
  final time = List<String>.filled(10, '');
  var rest = ms;
  for (var i = 9; i >= 0; i--) {
    time[i] = _alphabet[rest & 31];
    rest >>= 5;
  }
  final randomPart = [for (var i = 0; i < 16; i++) _alphabet[rng.nextInt(32)]];
  return time.join() + randomPart.join();
}
