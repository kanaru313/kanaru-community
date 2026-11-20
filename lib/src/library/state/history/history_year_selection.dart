import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'history_providers.dart';

/// The year the user picked on the History page; null = the newest one.
/// Falls back to null when the picked year has no plays any more (its last
/// play was removed).
final historySelectedYearProvider =
    NotifierProvider.autoDispose<HistorySelectedYear, int?>(
      HistorySelectedYear.new,
    );

class HistorySelectedYear extends Notifier<int?> {
  @override
  int? build() {
    ref.listen(historyYearsProvider, (_, next) {
      final years = next.value;
      final picked = state;
      if (years != null && picked != null && !years.contains(picked)) {
        state = null;
      }
    });
    return null;
  }

  void select(int? year) => state = year;
}

/// The year the page shows: the picked one when it has plays, else the
/// newest; null while the years load or there is no history.
final historyShownYearProvider = Provider.autoDispose<int?>((ref) {
  final years = ref.watch(historyYearsProvider).value;
  if (years == null || years.isEmpty) return null;
  final picked = ref.watch(historySelectedYearProvider);
  return picked != null && years.contains(picked) ? picked : years.first;
});
