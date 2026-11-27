import '../../../plugins/domain/run/run_outcome.dart';

/// Why one source's run did not give lyrics data, in the lyrics module's
/// terms (the run contract's lyrics column).
enum SourceFailKind {
  /// Network, timeout.
  network,

  /// The service or the plugin failed (server, auth, internal).
  server,

  /// A rate limit or a quota; the source is paused or in backoff.
  rateLimited,

  /// The plugin answered badly (bad output, memory, stack, too large).
  invalid,
}

/// Why a source was left alone without a failure.
enum SourceSkip { busy, pluginChanged, unavailable, needsConfig, paused }

/// The result of one run of a source as the lookup and the search see it.
sealed class SourceRun<T> {
  const SourceRun();
}

/// Data the plugin returned and the reader accepted.
final class SourceOk<T> extends SourceRun<T> {
  const SourceOk(this.value);

  final T value;
}

/// A failure; [retryAfter] is the service's own wait request.
final class SourceFailed<T> extends SourceRun<T> {
  const SourceFailed(this.kind, {this.retryAfter});

  final SourceFailKind kind;
  final Duration? retryAfter;
}

/// Nothing was asked of the service.
final class SourceSkipped<T> extends SourceRun<T> {
  const SourceSkipped(this.reason, {this.until});

  final SourceSkip reason;

  /// End of the pause for [SourceSkip.paused].
  final DateTime? until;
}

/// The caller cancelled the run: nothing to record.
final class SourceAbandoned<T> extends SourceRun<T> {
  const SourceAbandoned();
}

/// The run outcome reduced to what a lyrics caller decides on.
sealed class RunDecision {
  const RunDecision();
}

/// The script returned [json]; [sticky] is a failure that happened inside the
/// run (a failed `fetch` the script caught, or a 429 / 503 it saw). It never
/// replaces non-empty data.
final class DecisionData extends RunDecision {
  const DecisionData(this.json, this.sticky);

  final String json;
  final SourceFailed<Never>? sticky;
}

final class DecisionFailed extends RunDecision {
  const DecisionFailed(this.failure);

  final SourceFailed<Never> failure;
}

final class DecisionSkipped extends RunDecision {
  const DecisionSkipped(this.reason, {this.until});

  final SourceSkip reason;
  final DateTime? until;
}

final class DecisionAbandoned extends RunDecision {
  const DecisionAbandoned();
}

SourceFailed<Never> _failed(SourceFailKind kind, [Duration? retryAfter]) =>
    SourceFailed<Never>(kind, retryAfter: retryAfter);

SourceFailed<Never>? _stickyOf(FetchFailureInfo? fetch, Duration? rateLimit) {
  if (rateLimit != null) return _failed(SourceFailKind.rateLimited, rateLimit);
  if (fetch == null) return null;
  return switch (fetch.kind) {
    FetchFailureKind.network => _failed(SourceFailKind.network),
    FetchFailureKind.rateLimited => _failed(
      SourceFailKind.rateLimited,
      fetch.retryAfter,
    ),
    FetchFailureKind.invalidResponse => _failed(SourceFailKind.invalid),
    FetchFailureKind.blockedHost ||
    FetchFailureKind.notConsented ||
    FetchFailureKind.abandoned ||
    FetchFailureKind.invalidRequest => _failed(SourceFailKind.server),
  };
}

/// The lyrics column of the run contract, one row per outcome. No `default`:
/// a new outcome breaks the build.
RunDecision decideRun(RunOutcome outcome) => switch (outcome) {
  RunOk(:final outputJson, :final fetchFailure, :final rateLimitSeen) =>
    DecisionData(outputJson, _stickyOf(fetchFailure, rateLimitSeen)),
  RunScriptError(:final kind, :final retryAfter) => DecisionFailed(
    switch (kind) {
      RunErrorKind.rateLimited => _failed(
        SourceFailKind.rateLimited,
        retryAfter,
      ),
      // A quota is a rate limit that lasts.
      RunErrorKind.quota => _failed(SourceFailKind.rateLimited, retryAfter),
      // The plugin saw the network fail itself: same retryable state as a
      // timeout.
      RunErrorKind.network => _failed(SourceFailKind.network),
      // A bad key is the user's to fix; a removed or geo-blocked item and
      // content the plugin cannot serve have no state of their own yet: all
      // shown like a server failure.
      RunErrorKind.auth ||
      RunErrorKind.unavailable ||
      RunErrorKind.unsupported ||
      RunErrorKind.server => _failed(SourceFailKind.server),
      RunErrorKind.invalidResponse => _failed(SourceFailKind.invalid),
    },
  ),
  RunFailed(:final reason) => DecisionFailed(switch (reason) {
    RunFailReason.timeout => _failed(SourceFailKind.network),
    RunFailReason.memory ||
    RunFailReason.stack ||
    RunFailReason.outputTooLarge => _failed(SourceFailKind.invalid),
    RunFailReason.internal => _failed(SourceFailKind.server),
  }),
  RunCancelled(:final reason) => switch (reason) {
    RunCancelReason.caller => const DecisionAbandoned(),
    RunCancelReason.pluginChanged => const DecisionSkipped(
      SourceSkip.pluginChanged,
    ),
  },
  RunBusy() => const DecisionSkipped(SourceSkip.busy),
  RunPaused(:final until) => DecisionSkipped(SourceSkip.paused, until: until),
  RunNeedsConfig() => const DecisionSkipped(SourceSkip.needsConfig),
  RunUnavailable() => const DecisionSkipped(SourceSkip.unavailable),
};
