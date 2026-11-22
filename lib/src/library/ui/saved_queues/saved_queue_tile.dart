import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/saved_queues/saved_queue_store.dart';
import '../../state/history/local_day_provider.dart';
import '../browse/library_navigation.dart';
import '../library_locations.dart';
import '../menus/more_button.dart';
import '../playlist_common/playlist_cover.dart';
import 'saved_queue_labels.dart';
import 'saved_queue_menu.dart';
import 'saved_queue_play.dart';

/// One saved queue in the list: the automatic cover, the time it was saved,
/// `24 songs · 1 h 41 min` (`· 2 songs gone`), `From …`, ▶ and ⋮. A tap opens
/// the queue's page; long press, right click and ⋮ open its menu. ▶ replaces
/// the current queue with it and is off when nothing in it can play now.
class SavedQueueTile extends ConsumerWidget {
  const SavedQueueTile({super.key, required this.row});

  final SavedQueueRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = row.summary;
    final info = summary.savedQueue;
    if (info == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final today = ref.watch(localDayProvider);
    final uid = summary.uid;
    return KContextRegion(
      onOpen: (at) => openSavedQueueMenu(context, uid, viaKeyboard: at == null),
      child: KMediaCard(
        title: savedQueueName(l10n, info.savedAt, today),
        line2: savedQueueStatsLine(l10n, summary, missing: row.missingCount),
        line3: savedQueueSourceLine(l10n, info),
        leading: PlaylistCover(
          uid: uid,
          autoCoverKeys: summary.autoCoverKeys,
          dimension: KMediaCard.coverSize,
          radius: KMediaCard.coverRadius,
        ),
        onAction: () => playSavedQueue(context, uid),
        actionEnabled: summary.trackCount > row.missingCount,
        actionLabel: l10n.savedQueuePlayRow,
        trailing: LibraryMoreButton(
          onPressed: ({required viaKeyboard}) =>
              openSavedQueueMenu(context, uid, viaKeyboard: viaKeyboard),
        ),
        onTap: () =>
            openLibraryPage<void>(context, LibraryLocations.savedQueue(uid)),
      ),
    );
  }
}
