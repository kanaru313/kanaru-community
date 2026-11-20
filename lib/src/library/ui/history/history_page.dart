import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/history/history_models.dart';
import '../../state/history/history_providers.dart';
import '../../state/history/history_year_selection.dart';
import '../../state/history/local_day_provider.dart';
import 'history_bar.dart';
import 'history_hero.dart';
import 'history_notice.dart';
import 'history_page_frame.dart';
import 'history_timeline.dart';

/// History page of the Playlist tab: the hero, the year bar and the plays of
/// the shown year as a timeline by day.
///
/// The hero and the overview show as soon as the overview is read; the year's
/// plays follow (a thin progress line meanwhile). Nothing played yet shows
/// the empty state; with recording switched off a strip above says so.
class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final years = ref.watch(historyYearsProvider);
    final overview = ref.watch(historyOverviewProvider);
    final yearList = years.value;
    final summary = overview.value;
    if (yearList == null || summary == null) {
      return HistoryPageFrame(
        title: '',
        titleInContent: true,
        child: years.hasError || overview.hasError
            ? Center(
                child: Text(
                  l10n.libraryLoadFailed,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              )
            : const SizedBox.shrink(),
      );
    }
    if (yearList.isEmpty) {
      return HistoryPageFrame(
        title: l10n.historyTitle,
        child: Column(
          children: [
            const HistoryRecordingNotice(),
            Expanded(
              child: KEmpty(
                icon: KIcons.history,
                message: l10n.historyEmptyMessage,
              ),
            ),
          ],
        ),
      );
    }
    return _HistoryContent(years: yearList, overview: summary);
  }
}

class _HistoryContent extends ConsumerWidget {
  const _HistoryContent({required this.years, required this.overview});

  /// Years with plays, newest first; never empty.
  final List<int> years;
  final HistoryOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final shown = ref.watch(historyShownYearProvider) ?? years.first;
    final plays = ref.watch(historyYearProvider(shown));
    // The hero's cover is the newest year's, whichever year is shown.
    final newest = shown == years.first
        ? plays
        : ref.watch(historyYearProvider(years.first));
    final older = years.where((y) => y < shown).firstOrNull;
    return HistoryPageFrame.layout(
      title: l10n.historyTitle,
      header: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HistoryRecordingNotice(),
          HistoryHero(overview: overview, plays: newest.value),
        ],
      ),
      slivers: [
        SliverToBoxAdapter(
          child: HistoryBar(
            years: years,
            year: shown,
            plays: plays.value?.length,
            onYear: (y) =>
                ref.read(historySelectedYearProvider.notifier).select(y),
          ),
        ),
        _timeline(context, ref, plays, shown, older),
      ],
    );
  }

  Widget _timeline(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<HistoryPlay>> plays,
    int shown,
    int? older,
  ) {
    final list = plays.value;
    if (list == null) {
      return SliverToBoxAdapter(
        child: plays.hasError
            ? Padding(
                padding: const EdgeInsets.all(KSpace.x4),
                child: Text(
                  AppLocalizations.of(context).libraryLoadFailed,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              )
            : const LinearProgressIndicator(minHeight: 2),
      );
    }
    if (list.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return HistoryTimeline(
      // A year is its own timeline (state): it puts the page's scroll
      // position at its first day bar when the page was scrolled deeper.
      key: ValueKey(shown),
      scope: shown,
      plays: list,
      today: ref.watch(localDayProvider),
      olderYear: older,
      onOlderYear: older == null
          ? null
          : () => ref.read(historySelectedYearProvider.notifier).select(older),
    );
  }
}
