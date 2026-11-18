import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/src/widgets/fold_for_match.dart';

void main() {
  test('Vietnamese letters and đ fold to plain ASCII', () {
    expect(foldForMatch('Vũ Cát Tường'), 'vu cat tuong');
    expect(foldForMatch('Đặng Thị Ngọc Ánh'), 'dang thi ngoc anh');
    expect(foldForMatch('ỳ ý ỷ ỹ ỵ ế ề ể ễ ệ'), 'y y y y y e e e e e');
  });

  test('other Latin accents fold too', () {
    expect(foldForMatch('Müller'), 'muller');
    expect(foldForMatch('Mötley Crüe'), 'motley crue');
    expect(foldForMatch('Beyoncé'), 'beyonce');
    expect(foldForMatch('Año ç Łódź'.replaceAll('Ł', 'L')), 'ano c lodz');
    expect(foldForMatch('Čeština Ščučí'), 'cestina scuci');
  });

  test('combining marks are dropped and other scripts only lower-cased', () {
    expect(foldForMatch('Café'), 'cafe');
    expect(foldForMatch('ABC 日本語'), 'abc 日本語');
  });

  test('matcher needs every token, folded, in any order', () {
    final match = foldedMatcher('cat vu');
    expect(match('Vũ Cát Tường'), isTrue);
    expect(match('Vũ Tường'), isFalse);
    expect(foldedMatcher('  ')('anything'), isTrue);
    expect(foldedMatcher('muller')('Müller'), isTrue);
  });
}
