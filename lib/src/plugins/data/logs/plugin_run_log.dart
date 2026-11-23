import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

import '../../domain/logs/run_log_event.dart';
import '../store/plugin_store_rules.dart';
import 'log_lines.dart';

final _log = Logger('plugin_run_log');

/// Largest size of `<installId>.jsonl` before it moves to `.jsonl.1`, so a
/// plugin's logs stay under twice this.
const runLogMaxBytes = 512 * 1024;

/// Age after which a log line is dropped (at read and at rotation).
const runLogMaxAge = Duration(days: 7);

/// Writes the per-plugin JSON Lines files of [directory] (the caller gives
/// it; this class resolves no data path). A file is `<installId>.jsonl`,
/// appended one event per line through one serial queue per plugin, and moved
/// to `<installId>.jsonl.1` (replacing the older one, dropping lines older
/// than [maxAge]) before it would pass [maxBytes].
///
/// Events arrive already redacted. A write failure is logged once (its type
/// only) and swallowed: a log never fails a run.
class PluginRunLog {
  PluginRunLog(
    this.directory, {
    this.maxBytes = runLogMaxBytes,
    this.maxAge = runLogMaxAge,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Directory directory;
  final int maxBytes;
  final Duration maxAge;
  final DateTime Function() _clock;

  // Writes queue per plugin id.
  final _tails = <String, Future<void>>{};

  // How many times the logs of an id were deleted. A write remembers the
  // number it was queued under and is dropped when the logs were deleted in
  // between; a write queued after the delete (a plugin installed again keeps
  // its id) sees the new number and goes through.
  final _deletions = <String, int>{};
  bool _reportedFailure = false;

  /// The current file of [installId]; null when the id has no install-id
  /// shape (so it can never name another path).
  File? fileOf(String installId) => isInstallIdShape(installId)
      ? File('${directory.path}/$installId.jsonl')
      : null;

  /// The rotated file of [installId].
  File? previousFileOf(String installId) {
    final file = fileOf(installId);
    return file == null ? null : File('${file.path}.1');
  }

  /// Queues [event] for its plugin's file and returns at once. Never throws.
  void append(RunLogEvent event) {
    final file = fileOf(event.installId);
    if (file == null) return;
    final id = event.installId;
    final bytes = utf8.encode('${jsonEncode(event.toJson())}\n');
    final queuedUnder = _deletions[id] ?? 0;
    unawaited(
      _enqueue(id, () async {
        if ((_deletions[id] ?? 0) != queuedUnder) return;
        await _write(file, bytes);
      }),
    );
  }

  /// Deletes both files of [installId] inside its queue. Writes queued before
  /// this call are dropped (neither written nor deleted after), so none can
  /// bring the file back; writes queued after it are written normally. Never
  /// throws.
  Future<void> delete(String installId) {
    final file = fileOf(installId);
    final previous = previousFileOf(installId);
    if (file == null || previous == null) return Future.value();
    _deletions[installId] = (_deletions[installId] ?? 0) + 1;
    return _enqueue(installId, () async {
      for (final f in [file, previous]) {
        try {
          if (await f.exists()) await f.delete();
        } on FileSystemException catch (e) {
          _reportFailure(e);
        }
      }
    });
  }

  /// Deletes the logs of every plugin id that has a file in [directory] and
  /// is not in [liveIds]. Returns how many ids it cleared. Never throws.
  Future<int> deleteOrphans(Set<String> liveIds) async {
    final owners = <String>{};
    try {
      if (!await directory.exists()) return 0;
      await for (final entity in directory.list(followLinks: false)) {
        final owner = _ownerOf(entity.uri.pathSegments.last);
        if (owner != null && !liveIds.contains(owner)) owners.add(owner);
      }
    } on FileSystemException catch (e) {
      _reportFailure(e);
    }
    for (final id in owners) {
      await delete(id);
    }
    return owners.length;
  }

  /// Completes when every write and delete queued so far (for [installId], or
  /// for every plugin) has finished. Runs never wait for it; the reader and
  /// tests do.
  Future<void> whenIdle([String? installId]) async {
    if (installId != null) {
      await (_tails[installId] ?? Future<void>.value());
      return;
    }
    await Future.wait(List.of(_tails.values));
  }

  Future<void> _enqueue(String id, Future<void> Function() job) {
    final previous = _tails[id] ?? Future<void>.value();
    final done = previous.then((_) => job()).catchError((Object e) {
      _reportFailure(e);
    });
    _tails[id] = done;
    return done.whenComplete(() {
      if (identical(_tails[id], done)) _tails.remove(id);
    });
  }

  void _reportFailure(Object e) {
    if (_reportedFailure) return;
    _reportedFailure = true;
    // The type only: the text would carry a path.
    _log.warning('Could not write a plugin log: ${e.runtimeType}');
  }

  Future<void> _write(File file, List<int> bytes) async {
    // A line of its own over the limit would break the size bound.
    if (bytes.length > maxBytes) {
      _reportFailure(const FormatException('log line over the size limit'));
      return;
    }
    try {
      await directory.create(recursive: true);
      final size = await file.exists() ? await file.length() : 0;
      if (size > 0 && size + bytes.length > maxBytes) await _rotate(file);
      await file.writeAsBytes(bytes, mode: FileMode.append, flush: true);
    } on Object catch (e) {
      _reportFailure(e);
    }
  }

  /// Moves the current file to `.1` (the older `.1` goes), keeping only the
  /// lines not older than [maxAge].
  Future<void> _rotate(File file) async {
    final old = File('${file.path}.1');
    final cutoff = _clock().subtract(maxAge);
    final keep = [
      for (final line in await readLogLines(file))
        if (parseLogLine(line)?.time.isAfter(cutoff) ?? false) line,
    ];
    if (await old.exists()) await old.delete();
    if (keep.isNotEmpty) await old.writeAsString('${keep.join('\n')}\n');
    await file.delete();
  }
}

/// The plugin id a log file name belongs to (`<id>.jsonl` or
/// `<id>.jsonl.1`), or null for any other name.
String? _ownerOf(String fileName) {
  for (final suffix in ['.jsonl', '.jsonl.1']) {
    if (fileName.endsWith(suffix)) {
      final id = fileName.substring(0, fileName.length - suffix.length);
      return isInstallIdShape(id) ? id : null;
    }
  }
  return null;
}
