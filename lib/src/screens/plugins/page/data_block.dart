import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/domain/package/plugin_kind.dart';
import '../../../plugins/state/plugin_logs_provider.dart';
import '../../../plugins/state/plugin_run_info_provider.dart';
import '../../../plugins/state/plugin_run_provider.dart'
    show pluginPauseProvider;
import '../../settings/ui/soon_row.dart';
import '../plugin_paths.dart';
import 'confirm_delete_dialog.dart';

/// "Dữ liệu": what the plugin keeps and the way to its log. The own-storage
/// row is for every plugin, the saved-lyrics row for lyrics plugins; each
/// [Xoá] asks first and is dimmed (not hidden) when there is nothing. The
/// track cache of music sources is not built yet and stays dimmed "Sắp có".
class DataBlock extends ConsumerWidget {
  const DataBlock({super.key, required this.installId, required this.kind});

  final String installId;
  final PluginKind? kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final storage = ref.watch(pluginStorageBytesProvider(installId));
    final lyrics = kind == PluginKind.lyrics
        ? ref.watch(savedLyricsStatsProvider(installId))
        : null;
    // A pause starts when a run failed with a 429: that run just logged.
    ref.listen(
      pluginPauseProvider(installId),
      (_, _) => ref.invalidate(pluginLogSummaryProvider(installId)),
    );
    final log = ref.watch(pluginLogSummaryProvider(installId));
    final bytes = storage.value;
    final saved = lyrics?.value;
    return SetupSection(
      title: Text(l10n.pluginsPageData),
      children: [
        _DataRow(
          title: l10n.pluginsPageOwnStorage,
          value: bytes == null
              ? null
              : l10n.pluginsDataStorageValue(
                  (bytes / 1024).ceil(),
                  pluginStorageQuotaKb,
                ),
          canClear: (bytes ?? 0) > 0,
          onClear: () => _clear(
            context,
            ref,
            title: l10n.pluginsDataClearStorageTitle,
            body: l10n.pluginsDataClearStorageBody,
            done: l10n.pluginsDataStorageCleared,
            run: ref.read(pluginDataOpsProvider).clearStorage,
          ),
        ),
        if (kind == PluginKind.lyrics)
          _DataRow(
            title: l10n.pluginsPageSavedLyrics,
            value: saved == null
                ? null
                : saved.count == 0
                ? l10n.pluginsDataSavedLyricsNone
                : l10n.pluginsDataSavedLyricsValue(
                    saved.count,
                    _size(saved.bytes, Localizations.localeOf(context)),
                  ),
            canClear: (saved?.count ?? 0) > 0,
            onClear: () => _clear(
              context,
              ref,
              title: l10n.pluginsDataClearLyricsTitle,
              body: l10n.pluginsDataClearLyricsBody,
              done: l10n.pluginsDataLyricsCleared,
              run: ref.read(pluginDataOpsProvider).clearSavedLyrics,
            ),
          ),
        if (kind == PluginKind.streaming)
          SoonRow(
            icon: KIcons.musicFile,
            title: Text(l10n.pluginsPageTrackCache),
          ),
        SetupValueRow(
          title: Text(l10n.pluginsPageLog),
          value: Text(
            log.value == null
                ? ''
                : log.value!.errorsToday == 0
                ? l10n.pluginsDataLogNoErrors
                : l10n.pluginsDataLogSummary(
                    log.value!.errorsToday,
                    log.value!.total,
                  ),
          ),
          onTap: () async {
            await context.push(PluginPaths.pluginLogs(installId));
            if (!context.mounted) return;
            // The log may have been cleared or have grown meanwhile.
            ref.invalidate(pluginLogSummaryProvider(installId));
          },
        ),
      ],
    );
  }

  /// Asks, deletes, and says how it went. The messenger is taken before the
  /// dialog: the page may be gone when the delete ends.
  Future<void> _clear(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String body,
    required String done,
    required Future<void> Function(String installId) run,
  }) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmLabel = l10n.pluginsDataClear;
    final failed = l10n.pluginsDataClearFailed;
    final ok = await confirmDelete(
      context,
      title: title,
      body: body,
      confirmLabel: confirmLabel,
    );
    if (!ok) return;
    var succeeded = true;
    try {
      await run(installId);
    } on Object {
      succeeded = false;
    }
    showAppSnackBarOn(messenger, succeeded ? done : failed);
  }
}

/// A static row of the block: title, the value under it, a text [Xoá] at the
/// end. [value] is null while it is still being read.
class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.title,
    required this.value,
    required this.canClear,
    required this.onClear,
  });

  final String title;
  final String? value;
  final bool canClear;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SetupRowFrame(
      title: Text(title),
      subtitle: value == null ? null : Text(value!),
      trailing: TextButton(
        onPressed: canClear ? onClear : null,
        child: Text(l10n.pluginsDataClear),
      ),
    );
  }
}

/// "850 KB" below a megabyte, "1,2 MB" above (decimal comma in Vietnamese).
String _size(int bytes, Locale locale) {
  final tag = locale.toLanguageTag();
  if (bytes < 1024 * 1024) {
    return '${NumberFormat('#,##0', tag).format((bytes / 1024).ceil())} KB';
  }
  return '${NumberFormat('#,##0.#', tag).format(bytes / (1024 * 1024))} MB';
}
