import 'dart:io';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/lyrics/domain/online/lyrics_source.dart';
import 'package:kanaru/src/lyrics/state/online/lyrics_sources_provider.dart';
import 'package:kanaru/src/platform/domain/file_manager.dart';
import 'package:kanaru/src/platform/state/file_manager_provider.dart';
import 'package:kanaru/src/plugins/domain/logs/run_log_event.dart';
import 'package:kanaru/src/plugins/data/run/plugin_pauses.dart';
import 'package:kanaru/src/plugins/state/plugin_logs_provider.dart';
import 'package:kanaru/src/plugins/state/plugin_run_info_provider.dart';
import 'package:kanaru/src/plugins/state/plugin_run_provider.dart';

/// Deletes of the Dữ liệu block, recorded; [fail] makes them throw.
class FakeDataOps implements PluginDataOps {
  final storageCleared = <String>[];
  final lyricsCleared = <String>[];
  bool fail = false;

  @override
  Future<void> clearStorage(String installId) async {
    if (fail) throw StateError('disk');
    storageCleared.add(installId);
  }

  @override
  Future<void> clearSavedLyrics(String providerId) async {
    if (fail) throw StateError('disk');
    lyricsCleared.add(providerId);
  }
}

/// A file manager that records what it was asked to show.
class FakeFileManager implements FileManager {
  final revealed = <String>[];
  bool fails = false;

  @override
  bool get canReveal => true;

  @override
  Future<Result<void, FileManagerError>> reveal(String absolutePath) async {
    revealed.add(absolutePath);
    return fails ? const Err(FileManagerError.failed) : const Ok(null);
  }
}

/// What a plugin's run side shows on its page and log page.
class RunState {
  RunState({
    this.storageBytes = 0,
    this.savedLyrics = SavedLyricsStats.none,
    this.errorsToday = 0,
    this.entries = const [],
    this.pausedUntil,
    this.pauses,
    this.summaryOf,
    this.sources = const [],
    FakeDataOps? ops,
    FakeFileManager? files,
  }) : ops = ops ?? FakeDataOps(),
       files = files ?? FakeFileManager();

  final int storageBytes;
  final SavedLyricsStats savedLyrics;
  final int errorsToday;
  final List<RunLogEvent> entries;
  final DateTime? pausedUntil;

  /// Real pauses (a test that lets one end); [pausedUntil] is then unused.
  final PluginPauses? pauses;

  /// Replaces the fixed log summary (to count reads).
  final Future<PluginLogSummary> Function(String installId)? summaryOf;
  final List<LyricsSource> sources;
  final FakeDataOps ops;
  final FakeFileManager files;

  List<Override> get overrides => [
    pluginDataOpsProvider.overrideWithValue(ops),
    fileManagerProvider.overrideWithValue(files),
    pluginStorageBytesProvider.overrideWith((ref, id) async => storageBytes),
    savedLyricsStatsProvider.overrideWith((ref, id) async => savedLyrics),
    pluginLogSummaryProvider.overrideWith(
      (ref, id) =>
          summaryOf?.call(id) ??
          Future.value((errorsToday: errorsToday, total: entries.length)),
    ),
    pluginLogEntriesProvider.overrideWith(
      (ref, q) async => q.errorsOnly
          ? [
              for (final e in entries)
                if (e.isFailure) e,
            ]
          : entries,
    ),
    pluginLogFolderProvider.overrideWithValue(Directory('/data/plugin-logs')),
    if (pauses != null)
      pluginPausesProvider.overrideWithValue(pauses!)
    else
      pluginPauseProvider.overrideWith((ref, id) => pausedUntil),
    lyricsSourcesProvider.overrideWithValue(sources),
  ];
}

LyricsSource lyricsSource(String id, {bool enabled = true}) => LyricsSource(
  id: id,
  name: id,
  version: 1,
  origin: LyricsSourceOrigin.repo,
  enabled: enabled,
);

/// An entry of the log, [ago] before now.
RunLogEvent logEvent({
  Duration ago = Duration.zero,
  String script = 'search',
  String kind = runLogKindOk,
  String? message,
  List<String> console = const [],
  Object? query,
}) => RunLogEvent(
  time: DateTime.now().subtract(ago),
  installId: 'id-demo',
  pluginName: 'Demo',
  version: '3',
  script: script,
  kind: kind,
  message: message,
  console: console,
  query: query,
);
