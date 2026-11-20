import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'history_sticky_bar.dart';
import 'history_timeline_data.dart';
import 'history_timeline_line.dart';

/// The timeline's two slivers: the day bar pinned under the page header and
/// the flat list of lines. [onListLayout] gets the scroll offset of the
/// list's top at every layout of the list.
Widget historyTimelineSlivers(
  HistoryTimelineData data, {
  required DateTime today,
  required int? olderYear,
  required VoidCallback? onOlderYear,
  required void Function(double listTop) onListLayout,
}) {
  final metrics = data.metrics;
  return SliverMainAxisGroup(
    slivers: [
      // The bar reads its own constraints in layout: the day at the top is
      // right whatever moved above it (a notice, the hero, the text scale).
      SliverLayoutBuilder(
        builder: (context, constraints) => KStickyBarSliver(
          height: metrics.dayBar,
          child: HistoryStickyBar(
            index: data.index,
            days: data.days,
            today: today,
            offset: constraints.scrollOffset - metrics.dayBar,
          ),
        ),
      ),
      SliverLayoutBuilder(
        builder: (context, constraints) {
          onListLayout(constraints.precedingScrollExtent);
          return SliverVariedExtentList.builder(
            itemCount: data.index.lineCount,
            itemExtentBuilder: (i, _) => data.index.extentOf(i),
            findChildIndexCallback: (key) =>
                key is ValueKey<String> ? data.lineOfPlay[key.value] : null,
            itemBuilder: (context, i) => historyTimelineLine(
              context,
              data,
              i,
              today: today,
              olderYear: olderYear,
              onOlderYear: onOlderYear,
            ),
          );
        },
      ),
    ],
  );
}
