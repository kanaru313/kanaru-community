import '../../../platform/domain/local_audio_catalog.dart';
import '../../../platform/domain/storage_volumes.dart';
import '../../data/scan/scan_folders.dart';
import '../../domain/scan/folder_paths.dart';
import '../../domain/scan/root_rules.dart';
import 'music_folder_editor.dart';

/// The lists the Android sheets and the first-run subtitles are built from.
/// They come from the folders MediaStore reports (`audioFolders()`, each
/// with the audio it holds directly), with the short-file pre-filter and
/// junk folders already applied by the catalog. Pass [raw] to reuse one
/// MediaStore read for several lists.
extension MusicFolderLists on MusicFolderEditor {
  Future<List<AudioFolderSummary>> _raw(List<AudioFolderSummary>? raw) async =>
      raw ?? await catalog.audioFolders();

  /// Android: folders that can become a music folder: every listed folder and
  /// each of its ancestors below the volume root, with the audio of its whole
  /// subtree, minus chosen folders and folders inside or containing one.
  Future<List<AudioFolderSummary>> folderCandidates({
    List<AudioFolderSummary>? raw,
  }) async {
    final roots = [for (final f in await liveScanFolders(db)) f.root];
    return [
      for (final f in withAncestors(await _raw(raw), volumes))
        if (checkNewRoot(f.path, roots) is RootOk) f,
    ];
  }

  /// Android: folders (with their ancestors, as above) strictly inside a
  /// chosen folder that are not excluded nor inside an excluded one.
  Future<List<AudioFolderSummary>> exclusionCandidates({
    List<AudioFolderSummary>? raw,
  }) async {
    final roots = [
      for (final f in await liveScanFolders(db)) normalizeRootPath(f.root),
    ];
    final excluded = await excludedPaths();
    return [
      for (final f in withAncestors(await _raw(raw), volumes))
        if (roots.any((r) => f.path != r && isSameOrInside(f.path, r)) &&
            !excluded.any((e) => isSameOrInside(f.path, e)))
          f,
    ];
  }

  /// Android: tracks the chosen folders hold, without the excluded parts, as
  /// the scan will keep them. Null where the platform cannot count before a
  /// scan (Linux).
  Future<int?> estimatedTrackCount({List<AudioFolderSummary>? raw}) async {
    if (!isAndroid) return null;
    final roots = [
      for (final f in await liveScanFolders(db)) normalizeRootPath(f.root),
    ];
    final excluded = await excludedPaths();
    var total = 0;
    for (final f in await _raw(raw)) {
      final path = normalizeRootPath(f.path);
      if (roots.any((r) => isSameOrInside(path, r)) &&
          !excluded.any((e) => isSameOrInside(path, e))) {
        total += f.audioCount;
      }
    }
    return total;
  }

  /// Android: tracks under each chosen folder (excluded parts left out) and
  /// under each excluded folder, by absolute path. Null where the platform
  /// cannot count before a scan (Linux).
  Future<Map<String, int>?> subtreeCounts({
    List<AudioFolderSummary>? raw,
  }) async {
    if (!isAndroid) return null;
    final folders = await _raw(raw);
    final excluded = await excludedPaths();
    int under(String base) {
      var total = 0;
      for (final f in folders) {
        final path = normalizeRootPath(f.path);
        if (isSameOrInside(path, base) &&
            (path == base || !excluded.any((e) => isSameOrInside(path, e)))) {
          total += f.audioCount;
        }
      }
      return total;
    }

    return {
      for (final f in await liveScanFolders(db))
        normalizeRootPath(f.root): under(normalizeRootPath(f.root)),
      for (final e in excluded) e: under(e),
    };
  }
}

/// [raw] plus every ancestor of its folders that lies below the volume root
/// (never the volume itself), each with the audio of its whole subtree,
/// ordered by path. A folder on an unknown volume gets no ancestors. One walk
/// up the ancestors of each folder, so it is linear in folders times depth.
List<AudioFolderSummary> withAncestors(
  List<AudioFolderSummary> raw,
  StorageVolumes volumes,
) {
  final counts = <String, int>{};
  for (final f in raw) {
    final path = normalizeRootPath(f.path);
    counts[path] = (counts[path] ?? 0) + f.audioCount;
    final volume = volumes.volumeOf(path);
    if (volume.kind == StorageVolumeKind.other) continue;
    final volumeRoot = normalizeRootPath(volume.root);
    var parent = folderParentPath(path);
    while (parent != '/' &&
        parent != volumeRoot &&
        isSameOrInside(parent, volumeRoot)) {
      counts[parent] = (counts[parent] ?? 0) + f.audioCount;
      parent = folderParentPath(parent);
    }
  }
  return [
    for (final path in counts.keys.toList()..sort())
      AudioFolderSummary(path: path, audioCount: counts[path]!),
  ];
}
