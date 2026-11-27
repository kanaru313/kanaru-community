import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/run/plugin_engine.dart';
import 'package:kanaru/src/plugins/domain/run/run_failure_mapping.dart';
import 'package:kanaru/src/plugins/domain/run/run_outcome.dart';

void main() {
  RunOutcome map(
    EngineResult r, {
    RunCancelCause cause = RunCancelCause.none,
    Duration? seen,
  }) => mapEngineResult(r, cause: cause, rateLimitSeen: seen);

  const failure = FetchFailureInfo(
    kind: FetchFailureKind.network,
    message: 'offline',
  );

  group('every engine status has a row', () {
    // An exhaustive switch (no default): a new status breaks this build.
    RunOutcome expectedFor(EngineStatus status) => switch (status) {
      EngineStatus.ok => const RunOk('[]'),
      EngineStatus.scriptError => const RunScriptError(
        RunErrorKind.invalidResponse,
        'e',
      ),
      EngineStatus.timeout => const RunFailed(RunFailReason.timeout),
      EngineStatus.memory => const RunFailed(RunFailReason.memory),
      EngineStatus.stack => const RunFailed(RunFailReason.stack),
      EngineStatus.cancelled => const RunCancelled(RunCancelReason.caller),
      EngineStatus.outputTooLarge => const RunFailed(
        RunFailReason.outputTooLarge,
      ),
      EngineStatus.internal => const RunFailed(RunFailReason.internal),
      EngineStatus.busy => const RunBusy(),
    };

    for (final status in EngineStatus.values) {
      test(status.name, () {
        final got = map(EngineResult(status: status, outputJson: '[]'));
        expect(got.runtimeType, expectedFor(status).runtimeType);
        switch ((got, expectedFor(status))) {
          case (RunFailed a, RunFailed b):
            expect(a.reason, b.reason);
          case (RunCancelled a, RunCancelled b):
            expect(a.reason, b.reason);
          case (RunScriptError a, RunScriptError b):
            expect(a.kind, b.kind);
          default:
        }
      });
    }
  });

  test('Ok keeps its variant with a sticky failure and a seen limit', () {
    final got = map(
      const EngineResult(
        status: EngineStatus.ok,
        outputJson: '[1]',
        fetchFailure: failure,
      ),
      seen: const Duration(seconds: 60),
    );
    expect(got, isA<RunOk>());
    got as RunOk;
    expect(got.outputJson, '[1]');
    expect(got.fetchFailure, failure);
    expect(got.rateLimitSeen, const Duration(seconds: 60));
  });

  group('script errors', () {
    RunScriptError error(EngineErrorKind kind, {int? retry}) => map(
      EngineResult(
        status: EngineStatus.scriptError,
        errorKind: kind,
        errorMessage: 'm',
        retryAfterSec: retry,
        fetchFailure: failure,
      ),
    ) as RunScriptError;

    test('kinds stay raw; the runtime none is an invalid response', () {
      expect(error(EngineErrorKind.auth).kind, RunErrorKind.auth);
      expect(error(EngineErrorKind.quota).kind, RunErrorKind.quota);
      expect(error(EngineErrorKind.server).kind, RunErrorKind.server);
      expect(error(EngineErrorKind.unavailable).kind, RunErrorKind.unavailable);
      expect(error(EngineErrorKind.network).kind, RunErrorKind.network);
      expect(error(EngineErrorKind.unsupported).kind, RunErrorKind.unsupported);
      expect(error(EngineErrorKind.rateLimited).kind, RunErrorKind.rateLimited);
      expect(error(EngineErrorKind.none).kind, RunErrorKind.invalidResponse);
      expect(error(EngineErrorKind.auth).message, 'm');
      expect(error(EngineErrorKind.auth).fetchFailure, failure);
    });

    test('retry-after is clamped to 1 s .. 15 min', () {
      expect(error(EngineErrorKind.rateLimited).retryAfter, isNull);
      expect(
        error(EngineErrorKind.rateLimited, retry: 0).retryAfter,
        const Duration(seconds: 1),
      );
      expect(
        error(EngineErrorKind.rateLimited, retry: 30).retryAfter,
        const Duration(seconds: 30),
      );
      expect(
        error(EngineErrorKind.rateLimited, retry: 86400).retryAfter,
        const Duration(minutes: 15),
      );
    });
  });

  group('a cancelled job depends on who stopped it', () {
    const cancelled = EngineResult(status: EngineStatus.cancelled);
    test('caller', () {
      final got = map(cancelled, cause: RunCancelCause.caller);
      expect((got as RunCancelled).reason, RunCancelReason.caller);
    });
    test('run gate', () {
      final got = map(cancelled, cause: RunCancelCause.pluginChanged);
      expect((got as RunCancelled).reason, RunCancelReason.pluginChanged);
    });
    test('outer deadline is a timeout', () {
      final got = map(cancelled, cause: RunCancelCause.deadline);
      expect((got as RunFailed).reason, RunFailReason.timeout);
    });
  });

  test('a failure carries the sticky fetch failure', () {
    final got = map(
      const EngineResult(status: EngineStatus.memory, fetchFailure: failure),
    );
    expect((got as RunFailed).fetchFailure, failure);
  });
}
