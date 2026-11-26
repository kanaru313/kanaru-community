import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'seek_look.dart';

/// Height of the bar thumb of the flat track, and the least it overhangs the
/// track on each side.
const double flatThumbBarHeight = 16;
const double squiggleThumbBarHeight = 20;
const double seekThumbBarWidth = 4;

/// Draws the thumb of a squiggle or flat bar centred at ([x], [cy]) on a track
/// [trackThickness] thick. Bar: 4 x [barHeight] (taller when the track is
/// thick); dot: [primary] with a ring in [ring]; none: nothing. [paint] is
/// reused: its colour changes, nothing else.
void paintSeekThumb(
  Canvas canvas,
  Paint paint, {
  required KSeekThumb thumb,
  required double x,
  required double cy,
  required double trackThickness,
  required double barHeight,
  required Color primary,
  required Color ring,
}) {
  switch (thumb) {
    case KSeekThumb.none:
      return;
    case KSeekThumb.bar:
      final h = math.max(barHeight, trackThickness + 8);
      paint.color = primary;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x - seekThumbBarWidth / 2,
            cy - h / 2,
            seekThumbBarWidth,
            h,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
    case KSeekThumb.dot:
      paint.color = ring;
      canvas.drawCircle(
        Offset(x, cy),
        math.max(8, trackThickness / 2 + 4),
        paint,
      );
      paint.color = primary;
      canvas.drawCircle(
        Offset(x, cy),
        math.max(6.5, trackThickness / 2 + 2.5),
        paint,
      );
  }
}
