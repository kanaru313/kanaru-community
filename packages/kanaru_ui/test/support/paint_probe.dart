import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// A painter drawn once on a transparent canvas at scale 1, to read pixels.
class PaintProbe {
  PaintProbe._(this._data, this.width);

  final ByteData _data;
  final int width;

  /// Draws [painter] on a [size] canvas.
  static Future<PaintProbe> of(
    WidgetTester tester,
    CustomPainter painter,
    Size size,
  ) async {
    final recorder = ui.PictureRecorder();
    painter.paint(Canvas(recorder), size);
    final picture = recorder.endRecording();
    final data = await tester.runAsync(() async {
      final image = await picture.toImage(
        size.width.ceil(),
        size.height.ceil(),
      );
      final bytes = (await image.toByteData())!;
      image.dispose();
      return bytes;
    });
    picture.dispose();
    return PaintProbe._(data!, size.width.ceil());
  }

  int _at(int x, int y, int channel) =>
      _data.getUint8((y * width + x) * 4 + channel);

  // The bytes come premultiplied by alpha: undo it, so a channel reads as the
  // colour drawn (0 where nothing is).
  int _straight(int x, int y, int channel) {
    final a = alpha(x, y);
    return a == 0 ? 0 : (_at(x, y, channel) * 255 / a).round().clamp(0, 255);
  }

  int red(int x, int y) => _straight(x, y, 0);
  int green(int x, int y) => _straight(x, y, 1);
  int blue(int x, int y) => _straight(x, y, 2);
  int alpha(int x, int y) => _at(x, y, 3);
}
