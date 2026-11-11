import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'waveform_bars.dart';

/// What the bars depend on: change any of it and they are recorded again.
/// [levels] is compared by identity, so a new load re-records.
typedef WaveformPicturesKey = ({
  Uint8List levels,
  Duration length,
  Duration duration,
  Size size,
  double devicePixelRatio,
  Color played,
  Color rest,
});

/// The bars drawn once in the played colour and once in the rest colour.
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
    final extents = waveformBarExtents(
      levels: waveformContrastLevels(key.levels),
      length: key.length,
      duration: key.duration,
      width: key.size.width,
    );
    ui.Picture draw(Color color) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()..color = color;
      final dpr = key.devicePixelRatio;
      final centre = key.size.height / 2;
      // Both edges snapped to a device pixel so the bars stay crisp.
      double snap(double v) => (v * dpr).roundToDouble() / dpr;
      for (var j = 0; j < extents.length; j++) {
        final start = j * (waveformBarWidth + waveformBarGap);
        canvas.drawRRect(
          RRect.fromLTRBR(
            snap(start),
            centre - extents[j] / 2,
            snap(start + waveformBarWidth),
            centre + extents[j] / 2,
            const Radius.circular(waveformBarRadius),
          ),
          paint,
        );
      }
      return recorder.endRecording();
    }

    return (played: draw(key.played), rest: draw(key.rest));
  }
}

/// Draws the recorded bars with the thumb at [progress]: played bars left of
/// the thumb, rest bars right of it, a cleared band around it.
///
/// A tick only changes [progress], so painting is two clipped `drawPicture`s
/// and one rounded rectangle: no path or picture is built.
class WaveformTrackPainter extends CustomPainter {
  const WaveformTrackPainter({
    required this.progress,
    required this.pictures,
    required this.thumbColor,
  });

  final double progress;
  final WaveformPicturePair pictures;
  final Color thumbColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Narrower than the thumb there is no room to clamp into: centre it.
    final thumbX = size.width < waveformThumbWidth
        ? size.width / 2
        : (progress * size.width).clamp(
            waveformThumbWidth / 2,
            size.width - waveformThumbWidth / 2,
          );
    final playedEnd = thumbX - waveformThumbClearance;
    final restStart = thumbX + waveformThumbClearance;
    if (playedEnd > 0) {
      canvas
        ..save()
        ..clipRect(Rect.fromLTRB(0, 0, playedEnd, size.height))
        ..drawPicture(pictures.played)
        ..restore();
    }
    if (restStart < size.width) {
      canvas
        ..save()
        ..clipRect(Rect.fromLTRB(restStart, 0, size.width, size.height))
        ..drawPicture(pictures.rest)
        ..restore();
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(thumbX, size.height / 2),
          width: waveformThumbWidth,
          height: waveformThumbHeight,
        ),
        const Radius.circular(waveformThumbWidth / 2),
      ),
      Paint()..color = thumbColor,
    );
  }

  @override
  bool shouldRepaint(WaveformTrackPainter old) =>
      old.progress != progress ||
      old.pictures != pictures ||
      old.thumbColor != thumbColor;
}
