import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../state/history/history_providers.dart';
import '../browse/library_list_scaffold.dart';
import 'history_line_metrics.dart';
import 'history_row.dart';

/// The plays of [year] whose song matches [query], as slivers for the page's
/// scroll view: a count line, then one flat list (no day bars) of at most
/// `historyFilterCap` rows, then a line saying the list is cut when it is.
/// Nothing matching shows an empty state.
///
/// A tap on a row plays the matched songs from that one (each once, songs
/// that cannot play left out), the same rule as a day.
class HistoryFilterList extends ConsumerStatefulWidget {
  const HistoryFilterList({super.key, required this.year, required this.query});

  final int year;

  /// What the user typed; never empty (an empty filter is the timeline).
  final String query;

  @override
  ConsumerState<HistoryFilterList> createState() => _HistoryFilterListState();
}

class _HistoryFilterListState extends ConsumerState<HistoryFilterList> {
  HistoryFilterResult? _source;
  HistoryDayQueue? _queue;
  Set<String> _newestOfSong = const {};

  /// What every row of one result shares, built once per result.
  void _prepare(HistoryFilterResult result) {
    if (identical(_source, result)) return;
    _source = result;
    _queue = HistoryDayQueue(result.plays);
    final seen = <int>{};
    _newestOfSong = {
      for (final p in result.plays)
        if (seen.add(p.track.id.value)) p.uid,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final found = ref.watch(
      historyFilterProvider((year: widget.year, query: widget.query)),
    );
    final result = found.value;
    if (result == null) {
      return SliverToBoxAdapter(
        child: found.hasError
            ? Padding(
                padding: const EdgeInsets.all(KSpace.x4),
                child: Text(
                  l10n.libraryLoadFailed,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              )
            : const LinearProgressIndicator(minHeight: 2),
      );
    }
    if (result.matched == 0) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: KSpace.x6),
          child: KEmpty(
            icon: KIcons.filter,
            message: l10n.historyFilterEmpty(widget.query),
          ),
        ),
      );
    }
    _prepare(result);
    final queue = _queue!;
    final gutter = libraryRowGutter(context);
    final row = HistoryLineMetrics.of(
      theme.textTheme,
      MediaQuery.textScalerOf(context),
    ).row;
    Widget note(String text) => Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        libraryBarGutter(context),
        KSpace.x1,
        libraryBarGutter(context),
        KSpace.x2,
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: note(l10n.historyFilterMatches(result.matched)),
        ),
        SliverFixedExtentList.builder(
          itemExtent: row,
          itemCount: result.plays.length,
          itemBuilder: (context, i) {
            final play = result.plays[i];
            return Padding(
              key: ValueKey(play.uid),
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: HistoryRow(
                play: play,
                queue: queue,
                markCurrent: _newestOfSong.contains(play.uid),
              ),
            );
          },
        ),
        if (result.capped)
          SliverToBoxAdapter(
            child: note(l10n.historyFilterCapped(historyFilterCap)),
          ),
      ],
    );
  }
}
