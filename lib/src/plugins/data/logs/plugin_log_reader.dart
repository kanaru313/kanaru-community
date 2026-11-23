import 'dart:io';

import '../../domain/logs/run_log_event.dart';
import 'log_lines.dart';
import 'plugin_run_log.dart';

/// Most entries one read returns.
const runLogReadCap = 500;

/// Reads the run logs for the plugin screens (Nhật ký) and clears them.
class PluginLogReader {
  PluginLogReader(this._log, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final PluginRunLog _log;
  final DateTime Function() _clock;

  /// The folder of the log files ("Mở thư mục nhật ký").
  Directory get logFolder => _log.directory;

  /// The entries of [installId] from both files, newest first, none older
  /// than seven days, at most [runLogReadCap]. Lines that are not events
  /// (corrupt, cut short) are skipped. With [errorsOnly] only failures come
  /// back (a failed run or a caller's refused output); the rest are `ok`
  /// runs that only printed to the console. Waits for the writes queued so
  /// far, so a line half-written is never read.
  Future<List<RunLogEvent>> readLog(
    String installId, {
    bool errorsOnly = false,
  }) async {
    final files = [_log.fileOf(installId), _log.previousFileOf(installId)];
    if (files.any((f) => f == null)) return const [];
    await _log.whenIdle(installId);
    final cutoff = _clock().subtract(_log.maxAge);
    final out = <RunLogEvent>[];
    for (final file in files) {
      for (final line in await readLogLines(file!)) {
        final event = parseLogLine(line);
        if (event == null || !event.time.isAfter(cutoff)) continue;
        if (errorsOnly && !event.isFailure) continue;
        out.add(event);
      }
    }
    out.sort((a, b) => b.time.compareTo(a.time));
    return out.length > runLogReadCap ? out.sublist(0, runLogReadCap) : out;
  }

  /// Deletes the log of [installId] ("Xoá nhật ký"); writes queued before it
  /// are dropped.
  Future<void> clearLog(String installId) => _log.delete(installId);
}
