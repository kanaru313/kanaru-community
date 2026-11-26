import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';

import '../../domain/net/cancel_token.dart';
import '../../domain/net/plugin_fetch_rules.dart';
import '../../domain/run/plugin_engine.dart';
import '../../domain/run/run_failure_mapping.dart';
import '../../domain/run/run_outcome.dart';
import '../../domain/run/run_request.dart';
import '../store/plugin_config_store.dart';
import '../store/plugin_files.dart';
import '../store/plugin_rows.dart';
import '../store/plugin_storage_store.dart';
import 'fetch_handler.dart';
import 'plugin_pauses.dart';
import 'run_admission.dart';
import 'run_cancel.dart';
import 'run_gate.dart';
import 'run_log_recorder.dart';
import 'run_dispatch_support.dart';
import 'run_setup.dart';
import 'stream_dispatch.dart';
import 'stream_fetch_handler.dart';
import 'stream_table.dart';

export 'run_dispatch_support.dart' show maxRunWall;

final _log = Logger('plugin_run');

/// Time the runtime gets after the run wall before the runner gives up on it.
const outerDeadlineGrace = Duration(seconds: 30);

/// The pause after a rate-limited run that gave no wait of its own.
const defaultRatePause = Duration(seconds: 60);

/// Runs one script of one installed plugin and says how it ended; the one
/// door to the plugin runtime for lyrics, translation and later streaming.
///
/// Order of a run: gate (waits while the plugin is being switched), pause,
/// row / package / settings, required settings, admission slot, engine, outcome
/// mapping, pause from the outcome. Nothing throws out of [run].
class PluginRunner {
  PluginRunner({
    required this._engine,
    required this._handler,
    required this._gate,
    required this._pauses,
    required this._rows,
    required this._files,
    required this._config,
    required this._storage,
    required this._recorder,
    RunAdmission? admission,
    RunAdmission? streamAdmission,
    this._streamHandler,
    this._streamTables = StreamTable.new,
    this.spacing = pluginSpacing,
    this.grace = outerDeadlineGrace,
    this._streamWait = streamAdmissionWait,
    this._settle = streamSettle,
  }) : _admission = admission ?? RunAdmission(),
       _streamAdmission = streamAdmission ?? RunAdmission(slots: 1);

  final PluginEngine _engine;
  final PluginFetchHandler _handler;
  final RunGate _gate;
  final PluginPauses _pauses;
  final PluginRows _rows;
  final PluginFiles _files;
  final PluginConfigStore _config;
  final PluginStorageStore _storage;
  final RunLogRecorder _recorder;
  final RunAdmission _admission;

  /// The one slot of streaming runs. Owned by the app (a provider nothing
  /// rebuilds), so a rebuilt runner still sees a stream that is running.
  final RunAdmission _streamAdmission;

  /// Null: a streaming request ends `RunFailed(internal)`.
  final StreamFetchHandler? _streamHandler;
  final StreamTableFactory _streamTables;
  final Duration spacing;
  final Duration grace;

  /// Longest wait of a streaming run for its slot.
  final Duration _streamWait;

  /// Time after the outer deadline before a stream job the runtime has not
  /// released is given up on (see [streamSettle]).
  final Duration _settle;
  bool _engineReset = false;

  /// Runs [request]. Waits for the plugin's gate and for a runtime slot; a
  /// [cancel] ends the wait (`RunCancelled(caller)`, nothing started) or stops
  /// the running job.
  Future<RunOutcome> run(PluginRunRequest request, {RunCancel? cancel}) async {
    try {
      while (true) {
        final lease = await _gate.enter(request.installId, cancel: cancel);
        if (lease == null) return const RunCancelled(RunCancelReason.caller);
        try {
          final outcome = await _attempt(request, cancel, lease);
          if (outcome != null) return outcome;
        } finally {
          lease.release();
        }
        // The plugin was switched before dispatch: start over on the new row.
      }
    } on Object catch (error) {
      _log.warning('A plugin run failed: ${error.runtimeType}');
      return const RunFailed(RunFailReason.internal);
    }
  }

  /// A caller's reader or validator refused a [RunOk] output. One app log
  /// line and one run log event with the plugin, the script and the caller's
  /// fixed [reason]; the output itself is never written.
  void reportRejectedOutput(String installId, String script, String reason) {
    _log.info(
      'Plugin output rejected: plugin=$installId script=$script reason=$reason',
    );
    _lastRejection = _recorder.recordRejected(installId, script, reason);
    unawaited(_lastRejection);
  }

  var _lastRejection = Future<void>.value();

  /// Completes when the run log work of the latest [reportRejectedOutput]
  /// call has finished (the event is queued for its file). For tests; callers
  /// never wait for it.
  Future<void> get lastRejectionLogged => _lastRejection;

  /// One pass under a lease; null when the plugin was switched before the
  /// engine started (the caller starts over).
  Future<RunOutcome?> _attempt(
    PluginRunRequest request,
    RunCancel? cancel,
    RunLease lease,
  ) async {
    final id = request.installId;
    if (cancel != null && cancel.isCancelled) {
      return const RunCancelled(RunCancelReason.caller);
    }
    if (request.stream != null && _streamHandler == null) {
      _log.warning('A streaming run was asked for without a stream handler');
      return const RunFailed(RunFailReason.internal);
    }
    final until = _pauses.until(id);
    if (until != null) return RunPaused(until);

    final setup = await prepareRun(
      request,
      rows: _rows,
      files: _files,
      config: _config,
      storage: _storage,
    );
    // Switched while setup ran: what was read may be of the old version, so
    // whatever it says (a refusal included) is dropped and the run starts over.
    if (lease.changed.isCancelled) return _beforeDispatch(cancel);
    final refused = setup.refused;
    if (refused != null) return refused;
    final prepared = setup.prepared!;

    // Waiting for a slot ends on the caller's cancel or a plugin switch.
    final abort = CancelToken();
    final stopWaiting = [
      ?cancel?.listen(abort.cancel),
      lease.changed.listen(abort.cancel),
    ];
    final AdmissionResult granted;
    try {
      granted = await _takeSlot(request, abort);
    } finally {
      for (final stop in stopWaiting) {
        stop();
      }
    }
    final RunSlot slot;
    switch (granted) {
      // A wait that ran out is a busy answer, never a restart.
      case AdmissionTimedOut():
        return const RunBusy();
      case AdmissionAborted():
        return _beforeDispatch(cancel);
      case AdmissionGranted(slot: final taken):
        if (abort.isCancelled) {
          taken.release();
          return _beforeDispatch(cancel);
        }
        slot = taken;
    }

    try {
      if (!_engineReset) {
        _engineReset = true;
        _engine.reset();
      }
      return await _dispatch(request, prepared, cancel, lease, slot);
    } on Object {
      slot.release();
      rethrow;
    }
  }

  Future<AdmissionResult> _takeSlot(
    PluginRunRequest request,
    CancelToken abort,
  ) {
    if (request.stream != null) {
      return _streamAdmission.acquireWithin(_streamWait, abort: abort);
    }
    return _admission
        .acquire(abort: abort)
        .then<AdmissionResult>(
          (slot) =>
              slot == null ? const AdmissionAborted() : AdmissionGranted(slot),
        );
  }

  RunOutcome? _beforeDispatch(RunCancel? cancel) =>
      cancel != null && cancel.isCancelled
      ? const RunCancelled(RunCancelReason.caller)
      : null;

  Future<RunOutcome> _dispatch(
    PluginRunRequest request,
    PreparedRun prepared,
    RunCancel? cancel,
    RunLease lease,
    RunSlot slot,
  ) async {
    final id = request.installId;
    final stream = request.stream;
    final wall = runWall(request.timeout, spacing, streaming: stream != null);
    // Encoded before the job is begun: a failure here leaves no job behind.
    final inputJson = jsonEncode(request.input);
    final job = _engine.begin();
    final jobCancel = RunCancel();
    final context = JobContext(
      installId: id,
      job: job,
      cancel: jobCancel,
      manifestHosts: prepared.manifestHosts,
      consentedHosts: prepared.consentedHosts,
      userEndpoints: prepared.userEndpoints,
    );

    var cause = RunCancelCause.none;
    final deadlineHit = Completer<void>();
    void stop(RunCancelCause why) {
      final first = cause == RunCancelCause.none;
      if (first) cause = why;
      // The deadline answer must not wait for the bridge call below.
      if (why == RunCancelCause.deadline && !deadlineHit.isCompleted) {
        deadlineHit.complete();
      }
      // The runtime is told first, once (a later cause finds it stopped):
      // nothing a listener of the job's own token does can skip it.
      if (first) _cancelQuietly(job);
      try {
        jobCancel.cancel();
      } on Object catch (error) {
        _log.warning('A job listener failed on cancel: ${error.runtimeType}');
      }
    }

    final engineRequest = EngineRequest(
      job: job,
      installId: id,
      files: prepared.files,
      entry: prepared.entry,
      inputJson: inputJson,
      timeoutMs: wall.inMilliseconds,
      config: prepared.config,
      storageJson: prepared.storageJson,
    );
    Future<EngineFetchResponse> fetch(EngineFetchRequest req) =>
        _fetch(req, context);
    final StartedRun startedRun;
    try {
      startedRun = startEngineRun(
        engine: _engine,
        request: engineRequest,
        fetch: fetch,
        context: context,
        jobCancel: jobCancel,
        slot: slot,
        hungAfter: wall + grace + _settle,
        stream: stream,
        streamHandler: _streamHandler,
        streamTables: _streamTables,
      );
    } on Object {
      // The job was begun but never ran: tell the runtime to forget it.
      _cancelQuietly(job);
      rethrow;
    }
    final streamRun = startedRun.streamRun;
    final running = startedRun.running;

    final unlisten = <void Function()>[];
    Timer? timer;
    try {
      unlisten.addAll([
        ?cancel?.listen(() => stop(RunCancelCause.caller)),
        lease.changed.listen(() => stop(RunCancelCause.pluginChanged)),
      ]);
      final deadlineTimer = timer = Timer(
        wall + grace,
        () => stop(RunCancelCause.deadline),
      );
      final result = await Future.any<EngineResult?>([
        running,
        deadlineHit.future.then((_) => null),
      ]);
      final outcome = result == null
          ? const RunFailed(RunFailReason.timeout)
          : mapEngineResult(
              result,
              cause: cause,
              rateLimitSeen: context.rateLimitSeen,
              pluginVersion: prepared.pluginVersion,
            );
      // Read before the listeners go: a cause after the result is ignored.
      final switched =
          cause == RunCancelCause.pluginChanged || lease.changed.isCancelled;
      final storageWritable =
          cause == RunCancelCause.none && !switched && request.persistStorage;
      // The job is over: a late cancel or the deadline must not reach it
      // while the write-back waits in the queue.
      deadlineTimer.cancel();
      for (final off in unlisten) {
        off();
      }
      // Events and streams of this run end here, whatever the engine still does.
      streamRun?.close();
      // A run the gate or the caller stopped, or that hit its deadline, leaves
      // the storage as it was.
      final newStorage = result?.storageJson;
      if (newStorage != null && storageWritable) {
        await writeBackStorage(_storage, id, newStorage, prepared);
      }
      // A run the plugin switch stopped is not a plugin fault: not logged.
      if (!switched) {
        _recorder.recordRun(
          request: request,
          prepared: prepared,
          context: context,
          outcome: outcome,
          result: result,
        );
      }
      _pauseFrom(id, outcome);
      return outcome;
    } finally {
      timer?.cancel();
      for (final off in unlisten) {
        off();
      }
      streamRun?.close();
      jobCancel.cancel();
    }
  }

  /// A bridge failure must never escape a cancel listener (the gate, a timer
  /// or the caller's `cancel()` would break): log the type and go on.
  void _cancelQuietly(int job) {
    try {
      _engine.cancel(job);
    } on Object catch (error) {
      _log.warning('A plugin job could not be cancelled: ${error.runtimeType}');
    }
  }

  Future<EngineFetchResponse> _fetch(
    EngineFetchRequest request,
    JobContext context,
  ) async {
    if (request.installId != context.installId) {
      return EngineFetchResponse.failure(EngineFetchOutcome.invalidRequest);
    }
    try {
      return await _handler.handle(request, context);
    } on Object catch (error) {
      _log.warning('A plugin fetch handler failed: ${error.runtimeType}');
      return EngineFetchResponse.failure(EngineFetchOutcome.network);
    }
  }

  /// Only a rate-limited run pauses its plugin (not a quota, a 429 the script
  /// handled, or a cancel).
  void _pauseFrom(String installId, RunOutcome outcome) {
    if (outcome is RunScriptError && outcome.kind == RunErrorKind.rateLimited) {
      _pauses.pause(installId, outcome.retryAfter ?? defaultRatePause);
    }
  }
}
