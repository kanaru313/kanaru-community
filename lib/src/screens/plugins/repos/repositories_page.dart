import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/state/store_ops.dart';
import '../../../plugins/state/store_view_models.dart';
import '../../settings/ui/settings_scaffold.dart';
import '../plugin_paths.dart';
import 'add_repository_dialog.dart';
import 'remove_repository_dialog.dart';
import 'repository_row.dart';

/// Repository: the repositories the user added, a refresh button in the
/// header and a floating button to add one.
class RepositoriesPage extends ConsumerWidget {
  const RepositoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final repos = ref.watch(repoViewsProvider);
    final ops = ref.read(storeOpsProvider);
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    final gutter = desktop ? KLayout.gutterDesktop : KLayout.gutterMobile;
    final rows = repos.value ?? const <RepoView>[];
    return Stack(
      children: [
        SettingsScaffold(
          title: l10n.pluginsReposTitle,
          parentPath: PluginPaths.store,
          actions: [
            KIconButton(
              icon: KIcons.refresh,
              tooltip: l10n.pluginsReposRefreshAll,
              onPressed: rows.isEmpty
                  ? null
                  : () => unawaited(ops.refreshAll()),
            ),
          ],
          children: [
            if (repos.hasError)
              KInlineNotice(
                icon: KIcons.warning,
                tone: KInlineNoticeTone.errorFilled,
                message: l10n.pluginsLoadFailed,
              )
            else
              SettingsBlock(
                children: [
                  if (rows.isEmpty && repos.hasValue)
                    Padding(
                      padding: const EdgeInsets.all(KSpace.x4),
                      child: Text(
                        l10n.pluginsReposEmpty,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  for (final repo in rows)
                    RepositoryRow(
                      key: ValueKey(repo.id),
                      repo: repo,
                      onRetry: () => unawaited(ops.refresh(repo.id)),
                      onRemove: () => confirmRemoveRepository(context, repo),
                    ),
                ],
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  KIcons.info,
                  size: KIconSize.xs,
                  color: scheme.onSurfaceVariant,
                ),
                const KGap(KSpace.x2),
                Expanded(
                  child: Text(
                    l10n.pluginsReposFooter,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            // The button floats over the list: this keeps the last row clear.
            const SizedBox(height: KFab.listEndPadding - KSpace.x7),
          ],
        ),
        PositionedDirectional(
          end: gutter,
          bottom: MediaQuery.paddingOf(context).bottom + KSpace.x4,
          child: KFab(
            icon: KIcons.add,
            tooltip: l10n.pluginsAddRepository,
            onPressed: () => showAddRepositoryDialog(context),
          ),
        ),
      ],
    );
  }
}
