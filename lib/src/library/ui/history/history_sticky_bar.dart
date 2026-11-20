import 'package:material_ui/material_ui.dart';

import '../../domain/history/history_models.dart';
import 'history_day_bar.dart';
import 'history_timeline_index.dart';

/// Content of the pinned day bar: the day at the top of the list. While the
/// next day's header line slides up under the bar it pushes the bar's text
/// up and its own text rises from below, so the swap is continuous; the
/// header line is as tall as the bar, so nothing jumps when the bar changes
/// to that day.
///
/// [offset] is the scroll offset of the list (0 = its first line at the top
/// of the page's scrolling area; negative while the list starts below it).
class HistoryStickyBar extends StatelessWidget {
  const HistoryStickyBar({
    super.key,
    required this.index,
    required this.days,
    required this.today,
    required this.offset,
  });

  final HistoryTimelineIndex index;
  final List<HistoryDay> days;
  final DateTime today;
  final double offset;

  @override
  Widget build(BuildContext context) {
    final height = index.metrics.dayBar;
    Widget bar(int day) =>
        HistoryDayBar(day: days[day], today: today, height: height);
    final o = offset;
    final day = index.dayAt(o);
    if (day < 0) return const SizedBox.shrink();
    final dy = index.pushUp(o);
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(top: dy, left: 0, right: 0, height: height, child: bar(day)),
        if (dy < 0)
          Positioned(
            top: dy + height,
            left: 0,
            right: 0,
            height: height,
            // The same day is in the list's header line right behind.
            child: ExcludeSemantics(child: bar(day + 1)),
          ),
      ],
    );
  }
}
