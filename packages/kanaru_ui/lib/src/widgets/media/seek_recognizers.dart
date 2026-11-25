import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

/// What a seek bar does with a drag, from whichever recognizer runs it.
class SeekDragHandlers {
  const SeekDragHandlers({
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.onCancel,
  });

  final GestureDragStartCallback onStart;
  final GestureDragUpdateCallback onUpdate;
  final GestureDragEndCallback onEnd;

  /// Also called when the drag never started: another recognizer (a tap, an
  /// ancestor's vertical drag) won the pointer.
  final GestureDragCancelCallback onCancel;
}

/// The recognizers of a seek bar.
///
/// - [onTapUp] null: no tap recognizer (the tap falls to an ancestor).
/// - [anyDirection]: a pan with the touch slop of [settings] (a pan's own
///   slop is twice that), added only while [pan] is true; otherwise a
///   horizontal drag, always attached so a running drag always ends.
Map<Type, GestureRecognizerFactory> seekRecognizers({
  required DeviceGestureSettings? settings,
  required GestureTapUpCallback? onTapUp,
  required bool anyDirection,
  required bool pan,
  required SeekDragHandlers drag,
}) {
  void wire(DragGestureRecognizer r, DeviceGestureSettings? s) => r
    ..gestureSettings = s
    ..onStart = drag.onStart
    ..onUpdate = drag.onUpdate
    ..onEnd = drag.onEnd
    ..onCancel = drag.onCancel;

  return {
    if (onTapUp != null)
      TapGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
            TapGestureRecognizer.new,
            (r) => r
              ..gestureSettings = settings
              ..onTapUp = onTapUp,
          ),
    if (anyDirection && pan)
      PanGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
            PanGestureRecognizer.new,
            (r) => wire(
              r,
              // Pan slop is twice the touch slop: halve it so a drag locks
              // after the same distance as a horizontal one.
              DeviceGestureSettings(
                touchSlop: (settings?.touchSlop ?? kTouchSlop) / 2,
              ),
            ),
          ),
    if (!anyDirection)
      HorizontalDragGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<HorizontalDragGestureRecognizer>(
            HorizontalDragGestureRecognizer.new,
            (r) => wire(r, settings),
          ),
  };
}
