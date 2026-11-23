import 'dart:async';

import 'package:logging/logging.dart';

import '../../domain/logs/failure_log_line.dart';
import '../../domain/logs/log_redaction.dart';
import '../../domain/logs/run_log_event.dart';
import '../../domain/logs/run_log_limits.dart';
import '../../domain/run/plugin_engine.dart';
import '../../domain/run/run_outcome.dart';
import '../../domain/run/run_request.dart';
import '../logs/plugin_run_log.dart';
import '../store/plugin_config_store.dart';
import '../store/plugin_rows.dart';
import '../store/plugin_storage_store.dart';
import 'fetch_handler.dart';
import 'run_setup.dart';

final _applog = Logger('plugin_run');

/// Turns the end of a run into a run log event: picks what is worth writing,
/// builds the event, redacts it and hands it to the [PluginRunLog] without
/// waiting. A failed run also gets one INFO line in the app log.
class RunLogRecorder {
  RunLogRecorder({
    required this._log,
    required this._rows,
    required this._config,
    required this._storage,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final PluginRunLog _log;
  final PluginRows _rows;
  final PluginConfigStore _config;
  final PluginStorageStore _storage;
  final DateTime Function() _clock;

  /// Notes a run that ended with [outcome] (the engine's [result] when it
  /// answered). Written: a failed run, and a run that only printed to the
  /// console. Never throws.
  void recordRun({
    required PluginRunRequest request,
    required PreparedRun prepared,
    required JobContext context,
    required RunOutcome outcome,
    EngineResult? result,
  }) {
    try {
      final console = result?.logs ?? const <String>[];
      final kind = _kindOf(outcome, hasConsole: console.isNotEmpty);
      if (kind == null) return;
      final redactor = LogRedactor(
        schema: prepared.configSchema,
        storedConfig: prepared.storedConfig,
        configAppend: request.configAppend.values,
        storageJsons: [prepared.storageJson, ?result?.storageJson],
        headerSecrets: context.maskValues,
        hiddenInput: request.logInput ? null : request.input,
      );
      final jsError = result?.jsError;
      final event = RunLogEvent(
        time: _clock(),
        installId: request.installId,
        pluginName: prepared.pluginName,
        version: prepared.pluginVersion,
        script: request.script,
        query: request.logInput ? request.input : null,
        kind: kind,
        message: _firstText([
          result?.errorMessage,
          jsError?.message,
          _fetchFailureOf(outcome)?.message,
        ]),
        stack: _firstText([jsError?.stack]),
        console: console,
        requests: context.requests,
      );
      _log.append(capRunLogEvent(redactor.apply(event)));
      if (kind == runLogKindOk) return;
      final blocked =
          _fetchFailureOf(outcome)?.kind == FetchFailureKind.blockedHost
          ? context.requests.where((r) => r.blocked).firstOrNull?.host
          : null;
      _applog.info(
        failureLogLine(
          pluginName: prepared.pluginName,
          installId: request.installId,
          script: request.script,
          kind: kind,
          blockedHost: blocked == null ? null : redactor.text(blocked),
        ),
      );
    } on Object catch (error) {
      _applog.warning('A plugin run was not logged: ${error.runtimeType}');
    }
  }

  /// Notes that a caller refused the output of a run of [script]: one
  /// failure event with the caller's fixed [reason] (never the output). Never
  /// throws; does nothing for a plugin that is not live.
  Future<void> recordRejected(
    String installId,
    String script,
    String reason,
  ) async {
    try {
      // Before the first await: a remove that lands meanwhile drops the event.
      final deletions = _log.deletionsOf(installId);
      final row = await _rows.liveById(installId);
      final manifest = row == null ? null : _rows.manifestOf(row);
      if (row == null || manifest == null) return;
      final stored = await _config.read(installId);
      final kept = await _storage.read(installId);
      final redactor = LogRedactor(
        schema: manifest.config,
        storedConfig: stored.values,
        storageJsons: [kept.json],
      );
      final event = RunLogEvent(
        time: _clock(),
        installId: installId,
        pluginName: row.name,
        version: row.version.toString(),
        script: script,
        kind: runLogKindInvalidResponse,
        message: reason,
      );
      _log.append(
        capRunLogEvent(redactor.apply(event)),
        deletionsAtStart: deletions,
      );
    } on Object catch (error) {
      _applog.warning('A rejected output was not logged: ${error.runtimeType}');
    }
  }
}

/// The log kind of [outcome]; null for the ones that are not written (the
/// run was cancelled, did not start, or ended well without console output).
String? _kindOf(RunOutcome outcome, {required bool hasConsole}) =>
    switch (outcome) {
      RunOk() => hasConsole ? runLogKindOk : null,
      RunScriptError(:final kind) => kind.name,
      RunFailed(:final reason) => reason.name,
      RunCancelled() ||
      RunBusy() ||
      RunPaused() ||
      RunNeedsConfig() ||
      RunUnavailable() => null,
    };

FetchFailureInfo? _fetchFailureOf(RunOutcome outcome) => switch (outcome) {
  RunOk(:final fetchFailure) => fetchFailure,
  RunScriptError(:final fetchFailure) => fetchFailure,
  RunFailed(:final fetchFailure) => fetchFailure,
  _ => null,
};

String? _firstText(List<String?> texts) =>
    texts.where((t) => t != null && t.isNotEmpty).firstOrNull;
