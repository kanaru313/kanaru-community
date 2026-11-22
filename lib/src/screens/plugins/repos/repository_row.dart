import 'dart:async';

import 'package:flutter/services.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/state/store_view_models.dart';
import '../common/plugin_labels.dart';

/// One repository: icon (a "!" on `errorContainer` after a failed fetch),
/// name, its address as entered, then the number of plugins or the red error
/// line with [Thử lại]; the trash button asks to remove it. A long press (or
/// a right click) copies the address exactly as stored.
class RepositoryRow extends StatelessWidget {
  const RepositoryRow({
    super.key,
    required this.repo,
    required this.onRetry,
    required this.onRemove,
  });

  final RepoView repo;
  final VoidCallback onRetry;
  final VoidCallback onRemove;

  Future<void> _copyAddress(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (FormFactor.of(context) == FormFactor.mobile) {
      unawaited(HapticFeedback.lightImpact());
    }
    try {
      await Clipboard.setData(ClipboardData(text: repo.url));
    } on PlatformException {
      return;
    }
    if (messenger.mounted) {
      showAppSnackBarOn(messenger, l10n.pluginsRepoAddressCopied);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final failed = repo.errorKind != null;
    final reason = failed
        ? l10n.pluginsRepoLastError(repoLoadReason(l10n, repo.errorKind))
        : null;
    return SetupRowFrame(
      onLongPress: () => unawaited(_copyAddress(context)),
      onSecondaryTap: () => unawaited(_copyAddress(context)),
      longPressLabel: l10n.pluginsRepoCopyAddress,
      leading: SizedBox.square(
        dimension: KIconSize.lg,
        child: failed
            ? Semantics(
                label: reason,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.errorContainer,
                    borderRadius: KRadius.xs,
                  ),
                  child: Center(
                    child: ExcludeSemantics(
                      child: Text(
                        '!',
                        style: text.titleMedium?.copyWith(
                          color: scheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : const Icon(KIcons.repository),
      ),
      title: Text(repo.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            repo.url,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: KFont.mono,
              fontFamilyFallback: KFont.monoFallback,
            ),
          ),
          if (failed) ...[
            Text(reason!, style: TextStyle(color: scheme.error)),
            RowGestureShield(
              child: TextButton(
                onPressed: onRetry,
                child: Text(l10n.pluginsRetry),
              ),
            ),
          ] else
            Text(l10n.pluginsRepoPluginCount(repo.pluginCount)),
        ],
      ),
      trailing: KIconButton(
        icon: KIcons.delete,
        tooltip: l10n.pluginsRepoRemoveTooltip(repo.name),
        onPressed: onRemove,
      ),
    );
  }
}
