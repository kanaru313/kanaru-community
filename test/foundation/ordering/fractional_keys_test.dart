import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/ordering/fractional_keys.dart';

void main() {
  group('generateKeyBetween table', () {
    const cases = <(String?, String?, String)>[
      (null, null, 'a0'),
      (null, 'a0', 'Zz'),
      ('a0', null, 'a1'),
      ('a0', 'a1', 'a0V'),
      ('a1', 'a2', 'a1V'),
      ('a0V', 'a1', 'a0l'),
      ('Zz', 'a0', 'ZzV'),
      ('Zz', 'a1', 'a0'),
      (null, 'Y00', 'Xzzz'),
      ('bzz', null, 'c000'),
      ('a0', 'a0V', 'a0G'),
      ('a0', 'a0G', 'a08'),
      ('b125', 'b129', 'b127'),
      ('a0', 'a1V', 'a1'),
      ('Zz', 'a01', 'a0'),
      (null, 'a0V', 'a0'),
      (null, 'b999', 'b99'),
      (null, 'A000000000000000000000000001', 'A000000000000000000000000000V'),
      ('zzzzzzzzzzzzzzzzzzzzzzzzzzy', null, 'zzzzzzzzzzzzzzzzzzzzzzzzzzz'),
      ('zzzzzzzzzzzzzzzzzzzzzzzzzzz', null, 'zzzzzzzzzzzzzzzzzzzzzzzzzzzV'),
    ];
    for (final (a, b, expected) in cases) {
      test('($a, $b) -> $expected', () {
        expect(generateKeyBetween(a, b), expected);
      });
    }
  });

  group('generateKeyBetween errors', () {
    test('rejects a >= b', () {
      expect(() => generateKeyBetween('a1', 'a0'), throwsArgumentError);
      expect(() => generateKeyBetween('a1', 'a1'), throwsArgumentError);
    });
    test('rejects malformed keys', () {
      expect(() => generateKeyBetween('a00', null), throwsArgumentError);
      expect(() => generateKeyBetween('a00', 'a1'), throwsArgumentError);
      expect(() => generateKeyBetween('0', null), throwsArgumentError);
      expect(() => generateKeyBetween('', null), throwsArgumentError);
      expect(() => generateKeyBetween('a0-', null), throwsArgumentError);
      expect(() => generateKeyBetween('a0é', null), throwsArgumentError);
      expect(() => generateKeyBetween('a0 1', 'a2'), throwsArgumentError);
      expect(() => generateKeyBetween(null, 'a_1'), throwsArgumentError);
      expect(() => generateKeyBetween('a', null), throwsArgumentError);
      expect(
        () => generateKeyBetween(null, 'A00000000000000000000000000'),
        throwsArgumentError,
      );
    });
  });

  group('generateNKeysBetween', () {
    test('zero and one', () {
      expect(generateNKeysBetween(null, null, 0), isEmpty);
      expect(generateNKeysBetween(null, null, 1), ['a0']);
      expect(() => generateNKeysBetween(null, null, -1), throwsRangeError);
    });
    test('README examples', () {
      expect(generateNKeysBetween(null, null, 5), [
        'a0',
        'a1',
        'a2',
        'a3',
        'a4',
      ]);
      expect(generateNKeysBetween('a4', null, 10), [
        'a5', 'a6', 'a7', 'a8', 'a9', 'aA', 'aB', 'aC', 'aD', 'aE', //
      ]);
      expect(generateNKeysBetween(null, 'a0', 5), [
        'Zv',
        'Zw',
        'Zx',
        'Zy',
        'Zz',
      ]);
      expect(generateNKeysBetween('a0', 'a2', 20), [
        'a04', 'a08', 'a0G', 'a0K', 'a0O', 'a0V', 'a0Z', 'a0d', 'a0l', 'a0t', //
        'a1', 'a14', 'a18', 'a1G', 'a1O', 'a1V', 'a1Z', 'a1d', 'a1l', 'a1t', //
      ]);
    });
    test('sorted and strictly inside the gap', () {
      for (final (a, b) in <(String?, String?)>[
        (null, null),
        ('a0', null),
        (null, 'a0'),
        ('a0', 'a1'),
        ('Zz', 'a0'),
      ]) {
        final keys = generateNKeysBetween(a, b, 37);
        expect(keys, hasLength(37));
        expect([...keys]..sort(), keys);
        expect(keys.toSet(), hasLength(37));
        if (a != null) expect(a.compareTo(keys.first) < 0, isTrue);
        if (b != null) expect(keys.last.compareTo(b) < 0, isTrue);
      }
    });
  });

  test('1000 inserts into the same gap stay ordered', () {
    final keys = <String>['a0', 'a1'];
    // Always insert right after the first key: the gap keeps narrowing.
    for (var i = 0; i < 1000; i++) {
      keys.insert(1, generateKeyBetween(keys[0], keys[1]));
    }
    expect([...keys]..sort(), keys);
    expect(keys.toSet(), hasLength(keys.length));
    // Always insert right before the last key.
    final tail = <String>['a0', 'a1'];
    for (var i = 0; i < 1000; i++) {
      tail.insert(
        tail.length - 1,
        generateKeyBetween(tail[tail.length - 2], tail.last),
      );
    }
    expect([...tail]..sort(), tail);
  });

  test('1000 random operations match a Dart list', () {
    final random = Random(42);
    final keys = <String>[];
    final ids = <int>[]; // ids[i] is the row that holds keys[i]
    final byKey = <String, int>{};
    for (var op = 0; op < 1000; op++) {
      if (keys.isNotEmpty && random.nextInt(4) == 0) {
        final at = random.nextInt(keys.length);
        byKey.remove(keys[at]);
        keys.removeAt(at);
        ids.removeAt(at);
        continue;
      }
      final at = random.nextInt(keys.length + 1);
      final key = generateKeyBetween(
        at == 0 ? null : keys[at - 1],
        at == keys.length ? null : keys[at],
      );
      keys.insert(at, key);
      ids.insert(at, op);
      byKey[key] = op;
    }
    final sorted = byKey.keys.toList()..sort();
    expect([for (final k in sorted) byKey[k]], ids);
  });
}
