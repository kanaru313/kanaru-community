import 'dart:async';

import 'package:flutter/animation.dart';

import '../tokens/k_motion.dart';

/// Press feedback state of a [KIconButton]: a value from 0 (rest) to 1
/// (pressed) that jumps to 1 on press and fades back after release.
///
/// The pressed look is held for at least [minHold] even when the release
/// comes in the same frame (a quick tap, where the press and release events
/// arrive together), so a tap is always visible. The fade controller is
/// created on the first press: an idle button owns no ticker.
class KIconButtonPulse {
  KIconButtonPulse({required this.vsync, required this.onChanged});

  /// Shortest time the pressed look stays after a press.
  static const Duration minHold = Duration(milliseconds: 100);

  final TickerProvider vsync;

  /// Called whenever [value] changes.
  final VoidCallback onChanged;

  AnimationController? _controller;
  Timer? _holdTimer;
  bool _holding = false;
  bool _released = false;
  bool _reduceMotion = false;

  /// 0 at rest, 1 fully pressed.
  double get value => _controller?.value ?? 0;

  void press() {
    _holdTimer?.cancel();
    _holding = true;
    _released = false;
    _holdTimer = Timer(minHold, _holdElapsed);
    _ensureController()
      ..stop()
      ..value = 1;
  }

  /// The pointer went up or the gesture was cancelled. [reduceMotion] makes
  /// the look end without a fade; the hold still applies.
  void release({required bool reduceMotion}) {
    if (!_holding) return;
    _released = true;
    _reduceMotion = reduceMotion;
    if (_holdTimer == null) _fadeBack();
  }

  /// Ends the pulse at once (the button got disabled).
  void reset() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _holding = false;
    _controller?.stop();
    _controller?.value = 0;
  }

  void dispose() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _controller?.dispose();
    _controller = null;
  }

  void _holdElapsed() {
    _holdTimer = null;
    if (_released) _fadeBack();
  }

  void _fadeBack() {
    _holding = false;
    final controller = _controller;
    if (controller == null) return;
    if (_reduceMotion) {
      controller.value = 0;
    } else {
      controller.animateTo(0, duration: KMotion.press, curve: Curves.easeOut);
    }
  }

  AnimationController _ensureController() {
    final existing = _controller;
    if (existing != null) return existing;
    return _controller = AnimationController(vsync: vsync)
      ..addListener(onChanged);
  }
}
