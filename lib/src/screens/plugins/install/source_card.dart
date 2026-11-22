import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/domain/install/held_package.dart';
import '../../../plugins/state/store_ops.dart';
import '../../../plugins/state/store_view_models.dart';

/// Where the package comes from: the repository (name and address), the file
/// (name and size) or the link.
class SourceCard extends ConsumerWidget {
  const SourceCard({super.key, required this.source, required this.size});

  final HeldSource source;

  /// Size of the zip in bytes.
  final int size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final repos = ref.watch(repoViewsProvider).value ?? const <RepoView>[];
    final (icon, title, detail) = switch (source) {
      RepoHeldSource(:final repoUrl) => (
        KIcons.repository,
        l10n.pluginsPkgFromRepo(
          repos.where((r) => r.url == repoUrl).firstOrNull?.name ?? repoUrl,
        ),
        repoUrl,
      ),
      FileHeldSource(:final fileName) => (
        KIcons.installFile,
        l10n.pluginsPkgFromFile(fileName, formatPackageSize(size)),
        null,
      ),
      LinkHeldSource(:final url) => (
        KIcons.installLink,
        l10n.pluginsPkgFromLink,
        url,
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: KRadius.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(KSpace.x3),
        child: Row(
          spacing: KSpace.x3,
          children: [
            Icon(icon, size: KIconSize.md, color: scheme.onSurfaceVariant),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (detail != null)
                    Text(
                      detail,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A package size as the screen writes it: whole KB, at least 1.
String formatPackageSize(int bytes) =>
    '${(bytes / 1024).ceil().clamp(1, 1 << 30)} KB';
