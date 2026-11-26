import 'plugin_engine.dart';
import 'run_outcome.dart';

/// Who stopped a job on purpose, if anyone; the first cause wins.
enum RunCancelCause { none, caller, pluginChanged, deadline }

const _minRetry = Duration(seconds: 1);
const _maxRetry = Duration(minutes: 15);

/// [seconds] as a duration clamped to 1 s .. 15 min; null when not given.
Duration? clampRetryAfter(int? seconds) {
  if (seconds == null) return null;
  final wait = Duration(seconds: seconds);
  if (wait < _minRetry) return _minRetry;
  return wait > _maxRetry ? _maxRetry : wait;
}

/// The engine's answer as a [RunOutcome]. A sticky fetch failure never
/// changes the variant: it rides along. [rateLimitSeen] belongs to [RunOk]
/// only.
RunOutcome mapEngineResult(
  EngineResult result, {
  RunCancelCause cause = RunCancelCause.none,
  Duration? rateLimitSeen,
  String pluginVersion = '',
}) {
  final failure = result.fetchFailure;
  return switch (result.status) {
    EngineStatus.ok => RunOk(
      result.outputJson,
      fetchFailure: failure,
      rateLimitSeen: rateLimitSeen,
      pluginVersion: pluginVersion,
    ),
    EngineStatus.scriptError => RunScriptError(
      _kindOf(result.errorKind),
      result.errorMessage,
      retryAfter: clampRetryAfter(result.retryAfterSec),
      fetchFailure: failure,
      pluginVersion: pluginVersion,
    ),
    EngineStatus.timeout => RunFailed(
      RunFailReason.timeout,
      fetchFailure: failure,
    ),
    EngineStatus.memory => RunFailed(
      RunFailReason.memory,
      fetchFailure: failure,
    ),
    EngineStatus.stack => RunFailed(RunFailReason.stack, fetchFailure: failure),
    EngineStatus.outputTooLarge => RunFailed(
      RunFailReason.outputTooLarge,
      fetchFailure: failure,
    ),
    EngineStatus.internal => RunFailed(
      RunFailReason.internal,
      fetchFailure: failure,
    ),
    EngineStatus.cancelled => switch (cause) {
      RunCancelCause.pluginChanged => const RunCancelled(
        RunCancelReason.pluginChanged,
      ),
      RunCancelCause.deadline => RunFailed(
        RunFailReason.timeout,
        fetchFailure: failure,
      ),
      // No recorded cause (the runtime was reset): nobody to tell.
      RunCancelCause.caller ||
      RunCancelCause.none => const RunCancelled(RunCancelReason.caller),
    },
    EngineStatus.busy => const RunBusy(),
  };
}

RunErrorKind _kindOf(EngineErrorKind kind) => switch (kind) {
  EngineErrorKind.rateLimited => RunErrorKind.rateLimited,
  EngineErrorKind.server => RunErrorKind.server,
  EngineErrorKind.auth => RunErrorKind.auth,
  EngineErrorKind.quota => RunErrorKind.quota,
  EngineErrorKind.invalidResponse ||
  EngineErrorKind.none => RunErrorKind.invalidResponse,
};
