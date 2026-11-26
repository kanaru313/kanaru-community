import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'flat_geometry.dart';
import 'seek_clock.dart';
import 'seek_look.dart';
import 'seek_thumb_painter.dart';

/// Paints the flat seek bar: track, played part (one colour or a gradient),
/// one effect from [KFlatEffect] while the [clock] has energy, and the thumb.
///
/// Reuses its paints, shaders and particle pool: a frame allocates no list,
/// path or shader (a comet's fade shader changes only while the energy
/// does). Repaints on the [clock] without a widget rebuild.
class FlatSeekPainter extends CustomPainter {
  FlatSeekPainter({
    required this.progress,
    this.playedProgress,
    required this.thickness,
    required this.look,
    required this.primary,
    required this.tertiary,
    required this.surface,
    required this.showThumb,
    required this.cache,
    this.clock,
  }) : super(repaint: clock);

  /// Where the thumb stands, 0..1.
  final double progress;

  /// Where the played part ends; [progress] when null.
  final double? playedProgress;

  /// Track thickness now, including the grow on hover and its animation.
  final double thickness;
  final KFlatLook look;
  final Color primary;
  final Color tertiary;
  final Color surface;
  final bool showThumb;

  /// What survives from frame to frame (see [FlatPaintCache]).
  final FlatPaintCache cache;

  /// Null: no effect runs (the plain bar).
  final SeekClock? clock;

  static const double _shinePeriod = 2.4;
  static const double _shineHalf = 30;
  static const double _glowPad = 13;

  FlatPaintCache get _c => cache;

  @override
  void paint(Canvas canvas, Size size) {
    _c.bind(primary, tertiary);
    final geo = FlatGeometry(
      size: size,
      progress: progress,
      playedProgress: playedProgress,
      thickness: thickness,
    );
    final energy = look.effect == KFlatEffect.off
        ? 0.0
        : (clock?.energy ?? 0.0);
    final r = Radius.circular(thickness / 2);

    _c.paint
      ..shader = null
      ..color = primary.withValues(alpha: 0.24);
    canvas.drawRRect(RRect.fromRectAndRadius(geo.track, r), _c.paint);

    if (geo.played.width > 0) {
      final played = RRect.fromRectAndRadius(geo.played, r);
      if (look.effect == KFlatEffect.comet && energy > 0) {
        _paintComet(canvas, played, geo.played, energy);
      } else {
        _c.paint
          ..shader = look.played == KFlatPlayed.gradient
              ? _gradientFor(geo.track.width)
              : null
          ..color = primary;
        canvas.drawRRect(played, _c.paint);
        _c.paint.shader = null;
      }
      if (look.effect == KFlatEffect.shine &&
          energy > 0 &&
          geo.played.width > 4) {
        _paintShine(canvas, played, geo, energy);
      }
    }
    if (look.effect == KFlatEffect.comet && energy > 0) {
      _paintGlow(canvas, geo, energy);
    }
    _paintSparks(canvas, geo, energy);

    if (showThumb) {
      final dot = look.thumb == KSeekThumb.dot;
      paintSeekThumb(
        canvas,
        _c.paint,
        thumb: look.thumb,
        x: dot ? geo.thumbX : geo.barX,
        cy: geo.cy,
        trackThickness: thickness,
        barHeight: flatThumbBarHeight,
        primary: primary,
        ring: surface,
      );
    }
  }

  ui.Shader _gradientFor(double width) {
    if (_c.gradient == null || _c.gradientWidth != width) {
      _c.gradientWidth = width;
      _c.gradient = ui.Gradient.linear(
        Offset.zero,
        Offset(math.max(width, 1), 0),
        [primary, tertiary],
      );
    }
    return _c.gradient!;
  }

  /// The played part fading in from the start: a unit gradient stretched to
  /// the played width.
  void _paintComet(Canvas canvas, RRect played, Rect rect, double energy) {
    final level = (energy * 32).round();
    if (_c.comet == null || level != _c.cometLevel) {
      _c.cometLevel = level;
      _c.comet = ui.Gradient.linear(Offset.zero, const Offset(1, 0), [
        primary.withValues(alpha: 1 - 0.8 * level / 32),
        primary,
      ]);
    }
    canvas
      ..save()
      ..clipRRect(played)
      ..scale(rect.width, 1);
    _c.paint
      ..color = const Color(0xFF000000)
      ..shader = _c.comet;
    canvas.drawRect(Rect.fromLTRB(0, rect.top, 1, rect.bottom), _c.paint);
    _c.paint.shader = null;
    canvas.restore();
  }

  void _paintShine(
    Canvas canvas,
    RRect played,
    FlatGeometry geo,
    double energy,
  ) {
    final time = clock?.time ?? 0;
    final u = (time % _shinePeriod) / _shinePeriod;
    final x = u * (geo.played.width + 2 * _shineHalf) - _shineHalf;
    _c.shine ??= ui.Gradient.linear(
      const Offset(-_shineHalf, 0),
      const Offset(_shineHalf, 0),
      const [Color(0x00FFFFFF), Color(0xA6FFFFFF), Color(0x00FFFFFF)],
      const [0, 0.5, 1],
    );
    canvas
      ..save()
      ..clipRRect(played)
      ..translate(x, 0);
    _c.paint
      ..shader = _c.shine
      ..color = Color.fromRGBO(255, 255, 255, energy);
    canvas.drawRect(
      Rect.fromLTRB(-_shineHalf, geo.played.top, _shineHalf, geo.played.bottom),
      _c.paint,
    );
    _c.paint.shader = null;
    canvas.restore();
  }

  /// Glow around the head from one radial gradient, then the solid head.
  void _paintGlow(Canvas canvas, FlatGeometry geo, double energy) {
    final radius = thickness / 2 + _glowPad;
    _c.glow ??= ui.Gradient.radial(Offset.zero, 1, [
      primary.withValues(alpha: 0.9),
      primary.withValues(alpha: 0),
    ]);
    canvas
      ..save()
      ..translate(geo.headX, geo.cy)
      ..scale(radius);
    _c.paint
      ..shader = _c.glow
      ..color = Color.fromRGBO(0, 0, 0, energy);
    canvas.drawCircle(Offset.zero, 1, _c.paint);
    _c.paint.shader = null;
    canvas.restore();
    _c.paint.color = primary;
    canvas.drawCircle(Offset(geo.headX, geo.cy), thickness / 2 + 1, _c.paint);
  }

  void _paintSparks(Canvas canvas, FlatGeometry geo, double energy) {
    if (look.effect != KFlatEffect.sparks || energy <= 0) {
      _c.pool.clear();
      _c.lastTime = clock?.time ?? 0;
      return;
    }
    final time = clock?.time ?? 0;
    final dt = (time - _c.lastTime).clamp(0.0, 0.1);
    _c.lastTime = time;
    _c.pool.step(dt, headX: geo.headX, headY: geo.cy, emit: energy);
    _c.paint.shader = null;
    for (var i = 0; i < _c.pool.count; i++) {
      _c.paint.color = primary.withValues(
        alpha: _c.pool.remaining(i) * 0.9 * energy,
      );
      canvas.drawCircle(
        Offset(_c.pool.x(i), _c.pool.y(i)),
        _c.pool.radius(i),
        _c.paint,
      );
    }
  }

  @override
  bool shouldRepaint(FlatSeekPainter old) =>
      old.progress != progress ||
      old.playedProgress != playedProgress ||
      old.thickness != thickness ||
      old.look != look ||
      old.primary != primary ||
      old.tertiary != tertiary ||
      old.surface != surface ||
      old.showThumb != showThumb ||
      old.clock != clock ||
      old.cache != cache;
}
