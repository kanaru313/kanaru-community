import '../../domain/history/history_models.dart';
import 'history_line_metrics.dart';
import 'history_row.dart';
import 'history_timeline_index.dart';

/// What the timeline draws, derived from the plays of a year and the line
/// sizes: the days, the line index, which play is the newest of its song,
/// where each play's line is, and the queue of each day.
class HistoryTimelineData {
  HistoryTimelineData(
    this.plays,
    HistoryLineMetrics metrics, {
    required bool hasOlderYear,
  }) : days = groupByDay(plays) {
    index = HistoryTimelineIndex(
      [for (final d in days) d.playCount],
      metrics,
      hasOlderYear: hasOlderYear,
    );
    final seen = <int>{};
    for (var i = 0; i < plays.length; i++) {
      final p = plays[i];
      if (seen.add(p.track.id.value)) newestOfSong.add(p.uid);
      lineOfPlay[p.uid] = index.lineOfPlay(i);
    }
  }

  /// Plays of the year, newest first.
  final List<HistoryPlay> plays;
  final List<HistoryDay> days;
  late final HistoryTimelineIndex index;

  /// Uids of the plays that are the newest of their song (only these can be
  /// marked as playing).
  final Set<String> newestOfSong = {};

  /// Line of each play, by uid (keeps a row's state when lines move).
  final Map<String, int> lineOfPlay = {};
  final Map<int, HistoryDayQueue> _queues = {};

  /// Same plays, same sizes: nothing to rebuild.
  bool matches(
    List<HistoryPlay> other,
    HistoryLineMetrics metrics, {
    required bool hasOlderYear,
  }) =>
      identical(plays, other) &&
      index.metrics.row == metrics.row &&
      index.metrics.dayBar == metrics.dayBar &&
      index.hasOlderYear == hasOlderYear;

  /// What a tap on a row of day [day] queues; built once per day.
  HistoryDayQueue queueOf(int day) =>
      _queues.putIfAbsent(day, () => HistoryDayQueue(days[day].plays));

  HistoryLineMetrics get metrics => index.metrics;

  /// How far the first play under the pinned bar at [offset] moved between
  /// [before] and [after] (signed; 0 when nothing moved). If that play is
  /// gone, the next one that is still there anchors. The caller moves the
  /// scroll offset by this much so the content on screen stays put.
  static double anchorShift(
    HistoryTimelineData before,
    HistoryTimelineData after,
    double offset,
  ) {
    final line = before.index.lineAt(offset + before.metrics.dayBar);
    if (line < 0) return 0;
    final first = before.index.playFromLine(line);
    if (first < 0) return 0;
    for (var play = first; play < before.plays.length; play++) {
      final now = after.lineOfPlay[before.plays[play].uid];
      if (now == null) continue;
      return after.index.topOf(now) -
          before.index.topOf(before.index.lineOfPlay(play));
    }
    return 0;
  }
}
