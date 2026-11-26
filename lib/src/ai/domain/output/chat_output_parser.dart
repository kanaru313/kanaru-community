import 'dart:convert';

import '../conversation/parts.dart';
import '../text/text_sanitizer.dart';

/// Calls the app accepts from one reply, per round and per turn (chat
/// contract, App guarantees).
const chatMaxCallsPerRound = 8;
const chatMaxCallsPerTurn = 24;
const chatMaxToolNameLength = 64;

final _providerId = RegExp(r'^[A-Za-z0-9_.:-]{1,64}$');

/// Why a reply ended.
enum ChatFinish {
  stop('stop'),
  toolCalls('tool_calls'),
  length('length'),

  /// A content filter refused: a normal result, not a failure.
  blocked('blocked');

  const ChatFinish(this.wire);

  final String wire;
}

/// Why a call the model made is answered with an error result instead of
/// running.
enum ChatCallRefusal {
  /// The name is not a tool offered in this round.
  unknownTool('unknown tool'),

  /// A final round offers no tool to call.
  noToolsInThisRound('tools are not available for this reply'),

  /// The arguments were not valid JSON.
  rawArguments('the arguments were not valid JSON');

  const ChatCallRefusal(this.modelText);

  /// What the model reads in the error result.
  final String modelText;
}

/// One call of a reply with the verdict the loop acts on.
class ChatParsedCall {
  const ChatParsedCall(this.part, {this.refusal});

  /// The call as stored: app id, provider id kept per the contract, name cut
  /// to 64 characters. A refused unknown call has no arguments.
  final ToolCallPart part;

  /// Null when the call may run (still subject to schema checks and the
  /// permission gate).
  final ChatCallRefusal? refusal;
}

/// What a valid reply holds.
class ChatRoundOutput {
  const ChatRoundOutput({
    required this.finish,
    required this.text,
    required this.calls,
    this.providerJson,
    this.inputTokens,
    this.outputTokens,
  });

  final ChatFinish finish;

  /// The full assistant text, cleaned for the screen.
  final String text;
  final List<ChatParsedCall> calls;

  /// The plugin's opaque `provider` blob as JSON text, or null.
  final String? providerJson;
  final int? inputTokens;
  final int? outputTokens;
}

/// What a limit counted by the caller was about.
enum ChatLimitKind { callsPerTurn, itemsRemoved, itemsAdded }

/// The reply asked for more than one turn may do. Its own card, never a
/// retryable error: asking again would ask for the same.
class ChatLimitExceeded {
  const ChatLimitExceeded(this.kind);

  final ChatLimitKind kind;
}

/// The loop's item counter (removed at most 50, added at most 200 per turn):
/// returns the limit [calls] break, or null. Only calls without a refusal are
/// passed.
typedef ChatItemLimitCheck = ChatLimitExceeded? Function(
  List<ToolCallPart> calls,
);

sealed class ChatOutputResult {
  const ChatOutputResult();
}

final class ChatOutputOk extends ChatOutputResult {
  const ChatOutputOk(this.output);

  final ChatRoundOutput output;
}

/// The output is not a valid reply (shape, caps).
final class ChatOutputRejected extends ChatOutputResult {
  const ChatOutputRejected(this.reason);

  /// A short developer reason; never shown, never stored.
  final String reason;
}

final class ChatOutputLimit extends ChatOutputResult {
  const ChatOutputLimit(this.limit);

  final ChatLimitExceeded limit;
}

/// Reads the plugin's final result. [turn] and [round] build the call ids
/// `t<turn>-r<round>-<n>`; [offeredNames] are the tools of this round;
/// [finalRound] is a round sent with `toolChoice: "none"`;
/// [callsSoFarInTurn] counts the calls of earlier rounds of the turn;
/// [itemLimit] is the caller's item counter.
ChatOutputResult parseChatOutput(
  String json, {
  required int turn,
  required int round,
  required Set<String> offeredNames,
  required bool finalRound,
  int callsSoFarInTurn = 0,
  ChatItemLimitCheck? itemLimit,
}) {
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException {
    return const ChatOutputRejected('output is not JSON');
  }
  if (decoded is! Map<String, Object?>) {
    return const ChatOutputRejected('output is not an object');
  }
  final finish = _finishOf(decoded['finish']);
  if (finish == null) return const ChatOutputRejected('unknown finish');
  final rawText = decoded['text'];
  if (rawText is! String) return const ChatOutputRejected('text is missing');
  final rawCalls = decoded['toolCalls'] ?? const <Object?>[];
  if (rawCalls is! List<Object?>) {
    return const ChatOutputRejected('toolCalls is not a list');
  }
  if (rawCalls.length > chatMaxCallsPerRound) {
    return const ChatOutputRejected('too many calls in one round');
  }
  final text = sanitizeText(rawText, keepLineBreaks: true);
  if (text.trim().isEmpty && rawCalls.isEmpty && finish != ChatFinish.blocked) {
    return const ChatOutputRejected('empty reply');
  }

  final calls = <ChatParsedCall>[];
  for (var i = 0; i < rawCalls.length; i++) {
    final raw = rawCalls[i];
    if (raw is! Map<String, Object?> || raw['name'] is! String) {
      return const ChatOutputRejected('a tool call has no name');
    }
    calls.add(
      _parseCall(
        raw,
        id: 't$turn-r$round-$i',
        offeredNames: offeredNames,
        finalRound: finalRound,
      ),
    );
  }
  if (callsSoFarInTurn + calls.length > chatMaxCallsPerTurn) {
    return const ChatOutputLimit(ChatLimitExceeded(ChatLimitKind.callsPerTurn));
  }
  final runnable = [
    for (final c in calls)
      if (c.refusal == null) c.part,
  ];
  final limit = runnable.isEmpty ? null : itemLimit?.call(runnable);
  if (limit != null) return ChatOutputLimit(limit);

  final provider = decoded['provider'];
  final usage = decoded['usage'];
  return ChatOutputOk(
    ChatRoundOutput(
      finish: finish,
      text: text,
      calls: List.unmodifiable(calls),
      providerJson: provider is Map<String, Object?>
          ? jsonEncode(provider)
          : null,
      inputTokens: usage is Map ? _intOf(usage['input']) : null,
      outputTokens: usage is Map ? _intOf(usage['output']) : null,
    ),
  );
}

ChatParsedCall _parseCall(
  Map<String, Object?> raw, {
  required String id,
  required Set<String> offeredNames,
  required bool finalRound,
}) {
  final rawName = raw['name']! as String;
  final name = rawName.length > chatMaxToolNameLength
      ? rawName.substring(0, chatMaxToolNameLength)
      : rawName;
  final providerId = raw['providerId'];
  final keptId = providerId is String && _providerId.hasMatch(providerId)
      ? providerId
      : null;
  final known =
      rawName.length <= chatMaxToolNameLength && offeredNames.contains(rawName);
  if (!known) {
    // Stored without arguments: they were meant for a tool that is not there.
    return ChatParsedCall(
      ToolCallPart.parsed(
        id: id,
        providerId: keptId,
        name: name,
        args: const {},
      ),
      refusal: ChatCallRefusal.unknownTool,
    );
  }
  final args = raw['args'];
  final ToolCallPart part;
  var refusal = finalRound ? ChatCallRefusal.noToolsInThisRound : null;
  if (args == null) {
    part = ToolCallPart.parsed(
      id: id,
      providerId: keptId,
      name: name,
      args: const {},
    );
  } else if (args is Map<String, Object?>) {
    part = ToolCallPart.parsed(
      id: id,
      providerId: keptId,
      name: name,
      args: args,
    );
  } else {
    // A string is the plugin's unparsed text; any other JSON is not an
    // arguments object either. Never replaced by `{}`.
    part = ToolCallPart.raw(
      id: id,
      providerId: keptId,
      name: name,
      rawArgs: args is String ? args : jsonEncode(args),
    );
    refusal ??= ChatCallRefusal.rawArguments;
  }
  return ChatParsedCall(part, refusal: refusal);
}

ChatFinish? _finishOf(Object? raw) {
  for (final f in ChatFinish.values) {
    if (f.wire == raw) return f;
  }
  return null;
}

int? _intOf(Object? v) => v is int && v >= 0 ? v : null;
