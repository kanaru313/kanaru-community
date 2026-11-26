import 'package:kanaru_ui/kanaru_ui.dart';

import '../domain/seek_bar_options.dart';
import '../domain/seek_bar_style.dart';

/// The shape the waveform bar draws for [style]. The squiggle and flat styles
/// have no shape of their own here yet: a squiggle that follows the music
/// draws the bars until its own painter exists.
KSeekKind seekKindOf(SeekBarStyle style) => switch (style) {
  SeekBarStyle.bars => KSeekKind.bars,
  SeekBarStyle.dots => KSeekKind.dots,
  SeekBarStyle.line => KSeekKind.line,
  SeekBarStyle.mirror => KSeekKind.mirror,
  SeekBarStyle.squiggle || SeekBarStyle.flat => KSeekKind.bars,
};

/// The look of the wave kinds from their stored options.
KWaveLook waveLookOf(WaveSeekOptions options) => KWaveLook(
  density: switch (options.density) {
    WaveDensity.loose => KWaveDensity.loose,
    WaveDensity.mid => KWaveDensity.mid,
    WaveDensity.dense => KWaveDensity.dense,
  },
  played: switch (options.played) {
    WavePlayed.single => KWavePlayed.single,
    WavePlayed.gradient => KWavePlayed.gradient,
    WavePlayed.height => KWavePlayed.height,
  },
  rest: switch (options.rest) {
    WaveRest.dim => KWaveRest.dim,
    WaveRest.outline => KWaveRest.outline,
    WaveRest.hidden => KWaveRest.hidden,
  },
  feedback: switch (options.feedback) {
    WaveFeedback.jelly => KSeekFeedback.jelly,
    WaveFeedback.lens => KSeekFeedback.lens,
    WaveFeedback.off => KSeekFeedback.off,
  },
);
