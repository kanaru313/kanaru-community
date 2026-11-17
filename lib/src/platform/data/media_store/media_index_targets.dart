import '../../domain/local_audio_catalog.dart';
import '../../domain/storage_volumes.dart';

/// Lists the sub-directories (full paths) of a directory; empty when it cannot
/// be read.
typedef ListChildDirs = Future<List<String>> Function(String dir);

String _name(String path) => path.substring(path.lastIndexOf('/') + 1);

/// `Music` and `Download` (ASCII case-insensitive) come first: a scan that
/// hits its time limit has then covered the folders that matter most.
int _priority(String path) {
  final name = _name(path).toLowerCase();
  return name == 'music' ? 0 : (name == 'download' ? 1 : 2);
}

/// Directories to hand to the system media scanner: the top-level folders of
/// each volume in [volumeRoots] (skipping `Android` and junk / dot folders;
/// `Music` and `Download` of every volume before any other folder),
/// then the chosen [folders] that no target already covers. No target lies
/// inside another.
Future<List<String>> mediaIndexTargets({
  required List<String> volumeRoots,
  required List<String> folders,
  required ListChildDirs listChildDirs,
}) async {
  final targets =
      <String>[
        for (final root in volumeRoots)
          for (final dir in await listChildDirs(root))
            if (_name(dir) != 'Android' && !isSkippedFolderName(_name(dir)))
              dir,
      ]..sort((a, b) {
        final byPriority = _priority(a).compareTo(_priority(b));
        return byPriority != 0 ? byPriority : a.compareTo(b);
      });
  for (final folder in folders) {
    final covered = targets.any((t) => isPathInside(folder, t));
    if (covered) continue;
    // A chosen folder that holds earlier targets replaces them.
    targets.removeWhere((t) => isPathInside(t, folder));
    targets.add(folder);
  }
  return targets;
}
