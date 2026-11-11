import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/browse/natural_compare.dart';

List<String> sorted(List<String> l) => [...l]..sort(naturalCompare);

void main() {
  test('digit runs compare by value', () {
    expect(sorted(['10', '2', '1']), ['1', '2', '10']);
    expect(sorted(['Disc 10', 'Disc 9', 'Disc 100']), [
      'Disc 9',
      'Disc 10',
      'Disc 100',
    ]);
  });

  test('huge digit runs do not overflow', () {
    const big = '99999999999999999999999999';
    expect(naturalCompare('a${big}1', 'a$big'), greaterThan(0));
    expect(naturalCompare('a$big', 'a${big}1'), lessThan(0));
  });

  test('leading zeros are equal by value, raw order breaks the tie', () {
    expect(naturalCompare('02', '2'), isNot(0));
    expect(naturalCompare('2', '10'), lessThan(0));
    expect(naturalCompare('02', '10'), lessThan(0));
  });

  test('ignores case and diacritics before the raw tie break', () {
    expect(naturalCompare('Đen', 'dep'), lessThan(0));
    expect(naturalCompare('a', 'B'), lessThan(0));
    expect(naturalCompare('Vũ', 'vu'), isNot(0));
    expect(naturalCompare('same', 'same'), 0);
  });

  test('prefix sorts first and text beats nothing', () {
    expect(naturalCompare('a', 'a1'), lessThan(0));
    expect(naturalCompare('', 'a'), lessThan(0));
  });

  test('antisymmetric', () {
    const names = ['1', 'a', 'A1', 'a10', 'a2', 'Đ', 'd', '', '007'];
    for (final x in names) {
      for (final y in names) {
        expect(naturalCompare(x, y).sign, -naturalCompare(y, x).sign);
      }
    }
  });
}
