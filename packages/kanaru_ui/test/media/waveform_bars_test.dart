import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

Uint8List _levels(List<int> v) => Uint8List.fromList(v);

void main() {
  group('waveformBarCount', () {
    test('3 dp bars with 2 dp gaps, the last one inside the width', () {
      expect(waveformBarCount(3), 1);
      expect(waveformBarCount(7.9), 1);
      expect(waveformBarCount(8), 2);
      expect(waveformBarCount(390), 78);
    });

    test('too narrow or unbounded gives none', () {
      expect(waveformBarCount(2.9), 0);
      expect(waveformBarCount(double.infinity), 0);
      expect(waveformBarCount(double.nan), 0);
    });
  });

  group('waveformBarExtents', () {
    List<double> extents(
      List<int> levels, {
      int lengthMs = 10000,
      int durationMs = 10000,
      double width = 50,
    }) => waveformBarExtents(
      levels: _levels(levels),
      length: Duration(milliseconds: lengthMs),
      duration: Duration(milliseconds: durationMs),
      width: width,
    );

    test('0 maps to the minimum height, 255 to the maximum', () {
      expect(extents([0], width: 3), [waveformMinExtent]);
      expect(extents([255], width: 3), [waveformMaxExtent]);
    });

    test('a bar takes the mean of the levels inside its time', () {
      // 10 bars over 10 levels: one level each.
      final one = extents(List.generate(10, (i) => i * 25), width: 50);
      expect(one.length, 10);
      // 5 bars over 10 levels: two levels each, the mean of the pair.
      final two = extents([
        0,
        100,
        100,
        200,
        0,
        0,
        255,
        255,
        50,
        50,
      ], width: 25);
      expect(two.length, 5);
      double extentOf(num level) =>
          waveformMinExtent +
          (waveformMaxExtent - waveformMinExtent) * (level / 255);
      expect(two[0], closeTo(extentOf(50), 1e-9));
      expect(two[1], closeTo(extentOf(150), 1e-9));
      expect(two[3], closeTo(extentOf(255), 1e-9));
    });

    test('fewer levels than bars repeats the level under the bar start', () {
      final e = extents([0, 255], width: 50);
      expect(e.length, 10);
      expect(e.first, waveformMinExtent);
      expect(e.last, waveformMaxExtent);
    });

    test('a waveform shorter than the duration leaves the rest minimal', () {
      final e = extents([255, 255, 255, 255], lengthMs: 5000, width: 50);
      expect(e.first, waveformMaxExtent);
      expect(e.last, waveformMinExtent);
    });

    test('a waveform longer than the duration is cut at the duration', () {
      final e = extents([0, 0, 255, 255], lengthMs: 20000, width: 50);
      expect(e.every((x) => x == waveformMinExtent), isTrue);
    });

    test('no duration, no length or no levels gives no bars', () {
      expect(extents([1, 2], durationMs: 0), isEmpty);
      expect(extents([1, 2], lengthMs: 0), isEmpty);
      expect(extents([]), isEmpty);
      expect(extents([1, 2], width: 2), isEmpty);
    });
  });

  group('waveformContrastLevels', () {
    test('spreads a quiet track over the full range', () {
      final out = waveformContrastLevels(
        _levels([60, 70, 80, 90, 100, 110, 120, 130, 140, 150]),
      );
      expect(out.first, 0);
      expect(out.last, 255);
      expect(out.length, 10);
    });

    test('silence stays silent and a steady tone stays full height', () {
      expect(
        waveformContrastLevels(_levels(List.filled(8, 0))),
        everyElement(0),
      );
      expect(
        waveformContrastLevels(_levels(List.filled(8, 200))),
        everyElement(255),
      );
    });

    test('a short sound in a mostly silent file survives', () {
      final out = waveformContrastLevels(
        _levels([...List.filled(199, 0), 180]),
      );
      expect(out.last, 255);
      expect(out.take(199), everyElement(0));
    });

    test('keeps the order of the levels and does not touch the input', () {
      final input = _levels([10, 50, 30, 200, 120]);
      final copy = Uint8List.fromList(input);
      final out = waveformContrastLevels(input);
      expect(input, copy);
      expect(out[1] < out[3], isTrue);
      expect(out[2] < out[1], isTrue);
    });

    test('empty stays empty', () {
      expect(waveformContrastLevels(Uint8List(0)), isEmpty);
    });
  });
}
