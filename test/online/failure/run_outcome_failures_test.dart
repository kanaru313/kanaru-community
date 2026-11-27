import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/online/domain/failure/online_failure.dart';
import 'package:kanaru/src/online/domain/failure/run_outcome_failures.dart';
import 'package:kanaru/src/plugins/domain/run/run_outcome.dart';

const page = OnlineScriptRole.page;
const stream = OnlineScriptRole.stream;

OnlineFailure failure(
  RunOutcome o, [
  OnlineScriptRole role = OnlineScriptRole.page,
]) {
  final d = decideOnlineRun(o, role: role);
  expect(d, isA<OnlineRunFailed>(), reason: '$o');
  return (d as OnlineRunFailed).failure;
}

OnlineFailureKind kindOf(RunOutcome o, [OnlineScriptRole r = page]) =>
    failure(o, r).kind;

FetchFailureInfo fetch(FetchFailureKind k, [Duration? retry]) =>
    FetchFailureInfo(kind: k, retryAfter: retry);

void main() {
  group('RunOk', () {
    OnlineFailure? sticky(RunOk ok) {
      final d = decideOnlineRun(ok, role: page) as OnlineRunData;
      expect(d.json, ok.outputJson);
      return d.sticky;
    }

    test('no failure seen: data without sticky', () {
      expect(sticky(const RunOk('[]')), isNull);
    });

    test('rate limit seen wins over a fetch failure', () {
      expect(
        sticky(
          RunOk(
            '[]',
            rateLimitSeen: const Duration(seconds: 60),
            fetchFailure: fetch(FetchFailureKind.network),
          ),
        ),
        const OnlineFailure(
          OnlineFailureKind.rateLimited,
          retryAfter: Duration(seconds: 60),
        ),
      );
    });

    test('fetch failure kinds', () {
      final expected = {
        FetchFailureKind.network: OnlineFailureKind.network,
        FetchFailureKind.rateLimited: OnlineFailureKind.rateLimited,
        FetchFailureKind.invalidResponse: OnlineFailureKind.invalidOutput,
        FetchFailureKind.blockedHost: OnlineFailureKind.blockedHost,
        FetchFailureKind.notConsented: OnlineFailureKind.server,
        FetchFailureKind.abandoned: OnlineFailureKind.server,
        FetchFailureKind.invalidRequest: OnlineFailureKind.server,
      };
      expect(expected.keys.toSet(), FetchFailureKind.values.toSet());
      for (final e in expected.entries) {
        expect(
          sticky(RunOk('[]', fetchFailure: fetch(e.key)))?.kind,
          e.value,
          reason: '${e.key}',
        );
      }
    });

    test('rate limited fetch keeps its retry-after', () {
      expect(
        sticky(
          RunOk(
            '[]',
            fetchFailure: fetch(
              FetchFailureKind.rateLimited,
              const Duration(seconds: 7),
            ),
          ),
        )?.retryAfter,
        const Duration(seconds: 7),
      );
    });
  });

  group('RunScriptError', () {
    RunScriptError err(
      RunErrorKind k, {
      Duration? retry,
      FetchFailureInfo? f,
    }) => RunScriptError(k, 'm', retryAfter: retry, fetchFailure: f);

    test('every kind has a mapping', () {
      final expected = {
        RunErrorKind.rateLimited: OnlineFailureKind.rateLimited,
        RunErrorKind.quota: OnlineFailureKind.rateLimited,
        RunErrorKind.network: OnlineFailureKind.network,
        RunErrorKind.unavailable: OnlineFailureKind.gone,
        RunErrorKind.unsupported: OnlineFailureKind.unsupported,
        RunErrorKind.auth: OnlineFailureKind.authFailed,
        RunErrorKind.server: OnlineFailureKind.server,
        RunErrorKind.invalidResponse: OnlineFailureKind.invalidOutput,
      };
      expect(expected.keys.toSet(), RunErrorKind.values.toSet());
      for (final e in expected.entries) {
        expect(failure(err(e.key)).kind, e.value, reason: '${e.key}');
      }
    });

    test('rate limit and quota carry retry-after', () {
      const r = Duration(seconds: 30);
      expect(failure(err(RunErrorKind.rateLimited, retry: r)).retryAfter, r);
      expect(failure(err(RunErrorKind.quota, retry: r)).retryAfter, r);
    });

    test('auth splits by role', () {
      expect(
        kindOf(err(RunErrorKind.auth), stream),
        OnlineFailureKind.authRequired,
      );
      expect(
        kindOf(err(RunErrorKind.auth), page),
        OnlineFailureKind.authFailed,
      );
      expect(
        failure(err(RunErrorKind.auth), stream).failureClass,
        OnlineFailureClass.source,
      );
      expect(
        failure(err(RunErrorKind.auth)).failureClass,
        OnlineFailureClass.source,
      );
    });

    test('server refined by the fetch failure', () {
      expect(
        kindOf(err(RunErrorKind.server, f: fetch(FetchFailureKind.network))),
        OnlineFailureKind.network,
      );
      expect(
        kindOf(
          err(RunErrorKind.server, f: fetch(FetchFailureKind.blockedHost)),
        ),
        OnlineFailureKind.blockedHost,
      );
      final limited = failure(
        err(
          RunErrorKind.server,
          retry: const Duration(seconds: 5),
          f: fetch(FetchFailureKind.rateLimited, const Duration(seconds: 9)),
        ),
      );
      expect(limited.kind, OnlineFailureKind.rateLimited);
      expect(limited.retryAfter, const Duration(seconds: 9));
      expect(
        failure(
          err(
            RunErrorKind.server,
            retry: const Duration(seconds: 5),
            f: fetch(FetchFailureKind.rateLimited),
          ),
        ).retryAfter,
        const Duration(seconds: 5),
      );
      for (final k in [
        FetchFailureKind.notConsented,
        FetchFailureKind.abandoned,
        FetchFailureKind.invalidRequest,
        FetchFailureKind.invalidResponse,
      ]) {
        expect(
          kindOf(err(RunErrorKind.server, f: fetch(k))),
          OnlineFailureKind.server,
        );
      }
    });

    test('invalid response refined by the fetch failure', () {
      expect(
        kindOf(
          err(RunErrorKind.invalidResponse, f: fetch(FetchFailureKind.network)),
        ),
        OnlineFailureKind.network,
      );
      expect(
        kindOf(
          err(
            RunErrorKind.invalidResponse,
            f: fetch(FetchFailureKind.blockedHost),
          ),
        ),
        OnlineFailureKind.blockedHost,
      );
    });

    test('a 429 seen in the run is a rate limit whatever the script says', () {
      for (final k in RunErrorKind.values) {
        final f = failure(
          err(
            k,
            retry: const Duration(seconds: 3),
            f: fetch(FetchFailureKind.rateLimited, const Duration(seconds: 8)),
          ),
        );
        expect(f.kind, OnlineFailureKind.rateLimited, reason: '$k');
        expect(f.retryAfter, const Duration(seconds: 8), reason: '$k');
      }
      expect(
        failure(
          err(
            RunErrorKind.invalidResponse,
            f: fetch(FetchFailureKind.rateLimited),
          ),
        ).retryAfter,
        isNull,
      );
    });
  });

  group('RunFailed', () {
    test('every reason maps', () {
      final expected = {
        RunFailReason.timeout: OnlineFailureKind.timeout,
        RunFailReason.memory: OnlineFailureKind.invalidOutput,
        RunFailReason.stack: OnlineFailureKind.invalidOutput,
        RunFailReason.outputTooLarge: OnlineFailureKind.invalidOutput,
        RunFailReason.internal: OnlineFailureKind.internal,
      };
      expect(expected.keys.toSet(), RunFailReason.values.toSet());
      for (final e in expected.entries) {
        expect(kindOf(RunFailed(e.key)), e.value, reason: '${e.key}');
      }
    });

    test('timeout after a network failure is a network failure', () {
      expect(
        kindOf(
          RunFailed(
            RunFailReason.timeout,
            fetchFailure: fetch(FetchFailureKind.network),
          ),
        ),
        OnlineFailureKind.network,
      );
    });
  });

  group('the rest', () {
    test('cancel', () {
      expect(
        decideOnlineRun(const RunCancelled(RunCancelReason.caller), role: page),
        isA<OnlineRunAbandoned>(),
      );
      expect(
        kindOf(const RunCancelled(RunCancelReason.pluginChanged)),
        OnlineFailureKind.pluginChanged,
      );
      expect(RunCancelReason.values, hasLength(2));
    });

    test('busy, paused, needs config', () {
      expect(kindOf(const RunBusy()), OnlineFailureKind.busy);
      final until = DateTime.utc(2026, 1, 2);
      expect(failure(RunPaused(until)).until, until);
      expect(failure(RunPaused(until)).kind, OnlineFailureKind.paused);
      final c = failure(const RunNeedsConfig(['Key', 'Region']));
      expect(c.kind, OnlineFailureKind.needsConfig);
      expect(c.fieldTitles, ['Key', 'Region']);
    });

    test('unavailable reasons', () {
      final expected = {
        RunUnavailableReason.notInstalled: OnlineFailureKind.pluginMissing,
        RunUnavailableReason.packageUnreadable: OnlineFailureKind.internal,
        RunUnavailableReason.noScript: OnlineFailureKind.noScript,
      };
      expect(expected.keys.toSet(), RunUnavailableReason.values.toSet());
      for (final e in expected.entries) {
        expect(kindOf(RunUnavailable(e.key)), e.value);
      }
    });
  });

  test('the class of each kind', () {
    const track = {
      OnlineFailureKind.gone,
      OnlineFailureKind.unsupported,
      OnlineFailureKind.invalidOutput,
      OnlineFailureKind.blockedHost,
      OnlineFailureKind.pluginMissing,
    };
    for (final k in OnlineFailureKind.values) {
      final expected = track.contains(k)
          ? OnlineFailureClass.track
          : k == OnlineFailureKind.network
          ? OnlineFailureClass.network
          : OnlineFailureClass.source;
      expect(k.failureClass, expected, reason: '$k');
      expect(OnlineFailure(k).failureClass, expected);
    }
  });

  test('failure equality includes every field', () {
    expect(
      const OnlineFailure(OnlineFailureKind.needsConfig, fieldTitles: ['a']),
      const OnlineFailure(OnlineFailureKind.needsConfig, fieldTitles: ['a']),
    );
    expect(
      const OnlineFailure(OnlineFailureKind.needsConfig, fieldTitles: ['a']),
      isNot(
        const OnlineFailure(OnlineFailureKind.needsConfig, fieldTitles: ['b']),
      ),
    );
    expect(
      const OnlineFailure(
        OnlineFailureKind.rateLimited,
        retryAfter: Duration(seconds: 1),
      ),
      isNot(const OnlineFailure(OnlineFailureKind.rateLimited)),
    );
  });
}
