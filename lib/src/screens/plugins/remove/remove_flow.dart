import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/state/install_ops.dart';
import 'remove_plugin_dialog.dart';

/// Asks, removes plugin [installId], and says how it went ("Đã xoá {tên}" /
/// "Không xoá được {tên}"). Always asked. [onBeforeRemove] runs after the
/// user confirmed and before the delete starts: the plugin page uses it to go
/// blank while its files go. True when the plugin is gone.
Future<bool> removePluginFlow(
  BuildContext context,
  InstallOps ops,
  String installId, {
  VoidCallback? onBeforeRemove,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final preview = await ops.removePreview(installId);
  if (preview == null || !context.mounted) return false;
  final confirmed = await showKDialog<bool>(
    context,
    builder: (_) => RemovePluginDialog(preview: preview),
  );
  if (confirmed != true) return false;
  onBeforeRemove?.call();
  final result = await ops.remove(installId);
  final gone =
      result == RemoveResult.removed || result == RemoveResult.alreadyRemoved;
  showAppSnackBarOn(
    messenger,
    gone
        ? l10n.pluginsRemoved(preview.name)
        : l10n.pluginsRemoveFailed(preview.name),
  );
  return gone;
}
