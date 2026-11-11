import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/listen_accumulator.dart';

const _s = Duration(seconds: 1);

Duration secs(int n) => Duration(seconds: n);

/// Feeds [steps] playing samples one second apart, position following the
/// clock.
void play(ListenAccumulator a, {required int from, required int steps}) {
  for (var i = 0; i <= steps; i++) {
    a.sample(
      position: secs(from + i),
      clock: secs(from + i),
      playing: true,
      wallMs: 5000 + i,
    );
  }
}

void main() {
  group('threshold', () {
    test('half of the track, at most four minutes', () {
      expect(listenRequiredFor(secs(100)), secs(50));
      expect(listenRequiredFor(secs(600)), const Duration(minutes: 4));
      expect(listenRequiredFor(null), const Duration(minutes: 4));
    });

    test('never more than the length minus one second', () {
      expect(listenRequiredFor(const Duration(milliseconds: 1500)),
          const Duration(milliseconds: 500));
    });

    test('a track of 30 s or less never counts', () {
      expect(qualifiesAsListen(secs(30), secs(30)), isFalse);
      expect(qualifiesAsListen(secs(31), secs(31)), isTrue);
    });

    test('exactly the required time counts', () {
      expect(qualifiesAsListen(secs(49), secs(100)), isFalse);
      expect(qualifiesAsListen(secs(50), secs(100)), isTrue);
    });
  });

  group('accumulation', () {
    test('counts playing time between samples', () {
      final a = ListenAccumulator()..lockLength(secs(100));
      play(a, from: 0, steps: 10);
      expect(a.listened, secs(10));
      expect(a.qualifies, isFalse);
      play(a, from: 10, steps: 40);
      expect(a.listened, secs(50));
      expect(a.qualifies, isTrue);
    });

    test('a pause adds nothing and resuming continues', () {
      final a = ListenAccumulator();
      play(a, from: 0, steps: 5);
      a.sample(position: secs(5), clock: secs(5), playing: false, wallMs: 1);
      a.sample(position: secs(5), clock: secs(30), playing: false, wallMs: 1);
      // First playing sample after a pause only re-baselines.
      a.sample(position: secs(5), clock: secs(31), playing: true, wallMs: 1);
      a.sample(position: secs(8), clock: secs(34), playing: true, wallMs: 1);
      expect(a.listened, secs(8));
    });

    test('a seek forward counts only the clock time', () {
      final a = ListenAccumulator();
      play(a, from: 0, steps: 5);
      a.sample(position: secs(100), clock: secs(6), playing: true, wallMs: 1);
      expect(a.listened, secs(6));
    });

    test('a burst of late ticks counts the whole position move', () {
      final a = ListenAccumulator();
      a.sample(position: secs(0), clock: secs(0), playing: true, wallMs: 1);
      // The UI stalled 3 s; the engine position kept moving.
      a.sample(position: secs(3), clock: const Duration(milliseconds: 2500),
          playing: true, wallMs: 1);
      expect(a.listened, secs(3));
    });

    test('a move backward adds nothing', () {
      final a = ListenAccumulator();
      play(a, from: 10, steps: 2);
      a.sample(position: secs(0), clock: secs(13), playing: true, wallMs: 1);
      a.sample(position: secs(2), clock: secs(15), playing: true, wallMs: 1);
      expect(a.listened, secs(4));
    });
  });

  group('length lock and played_at', () {
    test('the first length wins (gapless reports the next track)', () {
      final a = ListenAccumulator()
        ..lockLength(secs(100))
        ..lockLength(secs(20));
      expect(a.length, secs(100));
    });

    test('a zero or null length does not lock', () {
      final a = ListenAccumulator()
        ..lockLength(Duration.zero)
        ..lockLength(null);
      expect(a.length, isNull);
      a.lockLength(secs(40));
      expect(a.length, secs(40));
    });

    test('played_at is the first playing sample', () {
      final a = ListenAccumulator();
      a.sample(position: secs(0), clock: secs(0), playing: false, wallMs: 100);
      expect(a.playedAt, isNull);
      a.sample(position: secs(0), clock: secs(1), playing: true, wallMs: 200);
      a.sample(position: secs(1), clock: secs(2), playing: true, wallMs: 300);
      expect(a.playedAt, 200);
      expect(_s, secs(1));
    });
  });
}
