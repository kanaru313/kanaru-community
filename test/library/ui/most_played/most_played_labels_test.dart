import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kanaru/l10n/gen/app_localizations_en.dart';
import 'package:kanaru/l10n/gen/app_localizations_vi.dart';
import 'package:kanaru/src/library/domain/history/history_ranges.dart';
import 'package:kanaru/src/library/ui/most_played/most_played_labels.dart';

final _today = DateTime(2026, 11, 20);
final _en = AppLocalizationsEn();
final _vi = AppLocalizationsVi();

void main() {
  setUpAll(() => initializeDateFormatting('en'));

  test('a preset reads its name and the days it covers', () {
    const range = MostPlayedRange();
    expect(
      mostPlayedRangeLine(_vi, range, _today),
      '30 ngày · 22/10 – 20/11/2026',
    );
    expect(mostPlayedPeriodText(_vi, range, _today), '22/10 – 20/11/2026');
    expect(
      mostPlayedRangeLine(
        _en,
        range.withPreset(MostPlayedPreset.today),
        _today,
      ),
      'Today · 20/11/2026',
    );
  });

  test('all time reads "Tất cả" alone', () {
    final all = const MostPlayedRange().withPreset(MostPlayedPreset.all);
    expect(mostPlayedRangeLine(_vi, all, _today), 'Tất cả');
    expect(mostPlayedPeriodText(_vi, all, _today), 'Tất cả');
    expect(mostPlayedListName(_vi, all, _today), 'Nghe nhiều nhất · Tất cả');
  });

  test('a custom range reads as its dates, across years too', () {
    final range = const MostPlayedRange().withCustom(
      DateTime(2025, 12, 28),
      DateTime(2026, 1, 3),
    );
    expect(mostPlayedRangeLine(_vi, range, _today), '28/12/2025 – 03/01/2026');
    expect(
      mostPlayedListName(_en, range, _today),
      'Most played · 28/12/2025 – 03/01/2026',
    );
    final one = const MostPlayedRange().withCustom(
      DateTime(2026, 11, 9),
      DateTime(2026, 11, 9),
    );
    expect(mostPlayedPeriodText(_vi, one, _today), '09/11/2026');
  });

  test('the list name is the range in a few words', () {
    expect(
      mostPlayedListName(_vi, const MostPlayedRange(), _today),
      'Nghe nhiều nhất · 30 ngày',
    );
    // A period moved back needs its dates to be told apart.
    expect(
      mostPlayedListName(_vi, const MostPlayedRange().previous(), _today),
      'Nghe nhiều nhất · 30 ngày · 22/09 – 21/10/2026',
    );
  });
}
