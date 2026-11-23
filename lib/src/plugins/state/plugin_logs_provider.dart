import 'dart:io';
import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/logs/log_lines.dart';
import '../data/logs/plugin_log_reader.dart' show runLogReadCap;
import '../data/logs/plugin_run_log.dart';
import '../domain/logs/run_log_event.dart';
import 'plugin_actions_provider.dart';
import 'plugin_services_provider.dart';

// Screens read the log entry type through this file, never from `domain/`.
export '../domain/logs/run_log_event.dart' show RunLogEvent, RunLogRequest;

/// Log files bigger than this (both files together) are read and parsed on
/// another isolate, so a full 1 MB log never stalls a frame.
const logIsolateThresholdBytes = 64 * 1024;

/// What the log page lists: the entries (newest first) and which ones to keep.
typedef PluginLogQuery = ({String installId, bool errorsOnly});

/// The entries of one plugin's log, newest first, at most 500, none older
/// than the log's age limit. With `errorsOnly` only failed runs.
final pluginLogEntriesProvider = FutureProvider.autoDispose
    .family<List<RunLogEvent>, PluginLogQuery>(
      (ref, query) => readPluginLog(
        ref.watch(pluginRunLogProvider),
        query.installId,
        errorsOnly: query.errorsOnly,
      ),
    );

/// "N lỗi hôm nay · M mục" of the plugin page: failures of today (local
/// date) and all entries kept.
typedef PluginLogSummary = ({int errorsToday, int total});

final pluginLogSummaryProvider = FutureProvider.autoDispose
    .family<PluginLogSummary, String>((ref, installId) async {
      final all = await ref.watch(
        pluginLogEntriesProvider((installId: installId, errorsOnly: false))
            .future,
      );
      final now = DateTime.now();
      final errorsToday = all
          .where(
            (e) =>
                e.isFailure &&
                e.time.toLocal().year == now.year &&
                e.time.toLocal().month == now.month &&
                e.time.toLocal().day == now.day,
          )
          .length;
      return (errorsToday: errorsToday, total: all.length);
    });

/// The folder that holds the log files ("Mở thư mục log").
final pluginLogFolderProvider = Provider<Directory>(
  (ref) => ref.watch(pluginLogReaderProvider).logFolder,
);

/// Deletes the log of [installId] and refreshes what the screens show.
final pluginLogOpsProvider = Provider<PluginLogOps>(PluginLogOps._);

/// "Xoá nhật ký".
class PluginLogOps {
  PluginLogOps._(this._ref);

  final Ref _ref;

  Future<void> clear(String installId) async {
    await _ref.read(pluginLogReaderProvider).clearLog(installId);
    _ref.invalidate(pluginLogEntriesProvider);
    _ref.invalidate(pluginLogSummaryProvider(installId));
  }
}

/// Reads the entries of [installId] from both log files: newest first, none
/// older than [PluginRunLog.maxAge], at most [runLogReadCap]; lines that are
/// not events are skipped. Waits for queued writes first. A big log is
/// parsed on another isolate.
Future<List<RunLogEvent>> readPluginLog(
  PluginRunLog log,
  String installId, {
  bool errorsOnly = false,
  DateTime Function()? clock,
}) async {
  final files = [log.fileOf(installId), log.previousFileOf(installId)];
  if (files.any((f) => f == null)) return const [];
  await log.whenIdle(installId);
  final paths = [for (final f in files) f!.path];
  final cutoff = (clock ?? DateTime.now)().subtract(log.maxAge);
  final job = (paths: paths, cutoff: cutoff, errorsOnly: errorsOnly);
  var bytes = 0;
  for (final f in files) {
    try {
      bytes += await f!.length();
    } on FileSystemException {
      // A missing file holds nothing.
    }
  }
  if (bytes == 0) return const [];
  return bytes > logIsolateThresholdBytes
      ? Isolate.run(() => _parseFiles(job))
      : _parseFiles(job);
}

typedef _ReadJob = ({List<String> paths, DateTime cutoff, bool errorsOnly});

Future<List<RunLogEvent>> _parseFiles(_ReadJob job) async {
  final out = <RunLogEvent>[];
  for (final path in job.paths) {
    for (final line in await readLogLines(File(path))) {
      final event = parseLogLine(line);
      if (event == null || !event.time.isAfter(job.cutoff)) continue;
      if (job.errorsOnly && !event.isFailure) continue;
      out.add(event);
    }
  }
  out.sort((a, b) => b.time.compareTo(a.time));
  return out.length > runLogReadCap ? out.sublist(0, runLogReadCap) : out;
}
