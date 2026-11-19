import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

final _log = Logger('storage.m3u');

/// Most missing levels walked up before giving up on a lexical path.
const _maxAncestorWalk = 32;

/// A canonical folder path, and whether looking it up timed out.
typedef M3uFolder = ({String path, bool stalled});

/// [path] without trailing slashes; `/` stays `/`.
String trimTrailingSlashes(String path) {
  var end = path.length;
  while (end > 1 && path[end - 1] == '/') {
    end--;
  }
  return path.substring(0, end);
}

/// File-system questions of the resolver, each bounded by [timeout] so a dead
/// network mount cannot hold the import. A folder that timed out is
/// remembered: later files in it are not looked up again. The memory is per
/// folder, so a dead mount holding many folders still costs one timeout per
/// batch of new folders (known limit).
class M3uFsProbe {
  M3uFsProbe({
    required this.canonicalize,
    required this.stat,
    required this.timeout,
  });

  final Future<String> Function(String) canonicalize;
  final Future<FileSystemEntityType> Function(String) stat;
  final Duration timeout;

  final _folders = <String, Future<M3uFolder>>{};
  final _stalledFolders = <String>{};

  /// The type at [path]; null when the lookup timed out.
  Future<FileSystemEntityType?> _type(String path) async {
    try {
      return await stat(path).timeout(timeout);
    } on TimeoutException {
      return null;
    } on FileSystemException {
      return FileSystemEntityType.notFound;
    }
  }

  /// [folder] with links resolved, memoised. A folder that does not exist
  /// gets the canonical form of its nearest existing ancestor plus the
  /// missing names, so a deleted folder reached through a link still lands
  /// inside the canonical root.
  Future<M3uFolder> folder(String folder) => _folderAt(folder, 0);

  Future<M3uFolder> _folderAt(String folder, int up) =>
      _folders.putIfAbsent(folder, () => _resolveFolder(folder, up));

  Future<M3uFolder> _resolveFolder(String folder, int up) async {
    M3uFolder lexical(bool stalled) {
      if (stalled) _log.warning('file system timed out under $folder');
      return (
        path: trimTrailingSlashes(p.posix.normalize(folder)),
        stalled: stalled,
      );
    }

    final type = await _type(folder);
    if (type == null) return lexical(true);
    if (type == FileSystemEntityType.notFound) {
      final norm = trimTrailingSlashes(p.posix.normalize(folder));
      if (norm != trimTrailingSlashes(folder)) return _folderAt(norm, up);
      final parent = p.posix.dirname(norm);
      if (parent == norm) return (path: norm, stalled: false);
      // A hostile deep path must not cost one stat per level.
      if (up >= _maxAncestorWalk) return lexical(false);
      final above = await _folderAt(parent, up + 1);
      final base = p.posix.basename(norm);
      return (
        path: above.path == '/' ? '/$base' : '${above.path}/$base',
        stalled: above.stalled,
      );
    }
    try {
      final path = await canonicalize(folder).timeout(timeout);
      return (path: trimTrailingSlashes(path), stalled: false);
    } on TimeoutException {
      return lexical(true);
    } on Exception catch (error) {
      _log.fine('canonicalize failed for $folder: $error');
      return lexical(false);
    }
  }

  /// Whether [path] (inside canonical [folder]) is a regular file. A folder
  /// already known to hang answers false without a lookup.
  Future<bool> isFile(String path, M3uFolder folder) async {
    if (folder.stalled || _stalledFolders.contains(folder.path)) return false;
    final type = await _type(path);
    if (type == null && _stalledFolders.add(folder.path)) {
      _log.warning('stat timed out in ${folder.path}');
    }
    return type == FileSystemEntityType.file;
  }
}
