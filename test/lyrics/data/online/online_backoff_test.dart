import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/data/online/online_backoff.dart';

void main() {
  var now = DateTime.utc(2026, 11, 23, 12);
  var random = 0.0;
  late OnlineBackoff backoff;
  setUp(() {
    now = DateTime.utc(2026, 11, 23, 12);
    random = 0.0;
    backoff = OnlineBackoff(now: () => now, random: () => random);
  });

  Duration waitOf(String id) => backoff.of(id)!.until.difference(now);

  test('at least 60 s, up to 30 % more by the jitter', () {
    backoff.failed('a', network: true);
    expect(waitOf('a'), const Duration(seconds: 60));
    random = 1;
    backoff.failed('b', network: true);
    expect(waitOf('b'), const Duration(seconds: 78));
  });

  test('a longer Retry-After wins, clamped to 1 s .. 15 min', () {
    backoff.failed('a', network: true, retryAfter: const Duration(minutes: 5));
    expect(waitOf('a'), const Duration(minutes: 5));
    backoff.failed('b', network: true, retryAfter: const Duration(hours: 3));
    expect(waitOf('b'), const Duration(minutes: 15));
    backoff.failed('c', network: true, retryAfter: Duration.zero);
    expect(waitOf('c'), const Duration(seconds: 60));
  });

  test('a pause never gets shorter', () {
    backoff.failed('a', network: true, retryAfter: const Duration(minutes: 5));
    backoff.failed('a', network: true);
    expect(waitOf('a'), const Duration(minutes: 5));
  });

  test('a source pauses alone and the pause ends with time', () {
    backoff.failed('a', network: false);
    expect(backoff.of('b'), isNull);
    expect(backoff.of('a')!.network, isFalse);
    now = now.add(const Duration(seconds: 61));
    expect(backoff.of('a'), isNull);
    expect(backoff.snapshot(), isEmpty);
  });

  test('clear lifts every pause', () {
    backoff.failed('a', network: true);
    backoff.failed('b', network: true);
    expect(backoff.snapshot().keys, {'a', 'b'});
    backoff.clear();
    expect(backoff.snapshot(), isEmpty);
  });
}
