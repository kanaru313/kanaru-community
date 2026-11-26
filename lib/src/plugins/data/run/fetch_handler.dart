import '../../../foundation/result.dart';
import '../../domain/run/plugin_engine.dart';
import '../net/plugin_http.dart';
import 'fetch_judgement.dart';
import 'plugin_limiter.dart';

export 'fetch_judgement.dart' show JobContext;

/// Answers the host `fetch` calls of one run. Never throws: every failure is
/// an answer with the matching outcome.
abstract interface class PluginFetchHandler {
  Future<EngineFetchResponse> handle(
    EngineFetchRequest request,
    JobContext context,
  );
}

/// The one network path of a plugin run: judges each request (job, consent,
/// URL and allowlist, headers; see [judgeFetch]), waits for the plugin's
/// spacing slot, then makes exactly one exchange. Redirects are not followed
/// and 429 / 503 are answers like any other: the script decides what they
/// mean.
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
      response = EngineFetchResponse.failure(unexpectedFetchFailure(error));
    }
    recordFetch(
      request,
      context,
      response.outcome,
      response.status,
      clock.elapsedMilliseconds,
    );
    return response;
  }

  Future<EngineFetchResponse> _handle(
    EngineFetchRequest request,
    JobContext context,
  ) async {
    final judged = await judgeFetch(request, context, _limiter);
    switch (judged) {
      case RefusedFetch(:final outcome):
        return EngineFetchResponse.failure(outcome);
      case AllowedFetch():
        break;
    }
    // 7 - 9 one exchange
    final answer = await _http.send(
      PluginHttpRequest(
        method: judged.method,
        url: judged.url,
        headers: judged.headers,
        body: judged.body,
      ),
      deadline: judged.timeLeft,
      cancel: context.cancel,
    );
    switch (answer) {
      case Err(:final error):
        return EngineFetchResponse.failure(switch (error) {
          PluginHttpFailure.blockedAddress => EngineFetchOutcome.blockedHost,
          PluginHttpFailure.tooLarge => EngineFetchOutcome.invalidResponse,
          PluginHttpFailure.cancelled => EngineFetchOutcome.abandoned,
          PluginHttpFailure.network ||
          PluginHttpFailure.timeout => EngineFetchOutcome.network,
        });
      case Ok(:final value):
        // 10, 11: every status is an answer; a 429 / 503 is only noted.
        noteResponse(context, value);
        return EngineFetchResponse(
          outcome: EngineFetchOutcome.ok,
          status: value.status,
          // The requested URL: nothing is followed, so it is also the final one.
          url: request.url,
          headers: value.headers,
          body: value.body,
          sends: 1,
        );
    }
  }
}
