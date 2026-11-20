import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/history/history_ordinal.dart';

void main() {
  test('A, B, A newest first: the later A is the 2nd', () {
    // Newest first: A, B, A. A has 2 plays, B 1.
    final o = assignOrdinals([1, 2, 1], playCount: {1: 2, 2: 1}, afterYear: {});
    expect(o, [2, 1, 1]);
  });

  test('plays after the year are subtracted', () {
    // The year holds the 3rd and 4th plays of track 1; 2 more came after it.
    final o = assignOrdinals([1, 1], playCount: {1: 6}, afterYear: {1: 2});
    expect(o, [4, 3]);
  });

  test('same-millisecond plays follow list order', () {
    final o = assignOrdinals([7, 7, 7], playCount: {7: 3}, afterYear: {});
    expect(o, [3, 2, 1]);
  });

  test('inconsistent counts never give a number below 1', () {
    final o = assignOrdinals([1, 1], playCount: {}, afterYear: {1: 5});
    expect(o, [1, 1]);
  });

  test('empty list', () {
    expect(assignOrdinals([], playCount: {}, afterYear: {}), isEmpty);
  });
}
