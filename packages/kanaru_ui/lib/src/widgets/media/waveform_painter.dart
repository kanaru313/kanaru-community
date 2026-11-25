import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import 'waveform_bars.dart';

/// What the recorded bars depend on: change any of it and they are recorded
/// again. [extents] is compared by identity, so new levels re-record.
typedef WaveformPicturesKey = ({
  List<double> extents,
  Size size,
  double inset,
  double devicePixelRatio,
  Color played,
  Color rest,
});

/// The bars drawn once in the played colour and once in the rest colour.
typedef WaveformPicturePair = ({ui.Picture played, ui.Picture rest});

/// Rounds [v] to a device pixel.
double snapToDevicePixel(double v, double devicePixelRatio) =>
    (v * devicePixelRatio).roundToDouble() / devicePixelRatio;

/// Draws one bar per entry of [heights], centred on [centreY], the first at
/// [offset], both edges on a device pixel so the bars stay crisp.
void paintWaveformBars(
  Canvas canvas, {
  required List<double> heights,
  required double offset,
  required double centreY,
  required double devicePixelRatio,
  required Color color,
}) {
  final paint = Paint()..color = color;
  for (var j = 0; j < heights.length; j++) {
    final start = offset + j * (waveformBarWidth + waveformBarGap);
    canvas.drawRRect(
      RRect.fromLTRBR(
        snapToDevicePixel(start, devicePixelRatio),
        centreY - heights[j] / 2,
        snapToDevicePixel(start + waveformBarWidth, devicePixelRatio),
        centreY + heights[j] / 2,
        const Radius.circular(waveformBarRadius),
      ),
      paint,
    );
  }
}

/// Keeps the recorded bars of one waveform bar. A position tick must not
/// record again: [pair] returns the same pictures until its key changes.
/// Replaced pictures are disposed, so are the last ones on [dispose].
class WaveformPictures {
  WaveformPicturesKey? _key;
  WaveformPicturePair? _pair;

  /// How many times bars were recorded, for tests.
  @visibleForTesting
  static int recordings = 0;

  WaveformPicturePair pair(WaveformPicturesKey key) {
    final kept = _pair;
    if (kept != null && key == _key) return kept;
    dispose();
    recordings++;
    final recorded = _record(key);
    _key = key;
    return _pair = recorded;
  }

  void dispose() {
    _pair?.played.dispose();
    _pair?.rest.dispose();
    _pair = null;
    _key = null;
  }

  static WaveformPicturePair _record(WaveformPicturesKey key) {
    final offset = waveformBarsOffset(
      count: key.extents.length,
      width: key.size.width,
      inset: key.inset,
    );
    ui.Picture draw(Color color) {
      final recorder = ui.PictureRecorder();
      paintWaveformBars(
        Canvas(recorder),
        heights: key.extents,
        offset: offset,
        centreY: key.size.height / 2,
        devicePixelRatio: key.devicePixelRatio,
        color: color,
      );
      return recorder.endRecording();
    }

    return (played: draw(key.played), rest: draw(key.rest));
  }
}

/// Draws the band of the waveform seek bar: the bars played up to [progress]
/// in one colour and the rest in another, and the keyboard focus line. No
/// thumb.
///
/// Steady state passes [pictures] (two clipped `drawPicture`s per frame, no
/// recording). During a transition [heights] are drawn directly instead, at
/// most about 70 rounded rectangles per layer. [opacity] scales both colours.
class WaveformBandPainter extends CustomPainter {
  const WaveformBandPainter({
    required this.progress,
    required this.inset,
    required this.devicePixelRatio,
    required this.playedColor,
    required this.restColor,
    required this.focusColor,
    this.pictures,
    this.heights,
    this.opacity = 1,
    this.focusLine = false,
  }) : assert(
         pictures != null || heights != null,
         'draw recorded pictures or direct heights',
       );

  /// 0..1 over the inner width (the band minus [inset] at each side).
  final double progress;
  final double inset;
  final double devicePixelRatio;
  final Color playedColor;
  final Color restColor;
  final Color focusColor;
  final WaveformPicturePair? pictures;
  final List<double>? heights;
  final double opacity;

  /// Draw the thin mark at the position (keyboard focus only).
  final bool focusLine;

  @override
  void paint(Canvas canvas, Size size) {
    final inner = size.width - 2 * inset;
    final at = inner <= 0
        ? size.width / 2
        : inset + progress.clamp(0.0, 1.0) * inner;
    final edge = snapToDevicePixel(at, devicePixelRatio);
    if (edge > 0) _layer(canvas, size, 0, edge, played: true);
    if (edge < size.width) {
      _layer(canvas, size, edge, size.width, played: false);
    }
    if (focusLine) {
      canvas.drawRect(
        Rect.fromLTWH(at - 0.75, 2, 1.5, size.height - 4),
        Paint()..color = focusColor,
      );
    }
  }

  void _layer(
    Canvas canvas,
    Size size,
    double from,
    double to, {
    required bool played,
  }) {
    canvas
      ..save()
      ..clipRect(Rect.fromLTRB(from, 0, to, size.height));
    final recorded = pictures;
    if (recorded != null) {
      canvas.drawPicture(played ? recorded.played : recorded.rest);
    } else {
      final bars = heights!;
      paintWaveformBars(
        canvas,
        heights: bars,
        offset: waveformBarsOffset(
          count: bars.length,
          width: size.width,
          inset: inset,
        ),
        centreY: size.height / 2,
        devicePixelRatio: devicePixelRatio,
        color: (played ? playedColor : restColor).withValues(
          alpha: (played ? playedColor : restColor).a * opacity,
        ),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(WaveformBandPainter old) =>
      old.progress != progress ||
      old.inset != inset ||
      old.devicePixelRatio != devicePixelRatio ||
      old.playedColor != playedColor ||
      old.restColor != restColor ||
      old.focusColor != focusColor ||
      old.pictures != pictures ||
      !identical(old.heights, heights) ||
      old.opacity != opacity ||
      old.focusLine != focusLine;
}
