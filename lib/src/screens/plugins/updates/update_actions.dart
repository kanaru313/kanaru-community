import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/domain/install/install_result.dart';
import '../../../plugins/state/install_ops.dart';
import 'update_failures.dart';
import 'update_reasons.dart';

/// [Cập nhật] of a row: updates in place. The row spins (the services mark
/// it), a failure puts the red line on the row and the same sentence in a
/// SnackBar, a new version that adds hosts turns the row into [Xem].
Future<void> updatePlugin(
  BuildContext context,
  InstallOps ops,
  UpdateFailures failures, {
  required String installId,
  required String name,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  failures.clear(installId);
  final run = await ops.update(installId);
  final result = run.result;
  if (result is Installed) {
    final version = run.version;
    showAppSnackBarOn(
      messenger,
      version == null
          ? l10n.pluginsUpdatedNoVersion(name)
          : l10n.pluginsPkgUpdated(name, version),
    );
  } else if (needsReviewResult(result)) {
    showAppSnackBarOn(messenger, l10n.pluginsUpdateNeedsReview(name));
  } else {
    final line = l10n.pluginsUpdateFailedLine(updateReason(l10n, result));
    failures.set(installId, line);
    showAppSnackBarOn(messenger, line);
  }
}

/// "Cập nhật tất cả": runs the update of every plugin without new hosts, then
/// says how it went. A version that adds hosts is never installed here.
Future<void> updateAllPlugins(BuildContext context, InstallOps ops) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final state = await ops.updateAll();
  var updated = 0;
  var review = 0;
  var failed = 0;
  for (final outcome in state.outcomes) {
    final result = outcome.result;
    if (result is Installed) {
      updated++;
    } else if (needsReviewResult(result)) {
      review++;
    } else {
      failed++;
    }
  }
  final parts = [
    if (updated > 0) l10n.pluginsUpdateAllUpdated(updated),
    if (review > 0) l10n.pluginsUpdateAllReview(review),
    if (failed > 0) l10n.pluginsUpdateAllFailed(failed),
  ];
  if (parts.isEmpty) return;
  showAppSnackBarOn(messenger, parts.join(' · '));
}
