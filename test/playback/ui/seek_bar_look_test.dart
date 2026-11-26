import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/seek_bar_options.dart';
import 'package:kanaru/src/playback/domain/seek_bar_style.dart';
import 'package:kanaru/src/playback/ui/seek_bar_look.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

void main() {
  group('seekKindOf', () {
    test('every wave style has its own kind', () {
      expect(seekKindOf(SeekBarStyle.bars), KSeekKind.bars);
      expect(seekKindOf(SeekBarStyle.dots), KSeekKind.dots);
      expect(seekKindOf(SeekBarStyle.line), KSeekKind.line);
      expect(seekKindOf(SeekBarStyle.mirror), KSeekKind.mirror);
    });

    test('squiggle and flat have a bar of their own, no wave kind', () {
      expect(seekKindOf(SeekBarStyle.squiggle), isNull);
      expect(seekKindOf(SeekBarStyle.flat), isNull);
    });

    test('a style that draws the waveform maps to a kind of its own name', () {
      for (final style in waveSeekBarStyles) {
        expect(seekKindOf(style)!.name, style.name);
      }
    });
  });

  group('waveLookOf', () {
    test('the defaults map to the default look', () {
      expect(waveLookOf(WaveSeekOptions.defaults), const KWaveLook());
    });

    test('every option value maps to the look value of its name', () {
      for (final d in WaveDensity.values) {
        expect(waveLookOf(WaveSeekOptions(density: d)).density.name, d.name);
      }
      for (final p in WavePlayed.values) {
        expect(waveLookOf(WaveSeekOptions(played: p)).played.name, p.name);
      }
      for (final r in WaveRest.values) {
        expect(waveLookOf(WaveSeekOptions(rest: r)).rest.name, r.name);
      }
      for (final f in WaveFeedback.values) {
        expect(waveLookOf(WaveSeekOptions(feedback: f)).feedback.name, f.name);
      }
    });

    test('all four options together', () {
      final look = waveLookOf(
        const WaveSeekOptions(
          density: WaveDensity.dense,
          played: WavePlayed.height,
          rest: WaveRest.hidden,
          feedback: WaveFeedback.lens,
        ),
      );
      expect(
        look,
        const KWaveLook(
          density: KWaveDensity.dense,
          played: KWavePlayed.height,
          rest: KWaveRest.hidden,
          feedback: KSeekFeedback.lens,
        ),
      );
    });
  });

  group('squiggleLookOf', () {
    test('the defaults map to the default look', () {
      expect(
        squiggleLookOf(SquiggleSeekOptions.defaults),
        const KSquiggleLook(),
      );
    });

    test('every option value maps to the look value of its name', () {
      for (final a in SquiggleAmplitude.values) {
        expect(
          squiggleLookOf(SquiggleSeekOptions(amplitude: a)).amplitude.name,
          a.name,
        );
      }
      for (final w in SquiggleWavelength.values) {
        expect(
          squiggleLookOf(SquiggleSeekOptions(wavelength: w)).wavelength.name,
          w.name,
        );
      }
      for (final m in SquiggleMotion.values) {
        expect(
          squiggleLookOf(SquiggleSeekOptions(motion: m)).motion.name,
          m.name,
        );
      }
      for (final t in SeekThumb.values) {
        expect(
          squiggleLookOf(SquiggleSeekOptions(thumb: t)).thumb.name,
          t.name,
        );
      }
    });

    test('as the fallback, music motion drifts and the rest is kept', () {
      const options = SquiggleSeekOptions(
        amplitude: SquiggleAmplitude.high,
        motion: SquiggleMotion.music,
        thumb: SeekThumb.dot,
      );
      final look = squiggleLookOf(options, asFallback: true);
      expect(look.motion, KSquiggleMotion.drift);
      expect(look.amplitude, KSquiggleAmplitude.high);
      expect(look.thumb, KSeekThumb.dot);
      expect(squiggleLookOf(options).motion, KSquiggleMotion.music);
      expect(
        squiggleLookOf(
          const SquiggleSeekOptions(motion: SquiggleMotion.still),
          asFallback: true,
        ).motion,
        KSquiggleMotion.still,
      );
    });
  });

  group('flatLookOf', () {
    test('the defaults map to the default look of the plain bar', () {
      expect(flatLookOf(FlatSeekOptions.defaults), const KFlatLook());
    });

    test('every option value maps to the look value of its name', () {
      for (final t in FlatThickness.values) {
        expect(
          flatLookOf(FlatSeekOptions(thickness: t)).thickness.name,
          t.name,
        );
      }
      for (final t in SeekThumb.values) {
        expect(flatLookOf(FlatSeekOptions(thumb: t)).thumb.name, t.name);
      }
      for (final p in FlatPlayed.values) {
        expect(flatLookOf(FlatSeekOptions(played: p)).played.name, p.name);
      }
      for (final e in FlatEffect.values) {
        expect(flatLookOf(FlatSeekOptions(effect: e)).effect.name, e.name);
      }
    });
  });
}
