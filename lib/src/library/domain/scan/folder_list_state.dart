import '../../../platform/domain/local_audio_catalog.dart';

/// What the folder lists of the Android sheets and the first-run card show:
/// a failed read, an index with no music, or the candidates. Platform-blind:
/// the UI watches the providers built on it only where folders come from the
/// platform index.
sealed class FolderListState {
  const FolderListState();
}

/// The index could not be read.
final class FolderListLoadFailed extends FolderListState {
  const FolderListLoadFailed();
}

/// The index was read and holds no usable audio.
final class FolderListNoIndexedMusic extends FolderListState {
  const FolderListNoIndexedMusic();
}

/// The index holds music; [candidates] may be empty (everything is chosen).
final class FolderListReady extends FolderListState {
  const FolderListReady(this.candidates);

  final List<AudioFolderSummary> candidates;
}

/// Maps a catalog read to a list state. [candidates] gets the listed folders
/// and runs only for a non-empty listing.
Future<FolderListState> folderListStateOf(
  AudioFoldersResult raw,
  Future<List<AudioFolderSummary>> Function(List<AudioFolderSummary> listed)
  candidates,
) async => switch (raw) {
  AudioFoldersFailed() => const FolderListLoadFailed(),
  AudioFoldersListed(:final folders) when folders.isEmpty =>
    const FolderListNoIndexedMusic(),
  AudioFoldersListed(:final folders) => FolderListReady(
    await candidates(folders),
  ),
};
