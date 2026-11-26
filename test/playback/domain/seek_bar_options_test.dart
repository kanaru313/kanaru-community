import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/seek_bar_options.dart';

void main() {
  test('defaults match the documented ones and report isDefault', () {
    expect(WaveSeekOptions.defaults.isDefault, isTrue);
    expect(SquiggleSeekOptions.defaults.isDefault, isTrue);
    expect(FlatSeekOptions.defaults.isDefault, isTrue);
    expect(WaveSeekOptions.defaults.density, WaveDensity.mid);
    expect(WaveSeekOptions.defaults.feedback, WaveFeedback.off);
    expect(SquiggleSeekOptions.defaults.motion, SquiggleMotion.drift);
    expect(FlatSeekOptions.defaults.thickness, FlatThickness.mid);
    expect(FlatSeekOptions.defaults.effect, FlatEffect.off);
  });

  test('copyWith changes one field and equality follows the fields', () {
    final a = const WaveSeekOptions().copyWith(rest: WaveRest.hidden);
    expect(a.isDefault, isFalse);
    expect(a, const WaveSeekOptions(rest: WaveRest.hidden));
    expect(a.hashCode, const WaveSeekOptions(rest: WaveRest.hidden).hashCode);
    expect(a.copyWith(rest: WaveRest.dim).isDefault, isTrue);
    expect(
      const SquiggleSeekOptions().copyWith(thumb: SeekThumb.none).isDefault,
      isFalse,
    );
    expect(
      const FlatSeekOptions().copyWith(played: FlatPlayed.gradient).isDefault,
      isFalse,
    );
  });

  test('every group round-trips through its setting', () {
    const wave = WaveSeekOptions(
      density: WaveDensity.dense,
      played: WavePlayed.height,
      rest: WaveRest.outline,
      feedback: WaveFeedback.lens,
    );
    const squiggle = SquiggleSeekOptions(
      amplitude: SquiggleAmplitude.high,
      wavelength: SquiggleWavelength.long,
      motion: SquiggleMotion.music,
      thumb: SeekThumb.dot,
    );
    const flat = FlatSeekOptions(
      thickness: FlatThickness.thick,
      thumb: SeekThumb.none,
      played: FlatPlayed.gradient,
      effect: FlatEffect.comet,
    );
    expect(
      waveSeekOptionsSetting.decode(waveSeekOptionsSetting.encode(wave)),
      wave,
    );
    expect(
      squiggleSeekOptionsSetting.decode(
        squiggleSeekOptionsSetting.encode(squiggle),
      ),
      squiggle,
    );
    expect(
      flatSeekOptionsSetting.decode(flatSeekOptionsSetting.encode(flat)),
      flat,
    );
    expect(waveSeekOptionsSetting.key, 'playback.seek_bar_wave');
    expect(squiggleSeekOptionsSetting.key, 'playback.seek_bar_squiggle');
    expect(flatSeekOptionsSetting.key, 'playback.seek_bar_flat');
  });

  test('a bad or missing field takes its default, others survive', () {
    final o = WaveSeekOptions.fromJson({
      'density': 'dense',
      'played': 'rainbow',
      'rest': 7,
      'extra': true,
    });
    expect(o.density, WaveDensity.dense);
    expect(o.played, WavePlayed.single);
    expect(o.rest, WaveRest.dim);
    expect(o.feedback, WaveFeedback.off);
    final s = SquiggleSeekOptions.fromJson({'motion': 'still', 'thumb': null});
    expect(s.motion, SquiggleMotion.still);
    expect(s.thumb, SeekThumb.bar);
    expect(
      FlatSeekOptions.fromJson({'effect': 'sparks'}).effect,
      FlatEffect.sparks,
    );
    expect(FlatSeekOptions.fromJson(<String, Object?>{}).isDefault, isTrue);
  });

  test('a value that is not a map is refused so the default is used', () {
    for (final bad in <Object?>[
      'x',
      3,
      null,
      [1],
    ]) {
      expect(
        () => waveSeekOptionsSetting.decode(bad),
        throwsA(isA<FormatException>()),
      );
    }
  });
}
