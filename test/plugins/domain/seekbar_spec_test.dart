import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/package/package_problem.dart';
import 'package:kanaru/src/plugins/domain/package/seekbar_spec.dart';
import 'package:kanaru/src/plugins/domain/package/seekbar_spec_read.dart';

Map<String, Object?> block([void Function(Map<String, Object?>)? edit]) {
  final b = <String, Object?>{
    'track': {'kind': 'flat'},
  };
  edit?.call(b);
  return b;
}

Map<String, Object?> thumb([Map<String, Object?> over = const {}]) => {
  'image': 'assets/t.png',
  'size': [16, 16],
  ...over,
};

Map<String, Object?> emitter([Map<String, Object?> over = const {}]) => {
  'image': 'assets/p.png',
  'size': [8, 8],
  'rate': 2,
  'life': [1, 2],
  'velocity': {
    'x': [0, 1],
    'y': [-5, 0],
  },
  ...over,
};

PackageProblem strictProblem(Object? value) {
  try {
    readSeekbarSpec(value, strict: true);
  } on PackageProblemError catch (e) {
    return e.problem;
  }
  fail('accepted: $value');
}

SeekbarSpec strictOk(Object? value) => readSeekbarSpec(value, strict: true);

void main() {
  group('strict refuses, naming the key path', () {
    final cases = <String, (Object?, String)>{
      'not an object': ('x', 'seekbar'),
      'unknown top key': (block((b) => b['feedback'] = 1), 'seekbar.feedback'),
      'no track': (block((b) => b.remove('track')), 'seekbar.track'),
      'track not object': (block((b) => b['track'] = 3), 'seekbar.track'),
      'bad track kind': (
        block((b) => b['track'] = {'kind': 'x'}),
        'seekbar.track.kind',
      ),
      'amplitude on bars': (
        block((b) => b['track'] = {'kind': 'bars', 'amplitude': 'low'}),
        'seekbar.track.amplitude',
      ),
      'bad density': (
        block((b) => b['track'] = {'kind': 'bars', 'density': 'x'}),
        'seekbar.track.density',
      ),
      'height on flat': (
        block((b) => b['track'] = {'kind': 'flat', 'color': 'height'}),
        'seekbar.track.color',
      ),
      'rest on squig': (
        block((b) => b['track'] = {'kind': 'squig', 'rest': 'dim'}),
        'seekbar.track.rest',
      ),
      'bad motion': (
        block((b) => b['track'] = {'kind': 'squig', 'motion': 'x'}),
        'seekbar.track.motion',
      ),
      'bad thickness': (
        block((b) => b['track'] = {'kind': 'flat', 'thickness': 5}),
        'seekbar.track.thickness',
      ),
      'colors not object': (
        block((b) => b['colors'] = 'primary'),
        'seekbar.colors',
      ),
      'unknown colors key': (
        block((b) => b['colors'] = {'tertiary': 'primary'}),
        'seekbar.colors.tertiary',
      ),
      'short hex': (
        block((b) => b['colors'] = {'primary': '#fff'}),
        'seekbar.colors.primary',
      ),
      'bad role': (
        block((b) => b['colors'] = {'secondary': 'red'}),
        'seekbar.colors.secondary',
      ),
      'baseline low': (block((b) => b['baseline'] = 0.1), 'seekbar.baseline'),
      'baseline high': (block((b) => b['baseline'] = 0.95), 'seekbar.baseline'),
      'baseline text': (
        block((b) => b['baseline'] = '0.5'),
        'seekbar.baseline',
      ),
      'glow': (block((b) => b['glow'] = 17), 'seekbar.glow'),
      'glow negative': (block((b) => b['glow'] = -1), 'seekbar.glow'),
      'thumb not object': (block((b) => b['thumb'] = 1), 'seekbar.thumb'),
      'thumb image and lottie': (
        block((b) => b['thumb'] = thumb({'lottie': 'assets/a.json'})),
        'seekbar.thumb',
      ),
      'thumb neither': (
        block(
          (b) => b['thumb'] = {
            'size': [8, 8],
          },
        ),
        'seekbar.thumb',
      ),
      'thumb unknown key': (
        block((b) => b['thumb'] = thumb({'rate': 1})),
        'seekbar.thumb.rate',
      ),
      'thumb bad name': (
        block((b) => b['thumb'] = thumb({'image': 'assets/../x.png'})),
        'seekbar.thumb.image',
      ),
      'thumb gif': (
        block((b) => b['thumb'] = thumb({'image': 'assets/t.gif'})),
        'seekbar.thumb.image',
      ),
      'thumb long name': (
        block((b) => b['thumb'] = thumb({'image': 'assets/${'a' * 65}.png'})),
        'seekbar.thumb.image',
      ),
      'thumb no size': (
        block((b) => b['thumb'] = thumb()..remove('size')),
        'seekbar.thumb.size',
      ),
      'thumb narrow': (
        block(
          (b) => b['thumb'] = thumb({
            'size': [3, 16],
          }),
        ),
        'seekbar.thumb.size',
      ),
      'thumb wide': (
        block(
          (b) => b['thumb'] = thumb({
            'size': [65, 16],
          }),
        ),
        'seekbar.thumb.size',
      ),
      'thumb tall': (
        block(
          (b) => b['thumb'] = thumb({
            'size': [16, 57],
          }),
        ),
        'seekbar.thumb.size',
      ),
      'thumb size three': (
        block(
          (b) => b['thumb'] = thumb({
            'size': [16, 16, 1],
          }),
        ),
        'seekbar.thumb.size',
      ),
      'thumb anchor': (
        block(
          (b) => b['thumb'] = thumb({
            'anchor': [1.5, 0],
          }),
        ),
        'seekbar.thumb.anchor',
      ),
      'thumb tint': (
        block((b) => b['thumb'] = thumb({'tint': '#12345'})),
        'seekbar.thumb.tint',
      ),
      'frames 0': (
        block((b) => b['thumb'] = thumb({'frames': 0})),
        'seekbar.thumb.frames',
      ),
      'frames 65': (
        block((b) => b['thumb'] = thumb({'frames': 65})),
        'seekbar.thumb.frames',
      ),
      'frames fraction': (
        block((b) => b['thumb'] = thumb({'frames': 2.0})),
        'seekbar.thumb.frames',
      ),
      'fps 0': (
        block((b) => b['thumb'] = thumb({'fps': 0})),
        'seekbar.thumb.fps',
      ),
      'fps 31': (
        block((b) => b['thumb'] = thumb({'fps': 31})),
        'seekbar.thumb.fps',
      ),
      'paused past frames': (
        block((b) => b['thumb'] = thumb({'frames': 2, 'paused': 2})),
        'seekbar.thumb.paused',
      ),
      'paused negative': (
        block((b) => b['thumb'] = thumb({'paused': -1})),
        'seekbar.thumb.paused',
      ),
      'emitter not object': (block((b) => b['emitter'] = 1), 'seekbar.emitter'),
      'emitter unknown key': (
        block(
          (b) => b['emitter'] = emitter({
            'anchor': [0, 0],
          }),
        ),
        'seekbar.emitter.anchor',
      ),
      'emitter bad image': (
        block((b) => b['emitter'] = emitter({'image': 'p.png'})),
        'seekbar.emitter.image',
      ),
      'emitter size': (
        block(
          (b) => b['emitter'] = emitter({
            'size': [8, 57],
          }),
        ),
        'seekbar.emitter.size',
      ),
      'emitter no rate': (
        block((b) => b['emitter'] = emitter()..remove('rate')),
        'seekbar.emitter.rate',
      ),
      'emitter no life': (
        block((b) => b['emitter'] = emitter()..remove('life')),
        'seekbar.emitter.life',
      ),
      'emitter no velocity': (
        block((b) => b['emitter'] = emitter()..remove('velocity')),
        'seekbar.emitter.velocity',
      ),
      'rate 0': (
        block((b) => b['emitter'] = emitter({'rate': 0})),
        'seekbar.emitter.rate',
      ),
      'rate 21': (
        block((b) => b['emitter'] = emitter({'rate': 21})),
        'seekbar.emitter.rate',
      ),
      'rate text': (
        block((b) => b['emitter'] = emitter({'rate': '2'})),
        'seekbar.emitter.rate',
      ),
      'life 0': (
        block(
          (b) => b['emitter'] = emitter({
            'life': [0, 1],
          }),
        ),
        'seekbar.emitter.life',
      ),
      'life 4': (
        block(
          (b) => b['emitter'] = emitter({
            'life': [1, 4],
          }),
        ),
        'seekbar.emitter.life',
      ),
      'life order': (
        block(
          (b) => b['emitter'] = emitter({
            'life': [2, 1],
          }),
        ),
        'seekbar.emitter.life',
      ),
      'velocity extra key': (
        block(
          (b) => b['emitter'] = emitter({
            'velocity': {
              'x': [0, 1],
              'y': [0, 1],
              'z': [0, 1],
            },
          }),
        ),
        'seekbar.emitter.velocity',
      ),
      'velocity x cap': (
        block(
          (b) => b['emitter'] = emitter({
            'velocity': {
              'x': [0, 201],
              'y': [0, 1],
            },
          }),
        ),
        'seekbar.emitter.velocity.x',
      ),
      'velocity y order': (
        block(
          (b) => b['emitter'] = emitter({
            'velocity': {
              'x': [0, 1],
              'y': [5, 1],
            },
          }),
        ),
        'seekbar.emitter.velocity.y',
      ),
      'spin cap': (
        block(
          (b) => b['emitter'] = emitter({
            'spin': [0, 721],
          }),
        ),
        'seekbar.emitter.spin',
      ),
      'fade number': (
        block((b) => b['emitter'] = emitter({'fade': 1})),
        'seekbar.emitter.fade',
      ),
      'lottie bad name': (
        block(
          (b) => b['thumb'] = {
            'lottie': 'assets/a.png',
            'size': [16, 16],
          },
        ),
        'seekbar.thumb.lottie',
      ),
      'lottie unknown key': (
        block(
          (b) => b['thumb'] = {
            'lottie': 'assets/a.json',
            'size': [16, 16],
            'fps': 12,
          },
        ),
        'seekbar.thumb.fps',
      ),
      'lottie bad recolor colour': (
        block(
          (b) => b['thumb'] = {
            'lottie': 'assets/a.json',
            'size': [16, 16],
            'recolor': {'label': 'red'},
          },
        ),
        'seekbar.thumb.recolor.label',
      ),
    };
    cases.forEach((name, c) {
      test(name, () {
        final problem = strictProblem(c.$1);
        expect(problem, isA<InvalidManifest>());
        expect(problem.detail, c.$2);
      });
    });
  });

  group('strict accepts the ends of every range', () {
    test('baseline, glow, size, anchor, frames, fps, rate, life', () {
      final spec = strictOk(
        block(
          (b) => b
            ..['baseline'] = 0.2
            ..['glow'] = 16
            ..['thumb'] = thumb({
              'size': [64, 4],
              'anchor': [0, 1],
              'frames': 64,
              'fps': 30,
              'paused': 63,
            })
            ..['emitter'] = emitter({
              'rate': 20,
              'life': [0.01, 3],
              'velocity': {
                'x': [-200, 200],
                'y': [-200, 200],
              },
              'spin': [-720, 720],
              'fade': true,
            }),
        ),
      );
      expect(spec.baseline, 0.2);
      expect(spec.glow, 16);
      final t = spec.thumb! as SpriteThumb;
      expect(
        (t.width, t.height, t.frames, t.fps, t.paused),
        (64, 4, 64, 30, 63),
      );
      expect(spec.emitter!.fade, isTrue);
      expect(spec.emitter!.velocityXMin, -200);
      expect(strictOk(block((b) => b['baseline'] = 0.9)).baseline, 0.9);
    });

    test('defaults', () {
      final spec = strictOk(block());
      expect(spec.baseline, 0.5);
      expect(spec.glow, 0);
      expect(spec.primary, isNull);
      expect(spec.thumb, isNull);
      expect(spec.emitter, isNull);
      expect((spec.track as FlatTrack).thickness, FlatThickness.mid);
      final t =
          strictOk(block((b) => b['thumb'] = thumb())).thumb! as SpriteThumb;
      expect(
        (t.frames, t.fps, t.paused, t.anchorX, t.anchorY),
        (1, 12, 0, .5, .5),
      );
      final e = strictOk(block((b) => b['emitter'] = emitter())).emitter!;
      expect((e.spinMin, e.spinMax, e.fade), (0, 0, false));
    });
  });

  group('colours', () {
    test('roles and hex', () {
      final spec = strictOk(
        block(
          (b) => b['colors'] = {
            'primary': 'onSurfaceVariant',
            'secondary': '#0A1b2C',
          },
        ),
      );
      expect((spec.primary! as SkinRoleColor).role, SkinRole.onSurfaceVariant);
      expect((spec.secondary! as SkinRgbColor).rgb, 0x0A1B2C);
    });
  });

  group('tracks', () {
    test('every kind with all its keys', () {
      final wave =
          strictOk(
                block(
                  (b) => b['track'] = {
                    'kind': 'mirror',
                    'density': 'dense',
                    'color': 'height',
                    'rest': 'hide',
                  },
                ),
              ).track
              as WaveTrack;
      expect(
        (wave.kind, wave.density, wave.color, wave.rest),
        (WaveKind.mirror, WaveDensity.dense, WaveColor.height, WaveRest.hide),
      );
      final squig =
          strictOk(
                block(
                  (b) => b['track'] = {
                    'kind': 'squig',
                    'amplitude': 'high',
                    'wavelength': 'long',
                    'motion': 'music',
                    'thumb': 'dot',
                  },
                ),
              ).track
              as SquigTrack;
      expect(
        (squig.amplitude, squig.wavelength, squig.motion, squig.thumb),
        (
          SquigAmplitude.high,
          SquigWavelength.long,
          SquigMotion.music,
          TrackThumb.dot,
        ),
      );
      final flat =
          strictOk(
                block(
                  (b) => b['track'] = {
                    'kind': 'flat',
                    'thickness': 'thick',
                    'thumb': 'none',
                    'color': 'grad',
                  },
                ),
              ).track
              as FlatTrack;
      expect(
        (flat.thickness, flat.thumb, flat.color),
        (FlatThickness.thick, TrackThumb.none, FlatColor.grad),
      );
    });
  });

  group('lottie thumb', () {
    final lottie = {
      'lottie': 'assets/a.json',
      'size': [30, 30],
      'recolor': {'label': 'primary'},
      'paused': 'freeze',
    };

    test('strict refuses it as an unsupported feature', () {
      final problem = strictProblem(block((b) => b['thumb'] = lottie));
      expect(problem, isA<UnsupportedFeature>());
      expect(problem.detail, 'seekbar.thumb.lottie');
    });

    test('a broken lottie thumb reports its own problem first', () {
      final problem = strictProblem(
        block(
          (b) => b['thumb'] = {
            ...lottie,
            'size': [1, 1],
          },
        ),
      );
      expect(problem, isA<InvalidManifest>());
    });

    test('lenient keeps it', () {
      final spec = readSeekbarSpec(
        block((b) => b['thumb'] = lottie),
        strict: false,
      );
      final t = spec.thumb! as LottieThumb;
      expect(t.lottie, 'assets/a.json');
      expect(t.pausedFrame, isNull);
      expect((t.recolor['label']! as SkinRoleColor).role, SkinRole.primary);
    });
  });
}
