import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

Uint8List _levels(List<int> v) => Uint8List.fromList(v);

void main() {
  group('density', () {
    test('the bar count follows the width and gap of the density', () {
      expect(waveformBarCount(100, barWidth: 4, barGap: 3), 14);
      expect(waveformBarCount(100, barWidth: 3, barGap: 2), 20);
      expect(waveformBarCount(100, barWidth: 2, barGap: 1), 33);
    });

    test('the bars stay centred in the inner width', () {
      for (final (w, g) in [(4.0, 3.0), (3.0, 2.0), (2.0, 1.0)]) {
        final n = waveformBarCount(100, barWidth: w, barGap: g);
        final offset = waveformBarsOffset(
          count: n,
          width: 112,
          inset: 6,
          barWidth: w,
          barGap: g,
        );
        final right = offset + n * (w + g) - g;
        expect(offset - 6, closeTo(112 - 6 - right, 1e-9));
        expect(offset, greaterThanOrEqualTo(6));
      }
    });
  });

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
      double inset = 0,
    }) => waveformBarExtents(
      levels: _levels(levels),
      length: Duration(milliseconds: lengthMs),
      duration: Duration(milliseconds: durationMs),
      width: width,
      inset: inset,
    );

    test('a bar is at least 3 dp tall and at most 32', () {
      expect(waveformMinExtent, 3);
      expect(waveformMaxExtent, 32);
    });

    test('0 maps to the minimum height, 255 to the maximum', () {
      expect(extents([0], width: 3), [waveformMinExtent]);
      expect(extents([255], width: 3), [waveformMaxExtent]);
    });

    test('a bar takes the mean of the levels inside its time', () {
      double extentOf(num level) =>
          waveformMinExtent +
          (waveformMaxExtent - waveformMinExtent) * (level / 255);
      // Width 48 holds 10 bars exactly (no offset): bar j covers 5 of 48
      // levels, so a block of 5 equal levels per bar comes back as its value.
      const blocks = [0, 100, 200, 255, 50, 0, 10, 20, 30, 40];
      final e = extents([
        for (var i = 0; i < 48; i++) blocks[i ~/ 5],
      ], width: 48);
      expect(e.length, 10);
      for (var j = 0; j < 10; j++) {
        expect(e[j], closeTo(extentOf(blocks[j]), 1e-9), reason: 'bar $j');
      }
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

  group('inset and offset', () {
    // 1000 levels rising evenly over the whole duration.
    final ramp = Uint8List.fromList(
      List.generate(1000, (i) => (i * 255 / 999).round()),
    );
    double extentOf(double level) =>
        waveformMinExtent +
        (waveformMaxExtent - waveformMinExtent) * (level / 255);

    test('bars are centred in the inner width', () {
      // Inner 181: 36 bars span 178, 1.5 free at each side.
      expect(waveformBarsOffset(count: 36, width: 193, inset: 6), 7.5);
      expect(waveformBarsOffset(count: 38, width: 200, inset: 6), 6);
    });

    test('the bar count follows the inner width', () {
      final e = waveformBarExtents(
        levels: ramp,
        length: const Duration(seconds: 100),
        duration: const Duration(seconds: 100),
        width: 200,
        inset: 6,
      );
      expect(e.length, waveformBarCount(188));
    });

    test('the bar under x stands for the time fraction (x - 6) / (w - 12)', () {
      const w = 193.0;
      const inset = 6.0;
      final e = waveformBarExtents(
        levels: ramp,
        length: const Duration(seconds: 100),
        duration: const Duration(seconds: 100),
        width: w,
        inset: inset,
      );
      final offset = waveformBarsOffset(
        count: e.length,
        width: w,
        inset: inset,
      );
      const pitch = waveformBarWidth + waveformBarGap;
      for (final x in [20.0, 60.5, 101.0, 150.0, 180.0]) {
        final j = ((x - offset) / pitch).floor();
        final fraction = (x - inset) / (w - 2 * inset);
        // The ramp is the fraction itself, so the bar's extent is that of the
        // middle of its time window, which holds the fraction under x.
        final from = (offset + j * pitch - inset) / (w - 2 * inset);
        final to = (offset + (j + 1) * pitch - inset) / (w - 2 * inset);
        expect(fraction, inInclusiveRange(from, to), reason: 'x $x');
        expect(
          e[j],
          closeTo(extentOf(255 * (from + to) / 2), 0.2),
          reason: 'x $x',
        );
      }
    });

    test('the first bar starts no earlier than the time axis', () {
      final e = waveformBarExtents(
        levels: Uint8List.fromList([255, 255]),
        length: const Duration(seconds: 10),
        duration: const Duration(seconds: 10),
        width: 193,
        inset: 6,
      );
      expect(e.first, waveformMaxExtent);
    });

    test('grown extents interpolate between a dot and the bar', () {
      expect(waveformGrownExtents([3, 32], 0), [3, 3]);
      expect(waveformGrownExtents([3, 32], 1), [3, 32]);
      expect(waveformGrownExtents([3, 23], 0.5), [3, 13]);
    });

    test('the cache keeps the list until an input changes', () {
      final cache = WaveformExtentsCache();
      List<double> get(Uint8List l, double w) => cache.of(
        levels: l,
        length: const Duration(seconds: 10),
        duration: const Duration(seconds: 10),
        width: w,
        inset: 6,
      );
      final a = get(ramp, 200);
      expect(identical(get(ramp, 200), a), isTrue);
      expect(identical(get(ramp, 220), a), isFalse);
      expect(identical(get(Uint8List.fromList([1, 2, 3]), 220), a), isFalse);
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

    test('silence stays silent', () {
      expect(
        waveformContrastLevels(_levels(List.filled(8, 0))),
        everyElement(0),
      );
    });

    test('a steady tone draws every bar at 60 % of the content height', () {
      final out = waveformContrastLevels(_levels(List.filled(8, 200)));
      expect(out, everyElement(out.first));
      final extents = waveformBarExtents(
        levels: out,
        length: const Duration(seconds: 8),
        duration: const Duration(seconds: 8),
        width: 112,
        inset: 6,
      );
      expect(extents, everyElement(closeTo(0.6 * waveformMaxExtent, 0.2)));
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
