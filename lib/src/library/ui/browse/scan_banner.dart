import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/scan_status.dart';
import '../../state/scan_providers.dart';

/// Thin line under the sub-tabs while a scan runs: what it is doing and, once
/// known, how far it is. Nothing is drawn otherwise. The progress bar is
/// determinate only, so it never animates on its own.
class ScanBanner extends ConsumerWidget {
  const ScanBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(scanStatusProvider).value;
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    if (status is ScanFailed && status.kind == 'permission') {
      return _PermissionBanner(l10n: l10n);
    }
    if (status is! ScanRunning) return const SizedBox.shrink();
    final known = status.total > 0;
    final text = switch (status.phase) {
      ScanPhase.listing => l10n.libraryScanning,
      ScanPhase.tags =>
        known
            ? l10n.libraryScanningTags(status.done, status.total)
            : l10n.libraryScanningTagsCount(status.done),
      ScanPhase.covers =>
        known
            ? l10n.libraryScanningCovers(status.done, status.total)
            : l10n.libraryScanningCoversStart,
    };
    final showBar = known && status.phase != ScanPhase.listing;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: KSpace.x1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (showBar) ...[
              const KGap(KSpace.x1),
              ClipRRect(
                borderRadius: KRadius.full,
                child: LinearProgressIndicator(
                  value: (status.done / status.total).clamp(0.0, 1.0),
                  minHeight: 3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Music permission is missing (Android): a thin error line above the list,
/// which keeps showing the songs already known. The grant button is dimmed
/// until the app can ask for the permission from here.
class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KSpace.x1),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: KRadius.sm,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KSpace.x3,
            vertical: KSpace.x1,
          ),
          child: Row(
            children: [
              Icon(KIcons.permission, size: 18, color: scheme.onErrorContainer),
              const KGap(KSpace.x2),
              Expanded(
                child: Text(
                  l10n.libraryPermissionMissing,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(color: scheme.onErrorContainer),
                ),
              ),
              Tooltip(
                message: l10n.appComingSoon,
                child: TextButton(
                  onPressed: null,
                  child: Text(l10n.libraryGrantPermission),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
