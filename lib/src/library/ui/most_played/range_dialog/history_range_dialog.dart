import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/history/history_days.dart';
import '../../../domain/history/history_ranges.dart';
import '../../../state/history/history_providers.dart';
import '../../../state/history/local_day_provider.dart';
import 'history_range_calendar.dart';
import 'history_range_dialog_header.dart';

final _log = Logger('library.history');

/// Widest the dialog's content gets (380) plus the dialog's inset (2 x 40).
const _dialogCap = 460.0;

/// First and last day (local midnights) of a picked range.
typedef HistoryDayRange = ({DateTime start, DateTime end});

/// Asks for a range of days in a centred dialog with one month at a time.
/// Only days from the first play to today (or the last play, when later) can
/// be picked; [initial] is selected at first (cut to those days) and today is
/// outlined. Returns the first and last day (local midnights), or null when
/// the dialog was dismissed or there is no play to pick a day from.
Future<HistoryDayRange?> showHistoryRangeDialog(
  BuildContext context, {
  HistoryDayRange? initial,
}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final ({int first, int last})? played;
  // The provider is auto-disposed: keep it alive while the read is in flight.
  final sub = container.listen(historyBoundsProvider, (_, _) {});
  try {
    played = await container.read(historyBoundsProvider.future);
  } on Object catch (e) {
    _log.warning('Reading the first and last play failed: ${e.runtimeType}');
    if (context.mounted) {
      showAppSnackBar(context, AppLocalizations.of(context).libraryLoadFailed);
    }
    return null;
  } finally {
    sub.close();
  }
  if (played == null || !context.mounted) return null;
  final today = localDay(container.read(historyClockProvider)());
  final bounds = pickerBounds(played, today);
  return showKDialog<HistoryDayRange>(
    context,
    // The dialog's own 40 dp inset on each side comes off this: the content is
    // at most 380 wide, 332 on a 412 dp phone.
    maxWidth: _dialogCap,
    builder: (_) => Dialog(
      child: SizedBox(
        width: double.maxFinite,
        child: HistoryRangePicker(
          bounds: bounds,
          today: today,
          initial: _cut(initial, bounds),
        ),
      ),
    ),
  );
}

/// [range] cut to [bounds]; null when none of it is left (the calendar
/// asserts on days outside its bounds).
HistoryDayRange? _cut(
  HistoryDayRange? range,
  ({DateTime first, DateTime last}) bounds,
) {
  if (range == null) return null;
  final start = range.start.isBefore(bounds.first) ? bounds.first : range.start;
  final end = range.end.isAfter(bounds.last) ? bounds.last : range.end;
  return end.isBefore(start) ? null : (start: start, end: end);
}

/// The 6-week grid of [month] as the epoch-ms window `[start, end)`, from the
/// first day of the locale's week that holds the 1st.
({int start, int end}) _gridWindow(DateTime month, int weekStart) {
  final first = DateTime(month.year, month.month);
  final lead = (first.weekday % 7 - weekStart + 7) % 7;
  final gridStart = addDays(first, -lead);
  return (
    start: gridStart.millisecondsSinceEpoch,
    end: addDays(gridStart, 42).millisecondsSinceEpoch,
  );
}

/// The dialog's content: title, month bar, calendar and buttons. The
/// selection lives here, so it stays while the calendar pages.
class HistoryRangePicker extends ConsumerStatefulWidget {
  const HistoryRangePicker({
    super.key,
    required this.bounds,
    required this.today,
    this.initial,
  });

  final ({DateTime first, DateTime last}) bounds;
  final DateTime today;
  final HistoryDayRange? initial;

  @override
  ConsumerState<HistoryRangePicker> createState() => _HistoryRangePickerState();
}

class _HistoryRangePickerState extends ConsumerState<HistoryRangePicker> {
  DateTime? _start;
  DateTime? _end;
  late DateTime _focused;

  /// Days with plays of every grid window read so far, by window start: the
  /// grid of a month shows days of its neighbours, and a window that reads
  /// again replaces its own days only.
  final _marks = <int, Set<DateTime>>{};

  @override
  void initState() {
    super.initState();
    _start = widget.initial?.start;
    _end = widget.initial?.end;
    _focused = _clamp(widget.initial?.end ?? widget.today);
  }

  DateTime _clamp(DateTime day) {
    final d = localDay(day);
    if (d.isBefore(widget.bounds.first)) return widget.bounds.first;
    if (d.isAfter(widget.bounds.last)) return widget.bounds.last;
    return d;
  }

  void _focus(DateTime day) {
    // The package hands out UTC dates; the app works in local days.
    setState(() => _focused = _clamp(localDay(day)));
  }

  void _step(int months) =>
      _focus(DateTime(_focused.year, _focused.month + months));

  void _tap(DateTime day) {
    final local = localDay(day);
    final next = applyRangeTap(_start, _end, local);
    setState(() {
      _start = next.start;
      _end = next.end;
    });
    _focus(local);
  }

  void _save() {
    final start = _start;
    final end = _end;
    if (start != null && end != null) {
      Navigator.of(context).pop((start: start, end: end));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bounds = widget.bounds;
    final month = DateTime(_focused.year, _focused.month);
    final window = _gridWindow(
      month,
      MaterialLocalizations.of(context).firstDayOfWeekIndex,
    );
    // A failed read leaves the grid without dots; the dialog stays usable.
    ref.listen(playDaysProvider(window), (_, next) {
      if (next is AsyncError) {
        _log.warning(
          'Reading the days with plays failed: ${next.error.runtimeType}',
        );
      }
    });
    final days = ref.watch(playDaysProvider(window)).value;
    if (days != null) _marks[window.start] = days;
    final canGoBack = month.isAfter(
      DateTime(bounds.first.year, bounds.first.month),
    );
    final canGoOn = month.isBefore(
      DateTime(bounds.last.year, bounds.last.month),
    );
    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) => saveOnEnter(context, event, _save),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HistoryRangeDialogHeader(start: _start, end: _end),
            const SizedBox(height: KSpace.x4),
            HistoryMonthBar(
              month: month,
              onPrevious: canGoBack ? () => _step(-1) : null,
              onNext: canGoOn ? () => _step(1) : null,
            ),
            const SizedBox(height: KSpace.x2),
            HistoryRangeCalendar(
              bounds: bounds,
              today: widget.today,
              focused: _focused,
              start: _start,
              end: _end,
              playDays: {for (final set in _marks.values) ...set},
              onDayTap: _tap,
              onPageChanged: _focus,
            ),
            const SizedBox(height: KSpace.x2),
            HistoryRangeFooter(
              onSave: _start != null && _end != null ? _save : null,
            ),
          ],
        ),
      ),
    );
  }
}
