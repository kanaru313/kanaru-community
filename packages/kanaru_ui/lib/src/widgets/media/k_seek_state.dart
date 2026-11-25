/// What a seek bar draws from: where the thumb is and whether the pointer or
/// keyboard is on the bar.
class KSeekState {
  const KSeekState({
    required this.progress,
    required this.width,
    required this.active,
    required this.seekable,
    this.dragging = false,
    this.focused = false,
    this.keyboardFocus = false,
    this.holding = false,
    this.cancelling = false,
    this.pointerFraction,
  });

  /// 0..1; follows the finger while dragging, the `position` of the bar
  /// otherwise (also while [cancelling]: the real position shows again).
  final double progress;
  final double width;

  /// Hovered, focused, held or being dragged.
  final bool active;

  /// There is a duration to seek in.
  final bool seekable;

  /// A drag is in progress (a subset of [active]), cancelling or not.
  final bool dragging;

  /// Has focus (a subset of [active]), from a click or tap too.
  final bool focused;

  /// Has focus the user is driving with the keyboard: focused, the keyboard
  /// highlight mode is on, no drag runs, and no pointer touched the bar since
  /// the keyboard last brought focus or pressed a key. A focus ring is drawn
  /// only for this (a mouse click on desktop leaves the highlight mode on
  /// keyboard).
  final bool keyboardFocus;

  /// A finger rests on the bar past the hold delay without dragging: the time
  /// under it is shown, nothing seeks yet.
  final bool holding;

  /// The drag went up past the cancel distance: releasing now does not seek.
  final bool cancelling;

  /// 0..1 under the pointer while [holding] or [dragging] (also while
  /// [cancelling], where [progress] is the real position); null otherwise.
  final double? pointerFraction;
}
