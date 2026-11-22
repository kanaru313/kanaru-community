import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../plugins/state/store_view_models.dart';

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

final storeActionsProvider = Provider<StoreActions>(
  (ref) => const StoreActions(),
);
