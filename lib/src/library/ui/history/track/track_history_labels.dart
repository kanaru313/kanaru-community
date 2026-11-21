import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../playback/ui/playback_time_label.dart' show formatClock;
import '../../../domain/history/history_days.dart';
import '../../../domain/history/history_models.dart';
import '../history_labels.dart';

/// The day cell of a play's row: "Hôm nay" / "Hôm qua" for those two days,
/// else the full date `dd/MM/yyyy` (no weekday: the table reads one date per
/// row). [today] is the local day the page is on.
String trackPlayDay(AppLocalizations l10n, int playedAt, DateTime today) {
  final day = localDay(DateTime.fromMillisecondsSinceEpoch(playedAt));
  return switch (dayLabelKind(day, today)) {
    DayLabelKind.today => l10n.historyDayToday,
    DayLabelKind.yesterday => l10n.historyDayYesterday,
    _ => historyDate(playedAt),
  };
}

/// `3:12`: how long a play was listened to, the last cell of its row; null
/// when the length is unknown.
String? trackPlayListened(int? listenedMs) =>
    listenedMs == null ? null : formatClock(Duration(milliseconds: listenedMs));

/// What a screen reader says for a play's row: the full date, the time and
/// the listened length (`14/11/2026, 21:42, listened 3:12`).
String trackPlayLabel(AppLocalizations l10n, HistoryPlay play) {
  final listened = trackPlayListened(play.listenedMs);
  return [
    historyDate(play.playedAt),
    historyClock(l10n, play.playedAt),
    if (listened != null) l10n.historyTrackListened(listened),
  ].join(', ');
}

/// The lines of the description under the hero, one fact each: `Last played:
/// today 21:42`, `First played: 07/10/2026`, `Listened in total: 22 min`.
/// Facts the song has no figure for are left out. [today] is the local day
/// the page is on, so the last play reads "today" or "yesterday" instead of a
/// date.
List<String> trackHistorySummary(
  AppLocalizations l10n,
  TrackHistory history,
  DateTime today, {
  required String Function(int ms) formatTotal,
}) {
  final last = history.last;
  final first = history.first;
  return [
    if (last != null)
      l10n.historyTrackSummaryLast(_lastPlayWhen(l10n, last, today)),
    if (first != null) l10n.historyTrackSummaryFirst(historyDate(first)),
    if (history.listenedMs > 0)
      l10n.historyTrackSummaryTotal(formatTotal(history.listenedMs)),
  ];
}

String _lastPlayWhen(AppLocalizations l10n, int epochMs, DateTime today) {
  final day = localDay(DateTime.fromMillisecondsSinceEpoch(epochMs));
  return l10n.historyTrackWhen(
    historyDayLabel(l10n, day, today).toLowerCase(),
    historyClock(l10n, epochMs),
  );
}
