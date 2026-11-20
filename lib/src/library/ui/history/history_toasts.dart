import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../state/history/history_actions.dart';

/// Runs a play of the history through [HistoryActions] and says so when
/// nothing played (every song gone, or the read failed). [context] belongs to
/// the root navigator (a menu action's), so the toast outlives the menu.
Future<void> playHistoryOrToast(
  BuildContext context,
  Future<bool> Function(HistoryActions actions) play,
) async {
  final actions = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(historyActionsProvider);
  final l10n = AppLocalizations.of(context);
  final ok = await play(actions);
  if (!ok && context.mounted) showAppSnackBar(context, l10n.historyPlayFailed);
}

/// The toast after a clear or a deleted day: "Removed N plays" (no undo), or
/// the error toast when the delete failed ([removed] null). Nothing when the
/// range was empty already.
void showHistoryClearedToast(
  ScaffoldMessengerState messenger,
  AppLocalizations l10n,
  int? removed,
) {
  if (!messenger.mounted) return;
  if (removed == null) {
    showAppSnackBarOn(messenger, l10n.historyClearFailed);
  } else if (removed > 0) {
    showAppSnackBarOn(messenger, l10n.historyCleared(removed));
  }
}
