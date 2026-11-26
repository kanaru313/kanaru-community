import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/data/chat_turn_runner.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_conversation.dart';
import 'package:kanaru/src/ai/domain/loop/loop_ports.dart';
import 'package:kanaru/src/ai/domain/permission.dart';
import 'package:kanaru/src/plugins/domain/install/install_id.dart';
import 'package:kanaru/src/plugins/domain/run/plugin_engine.dart';
import 'package:kanaru/src/plugins/domain/run/run_outcome.dart';
import 'package:kanaru/src/plugins/domain/run/run_request.dart';

import '../../plugins/data/install_test_support.dart';
import '../../plugins/domain/chat_test_support.dart';
import '../../plugins/run/support/fake_plugin_engine.dart';
import '../../plugins/run/support/runner_support.dart';
import '../state/scripted_chat_engine.dart';

AiConversation _conversation(String? installId) => AiConversation(
  id: 1,
  title: 't',
  titleAuto: true,
  permission: AiPermission.ask,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  lastMessageAt: DateTime(2026),
  installId: installId,
  installGeneration: 1,
);

ModelRoundRequest _request(String? installId) => ModelRoundRequest(
  conversation: _conversation(installId),
  input: const {'v': 1, 'model': 'm', 'messages': <Object?>[]},
);

void main() {
  late InstallHarness h;
  late RunnerHarness r;
  late ScriptedChatEngine engine;
  final chatId = fileInstallId('Chat', 'someone');
  final deltas = <String>[];
  final statuses = <ChatStreamStatus>[];

  Future<void> start() async {
    h = InstallHarness();
    engine = ScriptedChatEngine();
    r = RunnerHarness(h, engine: engine);
    await r.install(
      manifest: chatManifest((m) {
        (m['metadata']! as Map<String, Object?>)['author'] = 'someone';
      }),
      extra: {'src/chat.js': 'function execute(req) { return req; }'},
    );
    await h.config.setValue(chatId, 'apiKeys', 'k');
    await h.config.setValue(chatId, 'model', 'gemini-2.5-flash');
    deltas.clear();
    statuses.clear();
  }

  ChatTurnRunner runner({Duration idle = const Duration(seconds: 42)}) =>
      ChatTurnRunner(
        runner: r.runner,
        idleTimeout: (_) async => idle,
        onStatus: statuses.add,
      );

  setUp(start);

  tearDown(() async {
    r.dispose();
    await h.dispose();
  });

  test(
    'builds a stream request: chat script, idle from the manifest, no storage',
    () async {
      engine.rounds.add(ScriptedRound.reply('hi'));

      final outcome = await runner().run(_request(chatId), onDelta: deltas.add);

      expect(outcome, isA<RunOk>());
      final sent = engine.streamRequests.single;
      expect(sent.entry, endsWith('chat.js'));
      expect(engine.streamIdles.single, const Duration(seconds: 42));
      expect(jsonDecode(sent.inputJson), containsPair('model', 'm'));
      expect(sent.storageJson, isEmpty, reason: 'a chat run starts empty');
    },
  );

  test('what a chat run writes to storage is never saved', () async {
    final plain = FakePluginEngine();
    final harness = RunnerHarness(h, engine: plain);
    EngineResult writing(String json) => EngineResult(
      status: EngineStatus.ok,
      outputJson: '{"finish":"stop","text":"x"}',
      storageJson: json,
    );
    // Control: a streaming run that persists storage does save it.
    plain.streamResult = writing('{"kept":1}');
    await harness.runner.run(
      runRequest(
        installId: chatId,
        script: 'chat',
        stream: StreamOptions(
          idle: const Duration(seconds: 5),
          onEvent: (_) {},
        ),
      ),
    );
    expect((await h.storage.read(chatId)).json, contains('kept'));

    plain.streamResult = writing('{"dropped":2}');
    final outcome = await ChatTurnRunner(
      runner: harness.runner,
      idleTimeout: (_) async => const Duration(seconds: 5),
    ).run(_request(chatId), onDelta: deltas.add);

    expect(outcome, isA<RunOk>());
    final stored = (await h.storage.read(chatId)).json;
    expect(stored, contains('kept'));
    expect(stored, isNot(contains('dropped')));
    harness.dispose();
  });

  test('only an ai-chat plugin runs', () async {
    await r.install(); // the demo lyrics plugin
    final outcome = await runner().run(
      _request(demoPluginId),
      onDelta: deltas.add,
    );
    expect(
      (outcome as RunUnavailable).reason,
      RunUnavailableReason.notInstalled,
    );
    expect(engine.streamRequests, isEmpty);
  });

  test('a chat without a plugin is unavailable, nothing runs', () async {
    final outcome = await runner().run(_request(null), onDelta: deltas.add);
    expect(
      (outcome as RunUnavailable).reason,
      RunUnavailableReason.notInstalled,
    );
  });

  test('text events reach onDelta, status events onStatus', () async {
    engine.rounds.add(
      ScriptedRound(
        events: [
          '{"t":"status","s":"thinking"}',
          textEvent('a'),
          '{"t":"mystery","x":1}',
          'not json',
          textEvent('b'),
          '{"t":"status","s":"generating"}',
        ],
        output: jsonEncode({'finish': 'stop', 'text': 'ab'}),
      ),
    );

    await runner().run(_request(chatId), onDelta: deltas.add);

    expect(deltas, ['a', 'b']);
    expect(statuses, [ChatStreamStatus.thinking, ChatStreamStatus.generating]);
  });

  test('events after the outcome are dropped', () async {
    engine.rounds.add(ScriptedRound.reply('hi', chunks: ['hi']));
    await runner().run(_request(chatId), onDelta: deltas.add);
    expect(deltas, ['hi']);

    engine.lastOnEvent!(textEvent('late'));

    expect(deltas, ['hi']);
  });

  test('events after cancel are dropped and the run ends cancelled', () async {
    engine.rounds.add(
      ScriptedRound(events: [textEvent('a')], untilCancelled: true),
    );
    final chat = runner();
    final run = chat.run(_request(chatId), onDelta: deltas.add);
    await engine.started;
    await waitFor(() => deltas.isNotEmpty);

    chat.cancel();
    engine.lastOnEvent!(textEvent('after'));
    final outcome = await run;

    expect(deltas, ['a']);
    expect(outcome, isA<RunCancelled>());
  });

  test('the outcome names the plugin version that ran', () async {
    engine.rounds.add(ScriptedRound.reply('hi'));
    final outcome = await runner().run(_request(chatId), onDelta: deltas.add);
    expect((outcome as RunOk).pluginVersion, '1');
  });

  group('parseChatStreamEvent', () {
    test('reads text and status events', () {
      expect(
        (parseChatStreamEvent('{"t":"text","d":"x"}') as ChatTextEvent).delta,
        'x',
      );
      expect(
        (parseChatStreamEvent(
          '{"t":"status","s":"thinking"}',
        ) as ChatStatusEvent).status,
        ChatStreamStatus.thinking,
      );
    });

    test('ignores unknown, empty and damaged events', () {
      for (final bad in [
        '{"t":"other"}',
        '{"t":"text"}',
        '{"t":"text","d":""}',
        '{"t":"text","d":5}',
        '{"t":"status","s":"dreaming"}',
        '[]',
        '',
      ]) {
        expect(parseChatStreamEvent(bad), isNull, reason: bad);
      }
    });
  });
}
