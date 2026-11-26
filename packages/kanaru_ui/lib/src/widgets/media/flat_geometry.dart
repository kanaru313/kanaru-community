import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'seek_thumb_painter.dart';
import 'spark_pool.dart';

/// Where the parts of the flat bar lie in a box [size], for a track
/// [thickness] thick centred vertically. The thumb stands at [progress]
/// (0..1); the played part ends at [playedProgress] (default [progress]),
/// which a bar may let slide to its target.
class FlatGeometry {
  FlatGeometry({
    required Size size,
    required double progress,
    required double thickness,
    double? playedProgress,
  }) : track = Rect.fromLTWH(
         0,
         (size.height - thickness) / 2,
         size.width,
         thickness,
       ),
       played = Rect.fromLTWH(
         0,
         (size.height - thickness) / 2,
         size.width * (playedProgress ?? progress).clamp(0.0, 1.0),
         thickness,
       ),
       cy = size.height / 2,
       headX = size.width * (playedProgress ?? progress).clamp(0.0, 1.0),
       thumbX = size.width * progress.clamp(0.0, 1.0),
       barX = (size.width * progress.clamp(0.0, 1.0)).clamp(
         seekThumbBarWidth / 2,
         math.max(seekThumbBarWidth / 2, size.width - seekThumbBarWidth / 2),
       );

  final Rect track;
  final Rect played;
  final double cy;

  /// x of the played part's end: the head of the comet and the sparks.
  final double headX;

  /// x of the thumb: the centre of a dot thumb.
  final double thumbX;

  /// Centre x of a bar thumb: kept inside the box, as the plain bar always did.
  final double barX;
}

/// What a [FlatSeekPainter] keeps between frames, owned by the widget state
/// (a painter is rebuilt with every position tick): the paint, the particles
/// and the shaders. Shaders depend on the colours only, so a theme change
/// drops them.
class FlatPaintCache {
  final paint = Paint();
  final pool = SparkPool();
  double lastTime = 0;
  ui.Shader? gradient;
  double gradientWidth = -1;
  ui.Shader? comet;
  int cometLevel = -1;
  ui.Shader? shine;
  ui.Shader? glow;
  Color? _primary;
  Color? _tertiary;

  /// Number of particles alive.
  int get particles => pool.count;

  void bind(Color primary, Color tertiary) {
    if (primary == _primary && tertiary == _tertiary) return;
    _primary = primary;
    _tertiary = tertiary;
    gradient = null;
    comet = null;
    cometLevel = -1;
    glow = null;
  }
}
