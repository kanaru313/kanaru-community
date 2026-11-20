import 'history_days.dart';

/// What the "clear history" dialog offers to remove.
enum ClearScope {
  hour,
  today,
  week,
  all;

  /// The plays this option covers as epoch-ms bounds `[from, to)`, all taken
  /// from one fixed [now] so the count shown and the delete agree. The end is
  /// one millisecond after [now], so the range includes [now] itself. Days are
  /// local calendar days; [all] has no lower bound (`from` null) but the same
  /// upper bound, so a play that arrives after the dialog opened is not in it.
  ({int? from, int? to}) bounds(DateTime now) {
    final end = now.millisecondsSinceEpoch + 1;
    return switch (this) {
      ClearScope.hour => (
        from: now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
        to: end,
      ),
      ClearScope.today => (from: localDay(now).millisecondsSinceEpoch, to: end),
      ClearScope.week => (
        from: addDays(localDay(now), -6).millisecondsSinceEpoch,
        to: end,
      ),
      ClearScope.all => (from: null, to: end),
    };
  }
}
