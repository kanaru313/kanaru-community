import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// One action behind a row: the strip shows [icon] (and [label] for the
/// capped kind), a swipe past the trigger runs [onTrigger].
@immutable
class KSwipeAction {
  const KSwipeAction({
    required this.icon,
    required this.label,
    required this.onTrigger,
  });

  final IconData icon;

  /// Shown under the icon and used as the semantics action name.
  final String label;
  final VoidCallback onTrigger;
}

/// Pointers that may swipe a row. A trackpad two-finger pan scrolls the list
/// on desktop, so it is left out.
const Set<PointerDeviceKind> kSwipeDevices = {
  PointerDeviceKind.touch,
  PointerDeviceKind.mouse,
  PointerDeviceKind.stylus,
  PointerDeviceKind.invertedStylus,
};

/// A horizontal drag that needs [kTouchSlop] before it accepts for a mouse.
/// The stock recogniser accepts a mouse after ~1 px, which turns the jitter
/// of a click into a drag and loses the tap. Other pointers use the device's
/// touch slop (like a `Scrollable`), so a row wins a horizontal drag against
/// a list or page view that starts scrolling at the same distance.
class KSwipeDragRecognizer extends HorizontalDragGestureRecognizer {
  KSwipeDragRecognizer({super.debugOwner});

  @override
  bool hasSufficientGlobalDistanceToAccept(
    PointerDeviceKind pointerDeviceKind,
    double? deviceTouchSlop,
  ) =>
      globalDistanceMoved.abs() >
      (pointerDeviceKind == PointerDeviceKind.mouse
          ? kTouchSlop
          : deviceTouchSlop ?? kTouchSlop);
}
