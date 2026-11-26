import 'dart:typed_data';

import 'package:logging/logging.dart';

import '../../domain/logs/run_log_event.dart';
import '../../domain/net/cancel_token.dart';
import '../../domain/net/plugin_fetch_rules.dart';
import '../../domain/run/plugin_engine.dart';
import '../net/plugin_http.dart';
import 'plugin_limiter.dart';
import 'run_cancel.dart';

final _log = Logger('plugin_run');

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

  /// Most values [maskValues] keeps: a script cannot grow it without bound.
  static const maxMaskValues = 256;

  /// Set once a value did not fit in [maskValues]: the log then drops free
  /// text, since it cannot be masked reliably.
  bool maskOverflow = false;

  /// Adds [values] to [maskValues] up to [maxMaskValues].
  void addMask(Iterable<String> values) {
    for (final value in values) {
      if (maskValues.contains(value)) continue;
      if (maskValues.length >= maxMaskValues) {
        maskOverflow = true;
        return;
      }
      maskValues.add(value);
    }
  }

  /// What the log keeps of each request of the run (no query string, header
  /// or body), refused ones included.
  final List<RunLogRequest> requests = [];
}

/// Most requests one run's record keeps.
const _maxRecordedRequests = 100;

/// The verdict of [judgeFetch].
sealed class FetchJudgement {
  const FetchJudgement();
}

/// The request may be sent now: the spacing slot is taken.
final class AllowedFetch extends FetchJudgement {
  const AllowedFetch({
    required this.method,
    required this.url,
    required this.headers,
    required this.body,
    required this.timeLeft,
  });

  /// Upper-case `GET` or `POST`.
  final String method;
  final Uri url;

  /// Filtered headers, ready to send.
  final Map<String, String> headers;
  final Uint8List body;

  /// What is left of the request's deadline after the spacing wait.
  final Duration timeLeft;
}

/// The request is not sent; [outcome] is the answer the script gets.
final class RefusedFetch extends FetchJudgement {
  const RefusedFetch(this.outcome);

  final EngineFetchOutcome outcome;
}

/// Judges one request in the order: job, cancelled run, consent, URL and
/// allowlist (IP literals are refused here; names that resolve to private
/// addresses are refused later by the transport), method / body / headers,
/// then the plugin's spacing slot. The slot wait counts against the request's
/// deadline and stops when [cancel] (default: the run's token) fires. Credential
/// header values become masks first, so refused requests are covered too.
/// Never throws for a bad request.
Future<FetchJudgement> judgeFetch(
  EngineFetchRequest request,
  JobContext context,
  PluginLimiter limiter, {
  CancelToken? cancel,
}) async {
  final clock = Stopwatch()..start();
  // Credential headers are noted for every request, refused ones too: the
  // script may print them whatever the answer was.
  context.addMask(headerSecretsOf(request.headers));
  final requested = pluginRequestHeaders(request.headers);
  // 1 job
  if (request.installId != context.installId) {
    return const RefusedFetch(EngineFetchOutcome.invalidRequest);
  }
  if (context.cancel.isCancelled) {
    return const RefusedFetch(EngineFetchOutcome.abandoned);
  }
  // 2 consent, from the run's snapshot
  if (context.consentedHosts.isEmpty) {
    return const RefusedFetch(EngineFetchOutcome.notConsented);
  }
  // 3 + 4 URL shape, allowlist, saved endpoints
  final judged = judgePluginUrl(
    request.url,
    manifestHosts: context.manifestHosts,
    consentedHosts: context.consentedHosts,
    userEndpoints: context.userEndpoints,
  );
  final url = judged.uri;
  switch (judged.verdict) {
    case PluginUrlVerdict.invalid:
      return const RefusedFetch(EngineFetchOutcome.invalidRequest);
    case PluginUrlVerdict.blocked:
      return const RefusedFetch(EngineFetchOutcome.blockedHost);
    case PluginUrlVerdict.allowed:
      break;
  }
  // 5 method, body, headers
  final method = request.method.toUpperCase();
  if (url == null ||
      requested == null ||
      (method != 'GET' && method != 'POST') ||
      (method == 'GET' && request.body.isNotEmpty)) {
    return const RefusedFetch(EngineFetchOutcome.invalidRequest);
  }
  // 6 spacing; the wait counts against the deadline
  final deadline = Duration(milliseconds: request.deadlineMs);
  final granted = await limiter.acquire(
    context.installId,
    timeLeft: deadline - clock.elapsed,
    cancel: cancel ?? context.cancel,
  );
  switch (granted) {
    case LimiterResult.cancelled:
      return const RefusedFetch(EngineFetchOutcome.abandoned);
    case LimiterResult.tooLate:
      _log.info('Plugin fetch not sent: spacing wait exceeds deadline');
      return const RefusedFetch(EngineFetchOutcome.network);
    case LimiterResult.granted:
      break;
  }
  final left = deadline - clock.elapsed;
  if (left <= Duration.zero) {
    return const RefusedFetch(EngineFetchOutcome.network);
  }
  return AllowedFetch(
    method: method,
    url: url,
    headers: requested.headers,
    body: request.body,
    timeLeft: left,
  );
}

/// Notes what an answer tells the run: a 429 / 503 sets
/// [JobContext.rateLimitSeen] (the longest wait wins) and every `set-cookie`
/// value becomes a mask. Every status is still an answer for the script.
void noteResponse(JobContext context, PluginHttpResponse response) {
  if (response.status == 429 || response.status == 503) {
    String? retryAfter;
    for (final (name, value) in response.headers) {
      if (name == 'retry-after') {
        retryAfter = value;
        break;
      }
    }
    final wait = parseRetryAfter(retryAfter);
    final seen = context.rateLimitSeen;
    if (seen == null || wait > seen) context.rateLimitSeen = wait;
  }
  for (final (name, value) in response.headers) {
    if (name == 'set-cookie') context.addMask(setCookieSecrets(value));
  }
}

/// Logs a failure nobody expected and gives the outcome the script gets:
/// the outer catch of every fetch path.
EngineFetchOutcome unexpectedFetchFailure(Object error) {
  _log.warning('A plugin fetch failed: ${error.runtimeType}');
  return EngineFetchOutcome.network;
}

/// Notes the request for the run log: method, host, path, [status] (null when
/// no answer came) and [ms]. Refused requests are kept, `blocked` when the
/// outcome is [EngineFetchOutcome.blockedHost]. Stops at 100 requests.
void recordFetch(
  EngineFetchRequest request,
  JobContext context,
  EngineFetchOutcome outcome,
  int? status,
  int ms,
) {
  if (context.requests.length >= _maxRecordedRequests) return;
  final uri = Uri.tryParse(request.url);
  context.requests.add(
    RunLogRequest(
      method: _cut(request.method.toUpperCase(), 16),
      host: _cut(uri?.host ?? '', 253),
      path: uri?.path ?? '',
      status: outcome == EngineFetchOutcome.ok ? status : null,
      ms: ms,
      blocked: outcome == EngineFetchOutcome.blockedHost,
    ),
  );
}

String _cut(String text, int max) =>
    text.length <= max ? text : text.substring(0, max);
