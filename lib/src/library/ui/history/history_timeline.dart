import 'dart:math' as math;

import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/history/history_models.dart';
import '../browse/library_list_scaffold.dart';
import 'history_day_bar.dart';
import 'history_line_metrics.dart';
import 'history_row.dart';
import 'history_sticky_bar.dart';
import 'history_timeline_data.dart';
import 'history_timeline_index.dart';

/// The plays of a year as slivers for the page's own scroll view: the day
/// bar pinned under the page header, then one flat list of day header lines,
/// song rows and, last, the "See 2025" line.
///
/// Every line has a fixed extent ([HistoryTimelineIndex]), so the list places
/// lines without measuring and the pinned bar knows which day is at the top
/// from the scroll offset alone. When plays arrive at the top while the
/// reader is scrolled down, the scroll offset moves by the height they add,
/// so what is on screen stays where it is.
class HistoryTimeline extends StatefulWidget {
  const HistoryTimeline({
    super.key,
    required this.scope,
    required this.plays,
    required this.today,
    this.olderYear,
    this.onOlderYear,
  });

  /// What the plays are of (the year now; a day or a filter later). A change
  /// is a different list, not an edit of this one: the offset is not carried
  /// over by correction, and the page lands on the first day bar.
  final Object scope;

  /// The plays of [scope], newest first, as the page gives them.
  final List<HistoryPlay> plays;

  /// The local day the screen is on, for the names of the days.
  final DateTime today;

  /// The next older year with plays, offered after the last day.
  final int? olderYear;
  final VoidCallback? onOlderYear;

  @override
  State<HistoryTimeline> createState() => _HistoryTimelineState();
}

class _HistoryTimelineState extends State<HistoryTimeline> {
  /// Scroll offset of the list's top, read from the sliver constraints at
  /// layout (null before the first one).
  double? _listTop;

  /// The first layout of this timeline has run.
  bool _placed = false;

  HistoryTimelineData? _data;

  @override
  void didUpdateWidget(HistoryTimeline old) {
    super.didUpdateWidget(old);
    if (old.scope != widget.scope) {
      // A new scope starts over: nothing to correct against, land on top.
      _data = null;
      _placed = false;
    }
  }

  ScrollPosition? get _position => Scrollable.maybeOf(context)?.position;

  /// Scroll offset relative to the list's top; negative while the list's
  /// top is still below the viewport's.
  double _currentOffset() {
    final top = _listTop;
    final position = _position;
    if (top == null || position == null || !position.hasPixels) return 0;
    return position.pixels - top;
  }

  /// A new scope opens with its first day bar pinned and its first row right
  /// under it: when the page is scrolled past that place (the previous
  /// scope's depth), it goes there. Higher up (hero in view) it stays.
  void _placeAtTop() {
    if (!mounted) return;
    final top = _listTop;
    final position = _position;
    if (top == null || position == null || !position.hasPixels) return;
    final target = top - (_data?.metrics.dayBar ?? 0);
    if (position.pixels > target) position.jumpTo(target);
  }

  /// Rebuilds what is drawn when the plays or the line sizes changed, and
  /// keeps the reader's place: the first play under the pinned bar stays
  /// where it is, whether plays came in, went out or came back above it.
  HistoryTimelineData _refresh(HistoryLineMetrics metrics) {
    final old = _data;
    final hasOlder = widget.olderYear != null;
    if (old != null &&
        old.matches(widget.plays, metrics, hasOlderYear: hasOlder)) {
      return old;
    }
    final data = _data = HistoryTimelineData(
      widget.plays,
      metrics,
      hasOlderYear: hasOlder,
    );
    final position = _position;
    final offset = _currentOffset();
    // Scrolled under the bar at all: with the list top in full view a new
    // play simply appears first. Moved with `correctBy` (not an animated
    // jump, which would overwrite it) while the timeline rebuilds, so the
    // same frame already has it.
    if (old != null &&
        position != null &&
        _listTop != null &&
        offset > -old.index.metrics.dayBar &&
        old.index.metrics.row == metrics.row) {
      final shift = HistoryTimelineData.anchorShift(old, data, offset);
      // A big removal above would push the page past its top.
      final s = math.max(shift, position.minScrollExtent - position.pixels);
      if (s != 0) position.correctBy(s);
    }
    return data;
  }

  Widget _line(BuildContext context, HistoryTimelineData data, int i) {
    final info = data.index.lineInfo(i);
    final gutter = libraryRowGutter(context);
    switch (info.kind) {
      case HistoryLineKind.header:
        return HistoryDayBar(
          day: data.days[info.day],
          today: widget.today,
          height: data.index.metrics.dayBar,
        );
      case HistoryLineKind.row:
        final play = data.days[info.day].plays[info.row];
        return Padding(
          key: ValueKey(play.uid),
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: HistoryRow(
            play: play,
            queue: data.queueOf(info.day),
            markCurrent: data.newestOfSong.contains(play.uid),
          ),
        );
      case HistoryLineKind.footer:
        final l10n = AppLocalizations.of(context);
        final year = widget.olderYear!;
        return Center(
          child: FilledButton.tonal(
            onPressed: widget.onOlderYear,
            child: Text(l10n.historyYearFooter('$year')),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = HistoryLineMetrics.of(
      Theme.of(context).textTheme,
      MediaQuery.textScalerOf(context),
    );
    final data = _refresh(metrics);
    return SliverMainAxisGroup(
      slivers: [
        // The bar reads its own constraints in layout: the day at the top is
        // right whatever moved above it (a notice, the hero, the text scale).
        SliverLayoutBuilder(
          builder: (context, constraints) => KStickyBarSliver(
            height: metrics.dayBar,
            child: HistoryStickyBar(
              index: data.index,
              days: data.days,
              today: widget.today,
              offset: constraints.scrollOffset - metrics.dayBar,
            ),
          ),
        ),
        SliverLayoutBuilder(
          builder: (context, constraints) {
            _listTop = constraints.precedingScrollExtent;
            if (!_placed) {
              _placed = true;
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _placeAtTop(),
              );
            }
            return SliverVariedExtentList.builder(
              itemCount: data.index.lineCount,
              itemExtentBuilder: (i, _) => data.index.extentOf(i),
              findChildIndexCallback: (key) =>
                  key is ValueKey<String> ? data.lineOfPlay[key.value] : null,
              itemBuilder: (context, i) => _line(context, data, i),
            );
          },
        ),
      ],
    );
  }
}
