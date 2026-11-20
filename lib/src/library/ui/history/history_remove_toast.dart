import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/history/history_models.dart';
import '../../state/history/history_actions.dart';
import '../../state/history/history_removal_holder.dart'
    show HistoryToastHandle;

/// Removes one play and says so: the root toast "Removed N plays · Undo",
/// where N counts every removal whose toast is still open (they merge, and
/// one Undo brings all of them back). A failed write shows an error toast
/// and no "Removed".
///
/// The toast sits on the root navigator's messenger, so it outlives the page
/// that asked. Closing it any way but Undo commits the removals.
Future<void> removeHistoryPlay(BuildContext context, HistoryPlay play) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final messenger = ScaffoldMessenger.of(
    Navigator.of(context, rootNavigator: true).context,
  );
  final l10n = AppLocalizations.of(context);
  final actions = container.read(historyActionsProvider);

  final pending = await actions.remove(play);
  if (!messenger.mounted) return;
  if (pending == null) {
    showAppSnackBarOn(messenger, l10n.historyRemoveFailed);
    return;
  }
  // Already gone (removed from another place): nothing to undo.
  if (pending == 0) return;

  // The holder commits when this exact toast closes without Undo; a toast
  // that a newer one replaced is no longer that one. `hide` closes the
  // messenger's current snack bar, so it acts only while this toast is still
  // the one on screen: any close of it (also by another toast replacing it)
  // ends that.
  var showing = true;
  void hide() {
    // The messenger may be gone when the holder closes the toast on dispose.
    if (showing && messenger.mounted) messenger.hideCurrentSnackBar();
  }

  actions.attachToast(hide);
  showAppSnackBarOn(
    messenger,
    l10n.historyRemoved(pending),
    actionLabel: l10n.libraryMenuUndo,
    onAction: () {
      showing = false;
      unawaited(_undo(actions, messenger, l10n));
    },
    onClosedWithoutAction: () {
      showing = false;
      unawaited(_closed(actions, hide, messenger, l10n));
    },
  );
}

Future<void> _undo(
  HistoryActions actions,
  ScaffoldMessengerState messenger,
  AppLocalizations l10n,
) async {
  final ok = await actions.undo();
  if (!ok && messenger.mounted) {
    showAppSnackBarOn(messenger, l10n.libraryMenuUndoFailed);
  }
}

Future<void> _closed(
  HistoryActions actions,
  HistoryToastHandle hide,
  ScaffoldMessengerState messenger,
  AppLocalizations l10n,
) async {
  final ok = await actions.toastClosed(hide);
  if (!ok && messenger.mounted) {
    showAppSnackBarOn(messenger, l10n.historyWriteFailed);
  }
}
