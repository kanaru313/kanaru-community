import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:kanaru_ui/src/widgets/media/wave_style.dart';
import 'package:kanaru_ui/src/widgets/media/wave_style_painter.dart';

const _size = Size(364, seekBandHeight);
const _palette = WavePalette(
  primary: Color(0xFF3355CC),
  tertiary: Color(0xFFCC5533),
  outline: Color(0xFF888888),
);

List<double> _heights(int n) => [
  for (var i = 0; i < n; i++) 3 + (i % 10) * 2.9,
];

/// Alpha (0..255) of the pixel at ([x], [y]) of [shapes] drawn on a [size]
/// canvas at scale 1.
Future<int> _alphaAt(
  WidgetTester tester,
  WaveStyle style, {
  required bool played,
  required int x,
  required int y,
  required Size size,
  double height = 30,
  double opacity = 1,
}) async {
  final n = waveformBarCount(
    size.width - 12,
    barWidth: style.barWidth,
    barGap: style.barGap,
  );
  final recorder = ui.PictureRecorder();
  paintWaveShapes(
    Canvas(recorder),
    style: style,
    size: size,
    inset: seekInset,
    devicePixelRatio: 1,
    heights: List.filled(n, height),
    played: played,
    opacity: opacity,
  );
  final picture = recorder.endRecording();
  final alpha = await tester.runAsync(() async {
    final image = await picture.toImage(size.width.ceil(), size.height.ceil());
    final data = (await image.toByteData())!;
    image.dispose();
    return data.getUint8((y * size.width.ceil() + x) * 4 + 3);
  });
  picture.dispose();
  return alpha!;
}

WaveStyle _style(KSeekKind kind, KWaveLook look) =>
    WaveStyle(kind: kind, look: look, palette: _palette);

int _a(double alpha) => (alpha * 255).round();

void main() {
  group('alpha of what is drawn', () {
    // Band 57 dp tall: the centre line sits on a pixel edge.
    const size = Size(120, 57);
    const midX = 60;
    const midY = 28;

    for (final kind in [KSeekKind.bars, KSeekKind.line]) {
      for (final played in KWavePlayed.values) {
        testWidgets('${kind.name} ${played.name}: played .85, dim .35', (
          tester,
        ) async {
          final style = _style(kind, KWaveLook(played: played));
          // The bar centre of bar 11 (offset 6 + 11 * 5 + 1) for the bars.
          final x = kind == KSeekKind.bars ? 6 + 11 * 5 + 1 : midX;
          expect(
            await _alphaAt(
              tester,
              style,
              played: true,
              x: x,
              y: midY,
              size: size,
            ),
            closeTo(_a(0.85), 2),
          );
          expect(
            await _alphaAt(
              tester,
              style,
              played: false,
              x: x,
              y: midY,
              size: size,
            ),
            closeTo(_a(0.35), 2),
          );
        });
      }
    }

    testWidgets('line outline rest: stroke only, interior empty', (
      tester,
    ) async {
      final style = _style(
        KSeekKind.line,
        const KWaveLook(played: KWavePlayed.gradient, rest: KWaveRest.outline),
      );
      // The top edge of the outline is at y 13; the inside stays clear.
      expect(
        await _alphaAt(tester, style, played: false, x: 60, y: 28, size: size),
        0,
      );
      final edge = await _alphaAt(
        tester,
        style,
        played: false,
        x: 60,
        y: 13,
        size: size,
      );
      expect(edge, inInclusiveRange(_a(0.55 * 0.5), _a(0.55)));
    });

    testWidgets('bars outline rest: the stroke is 0.55, the inside clear', (
      tester,
    ) async {
      final style = _style(
        KSeekKind.bars,
        const KWaveLook(rest: KWaveRest.outline),
      );
      // Bar 11 spans x 61..64; its left edge column is at x 61.
      expect(
        await _alphaAt(tester, style, played: false, x: 62, y: 28, size: size),
        0,
      );
      expect(
        await _alphaAt(tester, style, played: false, x: 62, y: 13, size: size),
        greaterThan(0),
      );
    });

    testWidgets('hidden rest draws nothing, the thin line is .9', (
      tester,
    ) async {
      final style = _style(
        KSeekKind.bars,
        const KWaveLook(rest: KWaveRest.hidden),
      );
      expect(
        await _alphaAt(tester, style, played: false, x: 62, y: 28, size: size),
        0,
      );
      final recorder = ui.PictureRecorder();
      paintRestLine(
        Canvas(recorder),
        style: style,
        size: size,
        inset: seekInset,
        from: 40,
      );
      final picture = recorder.endRecording();
      final alpha = await tester.runAsync(() async {
        final image = await picture.toImage(120, 57);
        final data = (await image.toByteData())!;
        image.dispose();
        return [
          data.getUint8((28 * 120 + 80) * 4 + 3),
          data.getUint8((28 * 120 + 20) * 4 + 3),
          data.getUint8((28 * 120 + 116) * 4 + 3),
        ];
      });
      picture.dispose();
      expect(alpha![0], closeTo(_a(0.9), 2));
      expect(alpha[1], 0, reason: 'before the position');
      expect(alpha[2], 0, reason: 'inside the right inset');
    });

    testWidgets('mirror: the reflection is 40 % of the bar alpha', (
      tester,
    ) async {
      final style = _style(KSeekKind.mirror, const KWaveLook());
      // Baseline 37.5 (band 56.8), reflection from 39.5 down about 12 dp.
      const mirrorSize = Size(120, 56.8);
      expect(
        await _alphaAt(
          tester,
          style,
          played: true,
          x: 62,
          y: 44,
          size: mirrorSize,
        ),
        closeTo(_a(0.85 * 0.4), 2),
      );
      expect(
        await _alphaAt(
          tester,
          style,
          played: true,
          x: 62,
          y: 30,
          size: mirrorSize,
        ),
        closeTo(_a(0.85), 2),
      );
    });

    testWidgets('opacity scales the alpha', (tester) async {
      final style = _style(KSeekKind.line, const KWaveLook());
      expect(
        await _alphaAt(
          tester,
          style,
          played: true,
          x: 60,
          y: 28,
          size: size,
          opacity: 0.5,
        ),
        closeTo(_a(0.85 * 0.5), 2),
      );
    });
  });

  group('geometry', () {
    test('a dot column has max(1, round(h / step)) dots', () {
      // mid: width 3 -> diameter 3, gap 2 -> step 5
      expect(waveDotStep(barWidth: 3, barGap: 2), 5);
      expect(waveDotCount(3, barWidth: 3, barGap: 2), 1);
      expect(waveDotCount(32, barWidth: 3, barGap: 2), 6);
      // dense: width 2 -> diameter 2.5, gap 1 -> 1.5, step 4
      expect(waveDotStep(barWidth: 2, barGap: 1), 4);
      expect(waveDotCount(32, barWidth: 2, barGap: 1), 8);
      // loose: width 4, gap 3 -> step 7
      expect(waveDotCount(32, barWidth: 4, barGap: 3), 5);
      expect(waveDotCount(0, barWidth: 4, barGap: 3), 1);
    });

    test('the mirror stands on 66 % of the band and keeps its headroom', () {
      final base = waveMirrorBaseline(56);
      expect(base, closeTo(36.96, 1e-9));
      expect(waveMirrorRise(32, 32, base), closeTo(base - 4, 1e-9));
      expect(waveMirrorRise(3, 32, base), closeTo(3 / 32 * (base - 4), 1e-9));
      // A feedback-grown bar cannot rise above the band.
      expect(waveMirrorRise(54, 32, base), lessThanOrEqualTo(base - 2));
    });

    test('a bar never grows past the band less 2 dp', () {
      expect(waveBarHeight(32, 2.2, 56), 54);
      expect(waveBarHeight(32, 1.7, 56), 54);
      expect(waveBarHeight(20, 1, 56), 20);
      expect(waveBarHeight(20, 0.35, 56), closeTo(7, 1e-9));
    });
  });

  group('paintWaveShapes', () {
    final kinds = KSeekKind.values;
    final densities = KWaveDensity.values;

    for (final kind in kinds) {
      for (final density in densities) {
        for (final played in KWavePlayed.values) {
          for (final rest in KWaveRest.values) {
            test(
              '${kind.name} ${density.name} ${played.name} ${rest.name}',
              () {
                final style = WaveStyle(
                  kind: kind,
                  look: KWaveLook(density: density, played: played, rest: rest),
                  palette: _palette,
                );
                final n = waveformBarCount(
                  _size.width - 12,
                  barWidth: density.barWidth,
                  barGap: density.barGap,
                );
                final factors = Float32List(n)..fillRange(0, n, 2.2);
                for (final f in [null, factors]) {
                  for (final isPlayed in [true, false]) {
                    final recorder = ui.PictureRecorder();
                    paintWaveShapes(
                      Canvas(recorder),
                      style: style,
                      size: _size,
                      inset: seekInset,
                      devicePixelRatio: 2,
                      heights: _heights(n),
                      played: isPlayed,
                      factors: f,
                      opacity: 0.5,
                    );
                    recorder.endRecording().dispose();
                  }
                }
              },
            );
          }
        }
      }
    }

    test('no bars draws nothing and does not throw', () {
      final recorder = ui.PictureRecorder();
      paintWaveShapes(
        Canvas(recorder),
        style: const WaveStyle(
          kind: KSeekKind.line,
          look: KWaveLook(),
          palette: _palette,
        ),
        size: _size,
        inset: seekInset,
        devicePixelRatio: 1,
        heights: const [],
        played: true,
      );
      recorder.endRecording().dispose();
    });
  });

  group('WaveStyle', () {
    test('equal by kind, look and colours', () {
      const a = WaveStyle(
        kind: KSeekKind.dots,
        look: KWaveLook(density: KWaveDensity.dense),
        palette: _palette,
      );
      const b = WaveStyle(
        kind: KSeekKind.dots,
        look: KWaveLook(density: KWaveDensity.dense),
        palette: _palette,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a,
        isNot(
          const WaveStyle(
            kind: KSeekKind.bars,
            look: KWaveLook(density: KWaveDensity.dense),
            palette: _palette,
          ),
        ),
      );
    });

    test('a change of look or colour records the pictures again', () {
      final pictures = WaveformPictures();
      addTearDown(pictures.dispose);
      final extents = _heights(60);
      WaveformPicturesKey key(WaveStyle style) => (
        extents: extents,
        size: _size,
        inset: seekInset,
        devicePixelRatio: 1,
        style: style,
      );
      const base = WaveStyle(
        kind: KSeekKind.bars,
        look: KWaveLook(),
        palette: _palette,
      );
      final before = WaveformPictures.recordings;
      pictures.pair(key(base));
      pictures.pair(key(base));
      expect(WaveformPictures.recordings, before + 1);
      pictures.pair(
        key(
          const WaveStyle(
            kind: KSeekKind.bars,
            look: KWaveLook(played: KWavePlayed.gradient),
            palette: _palette,
          ),
        ),
      );
      pictures.pair(
        key(
          const WaveStyle(
            kind: KSeekKind.mirror,
            look: KWaveLook(played: KWavePlayed.gradient),
            palette: _palette,
          ),
        ),
      );
      expect(WaveformPictures.recordings, before + 3);
    });
  });
}
