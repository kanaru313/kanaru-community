import 'package:material_ui/material_ui.dart';

import 'k_seek_band.dart';
import 'k_seek_bar.dart';
import 'k_seek_gesture_area.dart';
import 'seek_look.dart';
import 'waveform_bars.dart';

/// The flat seek bar of Now Playing and the lyrics screen: [KFlatSeekTrack]
/// with a [KFlatLook] (thickness, thumb, played colour, play effect) in the
/// 56 dp band, with the input of every seek bar (tap, drag, keys, hold
/// bubble, drag-up cancel; see [KSeekBand]). It needs no waveform. The time
/// axis runs over the width minus [seekInset] at each side.
///
/// The effect of [look] runs only while [playing]. The mini player and the
/// player bar use [KSeekBar], which keeps the plain default look.
class KFlatStyledSeekBar extends StatelessWidget {
  const KFlatStyledSeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
    this.track,
    this.look = const KFlatLook(),
    this.playing = false,
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
  final Object? track;
  final ValueChanged<Duration> onSeek;
  final KFlatLook look;
  final bool playing;
  final VoidCallback? onSeekStart;
  final VoidCallback? onSeekEnd;
  final String? semanticLabel;
  final String? semanticValue;
  final Duration keyStep;
  final String Function(Duration at)? bubbleLabel;
  final String? cancelLabel;
  final ValueChanged<Duration?>? onScrub;

  @override
  Widget build(BuildContext context) {
    return KSeekBand(
      position: position,
      duration: duration,
      trackId: track,
      onSeek: onSeek,
      onSeekStart: onSeekStart,
      onSeekEnd: onSeekEnd,
      semanticLabel: semanticLabel,
      semanticValue: semanticValue,
      keyStep: keyStep,
      bubbleLabel: bubbleLabel,
      cancelLabel: cancelLabel,
      onScrub: onScrub,
      track: (context, inner) =>
          KFlatSeekTrack(state: inner, look: look, playing: playing),
    );
  }
}
