import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/run/plugin_engine.dart';

import 'support/fake_plugin_engine.dart';

const _request = EngineRequest(
  job: 1,
  installId: 'p',
  files: [],
  entry: 'main.js',
  inputJson: '{}',
  timeoutMs: 1000,
  config: [],
  storageJson: '',
);

EngineStreamCall _call(EngineStreamOp op) =>
    EngineStreamCall(installId: 'p', stream: 1, op: op);

void main() {
  test('scripted events delivered in order before the result', () async {
    final engine = FakePluginEngine()
      ..streamSteps = [
        const StreamStep.event('a'),
        StreamStep.call(_call(EngineStreamOp.read)),
        const StreamStep.event('b'),
      ]
      ..streamResult = FakePluginEngine.okResult('"done"');
    final seen = <String>[];
    final result = await engine.runStreaming(
      _request,
      (_) => EngineFetchResponse.failure(EngineFetchOutcome.network),
      (call) async => EngineStreamReply(
        outcome: EngineFetchOutcome.ok,
        chunk: Uint8List.fromList([1]),
      ),
      idle: const Duration(seconds: 5),
      onEvent: seen.add,
    );
    expect(seen, ['a', 'b']);
    expect(result.outputJson, '"done"');
    expect(engine.streamExchanges.single.$2.chunk, [1]);
    expect(engine.streamIdles.single, const Duration(seconds: 5));
  });

  test('a streaming run waits for cancel and ends cancelled', () async {
    final engine = FakePluginEngine()..streamUntilCancelled = true;
    final future = engine.runStreaming(
      _request,
      (_) => EngineFetchResponse.failure(EngineFetchOutcome.network),
      (_) async => EngineStreamReply.empty(EngineFetchOutcome.ok),
      idle: const Duration(seconds: 1),
      onEvent: (_) {},
    );
    await engine.started;
    engine.cancel(1);
    expect((await future).status, EngineStatus.cancelled);
  });
}
