import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../library/domain/music_folder.dart';
import '../../../library/state/music_folders_providers.dart';
import '../../../library/state/scan/display_volumes_provider.dart';
import '../../../library/state/scan/folder_candidates_provider.dart';
import '../../../library/state/scan/music_folder_editor.dart';
import '../../../library/state/scan/music_folder_editor_provider.dart';
import '../../../library/domain/scan/root_rules.dart';
import '../../../library/ui/scan/folder_display_path.dart';
import '../../../platform/domain/local_audio_catalog.dart';
import '../../../platform/state/local_audio_catalog_provider.dart';

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
/// (Android). Every refusal is a snackbar naming the folder.
Future<void> addMusicFolders(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final editor = ref.read(musicFolderEditorProvider);
  final catalog = ref.read(localAudioCatalogProvider);
  final fromCatalog = catalog.folderChoice == FolderChoice.mediaStoreSheet;
  final List<String> paths;
  try {
    if (fromCatalog) {
      final candidates = await ref.read(folderCandidatesProvider.future);
      if (!context.mounted) return;
      paths = await _pickFromSheet(
        context,
        ref,
        candidates,
        title: l10n.scanSetupFolderPickerTitle,
        hint: l10n.scanSetupFolderPickerHint,
        empty: l10n.scanSetupFolderPickerEmpty,
      );
    } else {
      final path = await catalog.pickFolder();
      paths = [?path];
    }
  } on Object catch (e, st) {
    _log.warning('choosing a music folder failed', e, st);
    if (context.mounted) showAppSnackBar(context, l10n.scanSetupLoadFailed);
    return;
  }
  for (final path in paths) {
    final message = addRefusal(
      l10n,
      path,
      await editor.addFolder(path, fromCatalog: fromCatalog),
    );
    if (message != null && context.mounted) showAppSnackBar(context, message);
  }
}

/// Excludes sub-folders of the chosen music folders, picked the same way.
Future<void> addExclusions(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final editor = ref.read(musicFolderEditorProvider);
  final catalog = ref.read(localAudioCatalogProvider);
  final folders = ref.read(musicFoldersProvider).value ?? const <MusicFolder>[];
  if (folders.isEmpty) return;
  final fromCatalog = catalog.folderChoice == FolderChoice.mediaStoreSheet;
  final List<String> paths;
  try {
    if (fromCatalog) {
      final candidates = await ref.read(exclusionCandidatesProvider.future);
      if (!context.mounted) return;
      paths = await _pickFromSheet(
        context,
        ref,
        candidates,
        title: l10n.scanSetupExclusionPickerTitle,
        hint: l10n.scanSetupExclusionPickerHint,
        empty: l10n.scanSetupExclusionPickerEmpty,
      );
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
  for (final path in paths) {
    final message = excludeRefusal(
      l10n,
      path,
      await editor.excludeInAnyFolder(folders, path, fromCatalog: fromCatalog),
    );
    if (message != null && context.mounted) showAppSnackBar(context, message);
  }
}

Future<List<String>> _pickFromSheet(
  BuildContext context,
  WidgetRef ref,
  List<AudioFolderSummary> candidates, {
  required String title,
  required String hint,
  required String empty,
}) async {
  final l10n = AppLocalizations.of(context);
  final volumes = await ref.read(displayVolumesProvider.future);
  if (!context.mounted) return const [];
  final picked = await showMultiSelectionSheet<String>(
    context,
    options: [
      for (final c in candidates)
        SelectionOption(
          value: c.path,
          leading: const Icon(KIcons.folders),
          title: Text(baseName(c.path)),
          subtitle: Text(
            '${folderDisplayPathOf(l10n, volumes, c.path)} · '
            '${l10n.scanSetupFolderSongs(c.audioCount)}',
          ),
        ),
    ],
    title: Text(title),
    subtitle: Text(hint),
    emptyNote: Text(empty),
    confirmLabel: (n) =>
        n == 0 ? l10n.scanSetupSheetAdd : l10n.scanSetupSheetAddCount(n),
    cancelLabel: l10n.scanSetupSheetCancel,
  );
  return topLevelPicks(picked ?? const <String>{});
}
