import 'package:material_ui/material_ui.dart';

import 'k_seek_gesture_area.dart';

/// Flat seek bar: 4 dp track, 4 x 16 dp thumb, in a 24 dp tall hit area.
///
/// Input (tap, drag, Left/Right) is [KSeekGestureArea]'s. The track grows a
/// little under the mouse, with focus or while dragging.
class KSeekBar extends StatelessWidget {
  const KSeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
    this.onSeekStart,
    this.onSeekEnd,
    this.semanticLabel,
    this.semanticValue,
    this.keyStep = const Duration(seconds: 5),
  });

  static const double hitHeight = 24;
  static const double trackHeight = 4;
  static const double trackHeightActive = 6;
  static const double thumbWidth = 4;
  static const double thumbHeight = 16;

  final Duration position;

  /// Null or zero: nothing to seek in; the bar shows empty and ignores input.
  final Duration? duration;
  final ValueChanged<Duration> onSeek;
  final VoidCallback? onSeekStart;
  final VoidCallback? onSeekEnd;
  final String? semanticLabel;

  /// Spoken value, for example "1:05 of 3:40".
  final String? semanticValue;
  final Duration keyStep;

  @override
  Widget build(BuildContext context) {
    return KSeekGestureArea(
      position: position,
      duration: duration,
      onSeek: onSeek,
      onSeekStart: onSeekStart,
      onSeekEnd: onSeekEnd,
      semanticLabel: semanticLabel,
      semanticValue: semanticValue,
      keyStep: keyStep,
      height: hitHeight,
      builder: (context, state) => KFlatSeekTrack(state: state),
    );
  }
}

/// The straight track and thumb of the flat seek bar, centred in the height
/// it is given. The waveform bar shows it while it has no bars.
class KFlatSeekTrack extends StatelessWidget {
  const KFlatSeekTrack({super.key, required this.state});

  final KSeekState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = state.width;
    final trackHeight = state.active
        ? KSeekBar.trackHeightActive
        : KSeekBar.trackHeight;
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: trackHeight,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(trackHeight / 2),
          ),
        ),
        Positioned(
          left: 0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: trackHeight,
            width: width * state.progress,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(trackHeight / 2),
            ),
          ),
        ),
        if (state.seekable)
          Positioned(
            left: (width * state.progress - KSeekBar.thumbWidth / 2).clamp(
              0.0,
              (width - KSeekBar.thumbWidth).clamp(0.0, width),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
              child: const SizedBox(
                width: KSeekBar.thumbWidth,
                height: KSeekBar.thumbHeight,
              ),
            ),
          ),
      ],
    );
  }
}
