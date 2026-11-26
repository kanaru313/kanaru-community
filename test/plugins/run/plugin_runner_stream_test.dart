
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/data/install/remover.dart';
import 'package:kanaru/src/plugins/data/run/run_admission.dart';
import 'package:kanaru/src/plugins/data/run/run_cancel.dart';
import 'package:kanaru/src/plugins/data/store/plugin_storage_store.dart';
import 'package:kanaru/src/plugins/domain/net/cancel_token.dart';
import 'package:kanaru/src/plugins/domain/run/plugin_engine.dart';
import 'package:kanaru/src/plugins/domain/run/run_outcome.dart';
import 'package:kanaru/src/plugins/domain/run/run_request.dart';
import 'package:kanaru/src/plugins/state/plugin_run_provider.dart';
import 'package:logging/logging.dart';

import '../data/install_test_support.dart';
import '../domain/plugin_test_support.dart';
import '../state/state_test_support.dart';
import 'support/fake_plugin_engine.dart';
import 'support/runner_support.dart';
import 'support/stream_call_support.dart';

/// A storage store that counts reads and write-backs.
class _SpyStore extends PluginStorageStore {
  _SpyStore(InstallHarness h) : super(h.db, h.queue);

  var reads = 0;
  var writes = 0;

  @override
  Future<StoredStorage> read(String installId) {
    reads++;
    return super.read(installId);
  }

  @override
  Future<bool> writeBack(
    String installId,
    String storageJson, {
    required int expectedRev,
    required int expectedUpdatedAt,
  }) {
    writes++;
    return super.writeBack(
      installId,
      storageJson,
      expectedRev: expectedRev,
      expectedUpdatedAt: expectedUpdatedAt,
    );
  }
}

/// An admission whose grant comes after the caller's timer has fired.
class _LateAdmission extends RunAdmission {
  _LateAdmission() : super(slots: 1);

  @override
  Future<RunSlot?> acquire({CancelToken? abort}) async {
    final slot = await super.acquire();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return slot;
  }
}

void main() {
  late InstallHarness h;
  late RunnerHarness r;
  late _SpyStore spy;
  final events = <String>[];

  PluginRunRequest streamRequest({
    Duration timeout = const Duration(seconds: 30),
    bool persistStorage = true,
    void Function(String json)? onEvent,
  }) => runRequest(
    script: 'search',
    timeout: timeout,
    persistStorage: persistStorage,
    stream: StreamOptions(
      idle: const Duration(seconds: 7),
      onEvent: onEvent ?? events.add,
    ),
  );

  Future<void> start({
    FakePluginEngine? engine,
    Duration streamWait = const Duration(seconds: 10),
    Duration settle = const Duration(milliseconds: 50),
    RunAdmission? streamAdmission,
    Map<String, Object?>? manifest,
  }) async {
    events.clear();
    h = InstallHarness(exclusiveWait: const Duration(milliseconds: 60));
    spy = _SpyStore(h);
    r = RunnerHarness(
      h,
      engine: engine,
      storage: spy,
      streamWait: streamWait,
      settle: settle,
      streamAdmission: streamAdmission,
      grace: const Duration(milliseconds: 80),
    );
    await r.install(manifest: manifest);
  }

  tearDown(() async {
    r.dispose();
    await h.dispose();
  });

  /// Starts a stream run that stays in the engine until it is cancelled.
  (Future<RunOutcome>, RunCancel) hold() {
    r.engine.streamUntilCancelled = true;
    final cancel = RunCancel();
    final run = r.runner.run(streamRequest(), cancel: cancel);
    return (run, cancel);
  }

  test('stream events reach onEvent in order before the outcome', () async {
    await start();
    r.engine.streamSteps = [
      const StreamStep.event('{"a":1}'),
      const StreamStep.event('{"b":2}'),
    ];
    final order = <String>[];
    final outcome = await r.runner.run(streamRequest(onEvent: order.add));
    order.add('outcome');

    expect(outcome, isA<RunOk>());
    expect(order, ['{"a":1}', '{"b":2}', 'outcome']);
    expect(r.engine.streamIdles.single, const Duration(seconds: 7));
    expect(r.engine.requests, isEmpty, reason: 'not the normal engine path');
  });

  test('events after outer-deadline outcome are dropped', () async {
    await start();
    r.engine.streamNeverCompletes = true;
    final outcome = await r.runner.run(
      streamRequest(timeout: const Duration(milliseconds: 40)),
    );

    expect((outcome as RunFailed).reason, RunFailReason.timeout);
    r.engine.lastOnEvent!('{"late":1}');
    expect(events, isEmpty);
  });

  test('event arriving after settle timeout is dropped', () async {
    await start(settle: const Duration(milliseconds: 40));
    r.engine.streamNeverCompletes = true;
    await r.runner.run(
      streamRequest(timeout: const Duration(milliseconds: 40)),
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));

    r.engine.lastOnEvent!('{"late":1}');
    expect(events, isEmpty);
  });

  test('onEvent throwing does not end the run and is logged by type', () async {
    await start();
    r.engine.streamSteps = [
      const StreamStep.event('first'),
      const StreamStep.event('second'),
    ];
    final seen = <String>[];
    final records = <String>[];
    final sub = Logger.root.onRecord.listen((e) => records.add(e.message));
    addTearDown(sub.cancel);

    final outcome = await r.runner.run(
      streamRequest(
        onEvent: (json) {
          seen.add(json);
          throw StateError('secret-conversation');
        },
      ),
    );

    expect(outcome, isA<RunOk>());
    expect(seen, ['first', 'second']);
    expect(records.any((m) => m.contains('StateError')), isTrue);
    expect(records.any((m) => m.contains('secret-conversation')), isFalse);
  });

  test(
    'cancel mid-stream ends RunCancelled(caller) and closes streams',
    () async {
      await start();
      r.engine.streamSteps = [
        StreamStep.call(
          openCall(1, 'https://x.test/s', installId: demoPluginId),
        ),
      ];
      final (run, cancel) = hold();
      await waitFor(() => r.engine.streamExchanges.isNotEmpty);
      expect(r.tables.single.length, 1);
      expect(r.tables.single.isSealed, isFalse);

      cancel.cancel();

      expect((await run as RunCancelled).reason, RunCancelReason.caller);
      expect(r.tables.single.isSealed, isTrue);
      expect(r.tables.single.length, 0);
      expect(r.engine.cancelled, [1]);
    },
  );

  test('needs-config never starts the engine', () async {
    await start(
      manifest: withConfig({
        'key': {
          'title': 'API key',
          'mode': 'input',
          'format': 'text',
          'required': true,
        },
      }),
    );
    final outcome = await r.runner.run(streamRequest());

    expect((outcome as RunNeedsConfig).fieldTitles, ['API key']);
    expect(r.engine.beginCalls, 0);
    expect(r.streamAdmission.inUse, 0);
  });

  test('second stream request waits then runs', () async {
    await start();
    final (first, cancel) = hold();
    await waitFor(() => r.engine.active == 1);
    r.engine.streamUntilCancelled = false;
    final second = r.runner.run(streamRequest());
    await waitFor(() => r.streamAdmission.waiting == 1);
    expect(r.engine.streamRequests, hasLength(1));

    cancel.cancel();

    expect(await first, isA<RunCancelled>());
    expect(await second, isA<RunOk>());
    expect(r.engine.streamRequests, hasLength(2));
    expect(r.engine.maxActive, 1);
    expect(r.streamAdmission.inUse, 0);
  });

  test('stream wait over 10 s returns RunBusy and setup ran once', () async {
    await start(streamWait: const Duration(milliseconds: 60));
    final (first, cancel) = hold();
    await waitFor(() => r.engine.active == 1);
    final readsBefore = spy.reads;

    final outcome = await r.runner.run(streamRequest());

    expect(outcome, isA<RunBusy>());
    expect(spy.reads - readsBefore, 1, reason: 'no restart after the wait');
    expect(r.engine.streamRequests, hasLength(1));
    expect(r.streamAdmission.waiting, 0);
    cancel.cancel();
    await first;
  });

  test('timer and slot grant in the same tick → slot released, RunBusy, no restart', () async {
    final admission = _LateAdmission();
    await start(
      streamAdmission: admission,
      streamWait: const Duration(milliseconds: 30),
    );
    final readsBefore = spy.reads;

    final outcome = await r.runner.run(streamRequest());

    expect(outcome, isA<RunBusy>());
    expect(admission.inUse, 0, reason: 'the late slot was given back');
    expect(spy.reads - readsBefore, 1);
    expect(r.engine.streamRequests, isEmpty);
    expect(r.engine.beginCalls, 0);
  });

  test('rebuilding pluginRunnerProvider keeps the stream slot held', () async {
    // Only so the shared tear-down has something to dispose.
    await start();
    final state = StateHarness(
      more: [pluginEngineProvider.overrideWithValue(FakePluginEngine())],
    );
    addTearDown(state.dispose);
    final c = state.container;
    final slot = (await c.read(streamRunAdmissionProvider).acquire())!;
    final before = c.read(pluginRunnerProvider);

    c.invalidate(pluginRunnerProvider);
    final after = c.read(pluginRunnerProvider);

    expect(identical(before, after), isFalse, reason: 'the runner was rebuilt');
    expect(c.read(streamRunAdmissionProvider).inUse, 1);
    slot.release();
    expect(c.read(streamRunAdmissionProvider).inUse, 0);
  });

  test(
    'hung engine job releases the slot after wall + grace + settle',
    () async {
      await start(settle: const Duration(milliseconds: 200));
      r.engine.streamNeverCompletes = true;

      final outcome = await r.runner.run(
        streamRequest(timeout: const Duration(milliseconds: 40)),
      );

      expect((outcome as RunFailed).reason, RunFailReason.timeout);
      expect(r.streamAdmission.inUse, 1, reason: 'the runtime has not let go');
      await waitFor(() => r.streamAdmission.inUse == 0);

      r.engine.streamNeverCompletes = false;
      expect(await r.runner.run(streamRequest()), isA<RunOk>());

      r.engine.streamResult = const EngineResult(status: EngineStatus.busy);
      expect(await r.runner.run(streamRequest()), isA<RunBusy>());
      expect(r.streamAdmission.inUse, 0);
    },
  );

  test('normal runs are not blocked by a running stream', () async {
    await start();
    final (first, cancel) = hold();
    await waitFor(() => r.engine.active == 1);

    final normal = await r.runner.run(runRequest());

    expect(normal, isA<RunOk>());
    expect(r.engine.requests, hasLength(1));
    cancel.cancel();
    await first;
  });

  test('stream wall 300 s, normal 90 s', () async {
    await start();
    const long = Duration(minutes: 10);
    await r.runner.run(streamRequest(timeout: long));
    await r.runner.run(runRequest(timeout: long));

    expect(r.engine.streamRequests.single.timeoutMs, 300000);
    expect(r.engine.requests.single.timeoutMs, 90000);
  });

  test('rate-limited script error pauses the plugin', () async {
    await start();
    r.engine.streamResult = const EngineResult(
      status: EngineStatus.scriptError,
      errorKind: EngineErrorKind.rateLimited,
      errorMessage: 'ai:rate_limited',
      retryAfterSec: 30,
    );

    final outcome = await r.runner.run(streamRequest());

    expect((outcome as RunScriptError).kind, RunErrorKind.rateLimited);
    expect(r.pauses.until(demoPluginId), isNotNull);
    expect(await r.runner.run(streamRequest()), isA<RunPaused>());
    expect(r.engine.streamRequests, hasLength(1));
  });

  test(
    'plugin update during a stream ends RunCancelled(pluginChanged)',
    () async {
      await start();
      final (run, _) = hold();
      await waitFor(() => r.engine.active == 1);

      expect(
        await h.actions.remover.remove(demoPluginId),
        RemoveResult.removed,
      );

      expect((await run as RunCancelled).reason, RunCancelReason.pluginChanged);
      expect(r.tables.single.isSealed, isTrue);
      expect(r.streamAdmission.inUse, 0);
    },
  );

  test('RunOk carries the plugin version that ran', () async {
    await start();
    final ok = await r.runner.run(streamRequest());
    expect((ok as RunOk).pluginVersion, '3');

    r.engine.streamResult = const EngineResult(
      status: EngineStatus.scriptError,
      errorKind: EngineErrorKind.server,
      errorMessage: 'ai:server',
    );
    final error = await r.runner.run(streamRequest());
    expect((error as RunScriptError).pluginVersion, '3');
  });

  test('persistStorage false starts empty and writes nothing back', () async {
    await start();
    await spy.writeBack(
      demoPluginId,
      '{"kept":"1"}',
      expectedRev: 0,
      expectedUpdatedAt: (await h.rows.byId(demoPluginId))!.updatedAt,
    );
    spy
      ..reads = 0
      ..writes = 1;
    r.engine.streamResult = const EngineResult(
      status: EngineStatus.ok,
      outputJson: '{}',
      storageJson: '{"new":"2"}',
    );

    final outcome = await r.runner.run(streamRequest(persistStorage: false));

    expect(outcome, isA<RunOk>());
    expect(r.engine.streamRequests.single.storageJson, '');
    expect(spy.writes, 1, reason: 'only the seeding write');
    expect((await spy.read(demoPluginId)).json, '{"kept":"1"}');

    await r.runner.run(streamRequest());
    expect(r.engine.streamRequests.last.storageJson, '{"kept":"1"}');
    expect(spy.writes, 2, reason: 'a normal stream run still saves');
  });
}
