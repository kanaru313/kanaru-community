import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/domain/listen_accumulator.dart';
import 'package:kanaru/src/playback/domain/playback_settings.dart';

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
      expect(
        listenRequiredFor(const Duration(milliseconds: 1500)),
        const Duration(milliseconds: 500),
      );
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

  group('rule', () {
    const std = ListenRule.standard;
    ListenRule rule(int afterMs, int percent) =>
        ListenRule(afterMs: afterMs, percent: percent);

    // (length, rule, expected required seconds)
    final table = <(Duration?, ListenRule, double)>[
      (null, std, 240),
      (null, rule(30000, 50), 30),
      (null, rule(0, 50), 240),
      (secs(10), std, 5),
      (secs(10), rule(0, 100), 9),
      (secs(30), std, 15),
      (secs(31), std, 15.5),
      (secs(31), rule(10000, 50), 10),
      (secs(31), rule(0, 100), 30),
      (secs(180), std, 90),
      (secs(180), rule(60000, 50), 60),
      (secs(180), rule(0, 10), 18),
      (secs(1200), std, 240),
      (secs(1200), rule(0, 50), 600),
      (secs(1200), rule(600000, 100), 600),
      (secs(1200), rule(0, 100), 1199),
      (secs(1200), rule(10000, 100), 10),
    ];
    for (final (length, r, seconds) in table) {
      test('length $length, ${r.afterMs} ms / ${r.percent} %', () {
        expect(
          listenRequiredFor(length, r),
          Duration(microseconds: (seconds * 1e6).round()),
        );
      });
    }

    test('the default rule is the standard one', () {
      expect(listenRequiredFor(secs(100)), listenRequiredFor(secs(100), std));
      expect(ListenAccumulator().qualifiesUnder(std), isFalse);
    });

    test('a track of 30 s or less never counts, whatever the rule', () {
      expect(qualifiesAsListen(secs(29), secs(30), rule(10000, 10)), isFalse);
      expect(qualifiesAsListen(secs(10), secs(31), rule(10000, 10)), isTrue);
    });

    test('snapped keeps the grid: percent 10..100 by 5, time to a stop', () {
      expect(ListenRule.snapped(240000, 50), std);
      expect(ListenRule.snapped(0, 3).percent, 10);
      expect(ListenRule.snapped(0, 250).percent, 100);
      expect(ListenRule.snapped(0, 52).percent, 50);
      expect(ListenRule.snapped(0, 53).percent, 55);
      expect(ListenRule.snapped(-5, 50).afterMs, 0);
      expect(ListenRule.snapped(47000, 50).afterMs, 45000);
      expect(ListenRule.snapped(99999999, 50).afterMs, 600000);
    });

    test('a rule change applies to the next check of the same listen', () {
      final a = ListenAccumulator()..lockLength(secs(100));
      play(a, from: 0, steps: 20);
      expect(a.qualifiesUnder(std), isFalse);
      expect(a.qualifiesUnder(rule(0, 20)), isTrue);
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
      a.sample(
        position: secs(3),
        clock: const Duration(milliseconds: 2500),
        playing: true,
        wallMs: 1,
      );
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

  // The settings that carry the rules.
  group('listenRuleSetting', () {
    test('round trips', () {
      const rule = ListenRule(afterMs: 90000, percent: 75);
      expect(listenRuleSetting.decode(listenRuleSetting.encode(rule)), rule);
    });

    test('snaps what is off the grid', () {
      final rule = listenRuleSetting.decode({'afterMs': 47000, 'percent': 3});
      expect(rule, const ListenRule(afterMs: 45000, percent: 10));
    });

    test('accepts whole doubles', () {
      final rule = listenRuleSetting.decode({
        'afterMs': 60000.0,
        'percent': 80.0,
      });
      expect(rule, const ListenRule(afterMs: 60000, percent: 80));
    });

    final bad = <String, Object?>{
      'not a map': 'x',
      'list': [1, 2],
      'null': null,
      'missing afterMs': {'percent': 50},
      'missing percent': {'afterMs': 1000},
      'string number': {'afterMs': '1000', 'percent': 50},
      'NaN': {'afterMs': double.nan, 'percent': 50},
      'infinity': {'afterMs': 1000, 'percent': double.infinity},
      'fraction': {'afterMs': 1000, 'percent': 50.5},
    };
    bad.forEach((name, json) {
      test('throws on $name', () {
        expect(
          () => listenRuleSetting.decode(json),
          throwsA(isA<FormatException>()),
        );
      });
    });
  });

  test('previous button: unknown name throws, default is today\'s', () {
    expect(
      () => previousButtonSetting.decode('nope'),
      throwsA(isA<FormatException>()),
    );
    expect(
      previousButtonSetting.defaultValue,
      PreviousButtonPolicy.alwaysPrevious,
    );
    expect(
      previousButtonSetting.decode('restartAfter3s'),
      PreviousButtonPolicy.restartAfter3s,
    );
  });

  test('history: bool only, on by default', () {
    expect(historyEnabledSetting.defaultValue, isTrue);
    expect(() => historyEnabledSetting.decode(1), throwsFormatException);
    expect(historyEnabledSetting.decode(false), isFalse);
  });
}
