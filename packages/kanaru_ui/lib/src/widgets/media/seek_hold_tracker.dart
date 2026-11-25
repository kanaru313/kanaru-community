import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

/// The hold part of a seek bar's input, fed from a `Listener` so it never
/// enters the gesture arena (a tap still seeks, a drag still locks, an
/// ancestor still takes a vertical move): a timer from pointer down that
/// marks a finger resting on the bar, and the pointer-down position a drag-up
/// cancel is measured from.
class SeekHoldTracker {
  /// [onChanged] is called when [heldX] changes outside a [stop] with
  /// `notify: false`.
  SeekHoldTracker(this._onChanged);

  final VoidCallback _onChanged;
  Timer? _timer;

  /// The pointer followed, from its down to its up or cancel; others are
  /// ignored.
  int? _pointer;
  Offset? _downGlobal;
  double _downX = 0;
  double _slop = kTouchSlop;
  bool _holding = false;

  /// Local x of a finger held past the delay; null when no hold shows.
  double? get heldX => _holding ? _downX : null;

  /// Global position where the followed pointer went down; null after it
  /// went up.
  Offset? get downGlobal => _downGlobal;

  /// Starts following [event]'s pointer, and the hold timer when [delay] is
  /// set and the primary button is down (a touch counts as primary).
  void down(
    PointerDownEvent event, {
    required Duration? delay,
    required DeviceGestureSettings? settings,
  }) {
    if (_pointer != null) return;
    _pointer = event.pointer;
    _downGlobal = event.position;
    _downX = event.localPosition.dx;
    _slop = computeHitSlop(event.kind, settings);
    if (delay != null && (event.buttons & kPrimaryButton) != 0) {
      _timer = Timer(delay, _fire);
    }
  }

  /// A move past the touch slop before the delay is not a hold.
  void move(PointerMoveEvent event) {
    if (event.pointer != _pointer || _timer == null) return;
    if ((event.position - _downGlobal!).distance > _slop) {
      _timer!.cancel();
      _timer = null;
    }
  }

  /// The followed pointer went up or was cancelled.
  void end(PointerEvent event) {
    if (event.pointer != _pointer) return;
    _pointer = null;
    _downGlobal = null;
    stop();
  }

  /// Stops the timer and hides the hold (a drag took over, an ancestor won
  /// the pointer, the track changed). [notify] false: the caller rebuilds.
  void stop({bool notify = true}) {
    _timer?.cancel();
    _timer = null;
    if (!_holding) return;
    _holding = false;
    if (notify) _onChanged();
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  void _fire() {
    _timer = null;
    _holding = true;
    _onChanged();
  }
}
