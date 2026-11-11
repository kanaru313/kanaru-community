import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations_en.dart';
import 'package:kanaru/l10n/gen/app_localizations_vi.dart';
import 'package:kanaru/src/library/ui/browse/library_labels.dart';

void main() {
  const min = 60000;
  final en = AppLocalizationsEn();
  final vi = AppLocalizationsVi();

  test('formatTotalDuration: minutes, hours and minutes, whole hours (en)', () {
    expect(formatTotalDuration(en, 12 * min), '12 min');
    expect(formatTotalDuration(en, 125 * min), '2 h 5 min');
    expect(formatTotalDuration(en, 120 * min), '2 h');
  });

  test('formatTotalDuration: the same in Vietnamese', () {
    expect(formatTotalDuration(vi, 12 * min), '12 phút');
    expect(formatTotalDuration(vi, 125 * min), '2 giờ 5 phút');
    expect(formatTotalDuration(vi, 120 * min), '2 giờ');
  });
}
