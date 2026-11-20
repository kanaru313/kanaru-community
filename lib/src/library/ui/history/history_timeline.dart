import 'package:material_ui/material_ui.dart';

import '../../domain/history/history_models.dart';
import 'history_line_metrics.dart';
import 'history_timeline_controller.dart';
import 'history_timeline_data.dart';
import 'history_timeline_slivers.dart';
import 'history_timeline_scroll.dart';

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
    this.controller,
    this.restore,
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

  /// Lets the page scroll to a day of this list.
  final HistoryTimelineController? controller;

  /// Where to put the page when this timeline first lays out (coming back
  /// from the filter), instead of at the first day bar. Taken once.
  final HistoryRestore? restore;

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
  void initState() {
    super.initState();
    widget.controller?.bind(jump: _jumpToDay, anchor: _anchor);
  }

  @override
  void dispose() {
    widget.controller?.unbind(_jumpToDay);
    super.dispose();
  }

  @override
  void didUpdateWidget(HistoryTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.unbind(_jumpToDay);
      widget.controller?.bind(jump: _jumpToDay, anchor: _anchor);
    }
    if (oldWidget.scope != widget.scope) {
      // A new scope starts over: nothing to correct against, land on top.
      _data = null;
      _placed = false;
    }
  }

  ScrollPosition? get _position => Scrollable.maybeOf(context)?.position;

  HistoryAnchor? _anchor() {
    final data = _data;
    final top = _listTop;
    final position = _position;
    if (!mounted ||
        data == null ||
        top == null ||
        position == null ||
        !position.hasPixels) {
      return null;
    }
    return historyAnchorAt(data, top, position.pixels);
  }

  /// Scrolls so day [day]'s bar is pinned at the top, its first row right
  /// under it. Reads the list's place from its last layout, so it is right
  /// whatever sits above the list (the hero, a notice, the text scale).
  bool _jumpToDay(DateTime day) {
    final data = _data;
    final top = _listTop;
    final position = _position;
    if (!mounted ||
        data == null ||
        top == null ||
        position == null ||
        !position.hasPixels) {
      return false;
    }
    final pixels = historyDayPixels(data, top, day);
    if (pixels == null) return false;
    historyJumpClamped(position, pixels);
    return true;
  }

  /// A new scope opens with its first day bar pinned and its first row right
  /// under it: when the page is scrolled past that place (the previous
  /// scope's depth), it goes there. Higher up (hero in view) it stays. A
  /// timeline that comes back from the filter goes back to the reader's
  /// place instead, once.
  void _placeAtTop() {
    if (!mounted) return;
    final top = _listTop;
    final data = _data;
    final position = _position;
    if (top == null || data == null || position == null) return;
    if (!position.hasPixels) return;
    final restore = widget.restore;
    if (restore != null && !restore.used) {
      restore.used = true;
      final pixels = historyRestorePixels(data, top, restore);
      if (pixels != null) {
        historyJumpClamped(position, pixels);
        return;
      }
    }
    final target = top - data.metrics.dayBar;
    if (position.pixels > target) position.jumpTo(target);
  }

  /// Rebuilds what is drawn when the plays or the line sizes changed, and
  /// keeps the reader's place (see [historyCorrectOffset]).
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
    final top = _listTop;
    if (old != null && position != null && top != null) {
      historyCorrectOffset(position, top, old, data);
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final metrics = HistoryLineMetrics.of(
      Theme.of(context).textTheme,
      MediaQuery.textScalerOf(context),
    );
    final data = _refresh(metrics);
    return historyTimelineSlivers(
      data,
      today: widget.today,
      olderYear: widget.olderYear,
      onOlderYear: widget.onOlderYear,
      onListLayout: (top) {
        _listTop = top;
        if (!_placed) {
          _placed = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _placeAtTop());
        }
      },
    );
  }
}
