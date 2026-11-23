import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../state/saved_queues/saved_queue_providers.dart';
import '../library_locations.dart';

final _log = Logger('library.saved_queues');

/// The wait for the page route to finish leaving is bounded, so a route that
/// stays on screen cannot block the delete.
const _exitWait = Duration(seconds: 1);

/// Asks, then deletes saved queue [uid] for good (the songs stay in the
/// library).
///
/// [pageRoute]: the route of the queue's own page when the flow starts from it
/// (capture `ModalRoute.of(pageContext)` before calling), null otherwise. With
/// it the page leaves first (pop, or go to the list when nothing is below) and
/// the delete waits for the route to finish leaving, so the page never flashes
/// "not found" while it slides away. Everything used after an await was taken
/// before it. A failure is shown as a toast.
Future<void> deleteSavedQueueFlow(
  BuildContext context,
  String uid, {
  ModalRoute<Object?>? pageRoute,
}) async {
  final l10n = AppLocalizations.of(context);
  final container = ProviderScope.containerOf(context, listen: false);
  final messenger = ScaffoldMessenger.of(
    Navigator.of(context, rootNavigator: true).context,
  );
  final router = pageRoute == null ? null : GoRouter.of(context);

  final confirmed = await confirmAction(
    context,
    title: l10n.savedQueueDeleteTitle,
    message: l10n.savedQueueDeleteBody,
    confirmLabel: l10n.playlistDeleteConfirm,
    destructive: true,
  );
  if (!confirmed) return;

  if (router != null && pageRoute != null && pageRoute.isCurrent) {
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(LibraryLocations.savedQueues);
    }
    await pageRoute.completed.timeout(_exitWait, onTimeout: () => null);
  }
  final bool deleted;
  try {
    deleted = await container
        .read(savedQueueStoreProvider)
        .deleteSavedQueue(uid);
  } on Object catch (e, s) {
    _log.warning('deleting saved queue $uid failed', e, s);
    if (messenger.mounted) {
      showAppSnackBarOn(messenger, l10n.savedQueueDeleteFailed);
    }
    return;
  }
  // false: it was gone already (dropped by the limit), nothing to announce.
  if (deleted && messenger.mounted) {
    showAppSnackBarOn(messenger, l10n.savedQueueDeleted);
  }
}
