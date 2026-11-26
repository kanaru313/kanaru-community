import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'seek_look.dart';

/// Opacity of the unplayed bars (the cover tint under Now Playing washes out
/// `secondaryContainer`, so the rest is `primary`, faded).
const double waveformRestAlpha = 0.35;

/// Opacity of the played bars: a little darker than the rest, not a block.
const double waveformPlayedAlpha = 0.85;

/// Opacity of the unplayed bars drawn as an outline.
const double waveformOutlineAlpha = 0.55;

/// Opacity of the thin line that stands for a hidden rest.
const double waveformRestLineAlpha = 0.9;

/// A dot is at least this wide, and two dots at least this far apart.
const double waveformDotMinDiameter = 2.5;
const double waveformDotMinGap = 1.5;

/// The mirror kind stands on this share of the band height, with its tallest
/// bar [waveformMirrorHeadroom] below the top.
const double waveformMirrorBaseShare = 0.66;
const double waveformMirrorHeadroom = 4;

/// Its reflection starts [waveformReflectionOffset] below the baseline, is
/// this share of the bar's height and this opaque.
const double waveformReflectionOffset = 2;
const double waveformReflectionHeight = 0.38;
const double waveformReflectionAlpha = 0.4;

const double waveformOutlineStroke = 1;
const double waveformLineOutlineStroke = 1.2;

/// The theme colours the shapes are drawn with.
class WavePalette {
  const WavePalette({
    required this.primary,
    required this.tertiary,
    required this.outline,
  });

  final Color primary;
  final Color tertiary;

  /// The thin line of a hidden rest.
  final Color outline;

  @override
  bool operator ==(Object other) =>
      other is WavePalette &&
      other.primary == primary &&
      other.tertiary == tertiary &&
      other.outline == outline;

  @override
  int get hashCode => Object.hash(primary, tertiary, outline);
}

/// Everything about the shapes that is not geometry or data: the kind, the
/// look and the colours. Recorded pictures are keyed by it.
class WaveStyle {
  const WaveStyle({
    required this.kind,
    required this.look,
    required this.palette,
  });

  final KSeekKind kind;
  final KWaveLook look;
  final WavePalette palette;

  /// What the recorded pictures depend on: the feedback and the colours the
  /// pictures never use (the hidden-rest line is drawn directly) are left out.
  WaveStyle get recorded => WaveStyle(
    kind: kind,
    look: KWaveLook(
      density: look.density,
      played: look.played,
      rest: look.rest,
    ),
    palette: WavePalette(
      primary: palette.primary,
      tertiary: look.played == KWavePlayed.single
          ? palette.primary
          : palette.tertiary,
      outline: palette.primary,
    ),
  );

  double get barWidth => look.density.barWidth;
  double get barGap => look.density.barGap;

  @override
  bool operator ==(Object other) =>
      other is WaveStyle &&
      other.kind == kind &&
      other.look == look &&
      other.palette == palette;

  @override
  int get hashCode => Object.hash(kind, look, palette);
}

/// Height of a bar of [base] dp after the touch feedback [factor]: never more
/// than the band less 2 dp, so a bar cannot touch its edges.
double waveBarHeight(double base, double factor, double bandHeight) =>
    math.min(bandHeight - 2, base * factor);

/// Number of dots in the column of a bar [height] tall.
int waveDotCount(
  double height, {
  required double barWidth,
  required double barGap,
}) {
  final step = waveDotStep(barWidth: barWidth, barGap: barGap);
  return math.max(1, (height / step).round());
}

/// Distance between the centres of two dots of a column.
double waveDotStep({required double barWidth, required double barGap}) =>
    math.max(barWidth, waveformDotMinDiameter) +
    math.max(barGap, waveformDotMinGap);

/// y of the baseline of the mirror kind in a band [bandHeight] tall.
double waveMirrorBaseline(double bandHeight) =>
    bandHeight * waveformMirrorBaseShare;

/// How far a bar of [height] (of at most [maxHeight]) rises above the
/// mirror baseline.
double waveMirrorRise(double height, double maxHeight, double baseline) =>
    math.min(
      height / maxHeight * (baseline - waveformMirrorHeadroom),
      baseline - 2,
    );

/// Rounds [v] to a device pixel.
double snapToDevicePixel(double v, double devicePixelRatio) =>
    (v * devicePixelRatio).roundToDouble() / devicePixelRatio;
