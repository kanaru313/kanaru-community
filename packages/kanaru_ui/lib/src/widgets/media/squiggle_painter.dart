import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/rendering.dart';

import 'seek_clock.dart';
import 'seek_look.dart';
import 'seek_thumb_painter.dart';

/// Stroke width of the played wave, and height of the straight rest line.
const double squiggleStroke = 4;

/// Space between the end of the wave (and the start of the rest line) and the
/// thumb, with a thumb.
const double squiggleThumbGap = 6;

/// Waves drift this many cycles a second while playing.
const double squiggleCyclesPerSecond = 0.9;

/// Distance between two points of the wave line.
const double _step = 2;

/// 0..1 factor of the wave height at [x] of a wave drawn from [start] to
/// [end]: it grows from 0.2 at the start over a quarter wavelength and tapers
/// to 0 over the last half wavelength, so the line meets the thumb flat.
double squiggleTaper(
  double x, {
  required double start,
  required double end,
  required double wavelength,
}) {
  final t = math.min(
    math.min(1.0, (end - x) / (wavelength / 2)),
    (x - start) / (wavelength / 4) + 0.2,
  );
  return math.max(0.0, t);
}

/// y of the wave at [x]: [amplitude] dp, scaled by [taper], on the line
/// [cy], moved to the right by [phase] radians.
double squiggleWaveY({
  required double x,
  required double cy,
  required double amplitude,
  required double taper,
  required double wavelength,
  double phase = 0,
}) => cy + amplitude * taper * math.sin(2 * math.pi * x / wavelength - phase);

/// The wave height now: [base] dp times [energy] (0 flat, 1 full). With a
/// [level] (0..1, the loudness at the position) the height follows the music,
/// with a small pulse in [time] (seconds).
double squiggleAmplitude({
  required double base,
  required double energy,
  double? level,
  double time = 0,
}) {
  final music = level == null
      ? 1.0
      : 0.35 + 1.3 * level * (0.85 + 0.15 * math.sin(time * 9));
  return base * music * energy;
}

/// Loudness (0..1) at [position] of the track: the mean of the level there and
/// the ones three steps before and after, from [levels] (0..255, evenly spaced
/// over [length]; the contrast-stretched levels the bars use). Null without
/// levels or a [length].
double? squiggleLevelAt(
  Uint8List? levels, {
  required Duration position,
  required Duration length,
}) {
  final n = levels?.length ?? 0;
  if (levels == null || n == 0 || length <= Duration.zero) return null;
  final i = (position.inMicroseconds / length.inMicroseconds * n).floor().clamp(
    0,
    n - 1,
  );
  final mid = levels[i];
  final before = i >= 3 ? levels[i - 3] : mid;
  final after = i + 3 < n ? levels[i + 3] : mid;
  return (mid + before + after) / 3 / 255;
}

/// What a [SquigglePainter] reuses between frames, owned by the widget state.
class SquigglePaintCache {
  final fill = Paint();
  final stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = squiggleStroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final path = Path();
}

/// Paints the squiggle: a wavy played line that drifts while playing and
/// flattens on pause (the [clock] energy), a straight rest line at 24 %, and
/// the thumb. [level] (loudness at the position) makes the height follow the
/// music. Repaints on the [clock] without a widget rebuild; a frame reuses the
/// cache's paints and path.
class SquigglePainter extends CustomPainter {
  SquigglePainter({
    required this.progress,
    required this.look,
    required this.primary,
    required this.surface,
    required this.cache,
    required this.clock,
    required this.showThumb,
    this.level,
  }) : super(repaint: clock);

  final double progress;
  final KSquiggleLook look;
  final Color primary;
  final Color surface;
  final SquigglePaintCache cache;
  final SeekClock clock;
  final bool showThumb;

  /// Loudness 0..1 at the position; null: no music motion.
  final double? level;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final px = size.width * progress.clamp(0.0, 1.0);
    final thumb = showThumb ? look.thumb : KSeekThumb.none;
    final gap = thumb == KSeekThumb.none ? 0.0 : squiggleThumbGap;
    final wavelength = look.wavelength.dp;
    final still = look.motion == KSquiggleMotion.still;

    final restStart = px + gap;
    if (size.width - restStart > 0) {
      cache.fill.color = primary.withValues(alpha: 0.24);
      canvas.drawRRect(
        RRect.fromLTRBR(
          restStart,
          cy - squiggleStroke / 2,
          size.width,
          cy + squiggleStroke / 2,
          const Radius.circular(squiggleStroke / 2),
        ),
        cache.fill,
      );
    }

    final end = math.max(0.0, px - gap);
    if (end > 0) {
      final amplitude = squiggleAmplitude(
        base: look.amplitude.dp,
        energy: clock.energy,
        level: look.motion == KSquiggleMotion.music ? level : null,
        time: clock.time,
      );
      final phase = still
          ? 0.0
          : clock.time * 2 * math.pi * squiggleCyclesPerSecond;
      final path = cache.path..reset();
      var x = 0.0;
      while (true) {
        final y = squiggleWaveY(
          x: x,
          cy: cy,
          amplitude: amplitude,
          taper: squiggleTaper(x, start: 0, end: end, wavelength: wavelength),
          wavelength: wavelength,
          phase: phase,
        );
        x == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
        if (x >= end) break;
        x = math.min(end, x + _step);
      }
      cache.stroke.color = primary;
      canvas.drawPath(path, cache.stroke);
    }

    paintSeekThumb(
      canvas,
      cache.fill,
      thumb: thumb,
      x: px,
      cy: cy,
      trackThickness: squiggleStroke,
      barHeight: squiggleThumbBarHeight,
      primary: primary,
      ring: surface,
    );
  }

  @override
  bool shouldRepaint(SquigglePainter old) =>
      old.progress != progress ||
      old.look != look ||
      old.primary != primary ||
      old.surface != surface ||
      old.level != level ||
      old.showThumb != showThumb ||
      old.clock != clock ||
      old.cache != cache;
}
