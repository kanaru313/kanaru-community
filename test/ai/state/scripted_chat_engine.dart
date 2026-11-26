import 'dart:async';
import 'dart:convert';

import 'package:kanaru/src/plugins/domain/run/plugin_engine.dart';

import '../../plugins/run/support/fake_plugin_engine.dart';

/// What the scripted chat plugin does in one round: emits [events] (JSON
/// text), then returns [output] (the `Response.success` JSON), or waits for
/// its job to be cancelled.
class ScriptedRound {
  const ScriptedRound({
    this.events = const [],
    this.output = '',
    this.untilCancelled = false,
    this.gate,
  });

  /// A plain reply: streamed in [chunks], ended with [text].
  factory ScriptedRound.reply(String text, {List<String>? chunks}) =>
      ScriptedRound(
        events: [
          for (final c in chunks ?? [text]) textEvent(c),
        ],
        output: jsonEncode({'finish': 'stop', 'text': text}),
      );

  /// A reply that asks for tool calls.
  factory ScriptedRound.calls(List<Map<String, Object?>> calls) =>
      ScriptedRound(
        output: jsonEncode({
          'finish': 'tool_calls',
          'text': '',
          'toolCalls': calls,
          'provider': {'blob': 1},
        }),
      );

  final List<String> events;
  final String output;
  final bool untilCancelled;

  /// The run waits for this before it ends (a long-running round).
  final Completer<void>? gate;
}

String textEvent(String delta) => jsonEncode({'t': 'text', 'd': delta});

/// A fake engine whose streaming runs follow [rounds], one per run.
class ScriptedChatEngine extends FakePluginEngine {
  final rounds = <ScriptedRound>[];

  /// The `input` of every run, parsed.
  List<Map<String, Object?>> get inputs => [
    for (final r in streamRequests)
      jsonDecode(r.inputJson) as Map<String, Object?>,
  ];

  @override
  Future<EngineResult> runStreaming(
    EngineRequest request,
    EngineFetch fetch,
    EngineStream stream, {
    required Duration idle,
    required void Function(String json) onEvent,
  }) async {
    final round = rounds.isEmpty
        ? ScriptedRound.reply('ok')
        : rounds.removeAt(0);
    streamSteps = [for (final e in round.events) StreamStep.event(e)];
    streamResult = FakePluginEngine.okResult(round.output);
    streamUntilCancelled = round.untilCancelled;
    await round.gate?.future;
    return super.runStreaming(
      request,
      fetch,
      stream,
      idle: idle,
      onEvent: onEvent,
    );
  }
}
