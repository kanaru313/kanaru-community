import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/history/history_days.dart';
import '../../domain/history/history_ranges.dart';
import '../../domain/history/history_span.dart';

/// Name of a range chip: "30 ngày", "Tất cả", "Tuỳ chọn…".
String mostPlayedPresetLabel(AppLocalizations l10n, MostPlayedPreset preset) =>
    switch (preset) {
      MostPlayedPreset.today => l10n.historyMostPlayedRange1Day,
      MostPlayedPreset.days7 => l10n.historyMostPlayedRange7Days,
      MostPlayedPreset.days30 => l10n.historyMostPlayedRange30Days,
      MostPlayedPreset.months6 => l10n.historyMostPlayedRange6Months,
      MostPlayedPreset.year => l10n.historyMostPlayedRange1Year,
      MostPlayedPreset.all => l10n.historyMostPlayedRangeAll,
      MostPlayedPreset.custom => l10n.historyMostPlayedRangeCustom,
    };

/// The days [range] covers as dates ("16/10 – 14/11/2026", one day
/// "09/11/2026"); "Tất cả" for all time. [today] is the local day it is now.
String mostPlayedPeriodText(
  AppLocalizations l10n,
  MostPlayedRange range,
  DateTime today,
) {
  final days = range.days(today);
  if (days == null) {
    return range.preset == MostPlayedPreset.all
        ? l10n.historyMostPlayedRangeAll
        : l10n.historyMostPlayedRangeCustom;
  }
  // One day: "Hôm nay" / "Hôm qua" as long as they are true, else the date.
  if (range.preset == MostPlayedPreset.today) {
    return switch (range.back) {
      0 => l10n.historyDayToday,
      1 => l10n.historyDayYesterday,
      _ => historySpanText(days.start, days.start),
    };
  }
  return historySpanText(days.start, addDays(days.end, -1));
}

/// `30 ngày · 16/10 – 14/11/2026`: the preset and its dates. A custom range,
/// or a period moved back (it is no longer the current "30 ngày"), shows its
/// dates alone; "Tất cả" for all time.
String mostPlayedRangeLine(
  AppLocalizations l10n,
  MostPlayedRange range,
  DateTime today,
) {
  final period = mostPlayedPeriodText(l10n, range, today);
  return switch (range.preset) {
    _ when range.back != 0 => period,
    MostPlayedPreset.all || MostPlayedPreset.custom => period,
    _ => '${mostPlayedPresetLabel(l10n, range.preset)} · $period',
  };
}

/// The range in a few words, for a playlist or a file made from the list:
/// "30 ngày" (the dates alone once the period moved back),
/// "Tất cả", or a custom range's dates.
String mostPlayedRangeName(
  AppLocalizations l10n,
  MostPlayedRange range,
  DateTime today,
) => range.preset == MostPlayedPreset.custom || range.back != 0
    ? mostPlayedRangeLine(l10n, range, today)
    : mostPlayedPresetLabel(l10n, range.preset);

/// `Nghe nhiều nhất · 30 ngày`: the suggested playlist name and the M3U file
/// name of the list.
String mostPlayedListName(
  AppLocalizations l10n,
  MostPlayedRange range,
  DateTime today,
) =>
    l10n.historyMostPlayedPlaylistName(mostPlayedRangeName(l10n, range, today));
