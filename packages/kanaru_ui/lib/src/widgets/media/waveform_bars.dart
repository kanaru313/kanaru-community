import 'dart:math' as math;
import 'dart:typed_data';

/// Height of the waveform seek track.
const double waveformTrackHeight = 48;

/// One bar's width and the empty space between two bars.
const double waveformBarWidth = 3;
const double waveformBarGap = 2;
const double waveformBarRadius = 1.5;

/// A bar is never shorter or taller than these, centred in the track.
const double waveformMinExtent = 2;
const double waveformMaxExtent = 32;

/// The thumb is an upright pill a little taller than the tallest bar.
const double waveformThumbWidth = 4;
const double waveformThumbHeight = waveformMaxExtent + 4;

/// Room kept free on each side of the thumb's centre: half the thumb plus the
/// same gap the straight track leaves around it.
const double waveformThumbClearance = waveformThumbWidth / 2 + 4;

/// Percentile of a track's levels that maps to 0 (the quietest tenth).
const int waveformContrastFloorPercentile = 10;

/// Percentile of a track's levels that maps to full height.
const int waveformContrastCeilingPercentile = 99;

/// Below this share of the ceiling the floor and ceiling count as one value
/// (a steady tone): the floor drops to silence and the level just fills up.
const double _flatSpreadShare = 0.05;

/// Number of bars that fit in [width]: bars start at x = 0, and the last one
/// ends at or before [width].
int waveformBarCount(double width) {
  if (!width.isFinite || width < waveformBarWidth) return 0;
  return ((width + waveformBarGap) / (waveformBarWidth + waveformBarGap))
      .floor();
}

/// Heights of the bars across [width], from [levels] (0 to 255, evenly spaced
/// over [length]).
///
/// Bars map time, not index: bar `j` covers a share of the player's [duration]
/// equal to its share of [width], and takes the mean of the levels whose time
/// falls in it (the level under its start when none does, as when there are
/// fewer levels than bars). A waveform shorter than the duration leaves the
/// bars after it at the minimum; a longer one is cut at the duration. A zero
/// [duration] or [length] gives no bars.
List<double> waveformBarExtents({
  required Uint8List levels,
  required Duration length,
  required Duration duration,
  required double width,
}) {
  final count = waveformBarCount(width);
  final lengthUs = length.inMicroseconds;
  final durationUs = duration.inMicroseconds;
  if (count == 0 || levels.isEmpty || lengthUs <= 0 || durationUs <= 0) {
    return const [];
  }
  const pitch = waveformBarWidth + waveformBarGap;
  final n = levels.length;
  double extentOf(double level) =>
      waveformMinExtent +
      (waveformMaxExtent - waveformMinExtent) * (level / 255);

  return List<double>.generate(count, (j) {
    final startUs = j * pitch / width * durationUs;
    if (startUs >= lengthUs) return waveformMinExtent;
    final endUs = (j + 1) * pitch / width * durationUs;
    // Levels i with startUs <= i / n * length < endUs.
    final first = (startUs / lengthUs * n).ceil();
    final end = (endUs / lengthUs * n).ceil().clamp(0, n);
    if (first >= end) {
      final under = (startUs / lengthUs * n).floor().clamp(0, n - 1);
      return extentOf(levels[under].toDouble());
    }
    var sum = 0;
    for (var i = first; i < end; i++) {
      sum += levels[i];
    }
    return extentOf(sum / (end - first));
  }, growable: false);
}

/// [levels] spread so the track's quieter tenth maps to 0 and its loudest
/// percent to 255. Same length; the input is not modified.
///
/// A stored level `l` is `255 * sqrt(rms / loudest)`, so the linear loudness
/// is `x = (l / 255)^2`. The floor and ceiling levels are found with a 256-bin
/// histogram (nearest rank, no sort); percentiles of `l` are those of `x`
/// because squaring keeps the order. Each level then becomes
/// `255 * clamp((x - xlo) / (xhi - xlo), 0, 1)`, through a 256-entry table. A
/// ceiling of 0 (a mostly silent file) falls back to the loudest level so a
/// short sound survives; silence stays all zeros; a flat track stays at full
/// height.
Uint8List waveformContrastLevels(Uint8List levels) {
  final n = levels.length;
  if (n == 0) return Uint8List(0);
  final histogram = List<int>.filled(256, 0);
  for (final l in levels) {
    histogram[l]++;
  }

  // The level at sorted position [rank], found by walking the histogram.
  int levelAt(int rank) {
    var seen = 0;
    for (var l = 0; l < 256; l++) {
      seen += histogram[l];
      if (seen > rank) return l;
    }
    return 255;
  }

  int rankOf(int percentile) => (percentile / 100 * (n - 1)).round();
  final lo = levelAt(rankOf(waveformContrastFloorPercentile));
  var hi = levelAt(rankOf(waveformContrastCeilingPercentile));
  if (hi == 0) hi = levelAt(n - 1);
  if (hi == 0) return Uint8List(n);

  double linear(int l) => math.pow(l / 255, 2).toDouble();
  var xlo = linear(lo);
  final xhi = linear(hi);
  if (xhi - xlo < _flatSpreadShare * xhi) xlo = 0;

  final table = Uint8List(256);
  for (var l = 0; l < 256; l++) {
    final t = ((linear(l) - xlo) / (xhi - xlo)).clamp(0.0, 1.0);
    table[l] = (255 * t).round();
  }
  final out = Uint8List(n);
  for (var i = 0; i < n; i++) {
    out[i] = table[levels[i]];
  }
  return out;
}
