/// Which shape the waveform seek bar draws.
enum KSeekKind {
  /// Vertical bars.
  bars,

  /// Columns of dots.
  dots,

  /// A closed outline through the bar tops, mirrored around the centre.
  line,

  /// Bars standing on a baseline with a faint reflection below.
  mirror,
}

/// How tightly the bars sit: bar width and the gap between two bars, in dp.
enum KWaveDensity {
  loose(4, 3),
  mid(3, 2),
  dense(2, 1);

  const KWaveDensity(this.barWidth, this.barGap);

  final double barWidth;
  final double barGap;
}

/// How the played part is coloured.
enum KWavePlayed {
  /// One colour.
  single,

  /// Blends along the bar from start to end.
  gradient,

  /// Blends with the height of each bar.
  height,
}

/// How the part not played yet is drawn.
enum KWaveRest {
  /// The bars faded.
  dim,

  /// The bars as an outline.
  outline,

  /// Nothing but a thin line from the position to the end.
  hidden,
}

/// What the bar does under the finger.
enum KSeekFeedback {
  /// Bars sink under the finger and wobble after a seek.
  jelly,

  /// Bars near the finger grow.
  lens,

  /// Nothing.
  off,
}

/// The look of the wave kinds.
class KWaveLook {
  const KWaveLook({
    this.density = KWaveDensity.mid,
    this.played = KWavePlayed.single,
    this.rest = KWaveRest.dim,
    this.feedback = KSeekFeedback.off,
  });

  final KWaveDensity density;
  final KWavePlayed played;
  final KWaveRest rest;
  final KSeekFeedback feedback;

  @override
  bool operator ==(Object other) =>
      other is KWaveLook &&
      other.density == density &&
      other.played == played &&
      other.rest == rest &&
      other.feedback == feedback;

  @override
  int get hashCode => Object.hash(density, played, rest, feedback);
}

/// The marker at the playing position of the squiggle and flat bars.
enum KSeekThumb {
  /// A vertical bar.
  bar,

  /// A round knob with a ring in the surface colour.
  dot,

  /// No marker; the bar is still a slider.
  none,
}

/// How tall the waves of the squiggle are (dp, peak from the centre line).
enum KSquiggleAmplitude {
  low(2.5),
  mid(4.5),
  high(7);

  const KSquiggleAmplitude(this.dp);

  final double dp;
}

/// Length of one wave of the squiggle, in dp.
enum KSquiggleWavelength {
  short(18),
  mid(28),
  long(44);

  const KSquiggleWavelength(this.dp);

  final double dp;
}

/// What moves the squiggle while playing.
enum KSquiggleMotion {
  /// The wave drifts at a steady speed.
  drift,

  /// The wave height follows the loudness at the position (drifts when the
  /// bar has no levels).
  music,

  /// The wave stands still.
  still,
}

/// The look of the squiggle kind.
class KSquiggleLook {
  const KSquiggleLook({
    this.amplitude = KSquiggleAmplitude.mid,
    this.wavelength = KSquiggleWavelength.mid,
    this.motion = KSquiggleMotion.drift,
    this.thumb = KSeekThumb.bar,
  });

  final KSquiggleAmplitude amplitude;
  final KSquiggleWavelength wavelength;
  final KSquiggleMotion motion;
  final KSeekThumb thumb;

  @override
  bool operator ==(Object other) =>
      other is KSquiggleLook &&
      other.amplitude == amplitude &&
      other.wavelength == wavelength &&
      other.motion == motion &&
      other.thumb == thumb;

  @override
  int get hashCode => Object.hash(amplitude, wavelength, motion, thumb);
}

/// Thickness of the flat track in dp; it grows by 2 while the bar is active.
enum KFlatThickness {
  thin(2),
  mid(4),
  thick(8);

  const KFlatThickness(this.dp);

  final double dp;
}

/// How the played part of the flat bar is coloured.
enum KFlatPlayed {
  /// One colour.
  single,

  /// Blends along the whole track from start to end.
  gradient,
}

/// What the flat bar shows while playing; it fades out on pause and is off
/// with reduced motion.
enum KFlatEffect {
  off,

  /// A light band runs along the played part every 2.4 s.
  shine,

  /// The played part fades in from the start with a glow at the head.
  comet,

  /// Small particles drop from the head and drift back.
  sparks,
}

/// The look of the flat bar. The default is the plain bar of the mini player
/// and the player bar.
class KFlatLook {
  const KFlatLook({
    this.thickness = KFlatThickness.mid,
    this.thumb = KSeekThumb.bar,
    this.played = KFlatPlayed.single,
    this.effect = KFlatEffect.off,
  });

  final KFlatThickness thickness;
  final KSeekThumb thumb;
  final KFlatPlayed played;
  final KFlatEffect effect;

  @override
  bool operator ==(Object other) =>
      other is KFlatLook &&
      other.thickness == thickness &&
      other.thumb == thumb &&
      other.played == played &&
      other.effect == effect;

  @override
  int get hashCode => Object.hash(thickness, thumb, played, effect);
}
