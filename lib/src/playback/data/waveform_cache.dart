import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../domain/waveform.dart';
import 'waveform_codec.dart';

final _log = Logger('waveform_cache');

const _extension = '.kwf';

/// A temporary file older than this was abandoned.
const _staleTemp = Duration(hours: 1);

/// Cache key of a file version: changes with the path, size or mtime.
String waveformCacheKey(String path, int size, int mtimeMs) =>
    sha1.convert(utf8.encode('$path\u0000$size\u0000$mtimeMs')).toString();

/// Waveforms on disk, one tiny file per file version, under one folder.
///
/// Files are written to a temporary name and renamed, so a reader never sees
/// half a file; a damaged file counts as a miss and is replaced. A hit
/// touches the file's mtime, which the sweep uses as "last used".
class WaveformCache {
  WaveformCache(
    this.dir, {
    this.maxFiles = 20000,
    this.keepFiles = 18000,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  /// The clock; a test injects its own.
  final DateTime Function() now;

  /// A negative that came from timeouts is tried again after this long.
  static const timeoutNegativeLife = Duration(days: 7);

  final Directory dir;

  /// The sweep starts above this many files...
  final int maxFiles;

  /// ...and deletes the least recently used down to this many.
  final int keepFiles;

  int _tmpCounter = 0;

  File _file(String key) => File(p.join(dir.path, '$key$_extension'));

  /// The stored result for [key], or null on a miss or a damaged file.
  Future<WaveformResult?> read(String key) async {
    final file = _file(key);
    try {
      final result = decodeWaveform(await file.readAsBytes());
      if (result == null) {
        _log.fine('damaged cache file ignored');
        return null;
      }
      if (result is NoWaveform &&
          result.timedOutAt != null &&
          now().difference(result.timedOutAt!) > timeoutNegativeLife) {
        return null;
      }
      await file.setLastModified(now()).catchError((_) {});
      return result;
    } on PathNotFoundException {
      return null;
    } on FileSystemException catch (e) {
      _log.fine('cache read failed: ${e.osError?.errorCode}');
      return null;
    }
  }

  /// Stores [result] under [key]. A result that is not cached is skipped; a
  /// failing disk is logged by its error code only (paths are personal data).
  Future<void> write(String key, WaveformResult result) async {
    final bytes = encodeWaveform(result);
    if (bytes == null) return;
    final target = _file(key);
    final tmp = File('${target.path}.tmp${_tmpCounter++}');
    try {
      await dir.create(recursive: true);
      await tmp.writeAsBytes(bytes, flush: false);
      await tmp.rename(target.path);
    } on FileSystemException catch (e) {
      _log.warning('cache write failed: ${e.osError?.errorCode}');
      await tmp.delete().catchError((_) => tmp);
    }
  }

  /// Deletes the least recently used files down to [keepFiles] when there are
  /// more than [maxFiles]. Returns how many it deleted.
  Future<int> sweep() async {
    try {
      if (!await dir.exists()) return 0;
      final files = <(File, DateTime)>[];
      final staleBefore = DateTime.now().subtract(_staleTemp);
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File) continue;
        if (entity.path.endsWith(_extension)) {
          files.add((entity, (await entity.stat()).modified));
        } else if (entity.path.contains('$_extension.tmp')) {
          // Left by a write that never finished (a crash between write and
          // rename); a fresh one may still be in flight.
          if ((await entity.stat()).modified.isBefore(staleBefore)) {
            await entity.delete().catchError((_) => entity);
          }
        }
      }
      if (files.length <= maxFiles) return 0;
      files.sort((a, b) => a.$2.compareTo(b.$2));
      final doomed = files.length - keepFiles;
      var deleted = 0;
      for (final (file, _) in files.take(doomed)) {
        try {
          await file.delete();
          deleted++;
        } on FileSystemException {
          // Gone already or locked: the next run tries again.
        }
      }
      return deleted;
    } on FileSystemException catch (e) {
      _log.warning('cache sweep failed: ${e.osError?.errorCode}');
      return 0;
    }
  }
}

/// Size and mtime of [path] for the cache key, or null when it cannot be read.
Future<(int, int)?> statForKey(String path) async {
  try {
    final stat = await File(path).stat();
    if (stat.type != FileSystemEntityType.file) return null;
    return (stat.size, stat.modified.millisecondsSinceEpoch);
  } on FileSystemException {
    return null;
  }
}
