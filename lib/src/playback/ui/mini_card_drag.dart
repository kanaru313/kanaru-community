import 'dart:ui' show VoidCallback;

import 'package:flutter/gestures.dart';

/// The direction a drag on the mini player card committed to.
enum MiniDragLock { x, up, down }

/// Slop of the card drag: a sequence is a drag once it moved this far.
const double miniDragSlop = 10;

/// The lock for a total movement [d] from the touch-down point: null while it
/// is shorter than [slop]; then horizontal (`|dx| > |dy|`), else up or down.
MiniDragLock? lockOf(Offset d, {double slop = miniDragSlop}) {
  if (d.distance < slop) return null;
  if (d.dx.abs() > d.dy.abs()) return MiniDragLock.x;
  return d.dy < 0 ? MiniDragLock.up : MiniDragLock.down;
}

/// The one place that decides what a drag on the mini player card is.
///
/// A touch that moved [miniDragSlop] locks to a direction and wins the arena,
/// so the card's tap loses at once (never both a snap back and an open). A
/// touch released before that gives up and the tap wins, also on the seek
/// band. One pointer at a time; a second finger is ignored.
///
/// A pointer is not taken at all when [declines] says so: a touch that
/// starts in the seek band belongs to the band, one that starts at the edge
/// of the screen belongs to the system Back gesture.
class MiniCardDragRecognizer extends OneSequenceGestureRecognizer {
  MiniCardDragRecognizer({
    super.debugOwner,
    super.supportedDevices,
    required this.declines,
  });

  /// True for a pointer-down this recognizer must leave alone. The event's
  /// `localPosition` is in the card.
  final bool Function(PointerDownEvent event) declines;

  void Function(MiniDragLock lock)? onLock;

  /// Total movement since the touch-down.
  void Function(Offset total)? onUpdate;
  void Function(Offset total, Offset velocityPxPerMs)? onEnd;

  /// The pointer was cancelled after the lock: go back, do nothing.
  VoidCallback? onCancel;

  int? _pointer;
  Offset _start = Offset.zero;
  Offset _total = Offset.zero;
  MiniDragLock? _lock;
  VelocityTracker? _velocity;

  @override
  String get debugDescription => 'mini card drag';

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (_pointer != null || declines(event)) return;
    super.addAllowedPointer(event);
    _pointer = event.pointer;
    _start = event.position;
    _total = Offset.zero;
    _lock = null;
    _velocity = VelocityTracker.withKind(event.kind)
      ..addPosition(event.timeStamp, event.position);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer != _pointer) return;
    if (event is PointerMoveEvent) {
      _total = event.position - _start;
      _velocity?.addPosition(event.timeStamp, event.position);
      if (_lock == null) {
        final lock = lockOf(_total);
        if (lock == null) return;
        _lock = lock;
        resolve(GestureDisposition.accepted);
        onLock?.call(lock);
      }
      onUpdate?.call(_total);
    } else if (event is PointerUpEvent) {
      final locked = _lock != null;
      // Per millisecond, like the pointer velocity of the card's thresholds.
      final v =
          (_velocity?.getVelocity().pixelsPerSecond ?? Offset.zero) / 1000;
      final total = _total;
      _finish();
      if (locked) {
        onEnd?.call(total, v);
      } else {
        // Never moved far enough: let the tap have it.
        resolve(GestureDisposition.rejected);
      }
    } else if (event is PointerCancelEvent) {
      final locked = _lock != null;
      _finish();
      if (locked) onCancel?.call();
    }
  }

  void _finish() {
    final pointer = _pointer;
    _pointer = null;
    _lock = null;
    _velocity = null;
    if (pointer != null) stopTrackingPointer(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  void rejectGesture(int pointer) {
    // Lost the arena before the lock (another recognizer took the touch).
    if (pointer == _pointer) _finish();
    super.rejectGesture(pointer);
  }
}
