import 'dart:math' as math;
import 'dart:typed_data';

import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../playback/domain/seek_bar_style.dart';
import '../../../../playback/ui/seek_bar_look.dart';

/// Where the preview is drawn: 38 % of the track.
const double seekPreviewPosition = 0.38;

const Duration _length = Duration(seconds: 100);
const int _levelCount = 200;

/// Loudness of the sample waveform: fixed and varied, so a preview never
/// changes between builds.
final Uint8List _sampleLevels = Uint8List.fromList([
  for (var i = 0; i < _levelCount; i++)
    (40 + 215 * (math.sin(i * 0.37) * math.cos(i * 0.11 + 1)).abs()).round(),
]);

/// A still picture of one seek bar style at its default options, drawn by the
/// same painters as the real bar ([KWaveformSeekBar], [KSquiggleSeekBar] or
/// [KFlatStyledSeekBar]). It takes no input, has no semantics and schedules no
/// frames: the squiggle stands still instead of drifting.
class SeekStylePreview extends StatelessWidget {
  const SeekStylePreview({super.key, required this.style});

  final SeekBarStyle style;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ExcludeFocus(
        child: IgnorePointer(
          child: SizedBox(height: seekBandHeight, child: _bar()),
        ),
      ),
    );
  }

  Widget _bar() {
    final kind = seekKindOf(style);
    if (kind != null) {
      return KWaveformSeekBar(
        position: _length * seekPreviewPosition,
        duration: _length,
        onSeek: (_) {},
        levels: _sampleLevels,
        status: KWaveformStatus.ready,
        kind: kind,
      );
    }
    if (style == SeekBarStyle.squiggle) {
      return KSquiggleSeekBar(
        position: _length * seekPreviewPosition,
        duration: _length,
        onSeek: (_) {},
        look: const KSquiggleLook(motion: KSquiggleMotion.still),
      );
    }
    return KFlatStyledSeekBar(
      position: _length * seekPreviewPosition,
      duration: _length,
      onSeek: (_) {},
    );
  }
}
