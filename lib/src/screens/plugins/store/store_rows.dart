import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/state/store_filter.dart';
import '../../../plugins/state/store_view_models.dart';
import '../../../plugins/state/updates_provider.dart';
import '../updates/update_failures.dart';
import 'store_actions.dart';
import 'store_row.dart';

/// A row of the Cập nhật block: one button, [Xem] when the update adds hosts
/// or permissions, else [Cập nhật]. A tap on the row opens the update screen.
class UpdateRow extends ConsumerWidget {
  const UpdateRow({super.key, required this.row, required this.actions});

  final StoreRowView row;
  final StoreActions actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final review = row.needsReview;
    final run = review ? actions.onReview : actions.onUpdate;
    final busy = ref.watch(updatingIdsProvider).contains(row.installId);
    final failure = ref.watch(updateFailuresProvider)[row.installId];
    return StoreRowFrame(
      row: row,
      errorLine: failure,
      onTap: actions.onReview == null
          ? null
          : () => actions.onReview!(context, row),
      trailing: FilledButton.tonal(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, KLayout.compactButton),
        ),
        onPressed: run == null || busy ? null : () => run(context, row),
        child: busy
            ? Row(
                mainAxisSize: MainAxisSize.min,
                spacing: KSpace.x2,
                children: [
                  const SizedBox.square(
                    dimension: KIconSize.sm,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  Text(l10n.pluginsUpdating),
                ],
              )
            : Text(review ? l10n.pluginsReview : l10n.pluginsUpdate),
      ),
    );
  }
}

/// A row of the Đã cài block: a tap opens the plugin page, the trash button
/// asks to remove it.
class InstalledRow extends StatelessWidget {
  const InstalledRow({super.key, required this.row, required this.actions});

  final StoreRowView row;
  final StoreActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final remove = actions.onRemove;
    return StoreRowFrame(
      row: row,
      onTap: actions.onOpenPlugin == null
          ? null
          : () => actions.onOpenPlugin!(context, row),
      trailing: KIconButton(
        icon: KIcons.delete,
        color: Theme.of(context).colorScheme.error,
        tooltip: l10n.pluginsRemoveTooltip(row.name),
        onPressed: remove == null ? null : () => remove(context, row),
      ),
    );
  }
}

/// A row of the Chưa cài block with its [Cài] button. A second streaming
/// plugin under the Free rule opens nothing: it says why in one line.
class AvailableRow extends StatelessWidget {
  const AvailableRow({super.key, required this.row, required this.actions});

  final StoreRowView row;
  final StoreActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final blocked = row.state == StoreItemState.locked;
    final install = actions.onInstall;
    final VoidCallback? run = blocked
        ? () => showAppSnackBar(context, l10n.pluginsFreeStreamingLimit)
        : install == null
        ? null
        : () => install(context, row);
    return StoreRowFrame(
      row: row,
      onTap: run,
      trailing: KIconButton(
        icon: KIcons.download,
        color: Theme.of(context).colorScheme.primary,
        tooltip: l10n.pluginsInstallTooltip(row.name),
        onPressed: run,
      ),
    );
  }
}
