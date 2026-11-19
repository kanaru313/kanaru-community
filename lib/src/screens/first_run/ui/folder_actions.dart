import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../library/domain/music_folder.dart';
import '../../../library/domain/scan_status.dart';
import '../../../library/state/music_folders_providers.dart';
import '../../../library/state/scan/music_folder_editor.dart';
import '../../../library/state/scan/music_folder_editor_provider.dart';
import '../../../library/state/scan_providers.dart';
import '../../../library/domain/scan/root_rules.dart';
import '../../../platform/domain/local_audio_catalog.dart';
import '../../../platform/state/local_audio_catalog_provider.dart';
import 'folder_picker_sheet.dart';
import 'setup_mode.dart';

final _log = Logger('screens.first_run');

String baseName(String path) {
  final trimmed = path.length > 1 && path.endsWith('/')
      ? path.substring(0, path.length - 1)
      : path;
  final name = trimmed.substring(trimmed.lastIndexOf('/') + 1);
  // `/` has no last segment: name the path itself.
  return name.isEmpty ? path : name;
}

/// [picked] without the paths that lie inside another picked path, parents
/// first, so the result does not depend on the order the user tapped.
List<String> topLevelPicks(Iterable<String> picked) {
  final sorted = picked.toList()..sort((a, b) => a.length - b.length);
  final kept = <String>[];
  for (final path in sorted) {
    if (!kept.any((k) => isSameOrInside(path, k))) kept.add(path);
  }
  return kept;
}

/// The message for a refused or failed add, or null when it worked.
String? addRefusal(AppLocalizations l10n, String path, AddFolderResult r) {
  final folder = baseName(path);
  return switch (r) {
    FolderAdded() => null,
    FolderAlreadyChosen() => l10n.scanSetupRefusedAlreadyChosen(folder),
    FolderTooBroad() => l10n.scanSetupRefusedTooBroad(folder),
    FolderNotADirectory() => l10n.scanSetupRefusedNotFolder(folder),
    FolderInsideExisting(:final root) => l10n.scanSetupRefusedInside(
      folder,
      baseName(root),
    ),
    FolderContainsExisting(:final root) => l10n.scanSetupRefusedContains(
      folder,
      baseName(root),
    ),
    FolderWriteFailed() => l10n.scanSetupWriteFailed,
  };
}

/// The message for a refused or failed exclusion, or null when it worked.
String? excludeRefusal(
  AppLocalizations l10n,
  String path,
  ExcludeFolderResult r,
) => switch (r) {
  ExcludeFolderResult.excluded => null,
  ExcludeFolderResult.outsideFolder => l10n.scanSetupRefusedOutside(
    baseName(path),
  ),
  ExcludeFolderResult.alreadyExcluded => l10n.scanSetupRefusedAlreadyExcluded(
    baseName(path),
  ),
  ExcludeFolderResult.writeFailed => l10n.scanSetupWriteFailed,
};

/// Adds music folders the way the platform chooses them: the system folder
/// dialog (Linux) or a multi-select sheet of the folders MediaStore found
/// (Android). Every refusal is a snackbar naming the folder. In
/// [SetupMode.settings] a folder that was added starts a background rescan
/// and says so.
Future<void> addMusicFolders(
  BuildContext context,
  WidgetRef ref, {
  SetupMode mode = SetupMode.firstRun,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final editor = ref.read(musicFolderEditorProvider);
  final scan = ref.read(libraryScanCommandsProvider);
  final catalog = ref.read(localAudioCatalogProvider);
  final fromCatalog = catalog.folderChoice == FolderChoice.mediaStoreSheet;
  final List<String> paths;
  try {
    if (fromCatalog) {
      paths = await _pickFromSheet(context, FolderSheetKind.add);
    } else {
      final path = await catalog.pickFolder();
      paths = [?path];
    }
  } on Object catch (e, st) {
    _log.warning('choosing a music folder failed', e, st);
    if (context.mounted) showAppSnackBar(context, l10n.scanSetupLoadFailed);
    return;
  }
  var added = false;
  for (final path in paths) {
    final result = await editor.addFolder(path, fromCatalog: fromCatalog);
    added |= result is FolderAdded;
    final message = addRefusal(l10n, path, result);
    if (message != null && context.mounted) showAppSnackBar(context, message);
  }
  if (added && mode == SetupMode.settings) {
    rescanInBackground(scan);
    showAppSnackBarOn(messenger, l10n.settingsLibraryRescanning);
  }
}

/// Excludes sub-folders of the chosen music folders, picked the same way. In
/// [SetupMode.settings] an exclusion that was added starts a background
/// rescan and says so.
Future<void> addExclusions(
  BuildContext context,
  WidgetRef ref, {
  SetupMode mode = SetupMode.firstRun,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final editor = ref.read(musicFolderEditorProvider);
  final scan = ref.read(libraryScanCommandsProvider);
  final catalog = ref.read(localAudioCatalogProvider);
  final folders = ref.read(musicFoldersProvider).value ?? const <MusicFolder>[];
  if (folders.isEmpty) return;
  final fromCatalog = catalog.folderChoice == FolderChoice.mediaStoreSheet;
  final List<String> paths;
  try {
    if (fromCatalog) {
      paths = await _pickFromSheet(context, FolderSheetKind.exclude);
    } else {
      final path = await catalog.pickFolder(
        initialDirectory: folders.first.root,
      );
      paths = [?path];
    }
  } on Object catch (e, st) {
    _log.warning('choosing an excluded folder failed', e, st);
    if (context.mounted) showAppSnackBar(context, l10n.scanSetupLoadFailed);
    return;
  }
  var excluded = false;
  for (final path in paths) {
    final result = await editor.excludeInAnyFolder(
      folders,
      path,
      fromCatalog: fromCatalog,
    );
    excluded |= result == ExcludeFolderResult.excluded;
    final message = excludeRefusal(l10n, path, result);
    if (message != null && context.mounted) showAppSnackBar(context, message);
  }
  if (excluded && mode == SetupMode.settings) {
    rescanInBackground(scan);
    showAppSnackBarOn(messenger, l10n.settingsLibraryRescanning);
  }
}

/// Asks for a scan without waiting for it: a request that fails is logged, the
/// scan status carries the outcome.
///
/// Takes the commands, not a `WidgetRef`: read them with
/// `ref.read(libraryScanCommandsProvider)` before any await or toast, because
/// a widget ref throws once its page is gone.
void rescanInBackground(LibraryScanCommands commands) {
  unawaited(
    commands.rescan().catchError((Object e, StackTrace st) {
      _log.warning('rescan after a folder change failed', e, st);
    }),
  );
}

/// Settings: removes [folder] after asking, then rescans in the background.
/// The last folder cannot go (a notice says why); a missing [songs] count
/// makes the question skip the number. Nothing is removed when the user
/// cancels.
Future<void> removeMusicFolderChecked(
  BuildContext context,
  WidgetRef ref,
  MusicFolder folder, {
  int? songs,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final folders = ref.read(musicFoldersProvider).value ?? const <MusicFolder>[];
  final editor = ref.read(musicFolderEditorProvider);
  final scan = ref.read(libraryScanCommandsProvider);
  if (folders.length <= 1) {
    await showKDialog<void>(
      context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.settingsLibraryLastFolderTitle),
        content: Text(l10n.settingsLibraryLastFolderBody(folder.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(),
            child: Text(l10n.settingsLibraryGotIt),
          ),
        ],
      ),
    );
    return;
  }
  final ok = await confirmAction(
    context,
    title: l10n.settingsLibraryRemoveFolderTitle(folder.name),
    message: songs == null
        ? l10n.settingsLibraryRemoveFolderBody
        : l10n.settingsLibraryRemoveFolderBodyCount(songs),
    confirmLabel: l10n.settingsLibraryRemoveFolderConfirm,
    destructive: true,
  );
  if (!ok || !context.mounted) return;
  final removed = await editor.removeFolder(folder);
  if (!removed) {
    showAppSnackBarOn(messenger, l10n.scanSetupWriteFailed);
    return;
  }
  rescanInBackground(scan);
  showAppSnackBarOn(
    messenger,
    songs == null
        ? l10n.settingsLibraryFolderRemoved(folder.name)
        : l10n.settingsLibraryFolderRemovedCount(folder.name, songs),
  );
}

/// Opens the folder sheet at once (it loads its own list) and returns the
/// picked paths, without the ones inside another picked path.
Future<List<String>> _pickFromSheet(
  BuildContext context,
  FolderSheetKind kind,
) async {
  final picked = await showKSheet<Set<String>>(
    context,
    builder: (_) => FolderPickerSheet(kind: kind),
  );
  return topLevelPicks(picked ?? const <String>{});
}
