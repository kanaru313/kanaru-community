/// Outcome of adding a music folder. Refusals are values: the caller shows
/// a message and never has an exception to handle.
sealed class AddFolderResult {
  const AddFolderResult();
}

/// The folder is now chosen; [revived] when it came back after being removed.
final class FolderAdded extends AddFolderResult {
  const FolderAdded({required this.revived});
  final bool revived;
}

final class FolderAlreadyChosen extends AddFolderResult {
  const FolderAlreadyChosen();
}

/// The path is `/` or empty.
final class FolderTooBroad extends AddFolderResult {
  const FolderTooBroad();
}

/// The path lies inside the chosen folder [root].
final class FolderInsideExisting extends AddFolderResult {
  const FolderInsideExisting(this.root);
  final String root;
}

/// The path contains the chosen folder [root].
final class FolderContainsExisting extends AddFolderResult {
  const FolderContainsExisting(this.root);
  final String root;
}

final class FolderNotADirectory extends AddFolderResult {
  const FolderNotADirectory();
}

final class FolderWriteFailed extends AddFolderResult {
  const FolderWriteFailed();
}

/// Outcome of excluding a sub-folder of a music folder.
enum ExcludeFolderResult {
  excluded,

  /// The path is not strictly inside the music folder.
  outsideFolder,
  alreadyExcluded,
  writeFailed,
}

/// A live exclusion, with the music folder it belongs to.
class ExclusionEntry {
  const ExclusionEntry({
    required this.sourceId,
    required this.folderKey,
    required this.displayPath,
  });

  final int sourceId;
  final String folderKey;

  /// The absolute path that was excluded (the screen shortens it).
  final String displayPath;

  @override
  bool operator ==(Object other) =>
      other is ExclusionEntry &&
      other.sourceId == sourceId &&
      other.folderKey == folderKey &&
      other.displayPath == displayPath;

  @override
  int get hashCode => Object.hash(sourceId, folderKey, displayPath);
}
