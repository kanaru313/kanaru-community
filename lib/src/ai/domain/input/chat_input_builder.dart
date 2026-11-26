import '../../../plugins/domain/package/chat_spec.dart';
import '../tools/ai_tool.dart';
import 'byte_budget.dart';
import 'history_turns.dart';

export 'history_turns.dart' show ChatBinding, HistoryRow;

/// Result of building one request.
sealed class ChatInputResult {
  const ChatInputResult();
}

final class ChatInputBuilt extends ChatInputResult {
  const ChatInputBuilt(this.input, {required this.bytes});

  /// The plugin's `input` object (chat contract), ready for `jsonEncode`.
  final Map<String, Object?> input;
  final int bytes;
}

/// Nothing is left to trim and the request still does not fit: the chat gets
/// the `too_large` card.
final class ChatInputTooLarge extends ChatInputResult {
  const ChatInputTooLarge({required this.bytes, required this.limit});

  final int bytes;
  final int limit;
}

enum _Mode { whole, flat, dropped, userOnly }

/// Builds the input of one round.
///
/// [history] is every stored row of the conversation in `seq` order, the
/// current turn last (its user message is the one just sent). [tools] are
/// the tools of this request (`offeredTools`); [finalRound] sends the same
/// tools with `toolChoice: "none"`.
///
/// Older turns are sent whole only while [binding] matches the plugin
/// install, generation, version and model they were written with, else
/// flattened to text. When the input is over the limit, trimming goes:
/// flatten the oldest turns, drop the oldest turns (the first user message
/// stays), elide the oldest tool-result contents of the current turn (calls,
/// results and blobs stay as pairs), then [ChatInputTooLarge]. A turn is
/// always whole or flattened: a blob never loses its calls, nor the reverse.
ChatInputResult buildChatInput({
  required ChatBinding binding,
  required List<HistoryRow> history,
  required List<AiTool> tools,
  required ChatCapabilities capabilities,
  required String system,
  required String boundary,
  bool finalRound = false,
  int? maxOutputTokens,
}) {
  final turns = groupTurns(history);
  final limit = chatInputByteLimit(
    context: capabilities.context,
    maxOutputTokens: maxOutputTokens,
  );
  final offered = capabilities.tools ? tools : const <AiTool>[];
  final modes = [
    for (final t in turns) t.isWholeFor(binding) ? _Mode.whole : _Mode.flat,
  ];
  final current = turns.length - 1;
  final elidable = turns.isEmpty || modes[current] != _Mode.whole
      ? const <String>[]
      : elidableResultIds(turns[current]);
  var elideCount = 0;

  Map<String, Object?> assemble() {
    final messages = <Map<String, Object?>>[];
    for (var i = 0; i < turns.length; i++) {
      final mode = modes[i];
      if (mode == _Mode.dropped) continue;
      messages.addAll(
        wireTurn(
          turns[i],
          whole: mode == _Mode.whole,
          elided: i == current ? elidable.take(elideCount).toSet() : const {},
          userOnly: mode == _Mode.userOnly,
        ),
      );
    }
    return {
      'v': 1,
      'model': binding.model,
      'system': system,
      'boundary': boundary,
      'messages': mergeSameRole(messages),
      'tools': [for (final t in offered) t.toWire()],
      'toolChoice': finalRound ? 'none' : 'auto',
      'options': {'maxOutputTokens': maxOutputTokens},
    };
  }

  // The exact size of the first try, merges of same-role neighbours
  // included. Most requests end here.
  var input = assemble();
  var bytes = jsonByteLength(input);
  // A turn that is still running is never flattened: its blob did not fit,
  // so the request cannot carry it (the loop ends such a turn after the round
  // that stored the marker).
  if (turns.isNotEmpty && turns[current].hasOversizeBlob) {
    return ChatInputTooLarge(bytes: bytes, limit: limit);
  }
  if (bytes <= limit) return ChatInputBuilt(input, bytes: bytes);

  // Trimming works on sizes: each turn is encoded once per mode and the total
  // is a sum, so a long chat is not re-encoded for every step. The sum is an
  // upper bound of the exact size (merging neighbours only shortens it).
  final base = jsonByteLength({...input, 'messages': const <Object?>[]});
  final cache = <(int, _Mode), int>{};
  int sizeOf(int i, _Mode mode) => cache[(i, mode)] ??= mode == _Mode.dropped
      ? 0
      : [
          for (final m in wireTurn(
            turns[i],
            whole: mode == _Mode.whole,
            userOnly: mode == _Mode.userOnly,
          ))
            jsonByteLength(m) + 1,
        ].fold(0, (a, b) => a + b);
  final savings = [
    for (final id in elidable) elisionSaving(turns[current], id),
  ];
  int estimate() {
    var n = base;
    for (var i = 0; i < turns.length; i++) {
      n += sizeOf(i, modes[i]);
    }
    for (var k = 0; k < elideCount; k++) {
      n -= savings[k];
    }
    return n;
  }

  bool fits() => estimate() <= limit;

  // 1. Flatten the oldest older turns that still carry tool data.
  for (var i = 0; i < current && !fits(); i++) {
    if (modes[i] == _Mode.whole && turns[i].hasToolData) modes[i] = _Mode.flat;
  }
  // 2. Drop the oldest turns, keeping the first user message.
  for (var i = 1; i < current && !fits(); i++) {
    modes[i] = _Mode.dropped;
  }
  if (!fits() && current > 0) modes[0] = _Mode.userOnly;
  // 3. Elide the oldest tool results of the current turn.
  while (!fits() && elideCount < elidable.length) {
    elideCount++;
  }

  input = assemble();
  bytes = jsonByteLength(input);
  if (bytes > limit) return ChatInputTooLarge(bytes: bytes, limit: limit);
  return ChatInputBuilt(input, bytes: bytes);
}
