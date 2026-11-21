import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';

import 'local_lyrics_reader.dart';

final _log = Logger('lyrics_lrc');

/// Largest `.lrc` file read. Lyrics are a few KiB; anything larger is not a
/// lyrics file worth showing.
const lrcMaxBytes = 1 << 20;

/// How long the stat and read of one `.lrc` may take (a dead network mount
/// would stall them for minutes).
const lrcReadTimeout = Duration(seconds: 5);

/// `errno` values that mean "not for us, for good": EPERM (1) and EACCES (13)
/// on Linux and Android, access denied (5) on Windows. EIO (5 on POSIX) and
/// everything else may pass.
final _permissionDenied = Platform.isWindows ? {5} : {1, 13};

/// Not found: ENOENT (2) everywhere, plus "path not found" (3) on Windows.
final _notFound = Platform.isWindows ? {2, 3} : {2};

/// Reads the bytes of an open file up to [maxBytes] + 1 (one more than the
/// cap, so a file that grew is noticed).
typedef LrcBytesReader = Future<Uint8List> Function(String path, int maxBytes);

Future<Uint8List> readFileBytes(String path, int maxBytes) async {
  final handle = await File(path).open();
  try {
    return await handle.read(maxBytes + 1);
  } finally {
    await handle.close();
  }
}

/// The stat of the regular file at [path] that a `.lrc` read would use: null
/// when there is no such file, it is not a regular file (a FIFO, device or
/// folder is never opened), or it is larger than [maxBytes]. A stat that does
/// not answer within [timeout] is a transient [LyricsReadFailure].
Future<LrcStat?> statLrcFile(
  String path, {
  int maxBytes = lrcMaxBytes,
  Duration timeout = lrcReadTimeout,
  Future<FileStat> Function(String path) statFn = FileStat.stat,
}) async {
  final FileStat stat;
  try {
    stat = await statFn(path).timeout(timeout);
  } on TimeoutException {
    throw const LyricsReadFailure(kind: 'timeout', transient: true);
  } on FileSystemException catch (e) {
    final failure = lrcFailureOf(e);
    if (failure.transient) throw failure;
    return null;
  }
  if (stat.type != FileSystemEntityType.file) return null;
  if (stat.size > maxBytes) {
    _log.info('a .lrc file is larger than the cap and is ignored');
    return null;
  }
  return LrcStat(
    path: path,
    mtimeMs: stat.modified.millisecondsSinceEpoch,
    size: stat.size,
  );
}

/// The `.lrc` file of [stat] (taken by [statLrcFile]: no second stat). Null
/// when it is unreadable for good (permission denied: logged as a kind, never
/// with the path) or grew past [maxBytes]. The read is bounded by [timeout];
/// a stall or another I/O error is a transient [LyricsReadFailure]. A read
/// that outlives the timeout closes its handle when the system call returns.
Future<LrcFile?> readLrcFile(
  LrcStat stat, {
  int maxBytes = lrcMaxBytes,
  Duration timeout = lrcReadTimeout,
  LrcBytesReader readBytes = readFileBytes,
}) async {
  try {
    return await _read(stat, maxBytes, readBytes).timeout(timeout);
  } on TimeoutException {
    throw const LyricsReadFailure(kind: 'timeout', transient: true);
  }
}

Future<LrcFile?> _read(
  LrcStat stat,
  int maxBytes,
  LrcBytesReader readBytes,
) async {
  try {
    final bytes = await readBytes(stat.path, maxBytes);
    if (bytes.length > maxBytes) {
      _log.info('a .lrc file grew past the cap and is ignored');
      return null;
    }
    return LrcFile(stat: stat, bytes: bytes);
  } on FileSystemException catch (e) {
    final failure = lrcFailureOf(e);
    if (!failure.transient) return null;
    throw failure;
  }
}

/// Permission denied and a vanished file are permanent (the file is simply
/// absent for us); every other I/O error, EIO included, may pass.
LyricsReadFailure lrcFailureOf(FileSystemException e) {
  final code = e.osError?.errorCode;
  if (code != null && _permissionDenied.contains(code)) {
    _log.info('a .lrc file is not readable: permission denied');
    return const LyricsReadFailure(kind: 'permissionDenied', transient: false);
  }
  if (code != null && _notFound.contains(code)) {
    return const LyricsReadFailure(kind: 'notFound', transient: false);
  }
  return const LyricsReadFailure(kind: 'io', transient: true);
}

/// What identifies one `.lrc` read: path, mtime and size (the stat the cache
/// key uses), so a read that started before an edit is never shared with one
/// after it.
String lrcReadKey(LrcStat stat) => '${stat.path}|${stat.mtimeMs}|${stat.size}';

/// Joins callers of the same key onto one running call, so a dead mount
/// holds at most one stuck stat and one stuck read per path. The entry stays
/// until the underlying call really ends, however many callers timed out.
class PathFlights<T> {
  final _running = <String, Future<T>>{};

  Future<T> join(String path, Future<T> Function() start) {
    final running = _running[path];
    if (running != null) return running;
    final call = start();
    _running[path] = call;
    // Block bodies: `remove` returns the (maybe failed) future, which the
    // derived future would otherwise adopt as an unhandled error.
    void forget() {
      _running.remove(path);
    }

    call.then<void>((_) => forget(), onError: (Object _) => forget());
    return call;
  }
}
