import 'music_folder.dart';

/// Folders hidden from the library, per [MusicFolder].
abstract interface class FolderExclusions {
  /// Excludes [folderKey] of [folder] and hides its tracks now (no question
  /// asked: the UI shows a toast with undo).
  Future<void> exclude(
    MusicFolder folder,
    String folderKey, {
    required String displayPath,
  });

  /// Undo: removes the exclusion; the rows come back after the next scan
  /// (one is requested).
  Future<void> include(MusicFolder folder, String folderKey);

  Stream<List<({String folderKey, String displayPath})>> watch(
    MusicFolder folder,
  );
}
