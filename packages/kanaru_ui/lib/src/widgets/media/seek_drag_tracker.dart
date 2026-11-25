import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/services.dart';

/// The drag part of a seek bar's input: the fraction under the finger, the
/// track the drag began on, and the drag-up cancel.
///
/// The owner rebuilds after each call; seeking and the start / end callbacks
/// stay with the owner, which gets what to do from [end].
class SeekDragTracker {
  /// 0..1 under the finger while dragging; null otherwise.
  double? fraction;

  /// The drag is above the cancel distance: a release now does not seek.
  bool cancelling = false;

  /// The track the drag began on.
  Object? _track;

  /// A drag started and its end was not reported yet; stays true when the
  /// drag is dropped, so the release reports the end once. That needs the
  /// recognizer to survive: when an any-direction band loses its pan
  /// mid-drag (dropped drag and no duration), no release comes and the end
  /// is not reported today.
  bool _seeking = false;

  /// Global y the cancel is measured from: where the pointer went down.
  double _originY = 0;

  /// See [start]; null: no cancel.
  double? _cancelUp;

  bool get dragging => fraction != null;

  static bool get _mobile =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  /// A drag began on [track] at [fraction]. [originY] is the global y of its
  /// pointer down, [globalY] where the drag is now; past [cancelUp] dp above
  /// the origin it is cancelling.
  void start({
    required double fraction,
    required Object? track,
    required double originY,
    required double globalY,
    required double? cancelUp,
  }) {
    _track = track;
    _seeking = true;
    _originY = originY;
    _cancelUp = cancelUp;
    this.fraction = fraction;
    cancelling = _isAbove(globalY);
  }

  /// The finger moved. Crossing the cancel distance upward gives one haptic
  /// tick on mobile.
  void update({required double fraction, required double globalY}) {
    if (this.fraction == null) return;
    final above = _isAbove(globalY);
    if (above && !cancelling && _mobile) HapticFeedback.selectionClick();
    this.fraction = fraction;
    cancelling = above;
  }

  /// Forgets a drag that outlived its track or duration; its end is still
  /// reported by [end].
  void drop() {
    fraction = null;
    _track = null;
    cancelling = false;
  }

  /// The drag is over. [seekTo]: the fraction to seek to, null when nothing
  /// seeks (not [commit]ted, cancelling, dropped, or [track] is not the one
  /// it began on). [ended]: a started drag ends here, report it.
  ({double? seekTo, bool ended}) end({
    required bool commit,
    required Object? track,
  }) {
    final at = fraction;
    final valid = commit && !cancelling && at != null && track == _track;
    final ended = _seeking;
    _seeking = false;
    drop();
    return (seekTo: valid ? at : null, ended: ended);
  }

  bool _isAbove(double globalY) {
    final distance = _cancelUp;
    return distance != null && _originY - globalY > distance;
  }
}
