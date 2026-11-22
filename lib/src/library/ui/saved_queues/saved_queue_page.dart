import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../state/history/local_day_provider.dart';
import '../../state/saved_queues/saved_queue_providers.dart';
import '../detail/detail_tint.dart';
import '../history/history_page_frame.dart';
import 'saved_queue_hero.dart';
import 'saved_queue_labels.dart';
import 'saved_queue_rows.dart';
import 'saved_queue_states.dart';

/// One saved queue, a sub-page of the Queue page with the layout of a
/// playlist page: the hero (a left column on a wide page) tinted with the
/// colours of its cover, and the songs in the order they were played.
///
/// A queue that is deleted or dropped while the page is open, or a uid that
/// is not a saved queue (a playlist, a stale link), shows "not found".
class SavedQueuePage extends ConsumerWidget {
  const SavedQueuePage({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(savedQueueDetailProvider(uid));
    final detail = async.value;
    if (detail == null) {
      return async.hasValue
          ? const SavedQueueNotFound()
          : SavedQueuePending(failed: async.hasError);
    }
    final info = detail.summary.savedQueue;
    if (info == null) return const SavedQueueNotFound();
    final l10n = AppLocalizations.of(context);
    final name = savedQueueName(
      l10n,
      info.savedAt,
      ref.watch(localDayProvider),
    );
    return HistoryPageFrame.layout(
      title: name,
      showBack: true,
      tint: watchCoverTint(ref, detail.summary.autoCoverKeys.firstOrNull),
      header: SavedQueueHero(detail: detail, name: name),
      slivers: savedQueueSlivers(context, detail),
    );
  }
}
