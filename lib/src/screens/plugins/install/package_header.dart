import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../common/plugin_labels.dart';
import 'package_controller.dart';
import 'package_icon.dart';

/// Icon, title and subtitle of the install / update screen, and its close
/// button. The title follows what is known: the name given by the opener until
/// the package is read, then the manifest.
class PackageHeader extends StatelessWidget {
  const PackageHeader({
    super.key,
    required this.controller,
    required this.subject,
    required this.expectUpdate,
  });

  final PackageController controller;
  final PackageSubject subject;
  final bool expectUpdate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = controller;
    final held = c.held;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final manifest = held?.package.manifest;
    final update = held == null ? expectUpdate : c.isUpdate;
    final name = manifest?.name ?? subject.name;
    final title = held == null && !subject.named
        ? l10n.pluginsPkgLoadingTitle
        : update
        ? l10n.pluginsPkgUpdateTitle(name)
        : l10n.pluginsPkgInstallTitle(name);
    String? subtitle;
    if (manifest != null) {
      final kind = kindPluginLabel(l10n, manifest.kind) ?? '';
      final author = manifest.author.isEmpty
          ? l10n.pluginsAuthorUnknown
          : l10n.pluginsPkgAuthorDeclared(manifest.author);
      subtitle = update
          ? l10n.pluginsPkgUpdateSubtitle(kind, author)
          : l10n.pluginsPkgInstallSubtitle(kind, manifest.version, author);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KSpace.x5,
        KSpace.x4,
        KSpace.x2,
        KSpace.x3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: KSpace.x3,
        children: [
          PackageIcon(kind: manifest?.kind, bytes: held?.package.icon),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: text.titleLarge),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          KIconButton(
            icon: KIcons.close,
            tooltip: l10n.pluginsPkgClose,
            onPressed: c.phase == PackagePhase.working
                ? null
                : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
