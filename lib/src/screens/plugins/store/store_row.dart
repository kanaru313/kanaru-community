import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/state/store_view_models.dart';
import '../common/plugin_icon.dart';
import '../common/plugin_labels.dart';

/// The frame every store row shares: icon, name, kind and author tags, an
/// optional short status, then [trailing]. No description, no version.
class StoreRowFrame extends StatelessWidget {
  const StoreRowFrame({
    super.key,
    required this.row,
    this.trailing,
    this.onTap,
    this.errorLine,
  });

  final StoreRowView row;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// A red line under the tags (a failed update).
  final String? errorLine;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final kind = kindLabel(l10n, row.kind);
    final note = _noteText(l10n, row.note);
    return SetupRowFrame(
      leading: PluginIcon(
        installId: row.installId,
        kind: row.kind,
        alerted: row.alerted,
      ),
      title: Text(row.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const KGap(KSpace.x1),
          Wrap(
            spacing: KSpace.x2,
            runSpacing: KSpace.x1,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (kind != null) KChip.tag(label: Text(kind)),
              KChip.tag(
                label: Text(
                  row.author.isEmpty ? l10n.pluginsAuthorUnknown : row.author,
                ),
                outlined: true,
              ),
              if (note != null) Text(note),
            ],
          ),
          if (errorLine != null)
            Padding(
              padding: const EdgeInsets.only(top: KSpace.x1),
              child: Text(errorLine!, style: TextStyle(color: scheme.error)),
            ),
        ],
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  static String? _noteText(AppLocalizations l10n, StoreRowNote note) =>
      switch (note) {
        StoreRowNote.none => null,
        StoreRowNote.reinstallFromFile => l10n.pluginsNoteReinstallFile,
        StoreRowNote.proRequired => l10n.pluginsNoteProRequired,
        StoreRowNote.packageMissing => l10n.pluginsNotePackageMissing,
      };
}
