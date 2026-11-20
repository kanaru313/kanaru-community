import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/history/history_span.dart';

void main() {
  group('historySpanText', () {
    test('a range inside one year writes the year once', () {
      expect(
        historySpanText(DateTime(2026, 10, 7), DateTime(2026, 10, 24)),
        '07/10 – 24/10/2026',
      );
    });

    test('a range across two years writes both', () {
      expect(
        historySpanText(DateTime(2025, 12, 28), DateTime(2026, 1, 3)),
        '28/12/2025 – 03/01/2026',
      );
    });

    test('one day is a single date', () {
      expect(
        historySpanText(DateTime(2026, 11, 9), DateTime(2026, 11, 9)),
        '09/11/2026',
      );
    });
  });

  group('rangeDays', () {
    test('counts both ends', () {
      expect(rangeDays(DateTime(2026, 10, 7), DateTime(2026, 10, 24)), 18);
      expect(rangeDays(DateTime(2026, 11, 9), DateTime(2026, 11, 9)), 1);
    });

    test('is right across a month and a year', () {
      expect(rangeDays(DateTime(2025, 12, 28), DateTime(2026, 1, 3)), 7);
    });
  });
}
