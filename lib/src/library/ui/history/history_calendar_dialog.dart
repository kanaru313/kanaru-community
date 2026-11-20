import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/history/history_models.dart';

/// Opens the "jump to date" dialog: a month grid of [year] with a dot under
/// each day that has plays in [plays] (local days, the value is how many);
/// days without plays are off. Resolves to the day picked, or null when the
/// dialog was dismissed.
Future<DateTime?> showHistoryCalendar(
  BuildContext context, {
  required int year,
  required Map<DateTime, int> plays,
}) => showKDialog<DateTime>(
  context,
  maxWidth: 360,
  builder: (context) => Dialog(
    child: SizedBox(
      width: historyDialogWidth(context),
      child: HistoryCalendar(year: year, plays: plays),
    ),
  ),
);

/// Width of a History dialog: fills up to the dialog's cap on desktop (the
/// content has no width of its own); null on mobile, where the dialog keeps
/// the app's default size.
double? historyDialogWidth(BuildContext context) =>
    FormFactor.of(context) == FormFactor.desktop ? double.maxFinite : null;

/// Opens the jump dialog for the plays of [year] (the days with plays get a
/// dot); the day picked, or null.
Future<DateTime?> pickHistoryDay(
  BuildContext context,
  int year,
  List<HistoryPlay> plays,
) => showHistoryCalendar(
  context,
  year: year,
  plays: {for (final day in groupByDay(plays)) day.start: day.playCount},
);

/// The month grid inside the dialog: one month at a time, within [year].
/// Opens on the month of the newest play (January when there is none).
class HistoryCalendar extends StatefulWidget {
  const HistoryCalendar({super.key, required this.year, required this.plays});

  final int year;

  /// Plays per local day of [year], keyed by `DateTime(year, month, day)`.
  final Map<DateTime, int> plays;

  @override
  State<HistoryCalendar> createState() => _HistoryCalendarState();
}

class _HistoryCalendarState extends State<HistoryCalendar> {
  late int _month;

  @override
  void initState() {
    super.initState();
    final newest = widget.plays.keys.fold<DateTime?>(
      null,
      (best, d) => best == null || d.isAfter(best) ? d : best,
    );
    _month = newest?.month ?? 1;
  }

  void _step(int by) => setState(() => _month += by);

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final first = DateTime(widget.year, _month);
    final days = DateTime(widget.year, _month + 1, 0).day;
    // Sunday is 0 in the localizations' weekday lists; DateTime's is 7.
    final lead = (first.weekday % 7 - loc.firstDayOfWeekIndex + 7) % 7;
    final weeks = (lead + days + 6) ~/ 7;
    return Padding(
      padding: const EdgeInsets.all(KSpace.x4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              KIconButton(
                tooltip: loc.previousMonthTooltip,
                padding: const EdgeInsets.all(KSpace.x3),
                onPressed: _month > 1 ? () => _step(-1) : null,
                icon: KIcons.chevronLeft,
              ),
              Expanded(
                child: Text(
                  loc.formatMonthYear(first),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              KIconButton(
                tooltip: loc.nextMonthTooltip,
                padding: const EdgeInsets.all(KSpace.x3),
                onPressed: _month < 12 ? () => _step(1) : null,
                icon: KIcons.chevronRight,
              ),
            ],
          ),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      loc.narrowWeekdays[(loc.firstDayOfWeekIndex + i) % 7],
                    ),
                  ),
                ),
            ],
          ),
          for (var w = 0; w < weeks; w++)
            Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(child: _cell(context, w * 7 + i - lead + 1, days)),
              ],
            ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(loc.closeButtonLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, int day, int days) {
    if (day < 1 || day > days) return const SizedBox(height: 44);
    final theme = Theme.of(context);
    final date = DateTime(widget.year, _month, day);
    final plays = widget.plays[date];
    final enabled = plays != null;
    final color = enabled
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withValues(alpha: 0.38);
    final full = MaterialLocalizations.of(context).formatFullDate(date);
    return Semantics(
      excludeSemantics: true,
      button: enabled,
      enabled: enabled,
      label: enabled
          ? '$full, ${AppLocalizations.of(context).historyHeroPlays(plays)}'
          : full,
      child: InkResponse(
        key: ValueKey('history-calendar-day-$day'),
        onTap: enabled ? () => Navigator.of(context).pop(date) : null,
        radius: 22,
        child: SizedBox(
          height: 44,
          // A large text scale shrinks the number and dot instead of
          // overflowing the fixed cell.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$day', style: TextStyle(color: color)),
                const SizedBox(height: 2),
                SizedBox.square(
                  dimension: 5,
                  child: enabled
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
