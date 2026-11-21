import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/history/history_models.dart';
import '../../state/history/local_day_provider.dart';
import '../../state/history/most_played_selection.dart';
import '../detail/detail_tint.dart';
import '../history/history_page_frame.dart';
import '../playlists/page/playlist_page_states.dart' show PlaylistStateSliver;
import '../selection/selection_inset.dart';
import 'most_played_hero.dart';
import 'most_played_period_row.dart';
import 'most_played_ranges.dart';
import 'most_played_rows.dart';

/// Most played page of the Playlist tab: the hero, the range chips, the
/// period row with its Top N chip and the ranked songs of the chosen range.
///
/// While a new range or number loads the previous list stays, with a thin
/// progress line under the period row. A range with no plays says so and
/// keeps the chips usable; a failed read does too, in place of the rows.
/// Range and number are kept for the session (see [mostPlayedRangeProvider]).
class MostPlayedPage extends ConsumerWidget {
  const MostPlayedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(mostPlayedProvider);
    final range = ref.watch(mostPlayedRangeProvider);
    final today = ref.watch(localDayProvider);
    final data = state.data;
    // The first read: nothing to show yet, not even the hero.
    if (data == null && state.error == null) {
      return const HistoryPageFrame(
        title: '',
        titleInContent: true,
        child: SizedBox.shrink(),
      );
    }
    final shown = data ?? const MostPlayed(entries: [], songs: 0, plays: 0);
    final coverKeys = mostPlayedCoverKeys(shown.entries);
    return HistoryPageFrame.layout(
      title: l10n.libraryNavMostPlayed,
      tint: watchCoverTint(ref, coverKeys.firstOrNull),
      header: MostPlayedHero(
        data: shown,
        range: range,
        today: today,
        stale: state.stale || data == null,
        coverKeys: coverKeys,
        showTotals: data != null,
      ),
      slivers: [
        const SliverToBoxAdapter(child: MostPlayedRangeChips()),
        const SliverToBoxAdapter(child: MostPlayedPeriodRow()),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 2,
            child: state.stale
                ? const LinearProgressIndicator(minHeight: 2)
                : null,
          ),
        ),
        if (data == null)
          PlaylistStateSliver(
            child: Center(
              child: Text(
                l10n.libraryLoadFailed,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          )
        else if (data.entries.isEmpty)
          PlaylistStateSliver(
            child: KEmpty(
              icon: KIcons.mostPlayed,
              message: l10n.historyMostPlayedEmpty,
            ),
          )
        else
          mostPlayedRows(context, data.entries),
        const SelectionInsetSliver(),
      ],
    );
  }
}
