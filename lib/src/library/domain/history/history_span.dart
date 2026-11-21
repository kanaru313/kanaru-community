import 'history_days.dart';

String _two(int n) => n.toString().padLeft(2, '0');

String _dayMonth(DateTime d) => '${_two(d.day)}/${_two(d.month)}';

String _full(DateTime d) => '${_dayMonth(d)}/${d.year}';

/// The days from [first] to [last] (inclusive, local midnights) as
/// dd/MM dates: one date for a single day ("09/11/2026"), "07/10 – 24/10/2026"
/// inside one year and "28/12/2025 – 03/01/2026" across two. The year is
/// written once when both ends share it.
String historySpanText(DateTime first, DateTime last) {
  if (!last.isAfter(first)) return _full(first);
  final start = first.year == last.year ? _dayMonth(first) : _full(first);
  return '$start – ${_full(last)}';
}

/// How many days there are from [first] to [last], both included.
int rangeDays(DateTime first, DateTime last) => daysBetween(first, last) + 1;
