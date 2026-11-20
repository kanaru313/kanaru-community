import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../browse/library_list_scaffold.dart';
import 'history_day_bar.dart';
import 'history_row.dart';
import 'history_timeline_data.dart';
import 'history_timeline_index.dart';

/// Line [i] of the timeline: a day's header bar, a play's row or the "See
/// 2025" footer. [today] names the days; the footer needs [olderYear] and
/// [onOlderYear].
Widget historyTimelineLine(
  BuildContext context,
  HistoryTimelineData data,
  int i, {
  required DateTime today,
  required int? olderYear,
  required VoidCallback? onOlderYear,
}) {
  final info = data.index.lineInfo(i);
  final gutter = libraryRowGutter(context);
  switch (info.kind) {
    case HistoryLineKind.header:
      return HistoryDayBar(
        day: data.days[info.day],
        today: today,
        height: data.index.metrics.dayBar,
      );
    case HistoryLineKind.row:
      final play = data.days[info.day].plays[info.row];
      return Padding(
        key: ValueKey(play.uid),
        padding: EdgeInsets.symmetric(horizontal: gutter),
        child: HistoryRow(
          play: play,
          queue: data.queueOf(info.day),
          markCurrent: data.newestOfSong.contains(play.uid),
        ),
      );
    case HistoryLineKind.footer:
      final l10n = AppLocalizations.of(context);
      return Center(
        child: FilledButton.tonal(
          onPressed: onOlderYear,
          child: Text(l10n.historyYearFooter('${olderYear!}')),
        ),
      );
  }
}
