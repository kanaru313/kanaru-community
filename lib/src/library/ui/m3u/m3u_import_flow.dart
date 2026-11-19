import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../foundation/result.dart';
import '../../../platform/domain/document_picker.dart';
import '../../../platform/state/document_picker_provider.dart';
import '../../../storage/data/m3u/m3u_document_filter.dart';
import '../../data/m3u/m3u_results.dart';
import '../../state/m3u/m3u_import_progress.dart';
import '../../state/m3u/m3u_providers.dart';
import '../library_locations.dart';
import 'm3u_import_report_dialog.dart';

final _log = Logger('library.m3u');

/// Imports an M3U file: system file dialog, a new playlist named after the
/// file, then either a toast and the playlist page (every line usable) or a
/// report dialog on the current page. Every failure is a toast; nothing is
/// created then. A second start while one runs does nothing.
///
/// Everything after the first await goes through objects captured here (root
/// navigator context, messenger, router, container): the page that started
/// the flow may be gone by then (a menu closes first).
Future<void> runM3uImport(BuildContext context) async {
  final root = Navigator.of(context, rootNavigator: true).context;
  final container = ProviderScope.containerOf(context, listen: false);
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(root);
  final router = GoRouter.of(root);
  final busy = container.read(m3uImportBusyProvider.notifier);
  if (!busy.tryBegin()) return;
  try {
    await _import(root, container, l10n, messenger, router);
  } finally {
    busy.end();
  }
}

void _toast(ScaffoldMessengerState messenger, String message) {
  // A messenger whose app was torn down mid-flow is gone: nothing to show.
  if (messenger.mounted) showAppSnackBarOn(messenger, message);
}

Future<void> _import(
  BuildContext root,
  ProviderContainer container,
  AppLocalizations l10n,
  ScaffoldMessengerState messenger,
  GoRouter router,
) async {
  final PickedDocument? doc;
  try {
    doc = await container
        .read(documentPickerProvider)
        .openDocument(m3uDocumentFilter(label: l10n.playlistM3uFileTypes));
  } on DocumentPickerException catch (e, st) {
    // Another dialog of the app is open: the tap is simply ignored.
    if (e.failure == DocumentPickerFailure.busy) return;
    _log.warning('M3U file dialog failed', e, st);
    _toast(messenger, l10n.m3uImportFailed);
    return;
  }
  if (doc == null) return;

  final progress = container.read(m3uImportProgressProvider.notifier);
  progress.begin(doc.name);
  Result<M3uImportResult, M3uImportError>? result;
  Object? failure;
  StackTrace? failureStack;
  try {
    result = await container
        .read(m3uImportServiceProvider)
        .importDocument(
          doc,
          fallbackName: l10n.playlistDefaultName,
          onProgress: progress.update,
        );
  } on Object catch (e, st) {
    failure = e;
    failureStack = st;
  } finally {
    // Before the toast or the report, so the card never sits next to them.
    progress.end();
  }

  if (failure != null) {
    _log.severe('M3U import failed', failure, failureStack);
    _toast(messenger, l10n.m3uImportFailed);
    return;
  }
  switch (result!) {
    case Err(:final error):
      _toast(messenger, _errorText(l10n, error));
    case Ok(:final value):
      if (!root.mounted) return;
      await _showOutcome(root, l10n, messenger, router, value);
  }
}

String _errorText(AppLocalizations l10n, M3uImportError error) =>
    switch (error) {
      M3uImportError.tooLarge => l10n.playlistM3uTooLarge,
      M3uImportError.notAFile ||
      M3uImportError.unreadable => l10n.playlistM3uReadFailed,
      M3uImportError.nothingFound => l10n.playlistM3uNothingFound,
      M3uImportError.allOutsideFolders => l10n.playlistM3uAllOutside,
      M3uImportError.notIndexed => l10n.m3uImportNotIndexed,
    };

Future<void> _showOutcome(
  BuildContext root,
  AppLocalizations l10n,
  ScaffoldMessengerState messenger,
  GoRouter router,
  M3uImportResult r,
) async {
  final location = LibraryLocations.playlist(r.playlistUid);
  if (r.clean) {
    router.push<void>(location).ignore();
    _toast(messenger, l10n.playlistM3uImported(r.songsAdded, r.name));
    return;
  }
  final open = await showM3uImportReport(root, r);
  if (open && root.mounted) router.push<void>(location).ignore();
}
