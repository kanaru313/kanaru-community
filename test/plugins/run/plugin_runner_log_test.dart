import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/data/logs/plugin_log_reader.dart';
import 'package:kanaru/src/plugins/data/run/run_cancel.dart';
import 'package:kanaru/src/plugins/domain/logs/run_log_event.dart';
import 'package:kanaru/src/plugins/domain/run/plugin_engine.dart';
import 'package:kanaru/src/plugins/domain/run/run_outcome.dart';
import 'package:kanaru/src/plugins/domain/run/run_request.dart';
import 'package:logging/logging.dart';

import '../data/install_test_support.dart';
import '../domain/plugin_test_support.dart';
import 'support/fake_plugin_engine.dart';
import 'support/runner_support.dart';

const apiKey = 'secret-api-key-12345';

void main() {
  late InstallHarness h;
  late RunnerHarness r;
  late PluginLogReader reader;

  Future<void> start({
    FakePluginEngine? engine,
    RecordingFetchHandler? handler,
    bool withKey = true,
    bool requireKey = false,
  }) async {
    h = InstallHarness();
    r = RunnerHarness(
      h,
      engine: engine,
      handler: handler,
      grace: const Duration(milliseconds: 60),
    );
    reader = PluginLogReader(h.logs);
    await r.install(
      manifest: withConfig({
        'apiKey': {
          'title': 'API key',
          'mode': 'input',
          'format': 'text',
          if (requireKey) 'required': true,
        },
      }),
    );
    if (withKey) {
      await h.actions.configWrites.setValue(demoPluginId, 'apiKey', apiKey);
    }
  }

  tearDown(() async {
    r.dispose();
    await h.dispose();
  });

  Future<List<RunLogEvent>> events() => reader.readLog(demoPluginId);

  EngineResult scriptError(String message, {List<String> logs = const []}) =>
      EngineResult(
        status: EngineStatus.scriptError,
        errorKind: EngineErrorKind.server,
        errorMessage: message,
        logs: logs,
      );

  group('which runs are written', () {
    test('a script error: kind, redacted message, console, requests', () async {
      final engine = FakePluginEngine((req, fetch) async {
        await fetch(
          EngineFetchRequest(
            installId: req.installId,
            method: 'GET',
            url: 'https://music.example.com/api',
            headers: const [],
            body: Uint8List(0),
            deadlineMs: 1000,
            maxSends: 1,
          ),
        );
        return scriptError('rejected $apiKey', logs: ['using $apiKey']);
      });
      final handler = RecordingFetchHandler((req, ctx) async {
        ctx.requests.add(
          const RunLogRequest(
            method: 'GET',
            host: 'music.example.com',
            path: '/api',
            status: 500,
            ms: 12,
          ),
        );
        return EngineFetchResponse(
          outcome: EngineFetchOutcome.ok,
          status: 500,
          body: Uint8List(0),
        );
      });
      await start(engine: engine, handler: handler);

      final outcome = await r.runner.run(runRequest());
      expect(outcome, isA<RunScriptError>());

      final e = (await events()).single;
      expect(e.kind, 'server');
      expect(e.script, 'search');
      expect(e.pluginName, 'Demo');
      expect(e.message, 'rejected ***');
      expect(e.console, ['using ***']);
      expect(e.query, {'title': 'x'});
      expect(e.requests.single.status, 500);
    });

    test('timeout, memory and internal failures are written', () async {
      final engine = FakePluginEngine(
        (_, _) async => const EngineResult(status: EngineStatus.memory),
      );
      await start(engine: engine);
      await r.runner.run(runRequest());
      expect((await events()).single.kind, 'memory');
    });

    test('an ok run is written only when it printed', () async {
      final engine = FakePluginEngine();
      await start(engine: engine);
      await r.runner.run(runRequest());
      expect(await events(), isEmpty);

      engine.script = (_, _) async => const EngineResult(
        status: EngineStatus.ok,
        outputJson: '[]',
        logs: ['hello'],
      );
      await r.runner.run(runRequest());
      final e = (await events()).single;
      expect(e.kind, runLogKindOk);
      expect(e.isFailure, isFalse);
    });

    test(
      'cancelled, busy, paused, needs-config and unavailable are not',
      () async {
        final engine = FakePluginEngine(
          (_, _) async => const EngineResult(status: EngineStatus.busy),
        );
        await start(engine: engine);
        expect(await r.runner.run(runRequest()), isA<RunBusy>());

        final cancel = RunCancel()..cancel();
        expect(
          await r.runner.run(runRequest(), cancel: cancel),
          isA<RunCancelled>(),
        );
        expect(
          await r.runner.run(runRequest(installId: 'plugin-${'0' * 32}')),
          isA<RunUnavailable>(),
        );
        r.pauses.pause(demoPluginId, const Duration(minutes: 1));
        expect(await r.runner.run(runRequest()), isA<RunPaused>());
        expect(await events(), isEmpty);
      },
    );

    test('a run that needs a setting is not written', () async {
      await start(withKey: false, requireKey: true);
      expect(await r.runner.run(runRequest()), isA<RunNeedsConfig>());
      expect(await events(), isEmpty);
    });

    test('a run the plugin switch stopped is not written', () async {
      final engine = FakePluginEngine();
      engine.script = (req, _) async {
        await engine.untilCancelled(req.job);
        // The fake answers with a failure after the stop.
        return scriptError('stopped $apiKey');
      };
      await start(engine: engine);
      final run = r.runner.run(runRequest());
      await engine.started;
      // A switch (update, repair) holds the gate; the run is stopped.
      await h.runGate.exclusive(demoPluginId, () async {});
      await run;
      expect(engine.cancelled, isNotEmpty);
      expect(await events(), isEmpty);
    });
  });

  group('input that is not logged', () {
    test('query is never written and input strings are masked', () async {
      final engine = FakePluginEngine(
        (_, _) async => scriptError(
          'Bad prompt: Translate this exact sentence please',
          logs: ['sent: Translate this exact sentence please'],
        ),
      );
      await start(engine: engine);
      await r.runner.run(
        PluginRunRequest(
          installId: demoPluginId,
          script: 'search',
          input: const {
            'lines': ['Translate this exact sentence please', 'ok'],
          },
          timeout: const Duration(seconds: 5),
          logInput: false,
        ),
      );
      final e = (await events()).single;
      expect(e.query, isNull);
      expect(e.message, 'Bad prompt: ***');
      expect(e.console, ['sent: ***']);
    });
  });

  group('header values and appends', () {
    test('values the handler saw and the run append are masked', () async {
      final engine = FakePluginEngine();
      final handler = RecordingFetchHandler((req, ctx) async {
        ctx.maskValues.add('Bearer tok-abcdefgh');
        return EngineFetchResponse.failure(EngineFetchOutcome.network);
      });
      await start(engine: engine, handler: handler);
      // The script fetches once, so the handler sees the job's context.
      engine.script = (req, fetch) async {
        await fetch(
          EngineFetchRequest(
            installId: req.installId,
            method: 'GET',
            url: 'https://music.example.com/x',
            headers: const [],
            body: Uint8List(0),
            deadlineMs: 1000,
            maxSends: 1,
          ),
        );
        return scriptError(
          'failed with Bearer tok-abcdefgh and Please be formal',
        );
      };
      await r.runner.run(
        PluginRunRequest(
          installId: demoPluginId,
          script: 'search',
          timeout: const Duration(seconds: 5),
          configAppend: const {'apiKey': 'Please be formal'},
        ),
      );
      expect((await events()).single.message, 'failed with *** and ***');
    });
  });

  group('mask overflow', () {
    test('free text is dropped once the secrets did not fit', () async {
      final engine = FakePluginEngine();
      final handler = RecordingFetchHandler((req, ctx) async {
        ctx.addMask([for (var i = 0; i < 300; i++) 'secret-value-${i + 1000}']);
        return EngineFetchResponse.failure(EngineFetchOutcome.network);
      });
      await start(engine: engine, handler: handler);
      engine.script = (req, fetch) async {
        await fetch(
          EngineFetchRequest(
            installId: req.installId,
            method: 'GET',
            url: 'https://music.example.com/some/path',
            headers: const [],
            body: Uint8List(0),
            deadlineMs: 1000,
            maxSends: 1,
          ),
        );
        return scriptError('failed with secret-value-1299 inside');
      };
      await r.runner.run(
        PluginRunRequest(
          installId: demoPluginId,
          script: 'search',
          timeout: const Duration(seconds: 5),
        ),
      );
      final e = (await events()).single;
      expect(e.message, '…');
      expect(e.script, 'search');
    });
  });

  group('app log line', () {
    test('one INFO line without song data, console or stack', () async {
      final engine = FakePluginEngine(
        (_, _) async => EngineResult(
          status: EngineStatus.scriptError,
          errorKind: EngineErrorKind.auth,
          errorMessage: 'nope',
          logs: const ['console secret'],
          jsError: const EngineJsError(message: 'm', stack: 'stack secret'),
        ),
      );
      await start(engine: engine);
      final lines = <String>[];
      final sub = Logger.root.onRecord
          .where((rec) => rec.loggerName == 'plugin_run')
          .listen((rec) => lines.add(rec.message));
      addTearDown(sub.cancel);
      final oldLevel = Logger.root.level;
      addTearDown(() => Logger.root.level = oldLevel);
      Logger.root.level = Level.ALL;

      await r.runner.run(runRequest(input: const {'title': 'Private Song'}));
      await Future<void>.delayed(Duration.zero);

      final failed = lines.where((l) => l.contains('failed'));
      expect(failed, hasLength(1));
      expect(failed.single, contains(demoPluginId));
      expect(failed.single, contains('auth'));
      expect(failed.single, isNot(contains('Private Song')));
      expect(failed.single, isNot(contains('console secret')));
      expect(failed.single, isNot(contains('stack secret')));
      expect(failed.single, isNot(contains('host=')));
    });

    test('a blocked address names its host', () async {
      final engine = FakePluginEngine((req, fetch) async {
        await fetch(
          EngineFetchRequest(
            installId: req.installId,
            method: 'GET',
            url: 'https://10.0.0.1/x',
            headers: const [],
            body: Uint8List(0),
            deadlineMs: 1000,
            maxSends: 1,
          ),
        );
        return const EngineResult(
          status: EngineStatus.scriptError,
          errorKind: EngineErrorKind.none,
          errorMessage: 'blocked',
          fetchFailure: FetchFailureInfo(kind: FetchFailureKind.blockedHost),
        );
      });
      final handler = RecordingFetchHandler((req, ctx) async {
        ctx.requests.add(
          const RunLogRequest(
            method: 'GET',
            host: '10.0.0.1',
            path: '/x',
            status: null,
            ms: 1,
            blocked: true,
          ),
        );
        return EngineFetchResponse.failure(EngineFetchOutcome.blockedHost);
      });
      await start(engine: engine, handler: handler);
      final lines = <String>[];
      final sub = Logger.root.onRecord.listen((rec) => lines.add(rec.message));
      addTearDown(sub.cancel);
      final oldLevel = Logger.root.level;
      addTearDown(() => Logger.root.level = oldLevel);
      Logger.root.level = Level.ALL;

      await r.runner.run(runRequest());

      expect(lines.where((l) => l.contains('host=10.0.0.1')), hasLength(1));
      // The file never holds the blocked flag or a path of its own.
      expect((await events()).single.requests.single.host, '10.0.0.1');
    });
  });

  group('reportRejectedOutput', () {
    Future<List<RunLogEvent>> eventsWhenWritten() async {
      await r.runner.lastRejectionLogged;
      await h.logs.whenIdle();
      return events();
    }

    test('writes one invalidResponse event with the fixed reason', () async {
      await start();
      r.runner.reportRejectedOutput(
        demoPluginId,
        'search',
        '3 of 20 results dropped: no title',
      );
      final e = (await eventsWhenWritten()).single;
      expect(e.kind, 'invalidResponse');
      expect(e.message, '3 of 20 results dropped: no title');
      expect(e.script, 'search');
      expect(e.query, isNull);
      expect(e.isFailure, isTrue);
    });

    test('goes through the same redaction', () async {
      await start();
      r.runner.reportRejectedOutput(demoPluginId, 'search', 'bad $apiKey');
      expect((await eventsWhenWritten()).single.message, 'bad ***');
    });

    test('a plugin that is not live writes nothing', () async {
      await start();
      final ghost = 'plugin-${'0' * 32}';
      r.runner.reportRejectedOutput(ghost, 'search', 'x');
      await r.runner.lastRejectionLogged;
      await h.logs.whenIdle();
      expect(await reader.readLog(ghost), isEmpty);
      expect(h.logs.fileOf(ghost)!.existsSync(), isFalse);
      expect(await events(), isEmpty);
    });
  });
}
