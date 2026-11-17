import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../state/playback_position_provider.dart';
import 'mini_card_drag.dart';
import 'mini_seek_band.dart';

/// The layer of the mini player card that takes every touch except Play and
/// Next (they sit above it and take their own first): tap, long press, the
/// drag of [MiniCardDragRecognizer] and the seek band at the bottom edge.
///
/// - Tap: [onTap]. Long press (500 ms without moving 10 dp): haptic, then
///   [onLongPress]; the release after it is no tap and no drag end.
/// - A drag reports [onLock] at the first 10 dp, then [onUpdate] and one of
///   [onEnd] / [onCancel].
class MiniCardLayer extends ConsumerStatefulWidget {
  const MiniCardLayer({
    super.key,
    required this.cardHeight,
    required this.radius,
    required this.onTap,
    required this.onLongPress,
    this.onLock,
    this.onUpdate,
    this.onEnd,
    this.onCancel,
  });

  static const Duration longPressDelay = Duration(milliseconds: 500);

  final double cardHeight;
  final BorderRadius radius;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final void Function(MiniDragLock lock)? onLock;

  /// Total movement since the touch-down.
  final void Function(MiniDragLock lock, Offset total)? onUpdate;
  final void Function(MiniDragLock lock, Offset total, Offset velocityPxPerMs)?
  onEnd;
  final void Function(MiniDragLock lock)? onCancel;

  @override
  ConsumerState<MiniCardLayer> createState() => _MiniCardLayerState();
}

class _MiniCardLayerState extends ConsumerState<MiniCardLayer> {
  Timer? _longPress;
  Offset? _downAt;

  /// The first finger of the touch; every other pointer is ignored until it
  /// lifts, so a second finger cannot reset the lock or start a long press.
  int? _pointer;
  bool _longPressed = false;
  MiniDragLock? _lock;

  void _cancelLongPress() {
    _longPress?.cancel();
    _longPress = null;
  }

  void _onDown(PointerDownEvent e) {
    if (_pointer != null) return;
    _pointer = e.pointer;
    _downAt = e.position;
    _longPressed = false;
    _lock = null;
    _cancelLongPress();
    _longPress = Timer(MiniCardLayer.longPressDelay, () {
      _longPress = null;
      _longPressed = true;
      HapticFeedback.selectionClick();
      widget.onLongPress();
    });
  }

  void _onEnd(PointerEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    _cancelLongPress();
  }

  void _onMove(PointerMoveEvent e) {
    if (e.pointer != _pointer) return;
    final start = _downAt;
    if (start != null && (e.position - start).distance > miniDragSlop) {
      _cancelLongPress();
    }
  }

  /// True for a touch the card must not take: it starts in the seek band
  /// (when the track can seek) or in the system gesture area at a screen edge.
  bool _declines(PointerDownEvent e) {
    final seekable =
        (ref.read(playbackPositionProvider).value?.duration?.inMilliseconds ??
            0) >
        0;
    if (seekable &&
        e.localPosition.dy >= widget.cardHeight - MiniSeekBand.height) {
      return true;
    }
    if (e.kind != PointerDeviceKind.touch) return false;
    final inset = MediaQuery.systemGestureInsetsOf(context);
    // The screen edge, not the card: the system gesture area is the window's.
    final view = View.of(context);
    final width = view.physicalSize.width / view.devicePixelRatio;
    return e.position.dx < inset.left || e.position.dx > width - inset.right;
  }

  void _setUp(MiniCardDragRecognizer r) {
    r
      ..onLock = (lock) {
        // The long press already opened the queue: the rest of this touch
        // does nothing (a drag that locks after it never starts).
        if (_longPressed) return;
        _lock = lock;
        _cancelLongPress();
        widget.onLock?.call(lock);
      }
      ..onUpdate = (total) {
        final lock = _lock;
        if (lock != null) widget.onUpdate?.call(lock, total);
      }
      ..onEnd = (total, velocity) {
        final lock = _lock;
        _lock = null;
        if (lock != null) widget.onEnd?.call(lock, total, velocity);
      }
      ..onCancel = () {
        final lock = _lock;
        _lock = null;
        if (lock != null) widget.onCancel?.call(lock);
      };
  }

  @override
  void dispose() {
    _cancelLongPress();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        MiniCardDragRecognizer:
            GestureRecognizerFactoryWithHandlers<MiniCardDragRecognizer>(
              () => MiniCardDragRecognizer(declines: _declines),
              _setUp,
            ),
      },
      child: Listener(
        onPointerDown: _onDown,
        onPointerMove: _onMove,
        onPointerUp: _onEnd,
        onPointerCancel: _onEnd,
        child: KPressable(
          radius: widget.radius,
          onTap: () {
            if (!_longPressed) widget.onTap();
          },
          // Inside the tap layer, so a tap on the band still reaches the card.
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: MiniSeekBand.height,
                child: MiniSeekBand(
                  cardHeight: widget.cardHeight,
                  radius: widget.radius,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
