import 'package:kanaru_ui/kanaru_ui.dart';

import '../domain/seek_bar_options.dart';
import '../domain/seek_bar_style.dart';

/// The shape the waveform bar draws for [style]; null for the styles that
/// have a bar of their own (squiggle, flat).
KSeekKind? seekKindOf(SeekBarStyle style) => switch (style) {
  SeekBarStyle.bars => KSeekKind.bars,
  SeekBarStyle.dots => KSeekKind.dots,
  SeekBarStyle.line => KSeekKind.line,
  SeekBarStyle.mirror => KSeekKind.mirror,
  SeekBarStyle.squiggle || SeekBarStyle.flat => null,
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

/// The look of the squiggle from its stored options. As the ★ fallback (no
/// waveform to follow) `music` motion drifts: [asFallback].
KSquiggleLook squiggleLookOf(
  SquiggleSeekOptions options, {
  bool asFallback = false,
}) => KSquiggleLook(
  amplitude: switch (options.amplitude) {
    SquiggleAmplitude.low => KSquiggleAmplitude.low,
    SquiggleAmplitude.mid => KSquiggleAmplitude.mid,
    SquiggleAmplitude.high => KSquiggleAmplitude.high,
  },
  wavelength: switch (options.wavelength) {
    SquiggleWavelength.short => KSquiggleWavelength.short,
    SquiggleWavelength.mid => KSquiggleWavelength.mid,
    SquiggleWavelength.long => KSquiggleWavelength.long,
  },
  motion: switch (options.motion) {
    SquiggleMotion.drift => KSquiggleMotion.drift,
    SquiggleMotion.music =>
      asFallback ? KSquiggleMotion.drift : KSquiggleMotion.music,
    SquiggleMotion.still => KSquiggleMotion.still,
  },
  thumb: _thumbOf(options.thumb),
);

/// The look of the flat bar from its stored options.
KFlatLook flatLookOf(FlatSeekOptions options) => KFlatLook(
  thickness: switch (options.thickness) {
    FlatThickness.thin => KFlatThickness.thin,
    FlatThickness.mid => KFlatThickness.mid,
    FlatThickness.thick => KFlatThickness.thick,
  },
  thumb: _thumbOf(options.thumb),
  played: switch (options.played) {
    FlatPlayed.single => KFlatPlayed.single,
    FlatPlayed.gradient => KFlatPlayed.gradient,
  },
  effect: switch (options.effect) {
    FlatEffect.off => KFlatEffect.off,
    FlatEffect.shine => KFlatEffect.shine,
    FlatEffect.comet => KFlatEffect.comet,
    FlatEffect.sparks => KFlatEffect.sparks,
  },
);

KSeekThumb _thumbOf(SeekThumb thumb) => switch (thumb) {
  SeekThumb.bar => KSeekThumb.bar,
  SeekThumb.dot => KSeekThumb.dot,
  SeekThumb.none => KSeekThumb.none,
};
