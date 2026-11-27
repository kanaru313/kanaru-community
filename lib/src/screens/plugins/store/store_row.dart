import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../ai/domain/output/chat_readiness.dart';
import '../../../ai/state/chat_providers.dart';
import '../../../plugins/domain/package/plugin_kind.dart';
import '../../../plugins/state/store_filter.dart';
import '../../../plugins/state/store_view_models.dart';
import '../common/plugin_icon.dart';
import '../common/plugin_labels.dart';

/// The frame every store row shares: icon, name, kind and author tags, an
/// then [trailing]. No description, no version.
class StoreRowFrame extends ConsumerWidget {
  const StoreRowFrame({
    super.key,
    required this.row,
    this.trailing,
    this.onTap,
    this.errorLine,
    this.showSetupStatus = false,
  });

  final StoreRowView row;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// A red line under the tags (a failed update).
  final String? errorLine;

  /// Shows what the plugin still needs ("Cần API key"); only the Đã cài
  /// block asks for it.
  final bool showSetupStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final kind = kindLabel(l10n, row.kind);
    final status = _chatStatus(l10n, ref);
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
          KTagRow(
            fixed: [if (kind != null) KChip.tag(label: Text(kind))],
            shrinking: [
              KChip.tag(
                label: Text(
                  row.author.isEmpty ? l10n.pluginsAuthorUnknown : row.author,
                ),
                outlined: true,
              ),
              if (status != null)
                Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
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

  /// "Cần API key" for an installed AI chat plugin whose key field is empty
  /// (the same answer the chat composer uses); null for everything else.
  String? _chatStatus(AppLocalizations l10n, WidgetRef ref) {
    final installed =
        row.state == StoreItemState.installed ||
        row.state == StoreItemState.updateAvailable;
    if (!showSetupStatus || !installed || row.kind != PluginKind.aiChat) {
      return null;
    }
    final plugins = ref.watch(chatPluginsProvider).value;
    final info = plugins
        ?.where((p) => p.installId == row.installId)
        .firstOrNull;
    final readiness = info?.readiness;
    return readiness is ChatNeedsKey ? l10n.aiSetServiceNeedsKey : null;
  }
}
