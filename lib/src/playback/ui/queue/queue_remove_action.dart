import 'package:flutter/widgets.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/cleanup_kind.dart';
import '../../state/player_controller.dart';

/// How long the "Undo" toast stays.
const Duration queueUndoDuration = Duration(seconds: 4);

/// Removes [entryIds] from the queue and shows the "Removed … / Undo" toast.
/// Removing the last entry also calls [onEmptied] (the host closes). The toast
/// is shown from the root navigator's context, so it survives the host
/// closing. Undo restores the entries, the current track and its position,
/// but never reopens a closed host.
///
/// Returns false when nothing was removed (the entries were gone already).
Future<bool> removeQueueEntries(
  BuildContext context,
  PlayerController controller,
  Set<int> entryIds, {
  String? title,
  VoidCallback? onEmptied,
}) async {
  final host = Navigator.of(context, rootNavigator: true).context;
  final l10n = AppLocalizations.of(context);
  final token = await controller.remove(entryIds);
  if (token == null) return false;
  if (host.mounted) {
    showAppSnackBar(
      host,
      title != null && entryIds.length == 1
          ? l10n.playbackQueueRemovedOne(title)
          : l10n.playbackQueueRemovedMany(entryIds.length),
      actionLabel: l10n.playbackUndo,
      onAction: () => controller.undo(token),
      duration: queueUndoDuration,
    );
  }
  if (controller.queueState.length == 0) onEmptied?.call();
  return true;
}

/// Runs a cleanup choice and shows "Removed N tracks" with Undo. N is what
/// the controller removed, counted when it ran: the queue may have moved on
/// since the menu opened.
Future<void> cleanupQueue(
  BuildContext context,
  PlayerController controller,
  CleanupKind kind,
) async {
  final host = Navigator.of(context, rootNavigator: true).context;
  final l10n = AppLocalizations.of(context);
  final token = await controller.cleanup(kind);
  if (token == null || !host.mounted) return;
  showAppSnackBar(
    host,
    l10n.playbackQueueRemovedMany(token.items.length),
    actionLabel: l10n.playbackUndo,
    onAction: () => controller.undo(token),
    duration: queueUndoDuration,
  );
}
