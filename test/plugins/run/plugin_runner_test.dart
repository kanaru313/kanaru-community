import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/data/run/run_cancel.dart';
import 'package:kanaru/src/plugins/domain/run/plugin_engine.dart';
import 'package:kanaru/src/plugins/domain/run/run_outcome.dart';
import 'package:logging/logging.dart';

import '../data/install_test_support.dart';
import '../data/store_test_support.dart' show testInstallId;
import '../domain/plugin_test_support.dart';
import 'support/fake_plugin_engine.dart';
import 'support/runner_support.dart';

void main() {
  late InstallHarness h;
  late RunnerHarness r;

  Future<void> start({
    FakePluginEngine? engine,
    RecordingFetchHandler? handler,
    int slots = 4,
    Map<String, Object?>? manifest,
  }) async {
    h = InstallHarness();
    r = RunnerHarness(
      h,
      engine: engine,
      handler: handler,
      slots: slots,
      grace: const Duration(milliseconds: 60),
    );
    await r.install(manifest: manifest);
  }

  tearDown(() async {
    r.dispose();
    await h.dispose();
  });

  Map<String, Object?> withForm(Map<String, Object?> form) =>
      withConfig(form)
        ..['metadata'] = (validManifest()['metadata']! as Map<String, Object?>);

  const form = {
    'note': {
      'title': 'Note',
      'mode': 'input',
      'format': 'text',
      'default': 'base',
    },
    'endpoint': {'title': 'Endpoint', 'mode': 'input', 'format': 'url'},
  };

  group('a run', () {
    test('sends the package, input, config and the run wall', () async {
      await start();
      final outcome = await r.runner.run(
        runRequest(
          input: {'title': 'Song'},
          timeout: const Duration(seconds: 30),
        ),
      );

      expect(outcome, isA<RunOk>());
      final sent = r.engine.requests.single;
      expect(sent.installId, demoPluginId);
      expect(sent.entry, 'search.js');
      expect(
        sent.files.map((f) => f.name),
        containsAll(['search.js', 'lyrics.js']),
      );
      expect(jsonDecode(sent.inputJson), {'title': 'Song'});
      expect(sent.timeoutMs, 30000);
      expect(sent.storageJson, '');
    });

    test('the wall grows by nine request spacings, at most 90 s', () async {
      h = InstallHarness();
      r = RunnerHarness(h, spacing: const Duration(milliseconds: 100));
      await r.install();
      await r.runner.run(runRequest(timeout: const Duration(seconds: 30)));
      await r.runner.run(runRequest(timeout: const Duration(seconds: 90)));
      expect(r.engine.requests[0].timeoutMs, 30900);
      expect(r.engine.requests[1].timeoutMs, 90000);
    });

    test('the runtime is reset once across many runs', () async {
      await start();
      for (var i = 0; i < 5; i++) {
        await r.runner.run(runRequest());
      }
      expect(r.engine.resetCalls, 1);
    });

    test(
      'an engine that throws is an internal failure and frees its slot',
      () async {
        final engine = FakePluginEngine((_, _) async => throw StateError('x'));
        await start(engine: engine, slots: 1);
        final first = await r.runner.run(runRequest());
        expect((first as RunFailed).reason, RunFailReason.internal);

        engine.script = (_, _) async => FakePluginEngine.okResult();
        expect(await r.runner.run(runRequest()), isA<RunOk>());
      },
    );

    test('an input that cannot be encoded leaves no job behind', () async {
      await start(slots: 1);
      final bad = runRequest(input: {'x': Object()});
      expect(await r.runner.run(bad), isA<RunFailed>());
      expect(r.engine.beginCalls, 0);
      expect(await r.runner.run(runRequest()), isA<RunOk>());
    });
  });

  group('nothing starts', () {
    test('required settings missing: the engine is never begun', () async {
      await start(
        manifest: withForm({
          'key': {
            'title': 'API key',
            'mode': 'input',
            'format': 'text',
            'required': true,
          },
        }),
      );
      final outcome = await r.runner.run(runRequest());
      expect((outcome as RunNeedsConfig).fieldTitles, ['API key']);
      expect(r.engine.beginCalls, 0);

      await h.actions.configWrites.setValue(demoPluginId, 'key', 'abc');
      expect(await r.runner.run(runRequest()), isA<RunOk>());
    });

    test(
      'unknown plugin, removed plugin, missing script, lost folder',
      () async {
        await start();
        Future<RunUnavailableReason> reasonOf(
          String id, [
          String script = 'search',
        ]) async => ((await r.runner.run(
          runRequest(installId: id, script: script),
        )) as RunUnavailable).reason;

        expect(
          await reasonOf(testInstallId(9)),
          RunUnavailableReason.notInstalled,
        );
        expect(
          await reasonOf(demoPluginId, 'translate'),
          RunUnavailableReason.noScript,
        );

        final row = (await h.rows.liveById(demoPluginId))!;
        await h.files.deleteFolder(demoPluginId, row.packageDir!);
        expect(
          await reasonOf(demoPluginId),
          RunUnavailableReason.packageUnreadable,
        );

        await h.actions.remover.remove(demoPluginId);
        expect(await reasonOf(demoPluginId), RunUnavailableReason.notInstalled);
        expect(r.engine.beginCalls, 0);
      },
    );

    test('a cancel that came first never begins the engine', () async {
      await start();
      final cancel = RunCancel()..cancel();
      final outcome = await r.runner.run(runRequest(), cancel: cancel);
      expect((outcome as RunCancelled).reason, RunCancelReason.caller);
      expect(r.engine.beginCalls, 0);
    });

    test('a cancel while waiting for a slot never begins the engine', () async {
      final engine = FakePluginEngine();
      engine.script = (req, _) => engine.untilCancelled(req.job);
      await start(engine: engine, slots: 1);
      final running = r.runner.run(runRequest());
      await waitFor(() => engine.active == 1);

      final cancel = RunCancel();
      final waiting = r.runner.run(runRequest(), cancel: cancel);
      await turns(30);
      cancel.cancel();
      final outcome = await waiting;

      expect((outcome as RunCancelled).reason, RunCancelReason.caller);
      expect(engine.beginCalls, 1);
      engine.cancel(1);
      await running;
    });
  });

  group('cancel and deadline', () {
    test('a cancel while running cancels the job', () async {
      final engine = FakePluginEngine();
      engine.script = (req, _) => engine.untilCancelled(req.job);
      await start(engine: engine);
      final cancel = RunCancel();
      final run = r.runner.run(runRequest(), cancel: cancel);
      await waitFor(() => engine.active == 1);
      cancel.cancel();
      cancel.cancel();

      final outcome = await run;
      expect((outcome as RunCancelled).reason, RunCancelReason.caller);
      expect(engine.cancelled, [1]);
    });

    test(
      'the outer deadline counts from dispatch and ends in a timeout',
      () async {
        final engine = FakePluginEngine();
        engine.script = (req, _) => engine.untilCancelled(req.job);
        await start(engine: engine);
        final outcome = await r.runner.run(
          runRequest(timeout: const Duration(milliseconds: 30)),
        );
        expect((outcome as RunFailed).reason, RunFailReason.timeout);
        expect(engine.cancelled, [1]);
      },
    );

    test('time spent waiting for a slot is not run time', () async {
      final engine = FakePluginEngine();
      var calls = 0;
      engine.script = (req, _) async {
        // The first run holds the only slot for longer than the second run's
        // whole deadline.
        if (++calls == 1) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
        }
        return FakePluginEngine.okResult();
      };
      await start(engine: engine, slots: 1);
      final first = r.runner.run(runRequest());
      await waitFor(() => engine.active == 1);
      final second = await r.runner.run(
        runRequest(timeout: const Duration(milliseconds: 30)),
      );
      expect(second, isA<RunOk>());
      expect(await first, isA<RunOk>());
    });

    test(
      'the slot stays taken until the runtime lets go after a deadline',
      () async {
        final engine = FakePluginEngine();
        final release = Completer<void>();
        var calls = 0;
        engine.script = (req, _) async {
          if (++calls == 1) {
            await release.future;
            return const EngineResult(status: EngineStatus.cancelled);
          }
          return FakePluginEngine.okResult();
        };
        await start(engine: engine, slots: 1);
        final first = await r.runner.run(
          runRequest(timeout: const Duration(milliseconds: 20)),
        );
        expect((first as RunFailed).reason, RunFailReason.timeout);

        final second = r.runner.run(runRequest());
        await turns(30);
        expect(engine.beginCalls, 1, reason: 'the worker is still busy');
        release.complete();
        expect(await second, isA<RunOk>());
      },
    );
  });

  group('pause', () {
    test(
      'a rate-limited run pauses its plugin; the next run is not sent',
      () async {
        final engine = FakePluginEngine(
          (_, _) async => const EngineResult(
            status: EngineStatus.scriptError,
            errorKind: EngineErrorKind.rateLimited,
            retryAfterSec: 30,
          ),
        );
        await start(engine: engine);
        final first = await r.runner.run(runRequest());
        expect(
          (first as RunScriptError).retryAfter,
          const Duration(seconds: 30),
        );

        final second = await r.runner.run(runRequest());
        final until = (second as RunPaused).until;
        expect(
          until.difference(DateTime.now()).inSeconds,
          inInclusiveRange(28, 30),
        );
        expect(engine.beginCalls, 1);
      },
    );

    test('a rate limit without a wait pauses for 60 s', () async {
      final engine = FakePluginEngine(
        (_, _) async => const EngineResult(
          status: EngineStatus.scriptError,
          errorKind: EngineErrorKind.rateLimited,
        ),
      );
      await start(engine: engine);
      await r.runner.run(runRequest());
      final until = r.pauses.until(demoPluginId)!;
      expect(
        until.difference(DateTime.now()).inSeconds,
        inInclusiveRange(58, 60),
      );
    });

    test('quota, a seen 429, a failure and a cancel never pause', () async {
      final results = [
        const EngineResult(
          status: EngineStatus.scriptError,
          errorKind: EngineErrorKind.quota,
        ),
        const EngineResult(
          status: EngineStatus.ok,
          outputJson: '[]',
          fetchFailure: FetchFailureInfo(kind: FetchFailureKind.rateLimited),
        ),
        const EngineResult(status: EngineStatus.timeout),
        const EngineResult(status: EngineStatus.cancelled),
      ];
      final engine = FakePluginEngine((_, _) async => results.removeAt(0));
      await start(engine: engine);
      for (var i = 0; i < 4; i++) {
        expect(await r.runner.run(runRequest()), isNot(isA<RunPaused>()));
      }
      expect(r.pauses.until(demoPluginId), isNull);
    });

    test('a pause is not another plugin\'s problem', () async {
      await start();
      r.pauses.pause(testInstallId(9), const Duration(minutes: 1));
      expect(await r.runner.run(runRequest()), isA<RunOk>());
    });
  });

  group('configAppend', () {
    test(
      'joins the stored-or-default value of the same snapshot, never saved',
      () async {
        await start(manifest: withForm(form));
        await r.runner.run(runRequest(configAppend: {'note': 'extra'}));
        Map<String, String> sent() => {
          for (final (k, v) in r.engine.requests.last.config)
            k: jsonDecode(v) as String,
        };
        expect(sent()['note'], 'base\nextra');

        await h.actions.configWrites.setValue(demoPluginId, 'note', 'mine');
        await r.runner.run(runRequest(configAppend: {'note': 'extra'}));
        expect(sent()['note'], 'mine\nextra');

        await r.runner.run(runRequest());
        expect(sent()['note'], 'mine');
        expect((await h.config.read(demoPluginId)).values, {'note': 'mine'});
      },
    );

    test('an empty append changes nothing', () async {
      await start(manifest: withForm(form));
      await r.runner.run(runRequest(configAppend: {'note': ''}));
      final sent = {for (final (k, v) in r.engine.requests.single.config) k: v};
      expect(sent['note'], '"base"');
    });

    test('refused for a url key, an undeclared key and a long value', () async {
      await start(manifest: withForm(form));
      for (final append in [
        {'endpoint': 'https://x.example.com'},
        {'missing': 'x'},
        {'note': 'x' * 1001},
      ]) {
        final outcome = await r.runner.run(runRequest(configAppend: append));
        expect(
          (outcome as RunFailed).reason,
          RunFailReason.internal,
          reason: '$append',
        );
      }
      expect(r.engine.beginCalls, 0);
      final exact = await r.runner.run(
        runRequest(configAppend: {'note': 'x' * 1000}),
      );
      expect(exact, isA<RunOk>());
    });
  });

  group('fetch binding', () {
    test(
      'the snapshot holds saved endpoints only, not manifest defaults',
      () async {
        final manifest = withForm({
          'saved': {'title': 'Saved', 'mode': 'input', 'format': 'url'},
          'fallback': {
            'title': 'Fallback',
            'mode': 'input',
            'format': 'url',
            'default': 'https://default.example.com',
          },
        });
        final engine = FakePluginEngine((req, fetch) async {
          await fetch(_request(req.installId));
          return FakePluginEngine.okResult();
        });
        await start(engine: engine, manifest: manifest);
        await h.actions.configWrites.setValue(
          demoPluginId,
          'saved',
          'https://mine.example.com:8443',
        );
        await r.runner.run(runRequest());

        final (_, ctx) = r.handler.seen.single;
        expect(ctx.userEndpoints, {'https://mine.example.com:8443'});
        expect(ctx.manifestHosts, {'music.example.com'});
        expect(ctx.consentedHosts, {'music.example.com'});
        expect(ctx.installId, demoPluginId);
      },
    );

    test(
      'a request of another plugin is invalid and never reaches the handler',
      () async {
        EngineFetchResponse? answer;
        final engine = FakePluginEngine((req, fetch) async {
          answer = await fetch(_request(testInstallId(9)));
          return FakePluginEngine.okResult();
        });
        await start(engine: engine);
        await r.runner.run(runRequest());
        expect(answer!.outcome, EngineFetchOutcome.invalidRequest);
        expect(r.handler.seen, isEmpty);
      },
    );

    test('a handler that throws answers a network failure', () async {
      EngineFetchResponse? answer;
      final handler = RecordingFetchHandler(
        (_, _) async => throw StateError('x'),
      );
      final engine = FakePluginEngine((req, fetch) async {
        answer = await fetch(_request(req.installId));
        return FakePluginEngine.okResult();
      });
      await start(engine: engine, handler: handler);
      await r.runner.run(runRequest());
      expect(answer!.outcome, EngineFetchOutcome.network);
    });

    test('two runs of one plugin keep their own fetch binding', () async {
      final release = Completer<void>();
      final cancelledAtFetch = <int, bool>{};
      final handler = RecordingFetchHandler((_, ctx) async {
        cancelledAtFetch[ctx.job] = ctx.cancel.isCancelled;
        return EngineFetchResponse(
          outcome: EngineFetchOutcome.ok,
          status: 200,
          body: Uint8List(0),
        );
      });
      final engine = FakePluginEngine();
      engine.script = (req, fetch) async {
        final stopped = engine.untilCancelled(req.job);
        final go = await Future.any<EngineResult?>([
          release.future.then((_) => null),
          stopped,
        ]);
        if (go != null) return go;
        await fetch(_request(req.installId));
        return FakePluginEngine.okResult();
      };
      await start(engine: engine, handler: handler);
      final cancelFirst = RunCancel();
      final first = r.runner.run(runRequest(), cancel: cancelFirst);
      await waitFor(() => engine.active == 1);
      final second = r.runner.run(runRequest());
      await waitFor(() => engine.active == 2);

      cancelFirst.cancel();
      release.complete();
      expect(await first, isA<RunCancelled>());
      expect(await second, isA<RunOk>());

      // Only the surviving run fetched, through its own context, still open.
      expect(cancelledAtFetch, {2: false});
      expect(r.handler.seen.single.$2.job, 2);
    });

    test('a 429 the handler saw rides on RunOk', () async {
      final handler = RecordingFetchHandler((_, ctx) async {
        ctx.rateLimitSeen = const Duration(seconds: 60);
        return EngineFetchResponse.failure(EngineFetchOutcome.rateLimited);
      });
      final engine = FakePluginEngine((req, fetch) async {
        await fetch(_request(req.installId));
        return FakePluginEngine.okResult('[]');
      });
      await start(engine: engine, handler: handler);
      final outcome = await r.runner.run(runRequest());
      expect((outcome as RunOk).rateLimitSeen, const Duration(seconds: 60));
    });
  });

  group('admission', () {
    test('12 queued runs: at most 4 at once, in order, none busy', () async {
      final engine = FakePluginEngine((req, _) async {
        await Future<void>.delayed(const Duration(milliseconds: 15));
        return FakePluginEngine.okResult();
      });
      await start(engine: engine);
      final runs = [
        for (var i = 0; i < 12; i++) r.runner.run(runRequest(input: {'n': i})),
      ];
      final outcomes = await Future.wait(runs);

      expect(outcomes.every((o) => o is RunOk), isTrue);
      expect(engine.maxActive, lessThanOrEqualTo(4));
      expect(engine.maxActive, greaterThan(1));
      final order = [
        for (final q in engine.requests) (jsonDecode(q.inputJson) as Map)['n'],
      ];
      expect(order, [for (var i = 0; i < 12; i++) i]);
    });
  });

  test('a rejected output is one log line without the output', () async {
    await start();
    final lines = <String>[];
    final sub = Logger('plugin_run').onRecord
        .listen((rec) => lines.add(rec.message));
    addTearDown(sub.cancel);
    final oldLevel = Logger.root.level;
    addTearDown(() => Logger.root.level = oldLevel);
    Logger.root.level = Level.ALL;
    r.runner.reportRejectedOutput(
      demoPluginId,
      'lyrics',
      'no lyrics in the output',
    );
    expect(lines, hasLength(1));
    expect(lines.single, contains(demoPluginId));
    expect(lines.single, contains('lyrics'));
    expect(lines.single, contains('no lyrics in the output'));
  });
}

EngineFetchRequest _request(String installId) => EngineFetchRequest(
  installId: installId,
  method: 'GET',
  url: 'https://music.example.com/x',
  headers: const [],
  body: Uint8List(0),
  deadlineMs: 1000,
  maxSends: 10,
);
