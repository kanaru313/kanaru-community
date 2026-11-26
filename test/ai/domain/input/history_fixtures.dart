import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/input/chat_input_builder.dart';
import 'package:kanaru/src/ai/domain/settings/tool_groups.dart';
import 'package:kanaru/src/ai/domain/tools/ai_tool.dart';
import 'package:kanaru/src/ai/domain/tools/tool_env.dart';

const binding = ChatBinding(
  installId: 'plug',
  installGeneration: 1,
  pluginVersion: 3,
  model: 'm1',
);

int _seq = 0;

HistoryRow row(
  AiMessageRole role,
  List<AiPart> parts, {
  String? blob,
  ChatBinding? bound,
  AiMessageState state = AiMessageState.complete,
  String? live,
}) {
  final b = bound ?? binding;
  _seq++;
  return HistoryRow(
    AiMessage(
      id: _seq,
      conversationId: 1,
      seq: _seq,
      role: role,
      parts: parts,
      state: state,
      createdAt: DateTime(2026),
      liveText: live,
      installId: role == AiMessageRole.assistant ? b.installId : null,
      installGeneration: role == AiMessageRole.assistant
          ? b.installGeneration
          : null,
      pluginVersion: role == AiMessageRole.assistant ? b.pluginVersion : null,
      model: role == AiMessageRole.assistant ? b.model : null,
    ),
    providerJson: blob,
  );
}

HistoryRow user(String text, {List<AiPart> extra = const []}) =>
    row(AiMessageRole.user, [TextPart(text), ...extra]);

ToolCallPart callPart(String id, {String name = 'search_library'}) =>
    ToolCallPart.parsed(
      id: id,
      providerId: 'p-$id',
      name: name,
      args: const {'query': 'x'},
    );

ToolResultPart resultPart(String id, String text, {bool error = false}) =>
    ToolResultPart(
      id: id,
      providerId: 'p-$id',
      name: 'search_library',
      content: [TextPart(text)],
      isError: error,
    );

/// An assistant row with [text] and calls, its tool rows (with results) and
/// a blob.
List<HistoryRow> round(
  String turn,
  int n,
  String text,
  List<String> results, {
  ChatBinding? bound,
}) {
  final ids = [for (var i = 0; i < results.length; i++) 't$turn-r$n-$i'];
  return [
    row(
      AiMessageRole.assistant,
      [TextPart(text), for (final id in ids) callPart(id)],
      blob: '{"sig":"$turn-$n"}',
      bound: bound,
    ),
    for (var i = 0; i < ids.length; i++)
      row(AiMessageRole.tool, [
        callPart(ids[i]),
        resultPart(ids[i], results[i]),
      ], state: AiMessageState.done),
  ];
}

class FakeTool extends AiTool {
  const FakeTool(
    this.name, {
    this.risk = ToolRisk.read,
    this.group = AiToolGroup.librarySearch,
  });

  @override
  final String name;
  @override
  final ToolRisk risk;
  @override
  final AiToolGroup group;
  @override
  String get description => 'tool $name';
  @override
  Map<String, Object?> get parameters => const {
    'type': 'object',
    'properties': <String, Object?>{},
  };
  @override
  Future<ToolOutcome> call(Map<String, Object?> args, ToolEnv env) async =>
      const ToolOutcome.ok('{}');
}
