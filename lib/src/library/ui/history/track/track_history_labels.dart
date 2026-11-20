import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../playback/ui/playback_time_label.dart' show formatClock;
import '../../../domain/history/history_days.dart';
import '../../../domain/history/history_models.dart';
import '../history_labels.dart';

/// `Today · 20/11/2026 · 21:42`: when a play began, line 1 of its row. The
/// day is named as a History day bar names it (Today, Yesterday, a weekday
/// up to six days back, else `dd/MM`), then the full date and the time.
String trackPlayWhen(AppLocalizations l10n, int playedAt, DateTime today) => [
  historyDayLabel(
    l10n,
    localDay(DateTime.fromMillisecondsSinceEpoch(playedAt)),
    today,
  ),
  historyDate(playedAt),
  historyClock(l10n, playedAt),
].join(' · ');

/// `listened 3:12`: line 2 of a play's row; null when the length is unknown.
String? trackPlayListened(AppLocalizations l10n, int? listenedMs) =>
    listenedMs == null
    ? null
    : l10n.historyTrackListened(
        formatClock(Duration(milliseconds: listenedMs)),
      );

/// The description under the hero: `Last played today 21:42 · first played
/// 07/10/2026 · 22 min listened in total.` Parts the song has no figure for
/// are left out; null when none is left. [today] is the local day the page
/// is on, so the last play reads "today" or "yesterday" instead of a date.
String? trackHistorySummary(
  AppLocalizations l10n,
  TrackHistory history,
  DateTime today, {
  required String Function(int ms) formatTotal,
}) {
  final last = history.last;
  final first = history.first;
  final parts = <String>[
    if (last != null)
      l10n.historyTrackSummaryLast(_lastPlayWhen(l10n, last, today)),
    if (first != null) l10n.historyTrackSummaryFirst(historyDate(first)),
    if (history.listenedMs > 0)
      l10n.historyTrackSummaryTotal(formatTotal(history.listenedMs)),
  ];
  return parts.isEmpty ? null : '${parts.join(' · ')}.';
}

String _lastPlayWhen(AppLocalizations l10n, int epochMs, DateTime today) {
  final day = localDay(DateTime.fromMillisecondsSinceEpoch(epochMs));
  return l10n.historyTrackWhen(
    historyDayLabel(l10n, day, today).toLowerCase(),
    historyClock(l10n, epochMs),
  );
}
