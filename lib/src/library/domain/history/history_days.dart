import 'dart:math' as math;

// Local calendar days as the history pages need them. Every step goes through
// the `DateTime(y, m, d)` constructor, never `Duration(days: n)`: a day is 23
// or 25 hours long where the clock changes, and a midnight that does not
// exist moves to the first valid time of that day.

/// Midnight (the first valid time) of the local day [time] falls on.
DateTime localDay(DateTime time) => DateTime(time.year, time.month, time.day);

/// The local day [n] days after [day] (before it when [n] is negative).
DateTime addDays(DateTime day, int n) =>
    DateTime(day.year, day.month, day.day + n);

/// First day of the month [time] falls in.
DateTime monthStart(DateTime time) => DateTime(time.year, time.month);

/// The day [months] calendar months from [day] (before it when negative),
/// with the day of the month clamped to the target month's last day: 31 Aug
/// minus 6 months is the last day of February.
DateTime addMonthsClamped(DateTime day, int months) {
  final total = day.year * 12 + (day.month - 1) + months;
  final year = total ~/ 12;
  final month = total % 12 + 1;
  final last = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, math.min(day.day, last));
}

/// Calendar days from [a] to [b] (negative when [b] is earlier), counted on
/// dates so a 23 or 25 hour day is still one.
int daysBetween(DateTime a, DateTime b) => DateTime.utc(
  b.year,
  b.month,
  b.day,
).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

/// Whether [a] and [b] fall on the same local calendar day.
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Local calendar year [year] as the epoch-ms window `[start, end)`.
({int start, int end}) yearWindow(int year) => (
  start: DateTime(year).millisecondsSinceEpoch,
  end: DateTime(year + 1).millisecondsSinceEpoch,
);

/// Epoch-ms window `[start, end)` of the local calendar month of [month].
({int start, int end}) monthWindow(DateTime month) => (
  start: DateTime(month.year, month.month).millisecondsSinceEpoch,
  end: DateTime(month.year, month.month + 1).millisecondsSinceEpoch,
);

/// How a day header names a day.
enum DayLabelKind { today, yesterday, weekday, date }

/// Today and yesterday by name, the last week by weekday, older days by date.
DayLabelKind dayLabelKind(DateTime day, DateTime today) {
  final back = daysBetween(day, today);
  if (back <= 0) return DayLabelKind.today;
  if (back == 1) return DayLabelKind.yesterday;
  return back <= 6 ? DayLabelKind.weekday : DayLabelKind.date;
}
