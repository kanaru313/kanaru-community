import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../foundation/result.dart';
import '../../../media/domain/track_id.dart';
import '../../../platform/domain/document_picker.dart';
import '../../../platform/state/document_picker_provider.dart';
import '../../../storage/data/m3u/m3u_document_filter.dart';
import '../../../storage/domain/m3u/m3u_limits.dart';
import '../../../storage/domain/m3u/m3u_text.dart';
import '../../data/m3u/m3u_export_service.dart';
import '../../data/m3u/m3u_results.dart';
import '../../state/m3u/m3u_providers.dart';
import '../../state/playlists/playlist_providers.dart';
import '../playlist_common/playlist_labels.dart';

final _log = Logger('library.m3u');

/// Characters a file name cannot hold on some platform.
final _pathChars = RegExp(r'[/\\:*?"<>|]');

/// What one export writes: the name its file is suggested under and the
/// write itself (which knows whether paths are relative).
class _ExportSource {
  const _ExportSource({
    required this.name,
    required this.fallback,
    required this.write,
  });

  final String name;
  final String fallback;
  final Future<Result<M3uExportResult, M3uExportError>> Function(
    M3uExportService service,
    SaveTarget target,
  )
  write;
}

/// Exports playlist [playlistUid] to an M3U file the user picks the place of.
/// [relative] writes paths relative to the file's folder (needs a known
/// folder; refused with a toast otherwise). Every outcome is a toast. A
/// second start while one runs does nothing.
Future<void> runM3uExport(
  BuildContext context,
  String playlistUid, {
  required bool relative,
}) => _run(context, (container, l10n) async {
  final summary =
      (await container.read(playlistStoreProvider).loadPlaylist(playlistUid))
          ?.summary;
  if (summary == null) return null;
  return _ExportSource(
    name: playlistDisplayName(l10n, summary),
    fallback: l10n.playlistDefaultName,
    write: (service, target) =>
        service.exportPlaylist(playlistUid, target, relative: relative),
  );
});

/// Exports a list of songs that is not a playlist (Most played, History) in
/// the order [tracks] gives, under the file name [name]; otherwise as
/// [runM3uExport]. [tracks] is read when the export starts (the list can be
/// long and the menu opens without it); no song at all says so in a toast.
/// [fallback] names the file when [name] has nothing a file name can hold.
Future<void> runM3uTrackListExport(
  BuildContext context, {
  required String name,
  required String fallback,
  required Future<List<TrackId>> Function() tracks,
  required bool relative,
}) => _run(context, (container, l10n) async {
  final ids = await tracks();
  if (ids.isEmpty) throw const _NothingToExport();
  return _ExportSource(
    name: name,
    fallback: fallback,
    write: (service, target) =>
        service.exportTracks(ids, target, relative: relative),
  );
});

/// The list to export has no song (it emptied since the menu opened).
class _NothingToExport implements Exception {
  const _NothingToExport();
}

Future<void> _run(
  BuildContext context,
  Future<_ExportSource?> Function(
    ProviderContainer container,
    AppLocalizations l10n,
  )
  source,
) async {
  final root = Navigator.of(context, rootNavigator: true).context;
  final container = ProviderScope.containerOf(context, listen: false);
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(root);
  final busy = container.read(m3uExportBusyProvider.notifier);
  if (!busy.tryBegin()) return;
  try {
    await _export(root, container, l10n, messenger, source);
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
  Future<_ExportSource?> Function(ProviderContainer, AppLocalizations) load,
) async {
  final picker = container.read(documentPickerProvider);
  SaveTarget? target;
  _ExportSource? source;
  try {
    source = await load(container, l10n);
    if (source == null) {
      _toast(messenger, l10n.playlistM3uExportFailed);
      return;
    }
    target = await picker.createDocument(
      suggestedName: suggestedM3uFileName(source.name, source.fallback),
      filter: m3uDocumentFilter(label: l10n.playlistM3uFileTypes),
    );
  } on _NothingToExport {
    _toast(messenger, l10n.historyNothingToExport);
    return;
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
    result = await source.write(
      container.read(m3uExportServiceProvider),
      target,
    );
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
