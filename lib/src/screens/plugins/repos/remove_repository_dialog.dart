import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/domain/install/repo_results.dart';
import '../../../plugins/state/store_ops.dart';
import '../../../plugins/state/store_view_models.dart';

/// Asks "Gỡ {tên}?" and removes the repository on confirm. The plugins
/// installed from it stay. A failed removal is said in a snack bar.
Future<void> confirmRemoveRepository(
  BuildContext context,
  RepoView repo,
) async {
  final l10n = AppLocalizations.of(context);
  final scheme = Theme.of(context).colorScheme;
  final ops = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(storeOpsProvider);
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await showKDialog<bool>(
    context,
    builder: (context) => AlertDialog(
      title: Text(l10n.pluginsRemoveRepoTitle(repo.name)),
      content: Text(l10n.pluginsRemoveRepoBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.pluginsCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.pluginsRemoveRepoConfirm),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  final result = await ops.remove(repo.id);
  if (result == RepoRemoveResult.failed) {
    showAppSnackBarOn(messenger, l10n.pluginsRemoveRepoFailed(repo.name));
  }
}
