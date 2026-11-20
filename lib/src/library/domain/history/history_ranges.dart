import 'history_days.dart';

/// The ranges the Most played page offers.
enum MostPlayedPreset { today, days7, days30, months6, year, all, custom }

/// How many songs the list shows: the presets, then any 1-1000 the user types.
const mostPlayedLimitPresets = [5, 10, 50, 100];
const defaultMostPlayedLimit = 100;
const minMostPlayedLimit = 1;
const maxMostPlayedLimit = 1000;

/// The range of the Most played page: a [preset], and how many periods back
/// from it ([back], 0 is the current one) the user stepped.
///
/// Every range is whole local calendar days ending at midnight after today
/// (or, for a custom range, after the day the user picked). 6 months and
/// 1 year are rolling windows of calendar days, not calendar years; a calendar
/// year is a custom range. Periods follow one another with no gap or overlap:
/// the start of period `k` is the end of period `k + 1`.
class MostPlayedRange {
  const MostPlayedRange({
    this.preset = MostPlayedPreset.days30,
    this.back = 0,
    this.customStart,
    this.customEndInclusive,
  });

  final MostPlayedPreset preset;

  /// Periods before the current one. Negative only for a custom range moved
  /// past its own end.
  final int back;

  /// First and last day of the custom range (local midnights); set with
  /// [MostPlayedPreset.custom].
  final DateTime? customStart;
  final DateTime? customEndInclusive;

  /// The first day and the day after the last one; null for all time.
  ({DateTime start, DateTime end})? days(DateTime now) {
    final today = localDay(now);
    switch (preset) {
      case MostPlayedPreset.all:
        return null;
      case MostPlayedPreset.today:
        return _byDays(today, 1);
      case MostPlayedPreset.days7:
        return _byDays(today, 7);
      case MostPlayedPreset.days30:
        return _byDays(today, 30);
      case MostPlayedPreset.months6:
        return _byMonths(today, 6);
      case MostPlayedPreset.year:
        return _byMonths(today, 12);
      case MostPlayedPreset.custom:
        final a = customStart;
        final b = customEndInclusive;
        if (a == null || b == null) return null;
        final end = addDays(b, 1);
        final length = daysBetween(a, end);
        return (
          start: addDays(a, -back * length),
          end: addDays(end, -back * length),
        );
    }
  }

  ({DateTime start, DateTime end}) _byDays(DateTime today, int n) {
    final end = addDays(today, 1 - back * n);
    return (start: addDays(end, -n), end: end);
  }

  ({DateTime start, DateTime end}) _byMonths(DateTime today, int m) => (
    start: addDays(addMonthsClamped(today, -(back + 1) * m), 1),
    end: addDays(addMonthsClamped(today, -back * m), 1),
  );

  /// The window in epoch ms, `[start, end)`; null for all time.
  ({int start, int end})? window(DateTime now) {
    final d = days(now);
    return d == null
        ? null
        : (
            start: d.start.millisecondsSinceEpoch,
            end: d.end.millisecondsSinceEpoch,
          );
  }

  /// Whether a later period exists: this one ends before tomorrow.
  bool canNext(DateTime now) {
    final d = days(now);
    return d != null && d.end.isBefore(addDays(localDay(now), 1));
  }

  /// "All time" has no arrows.
  bool get canPrevious => preset != MostPlayedPreset.all;

  MostPlayedRange previous() => _moved(back + 1);

  MostPlayedRange next() => _moved(back - 1);

  MostPlayedRange _moved(int back) => MostPlayedRange(
    preset: preset,
    back: back,
    customStart: customStart,
    customEndInclusive: customEndInclusive,
  );

  /// [preset] at its current period; a custom range stays remembered.
  MostPlayedRange withPreset(MostPlayedPreset preset) => MostPlayedRange(
    preset: preset,
    customStart: customStart,
    customEndInclusive: customEndInclusive,
  );

  /// The custom range from day [start] to day [endInclusive].
  MostPlayedRange withCustom(DateTime start, DateTime endInclusive) =>
      MostPlayedRange(
        preset: MostPlayedPreset.custom,
        customStart: localDay(start),
        customEndInclusive: localDay(endInclusive),
      );
}

/// Whether [window] takes in every play in [played], so the all-time list
/// (cheaper to read, the same answer) can stand in for it.
bool windowCoversPlays(
  ({int start, int end}) window,
  ({int first, int last}) played,
) => window.start <= played.first && window.end > played.last;

/// [limit] cut to the 1-1000 the list accepts.
int clampMostPlayedLimit(int limit) =>
    limit.clamp(minMostPlayedLimit, maxMostPlayedLimit);
