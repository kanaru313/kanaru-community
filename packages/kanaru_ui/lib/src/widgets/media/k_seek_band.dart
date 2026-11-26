import 'package:material_ui/material_ui.dart';

import 'k_seek_gesture_area.dart';
import 'k_seek_time_bubble.dart';
import 'waveform_bars.dart';

/// How far above the pointer-down point a drag is cancelled.
const double seekCancelUpDistance = 48;

/// How long a finger rests on the bar before the time bubble shows.
const Duration seekHoldDelay = Duration(milliseconds: 150);

/// [state] for a box [inset] narrower at each side: the time axis of a band
/// (x = [inset] is the start) maps onto the box's own width, so
/// `progress * width` of the result lands under the finger.
KSeekState insetSeekState(KSeekState state, double inset) => KSeekState(
  progress: state.progress,
  width: (state.width - 2 * inset).clamp(0.0, double.infinity),
  active: state.active,
  seekable: state.seekable,
  dragging: state.dragging,
  focused: state.focused,
  keyboardFocus: state.keyboardFocus,
  holding: state.holding,
  cancelling: state.cancelling,
  pointerFraction: state.pointerFraction,
);

/// The input and chrome of a Now Playing seek bar that has no waveform shapes
/// (squiggle, flat): the 56 dp band with the 6 dp insets, the gesture area
/// with hold and drag-up cancel, and the time bubble. [track] draws the look
/// from the state of the inner width, centred and clipped in the band.
class KSeekBand extends StatelessWidget {
  const KSeekBand({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
    required this.track,
    this.trackId,
    this.onSeekStart,
    this.onSeekEnd,
    this.semanticLabel,
    this.semanticValue,
    this.keyStep = const Duration(seconds: 5),
    this.bubbleLabel,
    this.cancelLabel,
    this.onScrub,
  });

  final Duration position;
  final Duration? duration;

  /// Identity of the playing item (see [KSeekGestureArea.track]).
  final Object? trackId;
  final ValueChanged<Duration> onSeek;
  final VoidCallback? onSeekStart;
  final VoidCallback? onSeekEnd;
  final String? semanticLabel;
  final String? semanticValue;
  final Duration keyStep;

  /// Time text of the bubble; null: no bubble and no hold.
  final String Function(Duration at)? bubbleLabel;

  /// Text of the bubble while a drag cancels; null: no drag-up cancel.
  final String? cancelLabel;
  final ValueChanged<Duration?>? onScrub;

  /// Draws the look into a box as wide as the state it gets.
  final Widget Function(BuildContext context, KSeekState inner) track;

  Widget _band(BuildContext context, KSeekState state) => RepaintBoundary(
    child: ClipRect(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: seekInset),
        child: track(context, insetSeekState(state, seekInset)),
      ),
    ),
  );

  Widget _withBubble(BuildContext context, KSeekState state) {
    final band = _band(context, state);
    final label = bubbleLabel;
    if (label == null) return band;
    return KSeekTimeBubble(
      state: state,
      duration: duration,
      label: label,
      cancelLabel: cancelLabel,
      horizontalInset: seekInset,
      child: band,
    );
  }

  @override
  Widget build(BuildContext context) {
    return KSeekGestureArea(
      position: position,
      duration: duration,
      track: trackId,
      onSeek: onSeek,
      onSeekStart: onSeekStart,
      onSeekEnd: onSeekEnd,
      semanticLabel: semanticLabel,
      semanticValue: semanticValue,
      keyStep: keyStep,
      height: seekBandHeight,
      horizontalInset: seekInset,
      cancelUpDistance: cancelLabel != null ? seekCancelUpDistance : null,
      holdDelay: bubbleLabel != null ? seekHoldDelay : null,
      onScrub: onScrub,
      builder: _withBubble,
    );
  }
}
