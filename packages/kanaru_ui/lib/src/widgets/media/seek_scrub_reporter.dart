import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import 'seek_drag_tracker.dart';
import 'seek_hold_tracker.dart';

/// The scrub part of a seek bar's input: tells the owner's `onScrub` the
/// time under the pointer while the bar is held or dragged (not
/// cancelling), and null once that ends, only when it changes.
///
/// The listener may rebuild other widgets (an app label through a provider),
/// so nothing is reported from a build method: changes found while building
/// (a track change, an unmount) are reported after the frame.
class SeekScrubReporter {
  /// The scrub follows `drag` and `hold`. `timeAt` maps a fraction of the
  /// time axis to a time (null: nothing to seek in), `fractionOf` a local x
  /// on a bar [width] wide to that fraction. `onScrub` and `mounted` are
  /// read when a report goes out, so the owner's latest widget is used.
  SeekScrubReporter({
    required this._drag,
    required this._hold,
    required this._timeAt,
    required this._fractionOf,
    required this._onScrub,
    required this._mounted,
  });

  final SeekDragTracker _drag;
  final SeekHoldTracker _hold;
  final Duration? Function(double fraction) _timeAt;
  final double Function(double dx, double width) _fractionOf;
  final ValueChanged<Duration?>? Function() _onScrub;
  final bool Function() _mounted;

  /// Width of the owner's latest layout, to place a hold on the time axis.
  /// Written by the owner's `LayoutBuilder` during layout and read only from
  /// pointer and timer callbacks, so the write needs no rebuild.
  double width = 0;

  /// What `onScrub` was last told.
  Duration? _last;

  /// A report waits for the end of the frame.
  bool _pending = false;

  /// The time under the pointer: the drag's unless it is cancelling, else
  /// the hold's; null when neither runs.
  Duration? _now() {
    final drag = _drag.fraction;
    if (drag != null) return _drag.cancelling ? null : _timeAt(drag);
    final heldX = _hold.heldX;
    return heldX == null ? null : _timeAt(_fractionOf(heldX, width));
  }

  /// Reports the current scrub when it changed. Not from build methods.
  void report() {
    final now = _now();
    if (now == _last) return;
    _last = now;
    _onScrub()?.call(now);
  }

  /// [report] once the current frame is done; for changes found while
  /// building (`didUpdateWidget`). Only while a scrub is active.
  void reportAfterFrame() {
    if (_last == null || _pending) return;
    _pending = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _pending = false;
      if (_mounted()) report();
    });
  }

  /// The owner leaves the tree: an active scrub ends, heard after the frame
  /// when rebuilding is allowed again.
  void dispose() {
    final onScrub = _onScrub();
    if (_last == null || onScrub == null) return;
    _last = null;
    SchedulerBinding.instance.addPostFrameCallback((_) => onScrub(null));
  }
}
