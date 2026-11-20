import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/history/history_days.dart';

/// The suite is also run with TZ=Europe/Berlin and TZ=America/Sao_Paulo; the
/// zone-specific cases skip themselves elsewhere.
bool get _isBerlin =>
    DateTime(2026, 1, 1).timeZoneOffset == const Duration(hours: 1) &&
    DateTime(2026, 7, 1).timeZoneOffset == const Duration(hours: 2);

bool get _isSaoPaulo =>
    DateTime(2018, 11, 4, 12).timeZoneOffset == const Duration(hours: -2);

void main() {
  group('day math in any zone', () {
    test('addDays walks one calendar day per step across a whole year', () {
      var day = DateTime(2026);
      for (var i = 0; i < 400; i++) {
        final next = addDays(day, 1);
        expect(daysBetween(day, next), 1);
        expect(next.isAfter(day), isTrue);
        day = next;
      }
    });

    test('yearWindow is half open and adjacent years share a bound', () {
      final a = yearWindow(2025);
      final b = yearWindow(2026);
      expect(a.end, b.start);
      expect(DateTime.fromMillisecondsSinceEpoch(b.start).year, 2026);
      expect(DateTime.fromMillisecondsSinceEpoch(b.end - 1).year, 2026);
    });

    test('localDay drops the time of day', () {
      expect(localDay(DateTime(2026, 5, 6, 23, 59, 59)), DateTime(2026, 5, 6));
    });
  });

  group('DST', () {
    test('Berlin: spring day is 23 h, autumn day 25 h, both one day', () {
      final spring = DateTime(2026, 3, 29);
      final autumn = DateTime(2026, 10, 25);
      expect(addDays(spring, 1).difference(spring), const Duration(hours: 23));
      expect(addDays(autumn, 1).difference(autumn), const Duration(hours: 25));
      expect(daysBetween(spring, addDays(spring, 1)), 1);
      expect(daysBetween(autumn, addDays(autumn, 1)), 1);
      expect(localDay(DateTime(2026, 10, 25, 23, 30)), autumn);
    }, skip: _isBerlin ? false : 'needs TZ=Europe/Berlin');

    test(
      'Sao Paulo: the day whose midnight does not exist starts at 01:00',
      () {
        final day = localDay(DateTime(2018, 11, 4, 12));
        expect(day, DateTime(2018, 11, 4, 1));
        expect(addDays(DateTime(2018, 11, 3), 1), day);
        expect(daysBetween(DateTime(2018, 11, 3), day), 1);
        expect(isSameDay(day, DateTime(2018, 11, 4, 23)), isTrue);
      },
      skip: _isSaoPaulo ? false : 'needs TZ=America/Sao_Paulo',
    );
  });

  group('addMonthsClamped', () {
    test('clamps to the last day of a shorter month', () {
      expect(
        addMonthsClamped(DateTime(2026, 8, 31), -6),
        DateTime(2026, 2, 28),
      );
      expect(addMonthsClamped(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
    });

    test('leap years keep 29 February', () {
      expect(addMonthsClamped(DateTime(2024, 1, 31), 1), DateTime(2024, 2, 29));
      expect(
        addMonthsClamped(DateTime(2025, 2, 28), 12),
        DateTime(2026, 2, 28),
      );
      expect(
        addMonthsClamped(DateTime(2024, 2, 29), 12),
        DateTime(2025, 2, 28),
      );
    });

    test('crosses year boundaries both ways', () {
      expect(
        addMonthsClamped(DateTime(2026, 1, 15), -1),
        DateTime(2025, 12, 15),
      );
      expect(
        addMonthsClamped(DateTime(2025, 12, 15), 1),
        DateTime(2026, 1, 15),
      );
      expect(
        addMonthsClamped(DateTime(2026, 3, 10), -15),
        DateTime(2024, 12, 10),
      );
    });
  });

  group('windows', () {
    test('leap year has 366 days between its bounds', () {
      final w = yearWindow(2024);
      final days = daysBetween(
        DateTime.fromMillisecondsSinceEpoch(w.start),
        DateTime.fromMillisecondsSinceEpoch(w.end),
      );
      expect(days, 366);
    });

    test('monthWindow of December ends at the next January', () {
      final w = monthWindow(DateTime(2025, 12, 20));
      expect(w.start, DateTime(2025, 12).millisecondsSinceEpoch);
      expect(w.end, DateTime(2026).millisecondsSinceEpoch);
      expect(monthStart(DateTime(2025, 12, 20)), DateTime(2025, 12));
    });
  });

  test('dayLabelKind: today, yesterday, weekday within 6 days, then date', () {
    final today = DateTime(2026, 11, 19);
    DayLabelKind kind(int back) => dayLabelKind(addDays(today, -back), today);
    expect(kind(0), DayLabelKind.today);
    expect(kind(1), DayLabelKind.yesterday);
    expect(kind(2), DayLabelKind.weekday);
    expect(kind(6), DayLabelKind.weekday);
    expect(kind(7), DayLabelKind.date);
    // A play dated tomorrow (clock was wrong) reads as today, not a date.
    expect(dayLabelKind(addDays(today, 1), today), DayLabelKind.today);
  });
}
