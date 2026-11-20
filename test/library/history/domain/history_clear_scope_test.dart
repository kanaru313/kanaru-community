import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/history/history_clear_scope.dart';
import 'package:kanaru/src/library/domain/history/history_days.dart';

/// The zone-specific case skips itself unless the suite runs with
/// TZ=Europe/Berlin.
bool get _isBerlin =>
    DateTime(2026, 1, 1).timeZoneOffset == const Duration(hours: 1) &&
    DateTime(2026, 7, 1).timeZoneOffset == const Duration(hours: 2);

void main() {
  final now = DateTime(2026, 5, 6, 15, 30, 12, 345);
  final nowMs = now.millisecondsSinceEpoch;

  test('hour covers the last 60 minutes, end is now + 1 ms', () {
    final b = ClearScope.hour.bounds(now);
    expect(b.to, nowMs + 1);
    expect(b.from, nowMs - const Duration(hours: 1).inMilliseconds);
  });

  test('today starts at local midnight', () {
    final b = ClearScope.today.bounds(now);
    expect(b.from, DateTime(2026, 5, 6).millisecondsSinceEpoch);
    expect(b.to, nowMs + 1);
  });

  test('today at exactly midnight still starts at that midnight', () {
    final midnight = DateTime(2026, 5, 6);
    final b = ClearScope.today.bounds(midnight);
    expect(b.from, midnight.millisecondsSinceEpoch);
    expect(b.to, midnight.millisecondsSinceEpoch + 1);
  });

  test('week is 7 calendar days including today', () {
    final b = ClearScope.week.bounds(now);
    expect(b.from, DateTime(2026, 4, 30).millisecondsSinceEpoch);
    expect(daysBetween(DateTime.fromMillisecondsSinceEpoch(b.from!), now), 6);
    expect(b.to, nowMs + 1);
  });

  test('week crosses a month and year boundary', () {
    final b = ClearScope.week.bounds(DateTime(2026, 1, 3, 10));
    expect(b.from, DateTime(2025, 12, 28).millisecondsSinceEpoch);
  });

  test('all has no lower bound but the same upper bound as the others', () {
    final b = ClearScope.all.bounds(now);
    expect(b.from, isNull);
    expect(b.to, now.millisecondsSinceEpoch + 1);
    expect(b.to, ClearScope.today.bounds(now).to);
  });

  test(
    'Berlin: week across the spring DST change starts at local midnight',
    () {
      final b = ClearScope.week.bounds(DateTime(2026, 4, 2, 9));
      expect(b.from, DateTime(2026, 3, 27).millisecondsSinceEpoch);
      final start = DateTime.fromMillisecondsSinceEpoch(b.from!);
      expect(start.hour, 0);
    },
    skip: _isBerlin ? false : 'needs TZ=Europe/Berlin',
  );
}
