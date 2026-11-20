import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/history/history_models.dart';
import '../../state/history/history_year_selection.dart';
import '../../state/history/local_day_provider.dart';
import 'history_timeline.dart';
import 'history_timeline_controller.dart';
import 'history_timeline_scroll.dart';

/// The sliver of the shown year: a progress line while it loads, the error,
/// nothing for a year without plays, else the [HistoryTimeline]. [older] is
/// the next older year with plays (the "See 2025" line).
Widget historyYearTimeline(
  BuildContext context,
  WidgetRef ref,
  AsyncValue<List<HistoryPlay>> plays,
  int shown,
  int? older, {
  required HistoryTimelineController controller,
  required HistoryRestore? restore,
}) {
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
    controller: controller,
    restore: restore,
    plays: list,
    today: ref.watch(localDayProvider),
    olderYear: older,
    onOlderYear: older == null
        ? null
        : () => ref.read(historySelectedYearProvider.notifier).select(older),
  );
}

/// After the filter's results start: scrolls the bar (anchored by [barKey])
/// into view, whatever depth the timeline was at.
void scrollHistoryBarIntoView(GlobalKey barKey) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final bar = barKey.currentContext;
    if (bar != null && bar.mounted) {
      unawaited(
        Scrollable.ensureVisible(
          bar,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
        ),
      );
    }
  });
}
