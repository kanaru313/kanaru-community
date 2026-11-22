import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../repos/add_repository_dialog.dart';
import 'store_actions.dart';

/// "Chưa có repository nào": what a repository is and the three steps to add
/// one, with [Thêm repository] and [Cài từ tệp…].
class NoRepositoryCard extends StatelessWidget {
  const NoRepositoryCard({super.key, required this.actions});

  final StoreActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final steps = [
      l10n.pluginsNoRepoStep1,
      l10n.pluginsNoRepoStep2,
      l10n.pluginsNoRepoStep3,
    ];
    return Material(
      color: scheme.surfaceContainerLow,
      shape: KShape.of(KRadius.lg),
      child: Padding(
        padding: const EdgeInsets.all(KSpace.x6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(
                KIcons.repository,
                size: KIconSize.hero,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const KGap(KSpace.x3),
            Center(
              child: Text(l10n.pluginsNoRepoTitle, style: text.titleMedium),
            ),
            const KGap(KSpace.x2),
            Text(
              l10n.pluginsNoRepoBody,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const KGap(KSpace.x4),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: KSpace.x2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: KSpace.x6,
                      child: Text('${i + 1}.', style: text.bodyMedium),
                    ),
                    Expanded(child: Text(steps[i], style: text.bodyMedium)),
                  ],
                ),
              ),
            const KGap(KSpace.x3),
            Wrap(
              spacing: KSpace.x2,
              runSpacing: KSpace.x2,
              children: [
                FilledButton.icon(
                  onPressed: () => showAddRepositoryDialog(context),
                  icon: const Icon(KIcons.add),
                  label: Text(l10n.pluginsAddRepository),
                ),
                OutlinedButton(
                  onPressed: actions.onInstallFromFile == null
                      ? null
                      : () => actions.onInstallFromFile!(context),
                  child: Text(l10n.pluginsMenuInstallFile),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "Không có plugin khớp." with [Xoá bộ lọc] while a search or a filter is on.
class NoMatchNotice extends StatelessWidget {
  const NoMatchNotice({super.key, required this.onClear});

  /// Null when nothing is filtered: there is nothing to clear.
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KSpace.x7),
      child: Column(
        children: [
          Text(
            l10n.pluginsNoMatch,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (onClear != null)
            TextButton(
              onPressed: onClear,
              child: Text(l10n.pluginsClearFilters),
            ),
        ],
      ),
    );
  }
}

/// "n plugin cần Kanaru mới hơn" and the sandbox sentence.
class StoreFooter extends StatelessWidget {
  const StoreFooter({super.key, required this.newerAppCount});

  final int newerAppCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: scheme.onSurfaceVariant);
    return Column(
      children: [
        if (newerAppCount > 0) ...[
          Text(
            l10n.pluginsFooterNewer(newerAppCount),
            style: style,
            textAlign: TextAlign.center,
          ),
          const KGap(KSpace.x3),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              KIcons.sandbox,
              size: KIconSize.xs,
              color: scheme.onSurfaceVariant,
            ),
            const KGap(KSpace.x2),
            Expanded(child: Text(l10n.pluginsSandboxNote, style: style)),
          ],
        ),
      ],
    );
  }
}
