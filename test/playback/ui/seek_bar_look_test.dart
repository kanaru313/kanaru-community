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

    test('styles without a wave painter yet draw bars', () {
      expect(seekKindOf(SeekBarStyle.squiggle), KSeekKind.bars);
      expect(seekKindOf(SeekBarStyle.flat), KSeekKind.bars);
    });

    test('a style that draws the waveform maps to a kind of its own name', () {
      for (final style in waveSeekBarStyles) {
        expect(seekKindOf(style).name, style.name);
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
}
