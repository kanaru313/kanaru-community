import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/domain/install/install_result.dart';
import '../../../plugins/state/install_ops.dart';
import '../install/package_flow.dart';
import '../updates/update_reasons.dart';

/// [Cài lại] of the error band: brings the package folder back from the
/// plugin's own origin. The same package is written again without a word but
/// a SnackBar; a newer one that adds hosts opens the update screen; anything
/// else says why it did not work. Returns true when the folder was written.
Future<bool> repairPluginFlow(
  BuildContext context,
  InstallOps ops, {
  required String installId,
  required String name,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final result = await ops.repair(installId);
  switch (result) {
    case Installed():
      showAppSnackBarOn(messenger, l10n.pluginsPageReinstalled(name));
      return true;
    case InstallNeedsReview() ||
        InstallRefused(failure: InstallFailure.needsReview):
      if (!context.mounted) return false;
      await reviewPluginUpdate(context, ops, installId: installId, name: name);
      return false;
    default:
      showAppSnackBarOn(
        messenger,
        l10n.pluginsPageReinstallFailed(updateReason(l10n, result)),
      );
      return false;
  }
}
