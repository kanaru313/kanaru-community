import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/data/logs/plugin_log_reader.dart';
import 'package:kanaru/src/plugins/domain/logs/run_log_event.dart';
import 'package:kanaru/src/plugins/domain/run/plugin_engine.dart';
import 'package:kanaru/src/plugins/domain/run/run_outcome.dart';
import 'package:kanaru/src/plugins/domain/run/run_request.dart';

import '../data/install_test_support.dart';
import '../domain/plugin_test_support.dart';
import 'support/fake_plugin_engine.dart';
import 'support/runner_support.dart';

const _apiKey = 'secret-api-key-12345';

/// A streaming engine that makes one host `fetch`, then ends as [result].
class _FetchingEngine extends FakePluginEngine {
  _FetchingEngine(this.result);

  final EngineResult result;

  @override
  Future<EngineResult> runStreaming(
    EngineRequest request,
    EngineFetch fetch,
    EngineStream stream, {
    required Duration idle,
    required void Function(String json) onEvent,
  }) async {
    await fetch(
      EngineFetchRequest(
        installId: request.installId,
        method: 'POST',
        url: 'https://music.example.com/v1/$_apiKey',
        headers: const [],
        body: Uint8List(0),
        deadlineMs: 1000,
        maxSends: 1,
      ),
    );
    return result;
  }
}

void main() {
  late InstallHarness h;
  late RunnerHarness r;

  Future<List<RunLogEvent>> run(EngineResult result) async {
    h = InstallHarness();
    final handler = RecordingFetchHandler((req, ctx) async {
      ctx.requests.add(
        const RunLogRequest(
          method: 'POST',
          host: 'music.example.com',
          path: '/v1/$_apiKey',
          status: 500,
          ms: 4,
        ),
      );
      return EngineFetchResponse(
        outcome: EngineFetchOutcome.ok,
        status: 500,
        body: Uint8List(0),
      );
    });
    r = RunnerHarness(h, engine: _FetchingEngine(result), handler: handler);
    await r.install(
      manifest: withConfig({
        'apiKey': {'title': 'API key', 'mode': 'input', 'format': 'text'},
      }),
    );
    await h.actions.configWrites.setValue(demoPluginId, 'apiKey', _apiKey);
    final outcome = await r.runner.run(
      PluginRunRequest(
        installId: demoPluginId,
        script: 'search',
        input: {'text': 'my private question'},
        timeout: const Duration(seconds: 5),
        logInput: true,
        stream: StreamOptions(
          idle: const Duration(seconds: 5),
          onEvent: (_) {},
        ),
      ),
    );
    expect(outcome, isA<RunScriptError>());
    return PluginLogReader(h.logs).readLog(demoPluginId);
  }

  tearDown(() async {
    r.dispose();
    await h.dispose();
  });

  test(
    'failed stream run log has no input, message tail, console or stack',
    () async {
      final events = await run(
        const EngineResult(
          status: EngineStatus.scriptError,
          errorKind: EngineErrorKind.quota,
          errorMessage: 'ai:quota: provider said my private question',
          jsError: EngineJsError(
            message: 'ai:quota: tail',
            stack: 'at chat (chat.js:1)',
          ),
          logs: ['console line with my private question'],
        ),
      );

      final e = events.single;
      expect(e.kind, 'quota');
      expect(e.message, 'ai:quota');
      expect(e.query, isNull);
      expect(e.stack, isNull);
      expect(e.console, isEmpty);
    },
  );

  test('the new error kinds are written as their name', () async {
    for (final kind in [
      EngineErrorKind.network,
      EngineErrorKind.unavailable,
      EngineErrorKind.unsupported,
    ]) {
      final events = await run(
        EngineResult(
          status: EngineStatus.scriptError,
          errorKind: kind,
          errorMessage: 'ai:server',
        ),
      );
      expect(events.single.kind, kind.name);
    }
  });

  test('header masks still applied', () async {
    final events = await run(
      const EngineResult(
        status: EngineStatus.scriptError,
        errorKind: EngineErrorKind.server,
        errorMessage: 'upstream text without a code',
      ),
    );

    final e = events.single;
    expect(e.message, isNull, reason: 'no ai: code, no text');
    final request = e.requests.single;
    expect(request.path, isNot(contains(_apiKey)));
    expect(request.path, '/v1/…');
  });
}
