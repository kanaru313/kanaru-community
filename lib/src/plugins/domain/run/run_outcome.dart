/// Kind of a failure a script reported itself (`Response.error`). Kept raw:
/// the runtime's "none" is reported as [invalidResponse].
enum RunErrorKind { rateLimited, invalidResponse, server, auth, quota }

/// Why a run failed for a reason that is not the script's own report.
enum RunFailReason { timeout, memory, stack, outputTooLarge, internal }

/// Who ended a run on purpose.
enum RunCancelReason {
  /// The caller's `RunCancel`.
  caller,

  /// An install-over, update, repair or remove of the plugin switched it.
  pluginChanged,
}

/// Why a run could not start because of the plugin itself.
enum RunUnavailableReason { notInstalled, packageUnreadable, noScript }

/// Why the first failing host `fetch` of a run failed. Not the app's own
/// `FetchFailureKind` of `domain/net` (that one describes the store's
/// downloads); import one of them with a prefix when both are needed.
enum FetchFailureKind {
  network,
  blockedHost,
  notConsented,
  abandoned,
  invalidRequest,
  invalidResponse,
  rateLimited,
}

/// The first failing host `fetch` of a run, kept even when the script caught
/// it. [message] is runtime-made text and never holds configuration values.
class FetchFailureInfo {
  const FetchFailureInfo({
    required this.kind,
    this.retryAfter,
    this.message = '',
  });

  final FetchFailureKind kind;
  final Duration? retryAfter;
  final String message;

  @override
  bool operator ==(Object other) =>
      other is FetchFailureInfo &&
      other.kind == kind &&
      other.retryAfter == retryAfter &&
      other.message == message;

  @override
  int get hashCode => Object.hash(kind, retryAfter, message);
}

/// How a plugin run ended. Callers switch over it without a default, so a new
/// variant breaks the build, not the behaviour.
///
/// Nothing ran (no engine start, nothing sent) for [RunBusy], [RunPaused],
/// [RunNeedsConfig], [RunUnavailable], and for [RunCancelled] when the cancel
/// came before dispatch.
sealed class RunOutcome {
  const RunOutcome();
}

/// The script returned data. A sticky [fetchFailure] or [rateLimitSeen] never
/// turns this into a failure: the caller decides.
final class RunOk extends RunOutcome {
  const RunOk(this.outputJson, {this.fetchFailure, this.rateLimitSeen});

  final String outputJson;
  final FetchFailureInfo? fetchFailure;

  /// A 429 / 503 answer reached the script in this run: its `Retry-After`
  /// clamped to 1 s .. 15 min, else 60 s.
  final Duration? rateLimitSeen;
}

/// The script reported a failure itself.
final class RunScriptError extends RunOutcome {
  const RunScriptError(
    this.kind,
    this.message, {
    this.retryAfter,
    this.fetchFailure,
  });

  final RunErrorKind kind;
  final String message;

  /// The script's own wait request, clamped to 1 s .. 15 min.
  final Duration? retryAfter;
  final FetchFailureInfo? fetchFailure;
}

/// The run failed for a reason outside the script's report.
final class RunFailed extends RunOutcome {
  const RunFailed(this.reason, {this.fetchFailure});

  final RunFailReason reason;
  final FetchFailureInfo? fetchFailure;
}

final class RunCancelled extends RunOutcome {
  const RunCancelled(this.reason);

  final RunCancelReason reason;
}

/// Every runtime worker and queue slot was taken (should not happen behind
/// the admission queue).
final class RunBusy extends RunOutcome {
  const RunBusy();
}

/// The plugin is paused after a rate-limited run; nothing was sent.
final class RunPaused extends RunOutcome {
  const RunPaused(this.until);

  final DateTime until;
}

/// Required settings have no value; [fieldTitles] are the form titles.
final class RunNeedsConfig extends RunOutcome {
  const RunNeedsConfig(this.fieldTitles);

  final List<String> fieldTitles;
}

final class RunUnavailable extends RunOutcome {
  const RunUnavailable(this.reason);

  final RunUnavailableReason reason;
}
