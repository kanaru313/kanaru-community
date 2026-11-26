import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import 'seek_look.dart';
import 'wave_style.dart';
import 'wave_style_painter.dart';

export 'wave_style.dart' show snapToDevicePixel;

/// What the recorded bars depend on: change any of it and they are recorded
/// again. [extents] is compared by identity, so new levels re-record. [style]
/// holds the kind, the look and the colours.
typedef WaveformPicturesKey = ({
  List<double> extents,
  Size size,
  double inset,
  double devicePixelRatio,
  WaveStyle style,
});

/// The shapes drawn once as played and once as rest.
typedef WaveformPicturePair = ({ui.Picture played, ui.Picture rest});

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
    ui.Picture draw({required bool played}) {
      final recorder = ui.PictureRecorder();
      paintWaveShapes(
        Canvas(recorder),
        style: key.style,
        size: key.size,
        inset: key.inset,
        devicePixelRatio: key.devicePixelRatio,
        heights: key.extents,
        played: played,
      );
      return recorder.endRecording();
    }

    return (played: draw(played: true), rest: draw(played: false));
  }
}

/// Draws the band of the waveform seek bar: the shapes played up to [progress]
/// in one colour and the rest in another, and the keyboard focus line. No
/// thumb.
///
/// Steady state passes [pictures] (two clipped `drawPicture`s per frame, no
/// recording). During a transition or a touch feedback [heights] are drawn
/// directly instead, with [factors] scaling each bar for the feedback;
/// [factorsRevision] says when they changed in place. [opacity] scales the
/// colours.
class WaveformBandPainter extends CustomPainter {
  const WaveformBandPainter({
    required this.progress,
    required this.inset,
    required this.devicePixelRatio,
    required this.style,
    required this.focusColor,
    this.pictures,
    this.heights,
    this.factors,
    this.factorsRevision = 0,
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
  final WaveStyle style;
  final Color focusColor;
  final WaveformPicturePair? pictures;
  final List<double>? heights;
  final Float32List? factors;
  final int factorsRevision;
  final double opacity;

  /// Draw the thin mark at the position (keyboard focus only).
  final bool focusLine;

  @override
  void paint(Canvas canvas, Size size) {
    final direct = heights;
    // One outline for both layers of a line drawn directly.
    final line = pictures == null && style.kind == KSeekKind.line
        ? waveLinePath(
            style: style,
            size: size,
            inset: inset,
            heights: direct!,
            factors: factors,
          )
        : null;
    final inner = size.width - 2 * inset;
    final at = inner <= 0
        ? size.width / 2
        : inset + progress.clamp(0.0, 1.0) * inner;
    final edge = snapToDevicePixel(at, devicePixelRatio);
    if (edge > 0) _layer(canvas, size, 0, edge, played: true, line: line);
    if (edge < size.width && style.look.rest != KWaveRest.hidden) {
      _layer(canvas, size, edge, size.width, played: false, line: line);
    }
    if (style.look.rest == KWaveRest.hidden) {
      paintRestLine(
        canvas,
        style: style,
        size: size,
        inset: inset,
        from: at,
        opacity: opacity,
      );
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
    Path? line,
  }) {
    canvas
      ..save()
      ..clipRect(Rect.fromLTRB(from, 0, to, size.height));
    final recorded = pictures;
    if (recorded != null) {
      canvas.drawPicture(played ? recorded.played : recorded.rest);
    } else {
      paintWaveShapes(
        canvas,
        style: style,
        size: size,
        inset: inset,
        devicePixelRatio: devicePixelRatio,
        heights: heights!,
        played: played,
        factors: factors,
        opacity: opacity,
        clipFrom: from,
        clipTo: to,
        linePath: line,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(WaveformBandPainter old) =>
      old.progress != progress ||
      old.inset != inset ||
      old.devicePixelRatio != devicePixelRatio ||
      old.style != style ||
      old.focusColor != focusColor ||
      old.pictures != pictures ||
      !identical(old.heights, heights) ||
      !identical(old.factors, factors) ||
      old.factorsRevision != factorsRevision ||
      old.opacity != opacity ||
      old.focusLine != focusLine;
}
