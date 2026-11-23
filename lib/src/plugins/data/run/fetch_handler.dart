import 'package:logging/logging.dart';

import '../../../foundation/result.dart';
import '../../domain/logs/run_log_event.dart';
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

  /// What the log keeps of each request of the run (no query string, header
  /// or body), refused ones included.
  final List<RunLogRequest> requests = [];
}

/// Most requests one run's record keeps.
const _maxRecordedRequests = 100;

/// Answers the host `fetch` calls of one run. Never throws: every failure is
/// an answer with the matching outcome.
abstract interface class PluginFetchHandler {
  Future<EngineFetchResponse> handle(
    EngineFetchRequest request,
    JobContext context,
  );
}

/// The one network path of a plugin run: judges each request (job, consent,
/// URL and allowlist, headers), waits for the plugin's spacing slot, then makes
/// exactly one exchange. Redirects are not followed and 429 / 503 are answers
/// like any other: the script decides what they mean.
class HttpPluginFetchHandler implements PluginFetchHandler {
  HttpPluginFetchHandler({required this._http, required this._limiter});

  final PluginHttpClient _http;
  final PluginLimiter _limiter;

  @override
  Future<EngineFetchResponse> handle(
    EngineFetchRequest request,
    JobContext context,
  ) async {
    final clock = Stopwatch()..start();
    EngineFetchResponse response;
    try {
      response = await _handle(request, context);
    } on Object catch (error) {
      _log.warning('A plugin fetch failed: ${error.runtimeType}');
      response = _fail(EngineFetchOutcome.network);
    }
    _record(request, context, response, clock.elapsedMilliseconds);
    return response;
  }

  /// Notes the request for the run log: method, host, path, status (null
  /// when no answer came) and time.
  void _record(
    EngineFetchRequest request,
    JobContext context,
    EngineFetchResponse response,
    int ms,
  ) {
    if (context.requests.length >= _maxRecordedRequests) return;
    final uri = Uri.tryParse(request.url);
    final answered = response.outcome == EngineFetchOutcome.ok;
    context.requests.add(
      RunLogRequest(
        method: _cut(request.method.toUpperCase(), 16),
        host: _cut(uri?.host ?? '', 253),
        path: uri?.path ?? '',
        status: answered ? response.status : null,
        ms: ms,
        blocked: response.outcome == EngineFetchOutcome.blockedHost,
      ),
    );
  }

  String _cut(String text, int max) =>
      text.length <= max ? text : text.substring(0, max);

  Future<EngineFetchResponse> _handle(
    EngineFetchRequest request,
    JobContext context,
  ) async {
    final clock = Stopwatch()..start();
    // Credential headers are noted for every request, refused ones too: the
    // script may print them whatever the answer was.
    final requested = pluginRequestHeaders(request.headers);
    if (requested != null) context.maskValues.addAll(requested.secrets);
    // 1 job
    if (request.installId != context.installId) {
      return _fail(EngineFetchOutcome.invalidRequest);
    }
    if (context.cancel.isCancelled) return _fail(EngineFetchOutcome.abandoned);
    // 2 consent, from the run's snapshot
    if (context.consentedHosts.isEmpty) {
      return _fail(EngineFetchOutcome.notConsented);
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
        return _fail(EngineFetchOutcome.invalidRequest);
      case PluginUrlVerdict.blocked:
        return _fail(EngineFetchOutcome.blockedHost);
      case PluginUrlVerdict.allowed:
        break;
    }
    // 5 method, body, headers
    final method = request.method.toUpperCase();
    final headers = requested;
    if (url == null ||
        headers == null ||
        (method != 'GET' && method != 'POST') ||
        (method == 'GET' && request.body.isNotEmpty)) {
      return _fail(EngineFetchOutcome.invalidRequest);
    }
    // 6 spacing; the wait counts against the deadline
    final deadline = Duration(milliseconds: request.deadlineMs);
    final granted = await _limiter.acquire(
      context.installId,
      timeLeft: deadline - clock.elapsed,
      cancel: context.cancel,
    );
    switch (granted) {
      case LimiterResult.cancelled:
        return _fail(EngineFetchOutcome.abandoned);
      case LimiterResult.tooLate:
        _log.info('Plugin fetch not sent: spacing wait exceeds deadline');
        return _fail(EngineFetchOutcome.network);
      case LimiterResult.granted:
        break;
    }
    final left = deadline - clock.elapsed;
    if (left <= Duration.zero) return _fail(EngineFetchOutcome.network);
    // 7 - 9 one exchange
    final answer = await _http.send(
      PluginHttpRequest(
        method: method,
        url: url,
        headers: headers.headers,
        body: request.body,
      ),
      deadline: left,
      cancel: context.cancel,
    );
    switch (answer) {
      case Err(:final error):
        return _fail(switch (error) {
          PluginHttpFailure.blockedAddress => EngineFetchOutcome.blockedHost,
          PluginHttpFailure.tooLarge => EngineFetchOutcome.invalidResponse,
          PluginHttpFailure.cancelled => EngineFetchOutcome.abandoned,
          PluginHttpFailure.network ||
          PluginHttpFailure.timeout => EngineFetchOutcome.network,
        });
      case Ok(:final value):
        return _answer(request, context, value);
    }
  }

  /// 10, 11: every status is an answer; a 429 / 503 is only noted.
  EngineFetchResponse _answer(
    EngineFetchRequest request,
    JobContext context,
    PluginHttpResponse response,
  ) {
    if (response.status == 429 || response.status == 503) {
      final wait = parseRetryAfter(_header(response, 'retry-after'));
      final seen = context.rateLimitSeen;
      if (seen == null || wait > seen) context.rateLimitSeen = wait;
    }
    for (final (name, value) in response.headers) {
      if (name == 'set-cookie') {
        context.maskValues.addAll(setCookieSecrets(value));
      }
    }
    return EngineFetchResponse(
      outcome: EngineFetchOutcome.ok,
      status: response.status,
      // The requested URL: nothing is followed, so it is also the final one.
      url: request.url,
      headers: response.headers,
      body: response.body,
      sends: 1,
    );
  }

  String? _header(PluginHttpResponse response, String name) {
    for (final (key, value) in response.headers) {
      if (key == name) return value;
    }
    return null;
  }

  EngineFetchResponse _fail(EngineFetchOutcome outcome) =>
      EngineFetchResponse.failure(outcome);
}
