import 'dart:async';
import 'dart:convert';

import 'package:kanaru/src/ai/data/conversation_store.dart';
import 'package:kanaru/src/ai/data/loop_store_adapter.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_conversation.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/loop/loop_driver.dart';
import 'package:kanaru/src/ai/domain/loop/loop_ports.dart';
import 'package:kanaru/src/ai/domain/permission.dart';
import 'package:kanaru/src/ai/domain/settings/tool_groups.dart';
import 'package:kanaru/src/ai/domain/tools/ai_tool.dart';
import 'package:kanaru/src/ai/domain/tools/ai_tool_registry.dart';
import 'package:kanaru/src/ai/domain/tools/tool_env.dart';
import 'package:kanaru/src/database/database.dart';
import 'package:kanaru/src/plugins/domain/package/chat_spec.dart';
import 'package:kanaru/src/plugins/domain/run/run_outcome.dart';

import '../../data/conversation_store_fixtures.dart';
import '../tools/fake_tool_env.dart';

/// The plugin output of one reply.
String replyJson(String text, {List<Map<String, Object?>> calls = const []}) =>
    jsonEncode({
      'finish': calls.isEmpty ? 'stop' : 'tool_calls',
      'text': text,
      'toolCalls': calls,
      'provider': {'blob': 1},
    });

Map<String, Object?> toolCall(String name, [Map<String, Object?>? args]) => {
  'name': name,
  'args': args ?? const <String, Object?>{},
};

/// What a scripted round can do while it runs.
class RoundCtl {
  RoundCtl(this.onDelta, this.cancelled);

  final void Function(String) onDelta;

  /// Completes when the driver cancels the round.
  final Future<void> cancelled;
}

typedef Step = Future<RunOutcome> Function(RoundCtl ctl);

Step replies(String text, {List<Map<String, Object?>> calls = const []}) =>
    (ctl) async => RunOk(replyJson(text, calls: calls), pluginVersion: '3');

/// Streams [deltas], then waits to be cancelled.
Step streamThenHang(List<String> deltas) => (ctl) async {
  deltas.forEach(ctl.onDelta);
  await ctl.cancelled;
  return const RunCancelled(RunCancelReason.caller);
};

class FakeRunner implements ModelRoundRunner {
  FakeRunner([Iterable<Step> script = const []]) : script = [...script];

  final List<Step> script;
  final List<ModelRoundRequest> requests = [];
  Completer<void> _cancelled = Completer<void>();

  int get runs => requests.length;

  @override
  Future<RunOutcome> run(
    ModelRoundRequest request, {
    required void Function(String delta) onDelta,
  }) {
    requests.add(request);
    if (script.isEmpty) throw StateError('no scripted round left');
    _cancelled = Completer<void>();
    return script.removeAt(0)(RoundCtl(onDelta, _cancelled.future));
  }

  @override
  void cancel() {
    if (!_cancelled.isCompleted) _cancelled.complete();
  }
}

/// A tool whose run is scripted.
class FakeTool extends AiTool {
  FakeTool(
    this.name, {
    this.risk = ToolRisk.read,
    this.group = AiToolGroup.librarySearch,
    this.onRun,
  });

  @override
  final String name;
  @override
  final ToolRisk risk;
  @override
  final AiToolGroup group;
  final Future<ToolOutcome> Function(Map<String, Object?> args, ToolEnv env)?
  onRun;

  /// The arguments of every run, in order.
  final List<Map<String, Object?>> runs = [];

  @override
  String get description => 'fake $name';

  @override
  Map<String, Object?> get parameters => const {
    'type': 'object',
    'properties': {
      'tag': {'type': 'string'},
    },
  };

  @override
  Future<ToolOutcome> call(Map<String, Object?> args, ToolEnv env) async {
    runs.add(args);
    return onRun != null ? onRun!(args, env) : ToolOutcome.ok('{"ok":true}');
  }
}

LoopPlugin pluginOf({
  String installId = 'plug',
  int generation = 1,
  String model = 'm1',
  bool tools = true,
}) => LoopPlugin(
  installId: installId,
  installGeneration: generation,
  version: 3,
  model: model,
  capabilities: ChatCapabilities(tools: tools, context: 200000),
);

class FakeEnv implements LoopEnvironment {
  FakeEnv(List<AiTool> tools)
    : registry = AiToolRegistry([BuiltinToolProvider(tools)]);

  @override
  final AiToolRegistry registry;
  @override
  ToolEnv toolEnv = fakeEnv();
  LoopSettings current = const LoopSettings();
  LoopPlugin? installed = pluginOf();

  /// Runs when the loop asks for the plugin (between reading and writing).
  Future<void> Function()? onPlugin;

  @override
  Future<LoopSettings> settings() async => current;

  @override
  Future<LoopPlugin?> plugin(AiConversation conversation) async {
    await onPlugin?.call();
    return installed;
  }
}

/// A conversation bound to `plug` v1 / `m1` on an in-memory database.
class Rig {
  Rig._(this.db, this.store, this.conv, this.runner, this.env, this.clock);

  static Future<Rig> create({
    AiPermission permission = AiPermission.ask,
    List<AiTool>? tools,
    List<Step> script = const [],
  }) async {
    final db = openDb();
    final store = ConversationStore(db);
    final conv = await store.create(
      title: 'Chat',
      permission: permission,
      installId: 'plug',
      installGeneration: 1,
      model: 'm1',
    );
    final env = FakeEnv(
      tools ??
          [
            FakeTool('read_a'),
            FakeTool('read_b'),
            FakeTool(
              'write_a',
              risk: ToolRisk.write,
              group: AiToolGroup.queueEdit,
            ),
            FakeTool(
              'write_b',
              risk: ToolRisk.write,
              group: AiToolGroup.queueEdit,
            ),
          ],
    );
    final rig = Rig._(db, store, conv, FakeRunner(script), env, DateTime.now);
    rig.driver = rig.newDriver();
    return rig;
  }

  final AppDatabase db;
  final ConversationStore store;
  final AiConversation conv;
  final FakeRunner runner;
  final FakeEnv env;
  DateTime Function() clock;
  final List<Object> errors = [];
  late LoopDriver driver;

  FakeTool tool(String name) => env.registry.byName(name)! as FakeTool;

  /// A fresh driver on the same data, like the app after a restart.
  LoopDriver newDriver({Duration toolTimeout = const Duration(seconds: 30)}) =>
      LoopDriver(
        conversationId: conv.id,
        store: LoopStoreAdapter(store),
        runner: runner,
        env: env,
        now: () => clock(),
        toolTimeout: toolTimeout,
        newBoundary: () => 'kfixedbound',
        onInternalError: (e, s) => errors.add(e),
      );

  Future<List<AiMessage>> rows() async => [
    for (final m in await store.messages(conv.id, limit: 1000)) m.message,
  ];

  /// The tool rows, in order.
  Future<List<AiMessage>> cards() async => [
    for (final m in await rows())
      if (m.role == AiMessageRole.tool) m,
  ];

  /// Stores a user message and one finished round with a call per name, the
  /// way a crash between the round and its tools leaves them: `allowed`, or
  /// `pending` with a confirm part when [confirm]. Returns the tool rows.
  Future<List<AiMessage>> seedRound(
    List<String> names, {
    bool confirm = false,
  }) async {
    final user = await store.append(
      NewAiMessage(
        conversationId: conv.id,
        role: AiMessageRole.user,
        parts: const [TextPart('go')],
      ),
    );
    final assistant = await store.append(
      NewAiMessage(
        conversationId: conv.id,
        role: AiMessageRole.assistant,
        state: AiMessageState.streaming,
        installId: 'plug',
        installGeneration: 1,
        pluginVersion: 3,
        model: 'm1',
      ),
    );
    final calls = [
      for (var i = 0; i < names.length; i++)
        ToolCallPart.parsed(
          id: 't${user.message.id}-r1-$i',
          name: names[i],
          args: const {},
        ),
    ];
    await store.completeRound(
      messageId: assistant.message.id,
      finalParts: [const TextPart('x'), ...calls],
      blob: '{"blob":1}',
      calls: [
        for (final c in calls) ToolCardDraft(call: c, needsConfirm: confirm),
      ],
    );
    return cards();
  }

  Future<void> send(String text) async {
    final r = await driver.send([TextPart(text)]);
    if (r is DriverStarted) await r.done;
  }

  Future<void> dispose() async {
    await driver.dispose();
    store.dispose();
    await db.close();
  }
}

/// The text of the result of a tool row.
String resultText(AiMessage card) {
  for (final p in card.parts) {
    if (p is ToolResultPart) {
      return p.content.whereType<TextPart>().map((t) => t.text).join();
    }
  }
  return '';
}

/// `name:state` per tool row, in order.
List<String> cardStates(List<AiMessage> cards) => [
  for (final c in cards)
    '${(c.parts.whereType<ToolCallPart>().first).name}:${c.state.name}',
];
