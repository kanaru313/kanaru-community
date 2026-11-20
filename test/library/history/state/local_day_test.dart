import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/state/history/local_day_provider.dart';

void main() {
  testWidgets('ticks at local midnight with an injectable clock', (t) async {
    var now = DateTime(2026, 11, 20, 23, 59, 59, 500);
    final c = ProviderContainer(
      overrides: [historyClockProvider.overrideWithValue(() => now)],
    );
    final seen = <DateTime>[];
    c.listen(localDayProvider, (_, next) => seen.add(next));

    expect(c.read(localDayProvider), DateTime(2026, 11, 20));
    await t.pump(const Duration(milliseconds: 500));
    expect(seen, isEmpty, reason: 'same day, nothing emitted');

    now = DateTime(2026, 11, 21, 0, 0, 0, 100);
    await t.pump(const Duration(seconds: 2));
    expect(seen, [DateTime(2026, 11, 21)]);

    now = DateTime(2026, 11, 22, 0, 0, 1);
    await t.pump(const Duration(hours: 25));
    expect(seen.last, DateTime(2026, 11, 22));
    c.dispose();
  });

  testWidgets('disposing the container cancels the timer', (t) async {
    final c = ProviderContainer(
      overrides: [historyClockProvider.overrideWithValue(DateTime.now)],
    );
    c.read(localDayProvider);
    c.dispose();
    // A pending timer would fail the test at the end.
    await t.pump(const Duration(hours: 1));
  });
}
