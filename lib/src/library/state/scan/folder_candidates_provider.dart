import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../platform/domain/local_audio_catalog.dart';
import '../../../platform/state/local_audio_catalog_provider.dart';
import '../music_folders_providers.dart';
import 'music_folder_editor_lists.dart';
import 'music_folder_editor_provider.dart';

/// One MediaStore read of the folders that hold audio (Android), shared by
/// every list below. It is not refreshed by edits: choosing folders does not
/// change what MediaStore holds.
final audioFoldersProvider =
    FutureProvider.autoDispose<List<AudioFolderSummary>>(
      (ref) => ref.watch(localAudioCatalogProvider).audioFolders(),
    );

/// Re-run the derived lists after an edit of folders or exclusions.
void _afterEdits(Ref ref) {
  ref
    ..watch(folderEditsProvider)
    ..watch(musicFoldersProvider);
}

/// Android: folders that can still be added, for the add sheet.
final folderCandidatesProvider =
    FutureProvider.autoDispose<List<AudioFolderSummary>>((ref) async {
      _afterEdits(ref);
      final raw = await ref.watch(audioFoldersProvider.future);
      return ref.watch(musicFolderEditorProvider).folderCandidates(raw: raw);
    });

/// Android: sub-folders of the chosen folders that can be excluded.
final exclusionCandidatesProvider =
    FutureProvider.autoDispose<List<AudioFolderSummary>>((ref) async {
      _afterEdits(ref);
      final raw = await ref.watch(audioFoldersProvider.future);
      return ref.watch(musicFolderEditorProvider).exclusionCandidates(raw: raw);
    });

/// Android: "about N tracks" for the chosen folders; null when unknown.
final estimatedTrackCountProvider = FutureProvider.autoDispose<int?>((
  ref,
) async {
  _afterEdits(ref);
  final raw = await ref.watch(audioFoldersProvider.future);
  return ref.watch(musicFolderEditorProvider).estimatedTrackCount(raw: raw);
});

/// Android: track counts by absolute path for the chosen and excluded
/// folders; null where unknown.
final folderCountsProvider = FutureProvider.autoDispose<Map<String, int>?>((
  ref,
) async {
  _afterEdits(ref);
  final raw = await ref.watch(audioFoldersProvider.future);
  return ref.watch(musicFolderEditorProvider).subtreeCounts(raw: raw);
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
