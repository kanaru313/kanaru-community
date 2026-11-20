import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../domain/history/history_days.dart' show isSameDay;
import 'history_timeline_data.dart';

/// A place in the timeline that survives the list changing: the first play
/// under the pinned bar and how far its top is under the bar's bottom.
class HistoryAnchor {
  const HistoryAnchor(this.uid, this.below);
  final String uid;
  final double below;
}

/// Where a timeline that comes back from the filter puts the page: back at
/// [anchor] in its new list, or at [pixels] when the anchored play is gone
/// (or the page was above the list). Works once: the first timeline that
/// lays out takes it, a later one (another year, another visit) ignores it.
class HistoryRestore {
  HistoryRestore({this.anchor, this.pixels});
  final HistoryAnchor? anchor;
  final double? pixels;
  bool used = false;
}

/// The anchor at page scroll [pixels] of a list whose top is at [listTop];
/// null while the page is above the list, or past its last play.
HistoryAnchor? historyAnchorAt(
  HistoryTimelineData data,
  double listTop,
  double pixels,
) {
  final bar = data.metrics.dayBar;
  final offset = pixels - listTop;
  if (offset <= -bar) return null;
  final under = offset + bar;
  final play = data.index.playFromLine(data.index.lineAt(under));
  if (play < 0) return null;
  final top = data.index.topOf(data.index.lineOfPlay(play));
  return HistoryAnchor(data.plays[play].uid, top - under);
}

/// Page scroll offset that puts [restore] back in [data], unclamped; null
/// when it holds nothing to go back to.
double? historyRestorePixels(
  HistoryTimelineData data,
  double listTop,
  HistoryRestore restore,
) {
  final anchor = restore.anchor;
  final line = anchor == null ? null : data.lineOfPlay[anchor.uid];
  if (anchor != null && line != null) {
    return listTop +
        data.index.topOf(line) -
        anchor.below -
        data.metrics.dayBar;
  }
  return restore.pixels;
}

/// Page scroll offset that pins day [day]'s bar at the top with its first
/// play right under it; null when the day is not in [data]. The first day's
/// bar is the pinned bar itself, one bar height above the list's top.
double? historyDayPixels(
  HistoryTimelineData data,
  double listTop,
  DateTime day,
) {
  final i = data.days.indexWhere((d) => isSameDay(d.start, day));
  if (i < 0) return null;
  return listTop + (i == 0 ? -data.metrics.dayBar : data.index.dayOffset(i));
}

/// Moves [position] to [pixels], clamped to what the page can scroll.
void historyJumpClamped(ScrollPosition position, double pixels) => position
    .jumpTo(pixels.clamp(position.minScrollExtent, position.maxScrollExtent));

/// Keeps the reader's place when [data] replaced [old]: the first play under
/// the pinned bar stays where it is, whether plays came in, went out or came
/// back above it. Moved with `correctBy` (not an animated jump, which would
/// overwrite it) while the timeline rebuilds, so the same frame already has
/// it. With the list top still in full view a new play simply appears first.
void historyCorrectOffset(
  ScrollPosition position,
  double listTop,
  HistoryTimelineData old,
  HistoryTimelineData data,
) {
  final offset = position.hasPixels ? position.pixels - listTop : 0.0;
  if (offset <= -old.index.metrics.dayBar ||
      old.index.metrics.row != data.index.metrics.row) {
    return;
  }
  final shift = HistoryTimelineData.anchorShift(old, data, offset);
  // A big removal above would push the page past its top.
  final s = math.max(shift, position.minScrollExtent - position.pixels);
  if (s != 0) position.correctBy(s);
}
