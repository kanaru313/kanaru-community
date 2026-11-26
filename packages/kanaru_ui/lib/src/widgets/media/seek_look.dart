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
