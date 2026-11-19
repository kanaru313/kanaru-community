import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../platform/domain/local_audio_catalog.dart';
import '../../../platform/state/local_audio_catalog_provider.dart';
import '../../domain/scan/folder_list_state.dart';
import '../music_folders_providers.dart';
import 'music_folder_editor_lists.dart';
import 'music_folder_editor_provider.dart';
import 'scan_settings.dart';

/// One MediaStore read of the folders that hold audio (Android), shared by
/// every list below. It is not refreshed by edits (choosing folders does not
/// change what MediaStore holds); a failed read or a media index refresh
/// invalidates it. Counts skip files shorter than the scan's minimum
/// duration, so the estimate follows that setting.
final audioFoldersProvider = FutureProvider.autoDispose<AudioFoldersResult>(
  (ref) => ref
      .watch(localAudioCatalogProvider)
      .audioFolders(minDurationMs: ref.watch(minDurationMsProvider)),
);

/// Re-run the derived lists after an edit of folders or exclusions.
void _afterEdits(Ref ref) {
  ref
    ..watch(folderEditsProvider)
    ..watch(musicFoldersProvider);
}

/// Android: folders that can still be added, for the add sheet, or why there
/// are none to list.
final folderCandidatesProvider = FutureProvider.autoDispose<FolderListState>((
  ref,
) async {
  _afterEdits(ref);
  final raw = await ref.watch(audioFoldersProvider.future);
  final editor = ref.watch(musicFolderEditorProvider);
  return folderListStateOf(
    raw,
    (listed) => editor.folderCandidates(raw: listed),
  );
});

/// Android: sub-folders of the chosen folders that can be excluded, or why
/// there are none to list.
final exclusionCandidatesProvider = FutureProvider.autoDispose<FolderListState>(
  (ref) async {
    _afterEdits(ref);
    final raw = await ref.watch(audioFoldersProvider.future);
    final editor = ref.watch(musicFolderEditorProvider);
    return folderListStateOf(
      raw,
      (listed) => editor.exclusionCandidates(raw: listed),
    );
  },
);

/// Android: "about N tracks" for the chosen folders; null when unknown (read
/// failed or index empty).
final estimatedTrackCountProvider = FutureProvider.autoDispose<int?>((
  ref,
) async {
  _afterEdits(ref);
  final raw = await ref.watch(audioFoldersProvider.future);
  if (raw is! AudioFoldersListed) return null;
  return ref
      .watch(musicFolderEditorProvider)
      .estimatedTrackCount(raw: raw.folders);
});

/// Android: track counts by absolute path for the chosen and excluded
/// folders; null where unknown (read failed or index empty).
final folderCountsProvider = FutureProvider.autoDispose<Map<String, int>?>((
  ref,
) async {
  _afterEdits(ref);
  final raw = await ref.watch(audioFoldersProvider.future);
  if (raw is! AudioFoldersListed) return null;
  return ref.watch(musicFolderEditorProvider).subtreeCounts(raw: raw.folders);
});

/// The platform's suggested music folder in canonical form (so it compares
/// equal to a stored root), or null.
final suggestedFolderProvider = FutureProvider.autoDispose<String?>((
  ref,
) async {
  final catalog = ref.watch(localAudioCatalogProvider);
  final path = await catalog.suggestedMusicFolder();
  return path == null ? null : catalog.canonicalize(path);
});
