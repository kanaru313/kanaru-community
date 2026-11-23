import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/domain/package/plugin_kind.dart';
import '../../../plugins/state/install_ops.dart';
import '../../../plugins/state/plugin_run_info_provider.dart';
import 'remove_plugin_dialog.dart';

/// Asks, removes plugin [installId], and says how it went ("Đã xoá {tên}" /
/// "Không xoá được {tên}"). Always asked; the dialog shows the size of the
/// plugin's own storage and, for a lyrics plugin, the lyrics saved from it.
/// [onBeforeRemove] runs after the user confirmed and before the delete
/// starts: the plugin page uses it to go blank while its files go. True when
/// the plugin is gone.
Future<bool> removePluginFlow(
  BuildContext context,
  InstallOps ops,
  String installId, {
  VoidCallback? onBeforeRemove,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final container = ProviderScope.containerOf(context, listen: false);
  final preview = await ops.removePreview(installId);
  if (preview == null || !context.mounted) return false;
  final storageBytes = await _readOr(
    container.read(pluginStorageBytesProvider(installId).future),
    0,
  );
  final saved = preview.kind == PluginKind.lyrics
      ? await _readOr(
          container.read(savedLyricsStatsProvider(installId).future),
          SavedLyricsStats.none,
        )
      : SavedLyricsStats.none;
  if (!context.mounted) return false;
  final confirmed = await showKDialog<bool>(
    context,
    builder: (_) => RemovePluginDialog(
      preview: preview,
      storageKb: (storageBytes / 1024).ceil(),
      savedLyrics: saved.count,
    ),
  );
  if (confirmed != true) return false;
  onBeforeRemove?.call();
  final result = await ops.remove(installId);
  final gone =
      result == RemoveResult.removed || result == RemoveResult.alreadyRemoved;
  showAppSnackBarOn(
    messenger,
    gone
        ? l10n.pluginsRemoved(preview.name)
        : l10n.pluginsRemoveFailed(preview.name),
  );
  return gone;
}

/// [read], or [fallback] when it fails: the numbers of the dialog are
/// informative and never stop a remove.
Future<T> _readOr<T>(Future<T> read, T fallback) async {
  try {
    return await read;
  } on Object {
    return fallback;
  }
}
