import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/sleep_timer_state.dart';
import 'package:kanaru/src/playback/state/sleep_timer_provider.dart';

import '../support/sleep_timer_harness.dart';

/// What the timer remembers about how a run was set, through everything a
/// run goes through.
void main() {
  late SleepHarness s;
  setUp(() async {
    s = await SleepHarness.create();
  });
  tearDown(() => s.close());

  const sec = Duration(seconds: 1);
  const min = Duration(minutes: 1);

  DateTime wallNow() => DateTime.fromMillisecondsSinceEpoch(s.h.now);

  group('minutes', () {
    test('a start records its length, its time and a serial', () {
      final before = wallNow();
      s.timer.startMinutes(45);
      expect(s.state.setLength, const Duration(minutes: 45));
      expect(s.state.startedAt, before);
      expect(s.state.startSerial, 1);
      expect(s.state.tracksAtStart, 0);
    });

    test('every tick keeps them', () async {
      final before = wallNow();
      s.timer.startMinutes(45);
      for (var i = 0; i < 10; i++) {
        await s.pass(sec);
      }
      expect(s.state.remaining, const Duration(minutes: 44, seconds: 50));
      expect(s.state.setLength, const Duration(minutes: 45));
      expect(s.state.startedAt, before);
      expect(s.state.startSerial, 1);
    });

    test('hold and resume keep them', () async {
      final before = wallNow();
      s.timer.startMinutes(45);
      await s.pass(min);
      s.timer.pauseCounting();
      expect(s.state.countingPaused, isTrue);
      expect(s.state.setLength, const Duration(minutes: 45));
      expect(s.state.startedAt, before);
      expect(s.state.startSerial, 1);
      await s.pass(min);
      s.timer.resumeCounting();
      await s.pass(sec);
      expect(s.state.countingPaused, isFalse);
      expect(s.state.setLength, const Duration(minutes: 45));
      expect(s.state.startedAt, before);
      expect(s.state.startSerial, 1);
    });

    test('adding above the set length raises it; below it does not', () async {
      s.timer.startMinutes(45);
      await s.pass(const Duration(minutes: 10));
      s.timer.addMinutes(5);
      expect(s.state.remaining, const Duration(minutes: 40));
      expect(s.state.setLength, const Duration(minutes: 45));
      s.timer.addMinutes(5);
      s.timer.addMinutes(5);
      expect(s.state.remaining, const Duration(minutes: 50));
      expect(s.state.setLength, const Duration(minutes: 50));
      s.timer.addMinutes(-5);
      expect(s.state.setLength, const Duration(minutes: 50));
      expect(s.state.startSerial, 1);
    });

    test('adding while held raises it too and stays held', () async {
      s.timer.startMinutes(45);
      await s.pass(min);
      s.timer.pauseCounting();
      s.timer.addMinutes(5);
      s.timer.addMinutes(5);
      expect(s.state.countingPaused, isTrue);
      expect(s.state.remaining, const Duration(minutes: 54));
      expect(s.state.setLength, const Duration(minutes: 54));
      expect(s.state.startSerial, 1);
    });

    test('the time left is never above the set length', () async {
      s.timer.startMinutes(30);
      for (final d in [min, min, const Duration(minutes: 4)]) {
        await s.pass(d);
        s.timer.addMinutes(5);
        expect(s.state.remaining <= s.state.setLength, isTrue);
      }
    });
  });

  group('tracks', () {
    test('a start records the count; a natural end keeps it', () async {
      await s.play();
      final before = wallNow();
      s.timer.startTracks(5);
      await s.h.settle();
      await s.advance();
      expect(s.state.tracksLeft, 4);
      expect(s.state.tracksAtStart, 5);
      expect(s.state.startedAt, before);
      expect(s.state.startSerial, 1);
      expect(s.state.setLength, Duration.zero);
    });

    test('adding above the start raises it; below it does not', () async {
      await s.play();
      s.timer.startTracks(5);
      await s.h.settle();
      await s.advance();
      s.timer.addTracks(1);
      expect(s.state.tracksLeft, 5);
      expect(s.state.tracksAtStart, 5);
      s.timer.addTracks(1);
      expect(s.state.tracksLeft, 6);
      expect(s.state.tracksAtStart, 6);
      s.timer.addTracks(-2);
      expect(s.state.tracksAtStart, 6);
      expect(s.state.startSerial, 1);
    });
  });

  group('end-of modes', () {
    test('a start records its time and a serial', () {
      final before = wallNow();
      s.timer.startEndOfAlbum();
      expect(s.state.startedAt, before);
      expect(s.state.startSerial, 1);
      expect(s.state.setLength, Duration.zero);
      expect(s.state.tracksAtStart, 0);
    });

    test(
      'the bar after five minutes with nothing mounted is below full',
      () async {
        await s.play();
        s.timer.startEndOfTrack();
        await s.pass(const Duration(minutes: 5));
        final fraction = sleepEndOfFraction(
          left: const Duration(minutes: 10),
          startedAt: s.state.startedAt!,
          now: wallNow(),
        );
        expect(fraction, closeTo(10 / 15, 1e-9));
      },
    );
  });

  group('serial and reset', () {
    test('a start while running gives a new serial, a cancel resets', () {
      s.timer.startMinutes(10);
      s.timer.startMinutes(20);
      expect(s.state.startSerial, 2);
      expect(s.state.setLength, const Duration(minutes: 20));
      s.timer.cancel();
      expect(s.state, const SleepTimerState.off());
      s.timer.startTracks(3);
      expect(s.state.startSerial, 3);
    });

    test('a start of another mode drops the fields of the old one', () async {
      await s.play();
      s.timer.startTracks(5);
      s.timer.startMinutes(10);
      expect(s.state.tracksAtStart, 0);
      expect(s.state.tracksLeft, 0);
      expect(s.state.setLength, min * 10);
      s.timer.startTracks(2);
      expect(s.state.setLength, Duration.zero);
      expect(s.state.tracksAtStart, 2);
    });

    test('a start publishes in one step', () {
      s.states.clear();
      s.timer.startMinutes(10);
      expect(s.states, hasLength(1));
      expect(s.states.single.endsAt, isNotNull);
    });
  });
}
