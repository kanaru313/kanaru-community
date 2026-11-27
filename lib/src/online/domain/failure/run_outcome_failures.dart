import '../../../plugins/domain/run/run_outcome.dart';
import 'online_failure.dart';

/// What a run outcome means for an online call.
sealed class OnlineRunDecision {
  const OnlineRunDecision();
}

/// The script returned [json]. [sticky] is a failure seen inside the run that
/// only counts when the answer turns out empty.
final class OnlineRunData extends OnlineRunDecision {
  const OnlineRunData(this.json, this.sticky);

  final String json;
  final OnlineFailure? sticky;
}

final class OnlineRunFailed extends OnlineRunDecision {
  const OnlineRunFailed(this.failure);

  final OnlineFailure failure;
}

final class OnlineRunAbandoned extends OnlineRunDecision {
  const OnlineRunAbandoned();
}

OnlineRunFailed _fail(
  OnlineFailureKind kind, {
  Duration? retryAfter,
  DateTime? until,
  List<String> fieldTitles = const [],
}) => OnlineRunFailed(
  OnlineFailure(
    kind,
    retryAfter: retryAfter,
    until: until,
    fieldTitles: fieldTitles,
  ),
);

OnlineFailure? _stickyOf(FetchFailureInfo? fetch, Duration? rateLimit) {
  if (rateLimit != null) {
    return OnlineFailure(OnlineFailureKind.rateLimited, retryAfter: rateLimit);
  }
  if (fetch == null) return null;
  return switch (fetch.kind) {
    FetchFailureKind.network => const OnlineFailure(OnlineFailureKind.network),
    FetchFailureKind.rateLimited => OnlineFailure(
      OnlineFailureKind.rateLimited,
      retryAfter: fetch.retryAfter,
    ),
    FetchFailureKind.invalidResponse => const OnlineFailure(
      OnlineFailureKind.invalidOutput,
    ),
    FetchFailureKind.blockedHost => const OnlineFailure(
      OnlineFailureKind.blockedHost,
    ),
    FetchFailureKind.notConsented ||
    FetchFailureKind.abandoned ||
    FetchFailureKind.invalidRequest => const OnlineFailure(
      OnlineFailureKind.server,
    ),
  };
}

/// The online column of the run contract, one row per outcome. No `default`:
/// a new outcome, error kind or reason breaks the build.
OnlineRunDecision decideOnlineRun(
  RunOutcome outcome, {
  required OnlineScriptRole role,
}) => switch (outcome) {
  RunOk(:final outputJson, :final fetchFailure, :final rateLimitSeen) =>
    OnlineRunData(outputJson, _stickyOf(fetchFailure, rateLimitSeen)),
  RunScriptError(:final kind, :final retryAfter, :final fetchFailure) =>
    _scriptError(kind, retryAfter, fetchFailure, role),
  RunFailed(:final reason, :final fetchFailure) => switch (reason) {
    RunFailReason.timeout =>
      fetchFailure?.kind == FetchFailureKind.network
          ? _fail(OnlineFailureKind.network)
          : _fail(OnlineFailureKind.timeout),
    RunFailReason.memory ||
    RunFailReason.stack ||
    RunFailReason.outputTooLarge => _fail(OnlineFailureKind.invalidOutput),
    RunFailReason.internal => _fail(OnlineFailureKind.internal),
  },
  RunCancelled(:final reason) => switch (reason) {
    RunCancelReason.caller => const OnlineRunAbandoned(),
    RunCancelReason.pluginChanged => _fail(OnlineFailureKind.pluginChanged),
  },
  RunBusy() => _fail(OnlineFailureKind.busy),
  RunPaused(:final until) => _fail(OnlineFailureKind.paused, until: until),
  RunNeedsConfig(:final fieldTitles) => _fail(
    OnlineFailureKind.needsConfig,
    fieldTitles: fieldTitles,
  ),
  RunUnavailable(:final reason) => switch (reason) {
    RunUnavailableReason.notInstalled => _fail(OnlineFailureKind.pluginMissing),
    RunUnavailableReason.packageUnreadable => _fail(OnlineFailureKind.internal),
    RunUnavailableReason.noScript => _fail(OnlineFailureKind.noScript),
  },
};

/// A script that ended with its own error. A 429 seen inside the run wins over
/// whatever kind the script chose (an HTML 429 body is often reported as an
/// invalid response): it is a rate limit of the whole source.
OnlineRunFailed _scriptError(
  RunErrorKind kind,
  Duration? retryAfter,
  FetchFailureInfo? fetchFailure,
  OnlineScriptRole role,
) {
  if (fetchFailure?.kind == FetchFailureKind.rateLimited) {
    return _fail(
      OnlineFailureKind.rateLimited,
      retryAfter: fetchFailure?.retryAfter ?? retryAfter,
    );
  }
  return switch (kind) {
    RunErrorKind.rateLimited || RunErrorKind.quota => _fail(
      OnlineFailureKind.rateLimited,
      retryAfter: retryAfter,
    ),
    RunErrorKind.network => _fail(OnlineFailureKind.network),
    RunErrorKind.unavailable => _fail(OnlineFailureKind.gone),
    RunErrorKind.unsupported => _fail(OnlineFailureKind.unsupported),
    // Wrong credentials on any script are the source's problem. A stream's
    // own kind lets the player tell it from a page's.
    RunErrorKind.auth => switch (role) {
      OnlineScriptRole.stream => _fail(OnlineFailureKind.authRequired),
      OnlineScriptRole.page => _fail(OnlineFailureKind.authFailed),
    },
    RunErrorKind.server => switch (fetchFailure?.kind) {
      FetchFailureKind.network => _fail(OnlineFailureKind.network),
      FetchFailureKind.blockedHost => _fail(OnlineFailureKind.blockedHost),
      FetchFailureKind.rateLimited ||
      FetchFailureKind.notConsented ||
      FetchFailureKind.abandoned ||
      FetchFailureKind.invalidRequest ||
      FetchFailureKind.invalidResponse ||
      null => _fail(OnlineFailureKind.server),
    },
    RunErrorKind.invalidResponse => switch (fetchFailure?.kind) {
      FetchFailureKind.network => _fail(OnlineFailureKind.network),
      FetchFailureKind.blockedHost => _fail(OnlineFailureKind.blockedHost),
      FetchFailureKind.rateLimited ||
      FetchFailureKind.notConsented ||
      FetchFailureKind.abandoned ||
      FetchFailureKind.invalidRequest ||
      FetchFailureKind.invalidResponse ||
      null => _fail(OnlineFailureKind.invalidOutput),
    },
  };
}
