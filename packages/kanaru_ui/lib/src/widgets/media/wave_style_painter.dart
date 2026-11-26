import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import 'seek_look.dart';
import 'wave_style.dart';
import 'waveform_bars.dart';

// One paint reused by every call (painting is single threaded).
final Paint _paint = Paint()..isAntiAlias = true;

/// Draws every shape of [heights] once, as played bars or as rest bars; the
/// caller clips to the part it wants. [factors] (one per bar) scale the heights
/// for the touch feedback; [opacity] scales the alpha of the colours. Bars
/// wholly outside [clipFrom]..[clipTo] are skipped (the caller clips anyway);
/// the line kind draws [linePath] when given, so two layers share one path.
void paintWaveShapes(
  Canvas canvas, {
  required WaveStyle style,
  required Size size,
  required double inset,
  required double devicePixelRatio,
  required List<double> heights,
  required bool played,
  Float32List? factors,
  double opacity = 1,
  double? clipFrom,
  double? clipTo,
  Path? linePath,
}) {
  final n = heights.length;
  if (n == 0 || (!played && style.look.rest == KWaveRest.hidden)) return;
  final w = style.barWidth;
  final pitch = w + style.barGap;
  final offset = waveformBarsOffset(
    count: n,
    width: size.width,
    inset: inset,
    barWidth: w,
    barGap: style.barGap,
  );
  final inner = size.width - 2 * inset;
  final cy = size.height / 2;
  final maxH = math.min(waveformMaxExtent, size.height - 24);
  final outline = !played && style.look.rest == KWaveRest.outline;
  final alpha =
      (played
          ? waveformPlayedAlpha
          : outline
          ? waveformOutlineAlpha
          : waveformRestAlpha) *
      opacity;

  double heightOf(int j) => waveBarHeight(
    heights[j],
    factors != null && j < factors.length ? factors[j] : 1,
    size.height,
  );

  if (style.kind == KSeekKind.line) {
    _paintLine(
      canvas,
      style: style,
      size: size,
      cy: cy,
      maxH: maxH,
      alpha: alpha,
      outline: outline,
      path:
          linePath ??
          waveLinePath(
            style: style,
            size: size,
            inset: inset,
            heights: heights,
            factors: factors,
          ),
    );
    return;
  }

  _paint
    ..shader = null
    ..style = outline ? PaintingStyle.stroke : PaintingStyle.fill
    ..strokeWidth = waveformOutlineStroke;
  for (var j = 0; j < n; j++) {
    final bx = offset + j * pitch;
    if ((clipTo != null && bx > clipTo) ||
        (clipFrom != null && bx + w < clipFrom)) {
      continue;
    }
    final h = heightOf(j);
    final frac = inner <= 0
        ? 0.0
        : ((bx + w / 2 - inset) / inner).clamp(0.0, 1.0);
    _paint.color = _colorAt(style, frac, h / maxH, alpha);
    switch (style.kind) {
      case KSeekKind.dots:
        _paintDots(canvas, style, bx, h, cy);
      case KSeekKind.mirror:
        final base = waveMirrorBaseline(size.height);
        final rise = waveMirrorRise(h, maxH, base);
        _bar(canvas, bx, base - rise, rise, w, devicePixelRatio);
        final reflection = math.min(
          rise * waveformReflectionHeight,
          size.height - base - waveformReflectionOffset,
        );
        if (reflection > 0) {
          _paint.color = _paint.color.withValues(
            alpha: alpha * waveformReflectionAlpha,
          );
          _bar(
            canvas,
            bx,
            base + waveformReflectionOffset,
            reflection,
            w,
            devicePixelRatio,
          );
        }
      case KSeekKind.bars:
      case KSeekKind.line:
        _bar(canvas, bx, cy - h / 2, h, w, devicePixelRatio);
    }
  }
}

Color _colorAt(WaveStyle style, double fraction, double heightShare, double a) {
  final p = style.palette;
  final base = switch (style.look.played) {
    KWavePlayed.single => p.primary,
    KWavePlayed.gradient => Color.lerp(p.primary, p.tertiary, fraction)!,
    KWavePlayed.height => Color.lerp(
      p.tertiary,
      p.primary,
      heightShare.clamp(0.0, 1.0),
    )!,
  };
  return base.withValues(alpha: a);
}

void _bar(
  Canvas canvas,
  double x,
  double top,
  double height,
  double width,
  double dpr,
) {
  final h = math.max(height, 0.5);
  canvas.drawRRect(
    RRect.fromLTRBR(
      snapToDevicePixel(x, dpr),
      top,
      snapToDevicePixel(x + width, dpr),
      top + h,
      Radius.circular(math.min(width / 2, h / 2)),
    ),
    _paint,
  );
}

void _paintDots(
  Canvas canvas,
  WaveStyle style,
  double bx,
  double h,
  double cy,
) {
  final d = math.max(style.barWidth, waveformDotMinDiameter);
  final step = waveDotStep(barWidth: style.barWidth, barGap: style.barGap);
  final k = waveDotCount(h, barWidth: style.barWidth, barGap: style.barGap);
  final x = bx + style.barWidth / 2;
  for (var i = 0; i < k; i++) {
    canvas.drawCircle(
      Offset(x, cy - (k - 1) * step / 2 + i * step),
      d / 2,
      _paint,
    );
  }
}

/// The closed outline through the tops of the bars and back through their
/// mirrored bottoms (the line kind), one point per bar.
Path waveLinePath({
  required WaveStyle style,
  required Size size,
  required double inset,
  required List<double> heights,
  Float32List? factors,
}) {
  final n = heights.length;
  final w = style.barWidth;
  final pitch = w + style.barGap;
  final offset = waveformBarsOffset(
    count: n,
    width: size.width,
    inset: inset,
    barWidth: w,
    barGap: style.barGap,
  );
  final cy = size.height / 2;
  double heightOf(int j) => waveBarHeight(
    heights[j],
    factors != null && j < factors.length ? factors[j] : 1,
    size.height,
  );
  final path = Path();
  for (var j = 0; j < n; j++) {
    final x = offset + j * pitch + w / 2;
    final y = cy - heightOf(j) / 2;
    j == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
  }
  for (var j = n - 1; j >= 0; j--) {
    path.lineTo(offset + j * pitch + w / 2, cy + heightOf(j) / 2);
  }
  return path..close();
}

void _paintLine(
  Canvas canvas, {
  required WaveStyle style,
  required Size size,
  required double cy,
  required double maxH,
  required double alpha,
  required bool outline,
  required Path path,
}) {
  final p = style.palette;
  final shaded = style.look.played != KWavePlayed.single;
  // With a shader the alpha lives in its stops only: the paint colour is
  // multiplied into the shader output.
  _paint
    ..color = shaded
        ? const Color(0xFF000000)
        : p.primary.withValues(alpha: alpha)
    ..style = outline ? PaintingStyle.stroke : PaintingStyle.fill
    ..strokeWidth = waveformLineOutlineStroke
    ..strokeJoin = StrokeJoin.round
    ..shader = switch (style.look.played) {
      KWavePlayed.single => null,
      KWavePlayed.gradient => ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, 0),
        [
          p.primary.withValues(alpha: alpha),
          p.tertiary.withValues(alpha: alpha),
        ],
      ),
      KWavePlayed.height => ui.Gradient.linear(
        Offset(0, cy - maxH / 2),
        Offset(0, cy + maxH / 2),
        [
          p.primary.withValues(alpha: alpha),
          p.tertiary.withValues(alpha: alpha),
          p.primary.withValues(alpha: alpha),
        ],
        const [0, 0.5, 1],
      ),
    };
  canvas.drawPath(path, _paint);
  _paint
    ..shader = null
    ..strokeJoin = StrokeJoin.miter;
}

/// The thin line that stands for a hidden rest, from [from] to the right
/// inset.
void paintRestLine(
  Canvas canvas, {
  required WaveStyle style,
  required Size size,
  required double inset,
  required double from,
  double opacity = 1,
}) {
  final to = size.width - inset;
  if (from >= to) return;
  final y = style.kind == KSeekKind.mirror
      ? waveMirrorBaseline(size.height)
      : size.height / 2;
  _paint
    ..shader = null
    ..style = PaintingStyle.fill
    ..color = style.palette.outline.withValues(
      alpha: waveformRestLineAlpha * opacity,
    );
  canvas.drawRect(Rect.fromLTRB(from, y - 0.5, to, y + 0.5), _paint);
}
