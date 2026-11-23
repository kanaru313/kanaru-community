import '../../domain/run/plugin_engine.dart';
import 'run_cancel.dart';

/// What the host knows about one run, fixed when the run starts: the fetch
/// handler judges every request of the run against this snapshot, so a change
/// of the plugin or its settings mid-run never widens what the script may
/// reach.
class JobContext {
  JobContext({
    required this.installId,
    required this.job,
    required this.cancel,
    required Set<String> manifestHosts,
    required Set<String> consentedHosts,
    required Set<String> userEndpoints,
  }) : manifestHosts = Set.unmodifiable(manifestHosts),
       consentedHosts = Set.unmodifiable(consentedHosts),
       userEndpoints = Set.unmodifiable(userEndpoints);

  final String installId;

  /// The runtime job of this run.
  final int job;

  /// Cancelled when the run is stopped for any reason (caller, plugin change,
  /// deadline): the handler answers every pending and later fetch `abandoned`.
  final RunCancel cancel;

  /// Hosts the manifest declares.
  final Set<String> manifestHosts;

  /// Hosts the user consented to at install.
  final Set<String> consentedHosts;

  /// The `format: url` values the user saved (as stored, never manifest
  /// defaults and never a run's `configAppend`).
  final Set<String> userEndpoints;

  /// Set by the handler when a 429 / 503 answer reached the script: its
  /// `Retry-After` clamped to 1 s .. 15 min, else 60 s.
  Duration? rateLimitSeen;

  /// Strings to hide in the run log: values the handler saw that look like
  /// secrets (authorization headers and the like).
  final Set<String> maskValues = {};
}

/// Answers the host `fetch` calls of one run. Never throws: every failure is
/// an answer with the matching outcome.
abstract interface class PluginFetchHandler {
  Future<EngineFetchResponse> handle(
    EngineFetchRequest request,
    JobContext context,
  );
}

/// Refuses every request as a host that is not allowed.
class BlockAllFetchHandler implements PluginFetchHandler {
  const BlockAllFetchHandler();

  @override
  Future<EngineFetchResponse> handle(
    EngineFetchRequest request,
    JobContext context,
  ) async => EngineFetchResponse.failure(EngineFetchOutcome.blockedHost);
}
