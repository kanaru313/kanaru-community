import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import 'k_seek_bar.dart';
import 'k_seek_gesture_area.dart';
import 'waveform_bars.dart';
import 'waveform_painter.dart';

/// How long the bars take to fade in over the flat track.
const Duration waveformFadeDuration = Duration(milliseconds: 200);

/// Opacity of the unplayed bars (the cover tint under Now Playing washes out
/// `secondaryContainer`, so the rest is `primary`, faded).
const double waveformRestAlpha = 0.35;

/// Opacity of the played bars: a little darker than the rest, not a block.
const double waveformPlayedAlpha = 0.85;

/// Seek bar that draws the loudness of the track as mirrored bars, 48 dp tall.
///
/// Same input and API as [KSeekBar] plus [levels]. While [levels] is null or
/// empty, or the duration unknown, it shows the flat track instead. Bars fade
/// in over [waveformFadeDuration] when they arrive after the first build and
/// [instant] is false; with [instant] (a cached waveform) or reduced motion
/// they appear at once.
class KWaveformSeekBar extends StatefulWidget {
  const KWaveformSeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
    this.levels,
    this.levelsDuration,
    this.instant = false,
    this.onSeekStart,
    this.onSeekEnd,
    this.semanticLabel,
    this.semanticValue,
    this.keyStep = const Duration(seconds: 5),
  });

  final Duration position;
  final Duration? duration;
  final ValueChanged<Duration> onSeek;
  final VoidCallback? onSeekStart;
  final VoidCallback? onSeekEnd;
  final String? semanticLabel;
  final String? semanticValue;
  final Duration keyStep;

  /// 0..255 loudness, evenly spaced over [levelsDuration].
  final Uint8List? levels;

  /// Length of audio the levels were measured on; the player's [duration]
  /// when null.
  final Duration? levelsDuration;

  /// Show the bars without the fade.
  final bool instant;

  @override
  State<KWaveformSeekBar> createState() => _KWaveformSeekBarState();
}

class _KWaveformSeekBarState extends State<KWaveformSeekBar> {
  final _pictures = WaveformPictures();

  @override
  void dispose() {
    _pictures.dispose();
    super.dispose();
  }

  bool get _ready =>
      (widget.levels?.isNotEmpty ?? false) &&
      (widget.duration ?? Duration.zero) > Duration.zero;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final ready = _ready;
    final animate =
        ready && !widget.instant && !MediaQuery.disableAnimationsOf(context);
    if (!ready) _pictures.dispose();
    return KSeekGestureArea(
      position: widget.position,
      duration: widget.duration,
      onSeek: widget.onSeek,
      onSeekStart: widget.onSeekStart,
      onSeekEnd: widget.onSeekEnd,
      semanticLabel: widget.semanticLabel,
      semanticValue: widget.semanticValue,
      keyStep: widget.keyStep,
      height: waveformTrackHeight,
      builder: (context, state) => RepaintBoundary(
        // Starts at its end value on the first build, so bars that are there
        // from the start show at once; a later change fades.
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: ready ? 1 : 0),
          duration: animate ? waveformFadeDuration : Duration.zero,
          builder: (context, t, _) => Stack(
            fit: StackFit.expand,
            children: [
              if (t < 1)
                Opacity(
                  opacity: 1 - t,
                  child: KFlatSeekTrack(state: state),
                ),
              if (ready && t > 0)
                Opacity(
                  opacity: t,
                  child: CustomPaint(
                    key: const ValueKey('waveform bars'),
                    painter: WaveformTrackPainter(
                      progress: state.progress,
                      thumbColor: scheme.primary,
                      pictures: _pictures.pair((
                        levels: widget.levels!,
                        length: widget.levelsDuration ?? widget.duration!,
                        duration: widget.duration!,
                        size: Size(state.width, waveformTrackHeight),
                        devicePixelRatio: dpr,
                        played: scheme.primary.withValues(
                          alpha: waveformPlayedAlpha,
                        ),
                        rest: scheme.primary.withValues(
                          alpha: waveformRestAlpha,
                        ),
                      )),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
