import 'package:intl/intl.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/history/history_days.dart';
import '../../domain/history/history_models.dart';
import '../browse/library_labels.dart';

/// `dd/MM/yyyy` of an epoch-ms time, in the local zone.
String historyDate(int epochMs) =>
    DateFormat('dd/MM/yyyy')
        .format(DateTime.fromMillisecondsSinceEpoch(epochMs));

/// `Saturday, November 14, 2026` of a local day, as the add-to-playlist
/// picker and the day menu name it.
String historyFullDate(AppLocalizations l10n, DateTime day) =>
    DateFormat.yMMMMEEEEd(l10n.localeName).format(day);

/// `21:42` (24 hours) of an epoch-ms time, in the local zone.
String historyClock(AppLocalizations l10n, int epochMs) =>
    DateFormat.Hm(l10n.localeName)
        .format(DateTime.fromMillisecondsSinceEpoch(epochMs));

/// Name of a day in a header: Today, Yesterday, the weekday up to six days
/// back, then `dd/MM`. [today] is the local day the screen is on.
String historyDayLabel(AppLocalizations l10n, DateTime day, DateTime today) =>
    switch (dayLabelKind(day, today)) {
      DayLabelKind.today => l10n.historyDayToday,
      DayLabelKind.yesterday => l10n.historyDayYesterday,
      DayLabelKind.weekday => historyCapitalizeWords(
        DateFormat.EEEE(l10n.localeName).format(day),
      ),
      DayLabelKind.date => DateFormat('dd/MM').format(day),
    };

/// `dd/MM/yyyy · 6 plays · 4 songs · 1 h 5 min`, the figures line of a day.
String historyDayStats(AppLocalizations l10n, HistoryDay day) => [
  DateFormat('dd/MM/yyyy').format(day.start),
  l10n.historyDayPlays(day.playCount),
  l10n.librarySongCount(day.songCount),
  formatTotalDuration(l10n, day.listenedMs),
].join(' · ');

/// Third line of a play's row: `21:42 · play #6`, or `21:42 · can't play`
/// when its file is gone.
String historyRowLine(
  AppLocalizations l10n,
  HistoryPlay play, {
  required bool missing,
}) {
  final time = historyClock(l10n, play.playedAt);
  return missing
      ? l10n.historyRowMissing(time)
      : l10n.historyRowOrdinal(time, play.ordinal);
}

/// "thứ bảy" is "Thứ Bảy" in a header or a row.
String historyCapitalizeWords(String s) => s
    .split(' ')
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');
