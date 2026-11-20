import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/history/history_clear_scope.dart';
import 'package:kanaru/src/library/domain/history/history_days.dart';
import 'package:kanaru/src/library/domain/history/history_ranges.dart';

void main() {
  final now = DateTime(2026, 11, 19, 14, 30);
  final today = DateTime(2026, 11, 19);

  group('MostPlayedRange', () {
    test('Hôm nay, 7 and 30 days end at midnight after today', () {
      for (final (preset, n) in [
        (MostPlayedPreset.today, 1),
        (MostPlayedPreset.days7, 7),
        (MostPlayedPreset.days30, 30),
      ]) {
        final d = MostPlayedRange(preset: preset).days(now)!;
        expect(d.end, addDays(today, 1));
        expect(daysBetween(d.start, d.end), n);
      }
    });

    test('6 months and 1 year are clamped months plus one day', () {
      final six = const MostPlayedRange(preset: MostPlayedPreset.months6);
      expect(six.days(now)!.start, DateTime(2026, 5, 20));
      expect(six.days(now)!.end, DateTime(2026, 11, 20));
      final year = const MostPlayedRange(preset: MostPlayedPreset.year);
      expect(year.days(now)!.start, DateTime(2025, 11, 20));
    });

    test('previous periods follow with no gap or overlap', () {
      for (final preset in [
        MostPlayedPreset.days7,
        MostPlayedPreset.months6,
        MostPlayedPreset.year,
      ]) {
        final r = MostPlayedRange(preset: preset);
        expect(r.previous().days(now)!.end, r.days(now)!.start);
        expect(
          r.previous().previous().days(now)!.end,
          r.previous().days(now)!.start,
        );
      }
    });

    test('canNext only while the period ends before tomorrow', () {
      const r = MostPlayedRange();
      expect(r.canNext(now), isFalse);
      expect(r.previous().canNext(now), isTrue);
      expect(r.previous().next().canNext(now), isFalse);
      expect(r.previous().next().window(now), r.window(now));
    });

    test('all time has no window and no arrows', () {
      const r = MostPlayedRange(preset: MostPlayedPreset.all);
      expect(r.window(now), isNull);
      expect(r.canNext(now), isFalse);
      expect(r.canPrevious, isFalse);
    });

    test(
      'custom range shifts by its own length and survives preset change',
      () {
        final r = const MostPlayedRange().withCustom(
          DateTime(2026, 11, 10, 9),
          DateTime(2026, 11, 12, 18),
        );
        final d = r.days(now)!;
        expect(d.start, DateTime(2026, 11, 10));
        expect(d.end, DateTime(2026, 11, 13));
        expect(r.previous().days(now)!.start, DateTime(2026, 11, 7));
        expect(r.previous().days(now)!.end, DateTime(2026, 11, 10));
        expect(r.canNext(now), isTrue);
        final back = r
            .withPreset(MostPlayedPreset.days7)
            .withPreset(MostPlayedPreset.custom);
        expect(back.days(now), d);
      },
    );

    test('custom without days has no window', () {
      expect(
        const MostPlayedRange(preset: MostPlayedPreset.custom).window(now),
        isNull,
      );
    });

    test('window covers every play check', () {
      expect(
        windowCoversPlays((start: 0, end: 100), (first: 5, last: 99)),
        isTrue,
      );
      expect(
        windowCoversPlays((start: 6, end: 100), (first: 5, last: 99)),
        isFalse,
      );
      expect(
        windowCoversPlays((start: 0, end: 99), (first: 5, last: 99)),
        isFalse,
      );
    });

    test('limits clamp to 1-1000', () {
      expect(clampMostPlayedLimit(0), 1);
      expect(clampMostPlayedLimit(5000), 1000);
      expect(clampMostPlayedLimit(250), 250);
    });
  });

  group('ClearScope', () {
    test('every bounded scope ends one millisecond after the fixed now', () {
      final end = now.millisecondsSinceEpoch + 1;
      for (final s in [ClearScope.hour, ClearScope.today, ClearScope.week]) {
        expect(s.bounds(now).to, end);
      }
    });

    test('hour is the last 60 minutes, today from midnight, week 7 days', () {
      expect(
        ClearScope.hour.bounds(now).from,
        DateTime(2026, 11, 19, 13, 30).millisecondsSinceEpoch,
      );
      expect(ClearScope.today.bounds(now).from, today.millisecondsSinceEpoch);
      expect(
        ClearScope.week.bounds(now).from,
        DateTime(2026, 11, 13).millisecondsSinceEpoch,
      );
    });

    test('all has no bounds', () {
      expect(ClearScope.all.bounds(now), (from: null, to: null));
    });
  });
}
