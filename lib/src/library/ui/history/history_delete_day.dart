import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/history/history_models.dart';
import '../../state/history/history_actions.dart';
import 'history_labels.dart';
import 'history_toasts.dart';

/// Asks, then removes every play of [day] from the history: "Remove this day
/// from history?" with the count in the body. No undo; the toast says how many
/// went, or that the delete failed. [context] belongs to the root navigator
/// (a menu action's).
Future<void> deleteHistoryDay(BuildContext context, HistoryDay day) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final messenger = ScaffoldMessenger.of(
    Navigator.of(context, rootNavigator: true).context,
  );
  final l10n = AppLocalizations.of(context);
  final ok = await confirmAction(
    context,
    title: l10n.historyDeleteDayTitle,
    message: l10n.historyDeleteDayBody(
      day.playCount,
      historyDate(day.start.millisecondsSinceEpoch),
    ),
    confirmLabel: l10n.historyClearConfirm,
    destructive: true,
  );
  if (!ok) return;
  final removed = await container
      .read(historyActionsProvider)
      .deleteDay(day.start);
  showHistoryClearedToast(messenger, l10n, removed);
}
