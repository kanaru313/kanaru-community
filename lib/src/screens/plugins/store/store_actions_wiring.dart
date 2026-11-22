import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../plugins/state/install_ops.dart';
import '../../../platform/state/document_picker_provider.dart';
import '../install/link_install_dialog.dart';
import '../install/package_flow.dart';
import '../remove/remove_flow.dart';
import '../updates/update_actions.dart';
import '../updates/update_failures.dart';
import 'store_actions.dart';

/// The store's flows: install (repository, file, link), update, update all
/// and remove. Each runs its own screen or dialog; the store only calls them.
/// The plugin page flow (open an installed plugin) is not wired here.
StoreActions wiredStoreActions(Ref ref) {
  InstallOps ops() => ref.read(installOpsProvider);
  return StoreActions(
    onInstall: (context, row) => installFromRepository(
      context,
      ops(),
      installId: row.installId,
      name: row.name,
    ),
    onReview: (context, row) => reviewPluginUpdate(
      context,
      ops(),
      installId: row.installId,
      name: row.name,
    ),
    onUpdate: (context, row) => updatePlugin(
      context,
      ops(),
      ref.read(updateFailuresProvider.notifier),
      installId: row.installId,
      name: row.name,
    ),
    onUpdateAll: (context) => updateAllPlugins(context, ops()),
    onRemove: (context, row) => removePluginFlow(context, ops(), row.installId),
    onInstallFromFile: (context) =>
        installFromFile(context, ops(), ref.read(documentPickerProvider)),
    onInstallFromLink: (context) => installFromLink(context, ops()),
  );
}
