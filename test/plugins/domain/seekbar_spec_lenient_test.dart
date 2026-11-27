import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/package/seekbar_spec.dart';
import 'package:kanaru/src/plugins/domain/package/seekbar_spec_read.dart';

import 'seekbar_spec_test.dart' show block, emitter, thumb;

SeekbarSpec lenient(Object? value) => readSeekbarSpec(value, strict: false);

void main() {
  test('unknown keys at every level are ignored', () {
    final spec = lenient({
      'track': {'kind': 'bars', 'amplitude': 'low', 'zzz': 1},
      'colors': {'primary': 'primary', 'x': 1},
      'extra': true,
      'thumb': thumb({'rate': 3}),
      'emitter': emitter({
        'anchor': [0, 0],
      }),
    });
    expect(spec.track, isA<WaveTrack>());
    expect(spec.primary, isNotNull);
    expect(spec.thumb, isA<SpriteThumb>());
    expect(spec.emitter, isNotNull);
  });

  group('numbers are clamped', () {
    test('baseline and glow', () {
      expect(lenient(block((b) => b['baseline'] = 5)).baseline, 0.9);
      expect(lenient(block((b) => b['baseline'] = -5)).baseline, 0.2);
      expect(lenient(block((b) => b['glow'] = 99)).glow, 16);
      expect(lenient(block((b) => b['glow'] = -3)).glow, 0);
    });

    test('a wrong type gives the default', () {
      final spec = lenient(
        block(
          (b) => b
            ..['baseline'] = 'high'
            ..['glow'] = null,
        ),
      );
      expect(spec.baseline, 0.5);
      expect(spec.glow, 0);
    });

    test('thumb', () {
      final t =
          lenient(
                block(
                  (b) => b['thumb'] = thumb({
                    'size': [1, 500],
                    'anchor': [-2, 7],
                    'frames': 1000,
                    'fps': 0,
                    'paused': 9999,
                  }),
                ),
              ).thumb!
              as SpriteThumb;
      expect((t.width, t.height), (4, 56));
      expect((t.anchorX, t.anchorY), (0, 1));
      expect((t.frames, t.fps, t.paused), (64, 1, 63));
    });

    test('emitter', () {
      final e = lenient(
        block(
          (b) => b['emitter'] = emitter({
            'rate': 500,
            'life': [9, -1],
            'velocity': {
              'x': [-900, 900],
              'y': [30, 10],
            },
            'spin': [-9999, 9999],
            'fade': 'yes',
          }),
        ),
      ).emitter!;
      expect(e.rate, 20);
      expect((e.lifeMin, e.lifeMax), (0.05, 3));
      expect((e.velocityXMin, e.velocityXMax), (-200, 200));
      expect((e.velocityYMin, e.velocityYMax), (10, 30));
      expect((e.spinMin, e.spinMax), (-720, 720));
      expect(e.fade, isFalse);
    });

    test(
      'a null anchor gives the default; extra velocity keys are ignored',
      () {
        final spec = lenient(
          block((b) {
            b['thumb'] = thumb({'anchor': null});
            b['emitter'] = emitter({
              'velocity': {
                'x': [0, 1],
                'y': [2, 3],
                'z': [0, 1],
              },
            });
          }),
        );
        expect((spec.thumb as SpriteThumb).anchorX, 0.5);
        expect((spec.thumb as SpriteThumb).anchorY, 0.5);
        expect(spec.emitter, isNotNull);
        expect(
          (spec.emitter!.velocityYMin, spec.emitter!.velocityYMax),
          (2, 3),
        );
      },
    );

    test('a rate of zero is raised, not dropped', () {
      final e = lenient(block((b) => b['emitter'] = emitter({'rate': 0})))
          .emitter!;
      expect(e.rate, 0.1);
    });
  });

  group('broken parts', () {
    test('a thumb that cannot be read is dropped, the base stays', () {
      for (final bad in <Object?>[
        5,
        thumb()..remove('size'),
        thumb({'image': '../x.png'}),
        thumb({'size': 'big'}),
        {
          'size': [8, 8],
        },
      ]) {
        final spec = lenient(block((b) => b['thumb'] = bad));
        expect(spec.thumb, isNull, reason: '$bad');
        expect(spec.track, isA<FlatTrack>());
      }
    });

    test('an emitter missing a required key is dropped', () {
      for (final key in ['rate', 'life', 'velocity', 'size', 'image']) {
        final spec = lenient(
          block((b) => b['emitter'] = emitter()..remove(key)),
        );
        expect(spec.emitter, isNull, reason: key);
      }
    });

    test('a bad colour is ignored', () {
      final spec = lenient(
        block((b) => b['colors'] = {'primary': 'nope', 'secondary': '#112233'}),
      );
      expect(spec.primary, isNull);
      expect(spec.secondary, isA<SkinRgbColor>());
    });

    test('a bad track option falls back to its default', () {
      final t =
          lenient(
                block(
                  (b) => b['track'] = {
                    'kind': 'squig',
                    'amplitude': 'huge',
                    'motion': 'still',
                  },
                ),
              ).track
              as SquigTrack;
      expect(t.amplitude, SquigAmplitude.mid);
      expect(t.motion, SquigMotion.still);
    });

    test('an unreadable track is the default flat track', () {
      for (final bad in <Object?>[
        null,
        3,
        {'kind': 'nope'},
        <String, Object?>{},
      ]) {
        final spec = lenient({'track': bad});
        expect(spec.track, isA<FlatTrack>(), reason: '$bad');
      }
      expect(lenient({}).track, isA<FlatTrack>());
    });

    test('a block that is not an object never throws', () {
      for (final bad in <Object?>[null, 'x', 1, <Object?>[]]) {
        expect(lenient(bad).track, isA<FlatTrack>());
      }
    });
  });
}
