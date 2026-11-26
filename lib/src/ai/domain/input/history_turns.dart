import 'dart:convert';

import '../conversation/ai_message.dart';
import '../conversation/parts.dart';
import '../text/text_sanitizer.dart';
import 'byte_budget.dart';

/// A stored message as the input builder reads it: the message and its
/// provider blob text (kept out of [AiMessage] because the UI never needs it).
class HistoryRow {
  const HistoryRow(this.message, {this.providerJson});

  final AiMessage message;

  /// The blob of an assistant message, or the store's too-large marker.
  final String? providerJson;
}

/// The plugin install, version and model a blob is bound to.
class ChatBinding {
  const ChatBinding({
    required this.installId,
    required this.installGeneration,
    required this.pluginVersion,
    required this.model,
  });

  final String installId;
  final int installGeneration;
  final int pluginVersion;
  final String model;

  bool matches(AiMessage m) =>
      m.installId == installId &&
      m.installGeneration == installGeneration &&
      m.pluginVersion == pluginVersion &&
      m.model == model;
}

/// A user message and every row up to the next user message.
class HistoryTurn {
  HistoryTurn(this.user, this.rows);

  final HistoryRow user;
  final List<HistoryRow> rows;

  Iterable<HistoryRow> get assistants =>
      rows.where((r) => r.message.role == AiMessageRole.assistant);

  /// Whether the whole turn may be sent with its calls, results and blobs:
  /// every assistant row of it carries this binding and a readable blob.
  bool isWholeFor(ChatBinding binding) {
    for (final row in assistants) {
      final blob = row.providerJson;
      final bound =
          blob != null || row.message.parts.any((p) => p is ToolCallPart);
      // A text-only reply carries nothing the binding protects.
      if (!bound) continue;
      if (!binding.matches(row.message)) return false;
      if (blob != null && decodeBlob(blob) == null) return false;
    }
    return true;
  }

  /// Whether flattening changes what is sent (it has calls, results or a
  /// blob). A turn that was flattened already keeps tool rows for display
  /// only: they carry neither, so they do not count.
  bool get hasToolData => rows.any(
    (r) =>
        r.providerJson != null ||
        r.message.parts.any((p) => p is ToolCallPart || p is ToolResultPart),
  );

  /// Whether an assistant row of the turn holds the store's too-large marker
  /// instead of its blob: the turn cannot be sent whole.
  bool get hasOversizeBlob =>
      assistants.any((r) => r.providerJson == oversizeBlobText);
}

/// Groups [rows] (in `seq` order) into turns. Rows before the first user
/// message belong to no turn and are left out.
List<HistoryTurn> groupTurns(List<HistoryRow> rows) {
  final turns = <HistoryTurn>[];
  for (final row in rows) {
    if (row.message.role == AiMessageRole.user) {
      turns.add(HistoryTurn(row, []));
    } else if (turns.isNotEmpty) {
      turns.last.rows.add(row);
    }
  }
  return turns;
}

/// What the store keeps in place of a blob over its size cap (same text as
/// the store's marker; the turn is flattened when it ends).
const oversizeBlobText = '{"tooLarge":true}';

/// The blob as a JSON object, or null for the oversize marker, bad JSON or a
/// non-object.
Map<String, Object?>? decodeBlob(String text) {
  if (text == oversizeBlobText) return null;
  try {
    final v = jsonDecode(text);
    return v is Map<String, Object?> ? v : null;
  } on FormatException {
    return null;
  }
}

/// Text of an assistant message that has no final parts (stopped or failed
/// while streaming).
String _textOf(AiMessage m) {
  final text = m.parts.whereType<TextPart>().map((p) => p.text).join();
  if (text.isNotEmpty) return text;
  return m.liveText ?? '';
}

/// Breaks every `<data` / `</data` so text can never close or fake a fence.
String fenceSafe(String text) => sanitizeText(text, keepLineBreaks: true)
    .replaceAllMapped(RegExp('<(/?)data', caseSensitive: false), (m) {
      return '<${m[1]} data';
    });

Map<String, Object?>? _wirePart(AiPart p) => switch (p) {
  TextPart(:final text) => {'type': 'text', 'text': text},
  DataPart(:final source, :final text) => {
    'type': 'data',
    'source': source.wire,
    'text': fenceSafe(text),
  },
  ToolCallPart() => {
    'type': 'tool_call',
    'id': p.id,
    'providerId': ?p.providerId,
    'name': p.name,
    'args': p.rawArgs ?? p.args ?? const <String, Object?>{},
  },
  ToolResultPart() => {
    'type': 'tool_result',
    'id': p.id,
    'providerId': ?p.providerId,
    'name': p.name,
    'content': [for (final c in p.content) ?_wirePart(c)],
    'isError': p.isError,
  },
  // Chips are a screen element: what they stand for travels as data parts.
  _ => null,
};

List<Map<String, Object?>> wireParts(Iterable<AiPart> parts) => [
  for (final p in parts) ?_wirePart(p),
];

/// What the model reads in place of a result that never came.
String _missingResultText(HistoryRow? row) {
  final parts = row?.message.parts ?? const <AiPart>[];
  final confirm = parts.whereType<ConfirmPart>().firstOrNull;
  if (confirm != null &&
      (confirm.status == ConfirmStatus.denied ||
          confirm.status == ConfirmStatus.deniedByNewMessage)) {
    return 'The user declined this action.';
  }
  return switch (row?.message.state) {
    AiMessageState.unknown =>
      'The result is unknown: the app was closed while this ran.',
    AiMessageState.error => 'The tool failed.',
    _ => 'This call did not run.',
  };
}

/// Placeholder content of a tool result dropped to fit the size limit.
const elidedResultText = '[result omitted to fit the size limit]';

/// One turn as wire messages, the whole turn or flattened ([userOnly]: just
/// the user message). [elided] holds the
/// ids of tool results whose content is replaced by [elidedResultText].
List<Map<String, Object?>> wireTurn(
  HistoryTurn turn, {
  required bool whole,
  Set<String> elided = const {},
  bool userOnly = false,
}) {
  final user = turn.user.message.parts;
  final out = <Map<String, Object?>>[];
  final userParts = wireParts(user);
  if (userParts.isNotEmpty) out.add({'role': 'user', 'parts': userParts});
  if (userOnly) return out;
  if (!whole) {
    final text = [
      for (final r in turn.assistants)
        if (_textOf(r.message).trim().isNotEmpty) _textOf(r.message),
    ];
    if (text.isNotEmpty) {
      out.add({
        'role': 'assistant',
        'parts': [
          for (final t in text) {'type': 'text', 'text': t},
        ],
      });
    }
    return out;
  }
  for (var i = 0; i < turn.rows.length; i++) {
    final row = turn.rows[i];
    if (row.message.role != AiMessageRole.assistant) continue;
    final calls = row.message.parts.whereType<ToolCallPart>().toList();
    final text = _textOf(row.message);
    final parts = <Map<String, Object?>>[
      if (text.trim().isNotEmpty) {'type': 'text', 'text': text},
      ...wireParts(calls),
    ];
    if (parts.isEmpty) continue;
    final blob = row.providerJson;
    final provider = blob == null ? null : decodeBlob(blob);
    out.add({'role': 'assistant', 'parts': parts, 'provider': ?provider});
    if (calls.isEmpty) continue;
    // The tool rows between this assistant row and the next one.
    final results = <String, ToolResultPart>{};
    final rowOf = <String, HistoryRow>{};
    for (var j = i + 1; j < turn.rows.length; j++) {
      final next = turn.rows[j];
      if (next.message.role == AiMessageRole.assistant) break;
      if (next.message.role != AiMessageRole.tool) continue;
      for (final p in next.message.parts) {
        if (p is ToolResultPart) results[p.id] = p;
        if (p is ToolCallPart) rowOf[p.id] = next;
      }
    }
    out.add({
      'role': 'tool',
      'parts': [
        for (final c in calls)
          _wirePart(_resultFor(c, results[c.id], rowOf[c.id], elided))!,
      ],
    });
  }
  return out;
}

ToolResultPart _resultFor(
  ToolCallPart call,
  ToolResultPart? result,
  HistoryRow? row,
  Set<String> elided,
) {
  if (result == null) {
    return ToolResultPart(
      id: call.id,
      providerId: call.providerId,
      name: call.name,
      isError: true,
      content: [TextPart(_missingResultText(row))],
    );
  }
  return ToolResultPart(
    id: call.id,
    providerId: call.providerId,
    name: call.name,
    isError: result.isError,
    content: elided.contains(call.id)
        ? const [TextPart(elidedResultText)]
        : result.content,
  );
}

/// Ids of the tool results of [turn] whose content could be elided, oldest
/// first (only results bigger than the placeholder).
List<String> elidableResultIds(HistoryTurn turn) => [
  for (final row in turn.rows)
    for (final p in row.message.parts)
      if (p is ToolResultPart &&
          p.content.any(
            (c) =>
                (c is TextPart && c.text.length > elidedResultText.length) ||
                c is DataPart,
          ))
        p.id,
];

/// Merges neighbours of the same role (the contract guarantees none are
/// adjacent). Assistant messages with a provider blob are never merged.
List<Map<String, Object?>> mergeSameRole(List<Map<String, Object?>> messages) {
  final out = <Map<String, Object?>>[];
  for (final m in messages) {
    final last = out.isEmpty ? null : out.last;
    final mergeable =
        last != null &&
        last['role'] == m['role'] &&
        !last.containsKey('provider') &&
        !m.containsKey('provider');
    if (mergeable) {
      out[out.length - 1] = {
        ...last,
        'parts': [
          ...last['parts']! as List<Object?>,
          ...m['parts']! as List<Object?>,
        ],
      };
    } else {
      out.add(m);
    }
  }
  return out;
}

/// Bytes the request shrinks by when result [id] of [turn] is replaced by the
/// placeholder.
int elisionSaving(HistoryTurn turn, String id) {
  for (final row in turn.rows) {
    for (final p in row.message.parts) {
      if (p is ToolResultPart && p.id == id) {
        final before = jsonByteLength(wireParts(p.content));
        final after = jsonByteLength(
          wireParts(const [TextPart(elidedResultText)]),
        );
        return before > after ? before - after : 0;
      }
    }
  }
  return 0;
}
