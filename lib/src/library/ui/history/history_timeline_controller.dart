import 'history_timeline_scroll.dart';

/// Lets the page talk to the timeline: scroll to a day, take the place the
/// reader is at. The mounted timeline binds itself; with none bound a jump
/// does nothing and there is no anchor.
class HistoryTimelineController {
  bool Function(DateTime day)? _jump;
  HistoryAnchor? Function()? _anchor;

  /// For the timeline's state only.
  void bind({
    required bool Function(DateTime day) jump,
    required HistoryAnchor? Function() anchor,
  }) {
    _jump = jump;
    _anchor = anchor;
  }

  /// Releases what [jump] bound, unless another timeline took the controller
  /// meanwhile (a new year's timeline mounts before the old one goes).
  void unbind(bool Function(DateTime day) jump) {
    if (_jump != jump) return;
    _jump = null;
    _anchor = null;
  }

  /// Scrolls so [day]'s bar is pinned at the top. False when no timeline is
  /// bound or [day] is not in its list.
  bool jumpToDay(DateTime day) => _jump?.call(day) ?? false;

  /// The reader's place now, or null (page above the list, nothing bound).
  HistoryAnchor? captureAnchor() => _anchor?.call();
}
