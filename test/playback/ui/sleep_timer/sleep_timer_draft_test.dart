import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/sleep_timer_state.dart';
import 'package:kanaru/src/playback/ui/sleep_timer/sleep_timer_draft.dart';

void main() {
  group('ranges', () {
    test('minutes and tracks limits, defaults, steps and presets', () {
      expect(sleepMinutesRange.min, 1);
      expect(sleepMinutesRange.max, 720);
      expect(sleepMinutesRange.rulerMax, 180);
      expect(sleepMinutesRange.step, 5);
      expect(sleepMinutesRange.defaultValue, 45);
      expect(sleepMinutesRange.presets, [15, 30, 45, 60, 90]);
      expect(sleepTracksRange.min, 1);
      expect(sleepTracksRange.max, 20);
      expect(sleepTracksRange.rulerMax, 20);
      expect(sleepTracksRange.step, 1);
      expect(sleepTracksRange.defaultValue, 3);
      expect(sleepTracksRange.presets, [1, 2, 3, 5, 10]);
    });

    test('a new draft starts at the defaults', () {
      const d = SleepTimerDraft();
      expect(d.kind, SleepTimerKind.minutes);
      expect(d.value, 45);
      expect(d.withKind(SleepTimerKind.tracks).value, 3);
    });
  });

  group('typed text', () {
    int? minutes(String raw) => parseTypedNumber(raw, sleepMinutesRange);
    int? tracks(String raw) => parseTypedNumber(raw, sleepTracksRange);

    test('clamps the whole number before anything is cut', () {
      expect(minutes('1000'), 720);
      expect(minutes('721'), 720);
      expect(tracks('100'), 20);
      expect(tracks('21'), 20);
      expect(minutes('99999999999999999999'), 720);
    });

    test('other scripts\' digits become ASCII, other characters go', () {
      expect(minutes('１２０'), 120);
      expect(minutes('٤٥'), 45);
      expect(minutes('45 phút'), 45);
      expect(minutes('-5'), 5);
      expect(minutes('1.5'), 15);
    });

    test('empty, zero and no digits are not a value', () {
      expect(minutes(''), isNull);
      expect(minutes('0'), isNull);
      expect(minutes('000'), isNull);
      expect(minutes('abc'), isNull);
      expect(minutes('007'), 7);
    });

    test('withTyped keeps the last valid value for a non-value', () {
      const d = SleepTimerDraft(minutes: 30);
      expect(d.withTyped('').value, 30);
      expect(d.withTyped('0').value, 30);
      expect(d.withTyped('90').value, 90);
      expect(d.withTyped('1000').value, 720);
      expect(
        const SleepTimerDraft(kind: SleepTimerKind.tracks)
            .withTyped('100')
            .value,
        20,
      );
    });

    test('typing in one kind leaves the other kind alone', () {
      const d = SleepTimerDraft(minutes: 30, tracks: 4);
      final t = d.withKind(SleepTimerKind.tracks).withTyped('7');
      expect(t.tracks, 7);
      expect(t.minutes, 30);
    });
  });

  group('steps', () {
    test('step from the current value, also off-step values', () {
      expect(const SleepTimerDraft(minutes: 24).stepped(1).value, 29);
      expect(const SleepTimerDraft(minutes: 24).stepped(-1).value, 19);
      expect(
        const SleepTimerDraft(kind: SleepTimerKind.tracks).stepped(1).value,
        4,
      );
    });

    test('stop at the bounds and report them', () {
      const low = SleepTimerDraft(minutes: 3);
      expect(low.stepped(-1).value, 1);
      expect(low.stepped(-1).canStepDown, isFalse);
      const high = SleepTimerDraft(minutes: 718);
      expect(high.stepped(1).value, 720);
      expect(high.stepped(1).canStepUp, isFalse);
      expect(low.canStepDown, isTrue);
      expect(high.canStepUp, isTrue);
      const tracks = SleepTimerDraft(kind: SleepTimerKind.tracks, tracks: 20);
      expect(tracks.canStepUp, isFalse);
    });
  });

  group('ruler and chips', () {
    test('a value past the ruler leaves it at the end, value unchanged', () {
      final d = const SleepTimerDraft().withTyped('240');
      expect(d.value, 240);
      expect(d.rulerValue, 180);
      expect(const SleepTimerDraft(minutes: 120).rulerValue, 120);
    });

    test('a chip matches only an equal value', () {
      expect(const SleepTimerDraft(minutes: 45).matchingPreset, 45);
      expect(const SleepTimerDraft(minutes: 46).matchingPreset, isNull);
      expect(const SleepTimerDraft(minutes: 90).matchingPreset, 90);
      const t = SleepTimerDraft(kind: SleepTimerKind.tracks, tracks: 5);
      expect(t.matchingPreset, 5);
      expect(t.withValue(4).matchingPreset, isNull);
    });

    test('withValue clamps', () {
      expect(const SleepTimerDraft().withValue(0).value, 1);
      expect(const SleepTimerDraft().withValue(9999).value, 720);
    });
  });

  group('fromState', () {
    test('minutes: left rounded up to whole minutes', () {
      final d = SleepTimerDraft.fromState(
        const SleepTimerState(
          mode: SleepTimerMode.minutes,
          remaining: Duration(minutes: 23, seconds: 41),
        ),
      );
      expect(d.kind, SleepTimerKind.minutes);
      expect(d.minutes, 24);
    });

    test('minutes: exact minutes stay, sub-minute rounds to one', () {
      expect(
        SleepTimerDraft.fromState(
          const SleepTimerState(
            mode: SleepTimerMode.minutes,
            remaining: Duration(minutes: 10),
          ),
        ).minutes,
        10,
      );
      expect(
        SleepTimerDraft.fromState(
          const SleepTimerState(
            mode: SleepTimerMode.minutes,
            remaining: Duration(seconds: 12),
          ),
        ).minutes,
        1,
      );
    });

    test('tracks: tracks left; end-of and off: defaults', () {
      final t = SleepTimerDraft.fromState(
        const SleepTimerState(mode: SleepTimerMode.tracks, tracksLeft: 2),
      );
      expect(t.kind, SleepTimerKind.tracks);
      expect(t.tracks, 2);
      expect(
        SleepTimerDraft.fromState(
          const SleepTimerState(mode: SleepTimerMode.endOfAlbum),
        ),
        const SleepTimerDraft(),
      );
      expect(
        SleepTimerDraft.fromState(const SleepTimerState.off()),
        const SleepTimerDraft(),
      );
    });
  });
}
