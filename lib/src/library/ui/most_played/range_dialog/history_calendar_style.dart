import 'package:material_ui/material_ui.dart';
import 'package:table_calendar/table_calendar.dart';

/// Height of a week row, and of the filled circle in a day cell.
const historyCalendarRowHeight = 40.0;
const _cellMargin = 2.0;

/// The weekday a week starts on in the app's locale (Monday for Vietnamese,
/// Sunday for US English).
StartingDayOfWeek historyStartingDay(MaterialLocalizations loc) =>
    // `firstDayOfWeekIndex` counts from Sunday; the package's values from
    // Monday.
    StartingDayOfWeek.values[(loc.firstDayOfWeekIndex + 6) % 7];

/// Look of the grid: no package decoration, the day cells draw themselves
/// ([HistoryDayCell]); only the band behind a selected range is the
/// package's, in the theme's container colour.
CalendarStyle historyCalendarStyle(ThemeData theme) => CalendarStyle(
  outsideDaysVisible: true,
  cellMargin: const EdgeInsets.symmetric(vertical: _cellMargin),
  rangeHighlightColor: theme.colorScheme.primaryContainer.withValues(
    alpha: 0.7,
  ),
);

/// Height of the weekday row: the label with 4 above and 8 below.
const historyWeekdayRowHeight = 28.0;

/// One weekday label from the localizations' narrow names, like the jump
/// calendar's, with 4 above and 8 below.
Widget historyWeekdayCell(
  ThemeData theme,
  MaterialLocalizations loc,
  DateTime day,
) => Padding(
  padding: const EdgeInsets.only(top: 4, bottom: 8),
  child: Center(
    child: Text(
      // `DateTime.weekday` is 1 (Monday) to 7 (Sunday); the localizations'
      // list starts on Sunday.
      loc.narrowWeekdays[day.weekday % 7],
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    ),
  ),
);

/// Key of the cell for [day], for tests and finders.
ValueKey<String> historyDayCellKey(DateTime day) {
  String two(int n) => n.toString().padLeft(2, '0');
  return ValueKey(
    'history-range-day-${day.year}-${two(day.month)}-${two(day.day)}',
  );
}

/// One day of the range calendar: a number, a dot when the day has plays, a
/// filled circle on the first and last day of the range and an outline on
/// today. Days of the neighbouring months are faded but stay tappable; days
/// outside the bounds are fainter and the package does not let them be tapped.
class HistoryDayCell extends StatelessWidget {
  const HistoryDayCell({
    super.key,
    required this.day,
    required this.isOutside,
    required this.isDisabled,
    required this.isToday,
    required this.isEdge,
    required this.hasPlays,
  });

  final DateTime day;
  final bool isOutside;
  final bool isDisabled;
  final bool isToday;

  /// First or last day of the selection.
  final bool isEdge;
  final bool hasPlays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final Color text;
    if (isEdge) {
      text = scheme.onPrimary;
    } else if (isDisabled) {
      text = scheme.onSurface.withValues(alpha: 0.3);
    } else if (isOutside) {
      text = scheme.onSurface.withValues(alpha: 0.5);
    } else {
      text = scheme.onSurface;
    }
    return Center(
      child: Container(
        key: historyDayCellKey(day),
        width: historyCalendarRowHeight - 2 * _cellMargin,
        height: historyCalendarRowHeight - 2 * _cellMargin,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isEdge ? scheme.primary : null,
          border: isToday && !isEdge ? Border.all(color: scheme.primary) : null,
        ),
        // A large text scale shrinks the number and dot instead of
        // overflowing the fixed circle.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.day}',
                style: theme.textTheme.bodyMedium?.copyWith(color: text),
              ),
              SizedBox(
                height: 6,
                child: hasPlays && !isDisabled
                    ? Center(
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isEdge ? scheme.onPrimary : scheme.primary,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
