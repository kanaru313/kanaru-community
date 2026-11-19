import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../foundation/result.dart';
import '../../../platform/domain/document_picker.dart';
import '../../../platform/state/document_picker_provider.dart';
import '../../../storage/data/m3u/m3u_document_filter.dart';
import '../../../storage/domain/m3u/m3u_limits.dart';
import '../../../storage/domain/m3u/m3u_text.dart';
import '../../data/m3u/m3u_results.dart';
import '../../state/m3u/m3u_providers.dart';
import '../../state/playlists/playlist_providers.dart';
import '../playlist_common/playlist_labels.dart';

final _log = Logger('library.m3u');

/// Characters a file name cannot hold on some platform.
final _pathChars = RegExp(r'[/\\:*?"<>|]');

/// Exports playlist [playlistUid] to an M3U file the user picks the place of.
/// [relative] writes paths relative to the file's folder (needs a known
/// folder; refused with a toast otherwise). Every outcome is a toast. A
/// second start while one runs does nothing.
Future<void> runM3uExport(
  BuildContext context,
  String playlistUid, {
  required bool relative,
}) async {
  final root = Navigator.of(context, rootNavigator: true).context;
  final container = ProviderScope.containerOf(context, listen: false);
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(root);
  final busy = container.read(m3uExportBusyProvider.notifier);
  if (!busy.tryBegin()) return;
  try {
    await _export(root, container, l10n, messenger, playlistUid, relative);
  } finally {
    busy.end();
  }
}

void _toast(ScaffoldMessengerState messenger, String message) {
  if (messenger.mounted) showAppSnackBarOn(messenger, message);
}

/// `<display name>.m3u8`: control / direction characters and path separators
/// replaced, cut to [m3uNameMaxLength] graphemes; the default name when
/// nothing is left.
String suggestedM3uFileName(String displayName, String fallback) {
  var stem = displayName
      .replaceAll(m3uUnsafeTextChars, ' ')
      .replaceAll(_pathChars, '_')
      .trim();
  stem = stem.characters.take(m3uNameMaxLength).toString().trim();
  return '${stem.isEmpty ? fallback : stem}.m3u8';
}

Future<void> _export(
  BuildContext root,
  ProviderContainer container,
  AppLocalizations l10n,
  ScaffoldMessengerState messenger,
  String uid,
  bool relative,
) async {
  final picker = container.read(documentPickerProvider);
  SaveTarget? target;
  try {
    final summary =
        (await container.read(playlistStoreProvider).loadPlaylist(uid))
            ?.summary;
    if (summary == null) {
      _toast(messenger, l10n.playlistM3uExportFailed);
      return;
    }
    target = await picker.createDocument(
      suggestedName: suggestedM3uFileName(
        playlistDisplayName(l10n, summary),
        l10n.playlistDefaultName,
      ),
      filter: m3uDocumentFilter(label: l10n.playlistM3uFileTypes),
    );
  } on DocumentPickerException catch (e, st) {
    if (e.failure == DocumentPickerFailure.busy) return;
    _log.warning('M3U save dialog failed', e, st);
    _toast(messenger, l10n.playlistM3uExportFailed);
    return;
  } on Object catch (e, st) {
    _log.severe('M3U export failed before writing', e, st);
    _toast(messenger, l10n.playlistM3uExportFailed);
    return;
  }
  if (target == null) return;

  if (target.exists) {
    if (!root.mounted) return;
    final replace = await confirmAction(
      root,
      title: l10n.playlistM3uReplaceTitle(target.name),
      confirmLabel: l10n.m3uExportReplace,
      destructive: true,
    );
    if (!replace) return;
  }

  final Result<M3uExportResult, M3uExportError> result;
  try {
    result = await container
        .read(m3uExportServiceProvider)
        .exportPlaylist(uid, target, relative: relative);
  } on Object catch (e, st) {
    _log.severe('M3U export failed', e, st);
    // The service already gave the target up.
    _toast(messenger, l10n.playlistM3uExportFailed);
    return;
  }
  switch (result) {
    case Ok(:final value):
      _toast(
        messenger,
        value.skipped > 0
            ? l10n.m3uExportedSkipped(value.written, target.name, value.skipped)
            : l10n.playlistM3uExported(value.written, target.name),
      );
    case Err(:final error):
      _toast(
        messenger,
        error == M3uExportError.folderUnknown
            ? l10n.m3uExportFolderUnknown
            : l10n.playlistM3uExportFailed,
      );
  }
}
