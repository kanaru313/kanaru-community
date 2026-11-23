import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../platform/state/file_manager_provider.dart';
import '../../../plugins/state/plugin_logs_provider.dart';
import '../../../plugins/state/plugin_page_provider.dart';
import '../../settings/ui/settings_scaffold.dart';
import '../page/confirm_delete_dialog.dart';
import '../page/plugin_page_notice.dart';
import '../plugin_paths.dart';
import 'log_rows.dart';

/// "Nhật ký" of one plugin: chips [Tất cả | Lỗi], what the log holds and how
/// it is kept, the entries newest first, and where the file is. The header
/// has the way to the log folder (desktop) or the share button (phone, "Sắp
/// có") and 🗑 to clear the log.
class PluginLogsPage extends ConsumerStatefulWidget {
  const PluginLogsPage({super.key, required this.installId});

  final String installId;

  @override
  ConsumerState<PluginLogsPage> createState() => _PluginLogsPageState();
}

class _PluginLogsPageState extends ConsumerState<PluginLogsPage> {
  bool _errorsOnly = false;

  PluginLogQuery get _query =>
      (installId: widget.installId, errorsOnly: _errorsOnly);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    final entries = ref.watch(pluginLogEntriesProvider(_query));
    return SettingsScaffold(
      title: l10n.pluginsLogsTitle,
      parentPath: PluginPaths.plugin(widget.installId),
      actions: [
        if (desktop)
          KIconButton(
            icon: KIcons.folderOpen,
            tooltip: l10n.pluginsLogsOpenFolder,
            onPressed: () => unawaited(_openFolder()),
          )
        else
          // The share sheet is not built yet: dimmed, "Sắp có" in the tooltip.
          KIconButton(
            icon: KIcons.fileExport,
            tooltip: l10n.pluginsLogsShareSoon(l10n.appComingSoon),
            onPressed: null,
          ),
        KIconButton(
          icon: KIcons.delete,
          tooltip: l10n.pluginsLogsClear,
          onPressed: () => unawaited(_clear()),
        ),
      ],
      children: [
        _Filter(
          errorsOnly: _errorsOnly,
          onChanged: (v) => setState(() => _errorsOnly = v),
        ),
        if (entries.hasError)
          PluginPageNotice(
            icon: KIcons.warning,
            message: l10n.pluginsLogsLoadFailed,
            actionLabel: l10n.pluginsRetry,
            onAction: () => ref.invalidate(pluginLogEntriesProvider(_query)),
          )
        else if (entries.hasValue)
          _Entries(entries: entries.requireValue),
        _Footer(installId: widget.installId),
      ],
    );
  }

  Future<void> _openFolder() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final folder = ref.read(pluginLogFolderProvider);
    final result = await ref.read(fileManagerProvider).reveal(folder.path);
    if (!result.isOk) showAppSnackBarOn(messenger, l10n.pluginsLogsOpenFailed);
  }

  Future<void> _clear() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final name = ref.read(pluginPageProvider(widget.installId)).value?.row.name;
    final ok = await confirmDelete(
      context,
      title: l10n.pluginsLogsClearTitle,
      body: l10n.pluginsLogsClearBody(name ?? ''),
      confirmLabel: l10n.pluginsDataClear,
    );
    if (!ok) return;
    try {
      await ref.read(pluginLogOpsProvider).clear(widget.installId);
      showAppSnackBarOn(messenger, l10n.pluginsLogsCleared);
    } on Object {
      showAppSnackBarOn(messenger, l10n.pluginsDataClearFailed);
    }
  }
}

/// Chips [Tất cả | Lỗi].
class _Filter extends StatelessWidget {
  const _Filter({required this.errorsOnly, required this.onChanged});

  final bool errorsOnly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      container: true,
      label: l10n.pluginsLogsFilterLabel,
      child: Wrap(
        spacing: KSpace.x2,
        runSpacing: KSpace.x2,
        children: [
          KChip(
            label: Text(l10n.pluginsLogsAll),
            selected: !errorsOnly,
            dense: true,
            onTap: () => onChanged(false),
          ),
          KChip(
            label: Text(l10n.pluginsLogsErrors),
            selected: errorsOnly,
            dense: true,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

/// The caption and the card of entries, or the empty state.
class _Entries extends StatelessWidget {
  const _Entries({required this.entries});

  final List<RunLogEvent> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KSpace.x2,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: KSpace.x1),
          child: Text(
            l10n.pluginsLogsCaption,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: KSpace.x9),
            child: Text(
              l10n.pluginsLogsEmpty,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          )
        else
          SettingsBlock(
            children: [
              for (final e in entries) LogEntryRow(event: e, now: now),
            ],
          ),
      ],
    );
  }
}

/// "Giữ 7 ngày gần nhất (tối đa 1 MB mỗi plugin). Tệp: …".
class _Footer extends ConsumerWidget {
  const _Footer({required this.installId});

  final String installId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final folder = ref.watch(pluginLogFolderProvider).path;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: KSpace.x1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: KSpace.x2,
        children: [
          Icon(KIcons.info, size: KIconSize.xs, color: scheme.onSurfaceVariant),
          Expanded(
            child: Text(
              l10n.pluginsLogsFooter('$folder/$installId.jsonl'),
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
