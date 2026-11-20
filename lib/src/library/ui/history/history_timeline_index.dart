import 'dart:math' as math;

import 'history_line_metrics.dart';

/// What one line of the timeline is.
enum HistoryLineKind { header, row, footer }

/// A line of the timeline: [day] indexes the days (newest first); [row] is
/// the place of a play inside its day and -1 for the other kinds.
typedef HistoryLine = ({HistoryLineKind kind, int day, int row});

/// Place of every line of the timeline, from the plays per day alone.
///
/// The list is flat: for each day a header line (the first day has none: the
/// pinned bar shows it) and one line per play, then, when an older year
/// exists, a footer line. Extents are fixed per kind, so prefix sums give the
/// top of every line, the line under an offset and the offset of a day
/// without any row data. Offsets are relative to the top of the list.
class HistoryTimelineIndex {
  /// [dayCounts]: plays of each day, newest day first.
  HistoryTimelineIndex(
    this.dayCounts,
    this.metrics, {
    this.hasOlderYear = false,
  }) {
    final kinds = <HistoryLineKind>[];
    final days = <int>[];
    final rows = <int>[];
    final tops = <double>[0];
    final dayTops = <double>[];
    final dayLines = <int>[];
    final playLines = <int>[];
    final playOfLine = <int>[];
    var top = 0.0;
    void add(HistoryLineKind kind, int day, int row, double extent) {
      kinds.add(kind);
      playOfLine.add(kind == HistoryLineKind.row ? playLines.length - 1 : -1);
      days.add(day);
      rows.add(row);
      top += extent;
      tops.add(top);
    }

    for (var d = 0; d < dayCounts.length; d++) {
      dayTops.add(top);
      dayLines.add(kinds.length);
      if (d > 0) add(HistoryLineKind.header, d, -1, metrics.dayBar);
      for (var r = 0; r < dayCounts[d]; r++) {
        playLines.add(kinds.length);
        add(HistoryLineKind.row, d, r, metrics.row);
      }
    }
    if (hasOlderYear) {
      add(HistoryLineKind.footer, dayCounts.length, -1, metrics.footer);
    }
    _kinds = kinds;
    _days = days;
    _rows = rows;
    _tops = tops;
    _dayTops = dayTops;
    _dayLines = dayLines;
    _playLines = playLines;
    _playOfLine = playOfLine;
  }

  final List<int> dayCounts;
  final HistoryLineMetrics metrics;

  /// A last line offers the next older year.
  final bool hasOlderYear;

  late final List<HistoryLineKind> _kinds;
  late final List<int> _days;
  late final List<int> _rows;

  /// `_tops[i]` is the top of line `i`; the last entry is the list's height.
  late final List<double> _tops;
  late final List<double> _dayTops;
  late final List<int> _dayLines;
  late final List<int> _playLines;
  late final List<int> _playOfLine;

  int get lineCount => _kinds.length;
  int get dayCount => dayCounts.length;
  int get playCount => _playLines.length;

  /// Height of the whole list.
  double get totalExtent => _tops.last;

  double extentOf(int line) => _tops[line + 1] - _tops[line];
  double topOf(int line) => _tops[line];

  HistoryLine lineInfo(int line) =>
      (kind: _kinds[line], day: _days[line], row: _rows[line]);

  /// Index of the line that [offset] falls in (the first line for a negative
  /// offset, the last one past the end); -1 for an empty list.
  int lineAt(double offset) {
    if (lineCount == 0) return -1;
    var lo = 0;
    var hi = lineCount - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (_tops[mid] <= offset) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  /// Offset that puts day [day] under the pinned bar: the top of its header
  /// line (0 for the first day, whose header is the bar itself).
  double dayOffset(int day) => _dayTops[day];

  /// First line of day [day]: its header line, or its first row for day 0.
  int dayLine(int day) => _dayLines[day];

  /// The day the pinned bar shows at [offset]: the last day whose header has
  /// reached the bar's top.
  int dayAt(double offset) {
    if (dayCount == 0) return -1;
    var lo = 0;
    var hi = dayCount - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (_dayTops[mid] <= offset) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  /// How far the next day's header pushes the pinned bar up at [offset], in
  /// `(-dayBar, 0]`: 0 while the next header is below the bar. The header
  /// line is as tall as the bar, so at `-dayBar` the swap is complete.
  double pushUp(double offset) {
    final day = dayAt(offset);
    if (day < 0 || day + 1 >= dayCount) return 0;
    return math.min(0.0, _dayTops[day + 1] - offset - metrics.dayBar);
  }

  /// Top of the row of play number [play] (counted from the newest of the
  /// year, 0-based).
  double playOffset(int play) => _tops[_playLines[play]];

  /// The play on [line], or the next play after it; -1 when there is none
  /// (only the footer is left).
  int playFromLine(int line) {
    for (var i = line; i < lineCount; i++) {
      if (_playOfLine[i] >= 0) return _playOfLine[i];
    }
    return -1;
  }

  /// Line of play number [play] (counted from the newest of the year).
  int lineOfPlay(int play) => _playLines[play];

  /// Day index and row of play number [play].
  ({int day, int row}) playPlace(int play) {
    final info = lineInfo(_playLines[play]);
    return (day: info.day, row: info.row);
  }
}
