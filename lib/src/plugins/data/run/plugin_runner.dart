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
import 'run_setup.dart';

final _log = Logger('plugin_run');

/// Longest wall time of one run, whatever its request asks for.
const maxRunWall = Duration(seconds: 90);

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
    RunAdmission? admission,
    this.spacing = pluginSpacing,
    this.grace = outerDeadlineGrace,
  }) : _admission = admission ?? RunAdmission();

  final PluginEngine _engine;
  final PluginFetchHandler _handler;
  final RunGate _gate;
  final PluginPauses _pauses;
  final PluginRows _rows;
  final PluginFiles _files;
  final PluginConfigStore _config;
  final PluginStorageStore _storage;
  final RunAdmission _admission;
  final Duration spacing;
  final Duration grace;
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

  /// A caller's reader or validator refused a [RunOk] output. One log line
  /// with the plugin, the script and the caller's fixed [reason]; the output
  /// itself is never written.
  void reportRejectedOutput(String installId, String script, String reason) {
    _log.info(
      'Plugin output rejected: plugin=$installId script=$script reason=$reason',
    );
  }

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
    final RunSlot? slot;
    try {
      slot = await _admission.acquire(abort: abort);
    } finally {
      for (final stop in stopWaiting) {
        stop();
      }
    }
    if (slot != null && (abort.isCancelled)) {
      slot.release();
      return _beforeDispatch(cancel);
    }
    if (slot == null) return _beforeDispatch(cancel);

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
    final wall = _wallOf(request.timeout);
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

    final Future<EngineResult> started;
    try {
      started = _engine.run(
        EngineRequest(
          job: job,
          installId: id,
          files: prepared.files,
          entry: prepared.entry,
          inputJson: inputJson,
          timeoutMs: wall.inMilliseconds,
          config: prepared.config,
          storageJson: prepared.storageJson,
        ),
        (req) => _fetch(req, context),
      );
    } on Object {
      // The job was begun but never ran: tell the runtime to forget it.
      _cancelQuietly(job);
      rethrow;
    }
    // The slot stays taken until the runtime really let go of the job, even
    // when the run was already answered at its deadline.
    final running = started.whenComplete(slot.release);

    final unlisten = <void Function()>[];
    Timer? timer;
    try {
      unlisten.addAll([
        ?cancel?.listen(() => stop(RunCancelCause.caller)),
        lease.changed.listen(() => stop(RunCancelCause.pluginChanged)),
      ]);
      timer = Timer(wall + grace, () => stop(RunCancelCause.deadline));
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
            );
      // A run the gate or the caller stopped, or that hit its deadline, leaves
      // the storage as it was.
      final newStorage = result?.storageJson;
      if (newStorage != null &&
          cause == RunCancelCause.none &&
          !lease.changed.isCancelled) {
        await _writeBack(id, newStorage, prepared);
      }
      _pauseFrom(id, outcome);
      return outcome;
    } finally {
      timer?.cancel();
      for (final off in unlisten) {
        off();
      }
      jobCancel.cancel();
    }
  }

  /// Saves the storage the script changed, before the outcome is returned, so
  /// the next run of the plugin reads it. The slot is already free (it goes
  /// with the engine job). A refused write (the plugin was updated, removed or
  /// its storage cleared meanwhile) is silent; a failed one logs its type and
  /// the outcome still stands.
  Future<void> _writeBack(
    String installId,
    String storageJson,
    PreparedRun prepared,
  ) async {
    try {
      await _storage.writeBack(
        installId,
        storageJson,
        expectedRev: prepared.storageRev,
        expectedUpdatedAt: prepared.rowUpdatedAt,
      );
    } on Object catch (error) {
      _log.warning('Plugin storage was not saved: ${error.runtimeType}');
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

  /// `min(90 s, timeout + 9 x spacing)`: the allowance for the pauses between
  /// the up-to-ten sends of one call.
  Duration _wallOf(Duration timeout) {
    final wall = timeout + spacing * 9;
    return wall > maxRunWall ? maxRunWall : wall;
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
