import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../state/history/history_providers.dart';
import 'history_content.dart';
import 'history_notice.dart';
import 'history_page_frame.dart';

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
    return HistoryContent(years: yearList, overview: summary);
  }
}
