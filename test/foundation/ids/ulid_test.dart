import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/ids/ulid.dart';

void main() {
  test('has 26 Crockford characters and is a valid ULID', () {
    final id = newUlid();
    expect(id, hasLength(26));
    expect(id, matches(RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}$')));
    expect(isUlid(id), isTrue);
  });

  test('encodes the timestamp in the first 10 characters', () {
    final id = newUlid(nowMs: 0, random: Random(1));
    expect(id.substring(0, 10), '0000000000');
    expect(newUlid(nowMs: 32).substring(0, 10), '0000000010');
    expect(newUlid(nowMs: (1 << 48) - 1).substring(0, 10), '7ZZZZZZZZZ');
  });

  test('sorts by creation time across milliseconds', () {
    final random = Random(7);
    final ids = [
      for (final ms in [1, 2, 1000, 1700000000000, 1700000000001])
        newUlid(nowMs: ms, random: random),
    ];
    expect([...ids]..sort(), ids);
  });

  test('is reproducible with a seeded random and differs without', () {
    expect(
      newUlid(nowMs: 5, random: Random(3)),
      newUlid(nowMs: 5, random: Random(3)),
    );
    expect(newUlid(), isNot(newUlid()));
  });

  test('rejects timestamps outside 48 bits', () {
    expect(() => newUlid(nowMs: -1), throwsRangeError);
    expect(() => newUlid(nowMs: 1 << 48), throwsRangeError);
  });

  test('isUlid rejects malformed values', () {
    expect(isUlid(''), isFalse);
    expect(isUlid('test-device'), isFalse);
    expect(isUlid('01ARZ3NDEKTSV4RRFFQ69G5FAV'), isTrue);
    expect(isUlid('01arz3ndektsv4rrffq69g5fav'), isFalse);
    expect(isUlid('01ARZ3NDEKTSV4RRFFQ69G5FAI'), isFalse);
    expect(isUlid('81ARZ3NDEKTSV4RRFFQ69G5FAV'), isFalse);
  });
}
