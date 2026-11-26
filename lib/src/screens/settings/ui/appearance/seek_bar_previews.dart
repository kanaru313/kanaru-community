import 'dart:math' as math;
import 'dart:typed_data';

import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../playback/domain/seek_bar_options.dart';
import '../../../../playback/domain/seek_bar_style.dart';
import '../../../../playback/ui/seek_bar_look.dart';

/// Where the card preview is drawn: 38 % of the track.
const double seekPreviewPosition = 0.38;

const Duration _length = Duration(seconds: 100);
const int _levelCount = 200;

/// Loudness of the sample waveform: fixed and varied, so a preview never
/// changes between builds. The waveform of the pretend track is always there.
final Uint8List sampleSeekLevels = Uint8List.fromList([
  for (var i = 0; i < _levelCount; i++)
    (40 + 215 * (math.sin(i * 0.37) * math.cos(i * 0.11 + 1)).abs()).round(),
]);

/// One seek bar of [style] drawn with the given options, by the same widgets
/// as the real bar ([KWaveformSeekBar], [KSquiggleSeekBar] or
/// [KFlatStyledSeekBar]) over [sampleSeekLevels]. The waveform is always
/// ready, so the ★ fallback never shows here.
Widget buildSeekStyleBar({
  required SeekBarStyle style,
  required Duration position,
  required Duration duration,
  required ValueChanged<Duration> onSeek,
  WaveSeekOptions wave = WaveSeekOptions.defaults,
  SquiggleSeekOptions squiggle = SquiggleSeekOptions.defaults,
  FlatSeekOptions flat = FlatSeekOptions.defaults,
  bool playing = false,
  String? semanticLabel,
  String? semanticValue,
  String Function(Duration at)? bubbleLabel,
  String? cancelLabel,
  ValueChanged<Duration?>? onScrub,
  VoidCallback? onSeekStart,
  VoidCallback? onSeekEnd,
}) {
  final kind = seekKindOf(style);
  if (kind != null) {
    return KWaveformSeekBar(
      position: position,
      duration: duration,
      onSeek: onSeek,
      levels: sampleSeekLevels,
      status: KWaveformStatus.ready,
      kind: kind,
      look: waveLookOf(wave),
      semanticLabel: semanticLabel,
      semanticValue: semanticValue,
      bubbleLabel: bubbleLabel,
      cancelLabel: cancelLabel,
      onScrub: onScrub,
      onSeekStart: onSeekStart,
      onSeekEnd: onSeekEnd,
    );
  }
  if (style == SeekBarStyle.squiggle) {
    return KSquiggleSeekBar(
      position: position,
      duration: duration,
      onSeek: onSeek,
      look: squiggleLookOf(squiggle),
      playing: playing,
      levels: sampleSeekLevels,
      semanticLabel: semanticLabel,
      semanticValue: semanticValue,
      bubbleLabel: bubbleLabel,
      cancelLabel: cancelLabel,
      onScrub: onScrub,
      onSeekStart: onSeekStart,
      onSeekEnd: onSeekEnd,
    );
  }
  return KFlatStyledSeekBar(
    position: position,
    duration: duration,
    onSeek: onSeek,
    look: flatLookOf(flat),
    playing: playing,
    semanticLabel: semanticLabel,
    semanticValue: semanticValue,
    bubbleLabel: bubbleLabel,
    cancelLabel: cancelLabel,
    onScrub: onScrub,
    onSeekStart: onSeekStart,
    onSeekEnd: onSeekEnd,
  );
}

/// A picture of one seek bar style on a style card, drawn at the options of
/// its group so styles compare at the same density and colour. It takes no
/// input and has no semantics. It schedules no frames of its own while
/// [playing] is false; while true the squiggle drifts and the flat effect runs
/// through the bar's own animation (still under reduced motion or a covered
/// page).
class SeekStylePreview extends StatelessWidget {
  const SeekStylePreview({
    super.key,
    required this.style,
    this.wave = WaveSeekOptions.defaults,
    this.squiggle = SquiggleSeekOptions.defaults,
    this.flat = FlatSeekOptions.defaults,
    this.playing = false,
  });

  final SeekBarStyle style;
  final WaveSeekOptions wave;
  final SquiggleSeekOptions squiggle;
  final FlatSeekOptions flat;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ExcludeFocus(
        child: IgnorePointer(
          child: RepaintBoundary(
            child: SizedBox(
              height: seekBandHeight,
              child: buildSeekStyleBar(
                style: style,
                position: _length * seekPreviewPosition,
                duration: _length,
                onSeek: (_) {},
                wave: wave,
                squiggle: squiggle,
                flat: flat,
                playing: playing,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
