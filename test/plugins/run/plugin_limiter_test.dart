import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/data/run/plugin_limiter.dart';
import 'package:kanaru/src/plugins/domain/net/cancel_token.dart';

void main() {
  const spacing = Duration(milliseconds: 80);
  const plenty = Duration(seconds: 30);

  PluginLimiter limiter({Duration minTimeLeft = const Duration(seconds: 1)}) =>
      PluginLimiter(spacing: spacing, minTimeLeft: minTimeLeft);

  test(
    'the first request starts at once, the next waits the spacing',
    () async {
      final l = limiter();
      final clock = Stopwatch()..start();
      expect(await l.acquire('a', timeLeft: plenty), LimiterResult.granted);
      final first = clock.elapsed;
      expect(await l.acquire('a', timeLeft: plenty), LimiterResult.granted);
      expect(first, lessThan(spacing));
      // Timer granularity may fire a few ms early on a loaded machine.
      expect(clock.elapsed, greaterThanOrEqualTo(spacing * 0.9));
    },
  );

  test(
    'waiters of one plugin are served in order, one spacing apart',
    () async {
      final l = limiter();
      final order = <int>[];
      final starts = <Duration>[];
      final clock = Stopwatch()..start();
      final calls = [
        for (var i = 0; i < 4; i++)
          l.acquire('a', timeLeft: plenty).then((_) {
            order.add(i);
            starts.add(clock.elapsed);
          }),
      ];
      await Future.wait(calls);
      expect(order, [0, 1, 2, 3]);
      for (var i = 1; i < starts.length; i++) {
        expect(
          starts[i] - starts[i - 1],
          greaterThanOrEqualTo(spacing * 0.8),
          reason: 'gap $i',
        );
      }
    },
  );

  test('plugins do not wait for each other', () async {
    final l = limiter();
    await l.acquire('a', timeLeft: plenty);
    final clock = Stopwatch()..start();
    expect(await l.acquire('b', timeLeft: plenty), LimiterResult.granted);
    expect(clock.elapsed, lessThan(spacing));
  });

  test(
    'a wait that leaves under the minimum is refused, nothing reserved',
    () async {
      final l = limiter();
      await l.acquire('a', timeLeft: plenty);
      expect(
        await l.acquire(
          'a',
          timeLeft: spacing + const Duration(milliseconds: 500),
        ),
        LimiterResult.tooLate,
      );
      // The refused call took no slot: the next one waits one spacing only.
      final clock = Stopwatch()..start();
      expect(await l.acquire('a', timeLeft: plenty), LimiterResult.granted);
      expect(clock.elapsed, lessThan(spacing * 1.9));
    },
  );

  test(
    'a request that need not wait is granted whatever time is left',
    () async {
      final l = limiter();
      expect(
        await l.acquire('a', timeLeft: const Duration(milliseconds: 300)),
        LimiterResult.granted,
      );
    },
  );

  test('a cancel ends the wait and gives the slot back', () async {
    final l = limiter();
    await l.acquire('a', timeLeft: plenty);
    final cancel = CancelToken();
    final waiting = l.acquire('a', timeLeft: plenty, cancel: cancel);
    cancel.cancel();
    expect(await waiting, LimiterResult.cancelled);
    expect(cancel.listenerCount, 0);
    final clock = Stopwatch()..start();
    expect(await l.acquire('a', timeLeft: plenty), LimiterResult.granted);
    expect(clock.elapsed, lessThan(spacing * 1.9));
  });

  test('a token cancelled before the call is cancelled at once', () async {
    final l = limiter();
    final cancel = CancelToken()..cancel();
    expect(
      await l.acquire('a', timeLeft: plenty, cancel: cancel),
      LimiterResult.cancelled,
    );
  });

  test('a granted wait leaves no listener on the token', () async {
    final l = limiter();
    final cancel = CancelToken();
    await l.acquire('a', timeLeft: plenty, cancel: cancel);
    await l.acquire('a', timeLeft: plenty, cancel: cancel);
    expect(cancel.listenerCount, 0);
  });
}
