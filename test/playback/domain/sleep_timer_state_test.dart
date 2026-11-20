import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/sleep_timer_state.dart';

void main() {
  SleepTimerState minutes(Duration left, {bool held = false}) =>
      SleepTimerState(
        mode: SleepTimerMode.minutes,
        remaining: left,
        countingPaused: held,
      );

  test('off carries nothing', () {
    const s = SleepTimerState.off();
    expect(s.active, isFalse);
    expect(s.mode, isNull);
    expect(s.remaining, Duration.zero);
    expect(s.endsAt, isNull);
    expect(s.tracksLeft, 0);
    expect(s.canSubtract(5), isFalse);
    expect(s.canRemoveTrack, isFalse);
    expect(s.canAddTrack, isFalse);
  });

  test('minusMinutes is 5 above 5 minutes, 1 at 5 or less', () {
    expect(minutes(const Duration(minutes: 6)).minusMinutes, 5);
    expect(minutes(const Duration(minutes: 5, seconds: 1)).minusMinutes, 5);
    expect(minutes(const Duration(minutes: 5)).minusMinutes, 1);
    expect(minutes(const Duration(minutes: 1)).canSubtract(1), isFalse);
    expect(minutes(const Duration(minutes: 2)).canSubtract(1), isTrue);
  });

  group('canSubtract', () {
    test('needs more than the amount left', () {
      expect(minutes(const Duration(minutes: 5)).canSubtract(5), isFalse);
      expect(
        minutes(const Duration(minutes: 5, seconds: 1)).canSubtract(5),
        isTrue,
      );
      expect(minutes(const Duration(minutes: 4)).canSubtract(5), isFalse);
    });

    test('is for the minutes mode only', () {
      const s = SleepTimerState(
        mode: SleepTimerMode.tracks,
        remaining: Duration(minutes: 30),
        tracksLeft: 3,
      );
      expect(s.canSubtract(5), isFalse);
    });

    test('works while the count is held', () {
      expect(
        minutes(const Duration(minutes: 9), held: true).canSubtract(5),
        isTrue,
      );
    });
  });

  group('tracks limits', () {
    SleepTimerState tracks(int n) =>
        SleepTimerState(mode: SleepTimerMode.tracks, tracksLeft: n);

    test('cannot go below one or above twenty', () {
      expect(tracks(1).canRemoveTrack, isFalse);
      expect(tracks(2).canRemoveTrack, isTrue);
      expect(tracks(19).canAddTrack, isTrue);
      expect(tracks(20).canAddTrack, isFalse);
    });

    test('other modes allow neither', () {
      const s = SleepTimerState(mode: SleepTimerMode.endOfTrack);
      expect(s.canRemoveTrack, isFalse);
      expect(s.canAddTrack, isFalse);
    });
  });

  test('equality covers every field', () {
    final at = DateTime(2026, 11, 19, 23);
    SleepTimerState make({
      SleepTimerMode mode = SleepTimerMode.minutes,
      Duration remaining = const Duration(minutes: 1),
      DateTime? endsAt,
      bool held = false,
      int tracks = 0,
    }) => SleepTimerState(
      mode: mode,
      remaining: remaining,
      endsAt: endsAt,
      countingPaused: held,
      tracksLeft: tracks,
    );
    final base = make(endsAt: at);
    expect(make(endsAt: at), base);
    expect(make(endsAt: at).hashCode, base.hashCode);
    expect(make(endsAt: at, mode: SleepTimerMode.endOfTrack), isNot(base));
    expect(
      make(endsAt: at, remaining: const Duration(seconds: 59)),
      isNot(base),
    );
    expect(make(endsAt: at.add(const Duration(seconds: 1))), isNot(base));
    expect(make(endsAt: at, held: true), isNot(base));
    expect(make(endsAt: at, tracks: 2), isNot(base));
    expect(const SleepTimerState.off(), const SleepTimerState.off());
  });

  test('ranges are the documented ones', () {
    expect(sleepTimerMinMinutes, 1);
    expect(sleepTimerMaxMinutes, 720);
    expect(sleepTimerMinTracks, 1);
    expect(sleepTimerMaxTracks, 20);
  });

  group('copyWith', () {
    final started = DateTime.utc(2026, 11, 20, 22);
    final s = SleepTimerState(
      mode: SleepTimerMode.minutes,
      remaining: const Duration(minutes: 30),
      endsAt: started.add(const Duration(minutes: 30)),
      setLength: const Duration(minutes: 45),
      tracksAtStart: 4,
      startedAt: started,
      startSerial: 3,
    );

    test('keeps what it is not given', () {
      final c = s.copyWith(remaining: const Duration(minutes: 29));
      expect(c.mode, SleepTimerMode.minutes);
      expect(c.endsAt, s.endsAt);
      expect(c.setLength, const Duration(minutes: 45));
      expect(c.tracksAtStart, 4);
      expect(c.startedAt, started);
      expect(c.startSerial, 3);
    });

    test('can clear the nullable times', () {
      final c = s.copyWith(endsAt: null, startedAt: null);
      expect(c.endsAt, isNull);
      expect(c.startedAt, isNull);
      expect(c.setLength, const Duration(minutes: 45));
    });

    test('equality covers the new fields', () {
      expect(s.copyWith(), s);
      expect(s.copyWith().hashCode, s.hashCode);
      expect(s.copyWith(setLength: const Duration(minutes: 50)), isNot(s));
      expect(s.copyWith(tracksAtStart: 5), isNot(s));
      expect(s.copyWith(startSerial: 4), isNot(s));
      expect(
        s.copyWith(startedAt: started.add(const Duration(seconds: 1))),
        isNot(s),
      );
    });
  });

  group('sleepEndOfFraction', () {
    final start = DateTime.utc(2026, 11, 20, 22);
    double f(int leftMin, int sinceMin) => sleepEndOfFraction(
      left: Duration(minutes: leftMin),
      startedAt: start,
      now: start.add(Duration(minutes: sinceMin)),
    );

    test('is the share still to go of what has run and what is left', () {
      expect(f(10, 0), 1);
      expect(f(5, 5), 0.5);
      expect(f(1, 9), closeTo(0.1, 1e-9));
    });

    test('a queue edit that grows the time left widens the bar', () {
      expect(f(20, 5), 0.8);
      expect(f(20, 5), lessThanOrEqualTo(1));
    });

    test('nothing left, or nothing to divide by, is zero', () {
      expect(f(0, 5), 0);
      expect(
        sleepEndOfFraction(left: Duration.zero, startedAt: start, now: start),
        0,
      );
    });

    test('a clock that went back counts as no time run', () {
      expect(f(5, -3), 1);
    });
  });
}
