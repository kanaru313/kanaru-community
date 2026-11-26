import 'dart:math' as math;
import 'dart:typed_data';

/// Height of the seek band (hit area and paint area) of the waveform bar. The
/// bars live in a 32 dp zone in the middle; the rest is room for the touch
/// feedback and the focus line.
const double seekBandHeight = 56;

/// Room kept free at the left and right of the band: the time axis runs over
/// the width minus twice this.
const double seekInset = 6;

/// One bar's width and the empty space between two bars at the default
/// (mid) density; the other densities pass their own to the functions below.
const double waveformBarWidth = 3;
const double waveformBarGap = 2;

/// A bar is never shorter or taller than these, centred in the band. At the
/// minimum a bar is a dot.
const double waveformMinExtent = 3;
const double waveformMaxExtent = 32;

/// Percentile of a track's levels that maps to 0 (the quietest tenth).
const int waveformContrastFloorPercentile = 10;

/// Percentile of a track's levels that maps to full height.
const int waveformContrastCeilingPercentile = 99;

/// Below this share of the ceiling the floor and ceiling count as one value
/// (a steady tone): the floor drops to silence and the level just fills up.
const double _flatSpreadShare = 0.05;

/// Height of the bars of a steady tone as a share of the content zone: there
/// is nothing to stretch, so they stay calm instead of a solid block.
const double waveformSteadyShare = 0.6;

/// The stored level whose bar is [waveformSteadyShare] of the content zone.
final double _steadyLevel =
    255 *
    (waveformSteadyShare * waveformMaxExtent - waveformMinExtent) /
    (waveformMaxExtent - waveformMinExtent);

/// Number of bars that fit in [width] (the inner width, inset excluded): bars
/// start at its left edge, and the last one ends at or before its right edge.
int waveformBarCount(
  double width, {
  double barWidth = waveformBarWidth,
  double barGap = waveformBarGap,
}) {
  if (!width.isFinite || width < barWidth) return 0;
  return ((width + barGap) / (barWidth + barGap)).floor();
}

/// Left x of the first of [count] bars centred in the inner width of a band
/// [width] wide with [inset] free at each side.
double waveformBarsOffset({
  required int count,
  required double width,
  required double inset,
  double barWidth = waveformBarWidth,
  double barGap = waveformBarGap,
}) {
  final inner = width - 2 * inset;
  return inset + (inner - (count * (barWidth + barGap) - barGap)) / 2;
}

/// Heights of the bars across a band [width] wide with [inset] free at each
/// side, from [levels] (0 to 255, evenly spaced over [length]).
///
/// The bars are centred in the inner width ([waveformBarsOffset]). Bars map
/// time, not index: the time axis runs over the inner width, so bar `j` covers
/// the fractions `(offset + j * pitch - inset) / inner` to
/// `(offset + (j + 1) * pitch - inset) / inner` of the player's [duration]
/// (the same fraction a tap at that x seeks to) and takes the mean of the
/// levels whose time falls in it (the level under its start when none does,
/// as when there are fewer levels than bars). A waveform shorter than the
/// duration leaves the bars after it at the minimum; a longer one is cut at
/// the duration (the last window ends at the duration, not in the gap after
/// the last bar). A zero [duration] or [length] gives no bars.
List<double> waveformBarExtents({
  required Uint8List levels,
  required Duration length,
  required Duration duration,
  required double width,
  required double inset,
  double barWidth = waveformBarWidth,
  double barGap = waveformBarGap,
}) {
  final inner = width - 2 * inset;
  final count = waveformBarCount(inner, barWidth: barWidth, barGap: barGap);
  final lengthUs = length.inMicroseconds;
  final durationUs = duration.inMicroseconds;
  if (count == 0 || levels.isEmpty || lengthUs <= 0 || durationUs <= 0) {
    return const [];
  }
  final pitch = barWidth + barGap;
  final offset = waveformBarsOffset(
    count: count,
    width: width,
    inset: inset,
    barWidth: barWidth,
    barGap: barGap,
  );
  final n = levels.length;
  double extentOf(double level) =>
      waveformMinExtent +
      (waveformMaxExtent - waveformMinExtent) * (level / 255);

  return List<double>.generate(count, (j) {
    final startUs = (offset + j * pitch - inset) / inner * durationUs;
    if (startUs >= lengthUs) return waveformMinExtent;
    final endUs = math.min(
      (offset + (j + 1) * pitch - inset) / inner * durationUs,
      durationUs.toDouble(),
    );
    // Levels i with startUs <= i / n * length < endUs.
    final first = (startUs / lengthUs * n).ceil().clamp(0, n);
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

/// [base] heights grown by [t] (0 = every bar a dot, 1 = [base]); [t] is the
/// eased value. A new list.
List<double> waveformGrownExtents(List<double> base, double t) => [
  for (final h in base) waveformMinExtent + (h - waveformMinExtent) * t,
];

/// Remembers the bar heights of one waveform so a position tick or a frame of
/// a transition does not compute them again: [of] returns the same list until
/// the levels (by identity), the lengths or the width change.
class WaveformExtentsCache {
  Uint8List? _levels;
  Duration? _length;
  Duration? _duration;
  double? _width;
  double? _inset;
  double? _barWidth;
  double? _barGap;
  List<double> _extents = const [];

  List<double> of({
    required Uint8List levels,
    required Duration length,
    required Duration duration,
    required double width,
    required double inset,
    double barWidth = waveformBarWidth,
    double barGap = waveformBarGap,
  }) {
    if (!identical(levels, _levels) ||
        length != _length ||
        duration != _duration ||
        width != _width ||
        inset != _inset ||
        barWidth != _barWidth ||
        barGap != _barGap) {
      _levels = levels;
      _length = length;
      _duration = duration;
      _width = width;
      _inset = inset;
      _barWidth = barWidth;
      _barGap = barGap;
      _extents = waveformBarExtents(
        levels: waveformContrastLevels(levels),
        length: length,
        duration: duration,
        width: width,
        inset: inset,
        barWidth: barWidth,
        barGap: barGap,
      );
    }
    return _extents;
  }
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
/// short sound survives; silence stays all zeros; a steady tone (floor and
/// ceiling the same) has nothing to stretch, so its loudest bars stand at
/// [waveformSteadyShare] of the content zone instead of a solid block.
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
  final steady = xhi - xlo < _flatSpreadShare * xhi;
  if (steady) xlo = 0;
  final top = steady ? _steadyLevel : 255.0;

  final table = Uint8List(256);
  for (var l = 0; l < 256; l++) {
    final t = ((linear(l) - xlo) / (xhi - xlo)).clamp(0.0, 1.0);
    table[l] = (top * t).round();
  }
  final out = Uint8List(n);
  for (var i = 0; i < n; i++) {
    out[i] = table[levels[i]];
  }
  return out;
}
