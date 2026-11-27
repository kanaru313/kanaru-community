import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../platform/state/document_picker_provider.dart';
import '../../../plugins/state/install_ops.dart';
import '../../../plugins/state/store_view_models.dart';
import '../install/link_install_dialog.dart';
import '../install/package_flow.dart';
import '../plugin_paths.dart';
import '../remove/remove_flow.dart';
import '../updates/update_actions.dart';
import '../updates/update_failures.dart';

/// What a row or the menu of the store does for the flows that own a whole
/// screen of their own (install, update, remove, the plugin page). A flow
/// that is not wired is null: its control shows disabled. The flows replace
/// [storeActionsProvider]'s value; the store never reaches into them.
class StoreActions {
  const StoreActions({
    this.onOpenPlugin,
    this.onInstall,
    this.onUpdate,
    this.onReview,
    this.onRemove,
    this.onUpdateAll,
    this.onInstallFromFile,
    this.onInstallFromLink,
  });

  /// A tap on an installed row.
  final void Function(BuildContext context, StoreRowView row)? onOpenPlugin;

  /// [Cài] of a not-installed row (not called for a Free streaming limit).
  final void Function(BuildContext context, StoreRowView row)? onInstall;

  /// [Cập nhật] of an update row.
  final void Function(BuildContext context, StoreRowView row)? onUpdate;

  /// [Xem] of an update row that adds hosts or permissions.
  final void Function(BuildContext context, StoreRowView row)? onReview;

  /// The trash button of an installed row.
  final void Function(BuildContext context, StoreRowView row)? onRemove;

  /// "Cập nhật tất cả".
  final void Function(BuildContext context)? onUpdateAll;

  /// "Cài từ tệp…" of the menu and of the guide card.
  final void Function(BuildContext context)? onInstallFromFile;

  /// "Cài từ đường dẫn…" of the menu.
  final void Function(BuildContext context)? onInstallFromLink;
}

final storeActionsProvider = Provider<StoreActions>(_wiredStoreActions);

/// The store's flows: install (repository, file, link), update, update all
/// and remove. Each runs its own screen or dialog; the store only calls them.
/// A tap on an installed row opens its page.
StoreActions _wiredStoreActions(Ref ref) {
  InstallOps ops() => ref.read(installOpsProvider);
  return StoreActions(
    onOpenPlugin: (context, row) =>
        unawaited(context.push(PluginPaths.plugin(row.installId))),
    onInstall: (context, row) => installFromRepository(
      context,
      ops(),
      installId: row.installId,
      name: row.name,
      kind: row.kind,
    ),
    onReview: (context, row) => reviewPluginUpdate(
      context,
      ops(),
      installId: row.installId,
      name: row.name,
      kind: row.kind,
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
