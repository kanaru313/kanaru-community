import 'dart:convert';

import '../../database/database.dart';
import '../domain/conversation/ai_conversation.dart';
import '../domain/conversation/ai_message.dart';
import '../domain/conversation/parts.dart';
import '../domain/conversation/parts_codec.dart';
import '../domain/permission.dart';

/// Size caps of the store, in bytes (UTF-8). Enforced in Dart, never by SQL.
class ConversationStoreLimits {
  const ConversationStoreLimits({
    this.liveTextBytes = 256 * 1024,
    this.partsJsonBytes = 1024 * 1024,
    this.blobBytes = 256 * 1024,
    this.conversationBlobBytes = 4 * 1024 * 1024,
  });

  /// Streamed text kept per message.
  final int liveTextBytes;

  /// `parts_json` of one row (one tool-result row per call).
  final int partsJsonBytes;

  /// Provider blob of one message.
  final int blobBytes;

  /// All provider blobs of one conversation.
  final int conversationBlobBytes;
}

/// Written at the end of a live text that hit the cap; later deltas are
/// dropped.
const liveTextTruncationMarker = '\n[…]';

/// What replaces a provider blob that was over its cap: the turn is flattened
/// when it ends (`endTurn`).
const oversizeBlobMarker = '{"tooLarge":true}';

/// A write went over a cap. The message it belonged to is marked
/// `error(too_large)` in the same step.
class AiStoreTooLarge implements Exception {
  const AiStoreTooLarge(this.what, this.bytes, this.limit);

  final String what;
  final int bytes;
  final int limit;

  @override
  String toString() => 'AiStoreTooLarge: $what is $bytes bytes (cap $limit)';
}

const _knownCodes = {
  'key',
  'quota',
  'rate_limit',
  'config',
  'bad_request',
  'model_not_found',
  'context_length',
  'too_large',
  'blocked',
  'empty',
  'server',
};
const _knownKinds = {
  'rateLimited',
  'invalidResponse',
  'auth',
  'quota',
  'server',
};

/// The only error data that is stored: `{code, kind, retryAfterSec?}`. Never
/// provider text.
class AiStoredError {
  const AiStoredError({
    required this.code,
    required this.kind,
    this.retryAfterSec,
  });

  /// The error of a plugin run, from its `ai:<code>` message: everything
  /// after the code is dropped. An unknown code or kind is `server`.
  factory AiStoredError.fromPlugin(
    String message, {
    String? kind,
    int? retryAfterSec,
  }) {
    final m = RegExp(r'^ai:([a-z_]+)').firstMatch(message);
    final code = m != null && _knownCodes.contains(m.group(1))
        ? m.group(1)!
        : 'server';
    return AiStoredError(
      code: code,
      kind: _knownKinds.contains(kind) ? kind! : 'server',
      retryAfterSec: retryAfterSec != null && retryAfterSec > 0
          ? retryAfterSec
          : null,
    );
  }

  /// A failure the app itself raised (`too_large`).
  const AiStoredError.local(this.code, {this.kind = 'invalidResponse'})
    : retryAfterSec = null;

  final String code;
  final String kind;
  final int? retryAfterSec;

  String toJsonText() => jsonEncode({
    'code': code,
    'kind': kind,
    if (retryAfterSec != null) 'retryAfterSec': retryAfterSec,
  });

  /// Null when [text] is not the stored shape.
  static AiStoredError? tryParse(String? text) {
    if (text == null) return null;
    try {
      final j = jsonDecode(text);
      if (j is! Map<String, Object?>) return null;
      final code = j['code'];
      final kind = j['kind'];
      final retry = j['retryAfterSec'];
      if (code is! String || kind is! String) return null;
      return AiStoredError(
        code: code,
        kind: kind,
        retryAfterSec: retry is int ? retry : null,
      );
    } on FormatException {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is AiStoredError &&
      other.code == code &&
      other.kind == kind &&
      other.retryAfterSec == retryAfterSec;

  @override
  int get hashCode => Object.hash(code, kind, retryAfterSec);
}

/// A message as stored: the domain message plus the columns the engine
/// needs but the UI does not.
class StoredMessage {
  const StoredMessage({
    required this.message,
    this.providerJson,
    this.error,
    this.liveTextTruncated = false,
  });

  final AiMessage message;

  /// The provider blob, or [oversizeBlobMarker].
  final String? providerJson;
  final AiStoredError? error;
  final bool liveTextTruncated;

  bool get blobTooLarge => providerJson == oversizeBlobMarker;
}

/// The data a new message is written with.
class NewAiMessage {
  const NewAiMessage({
    required this.conversationId,
    required this.role,
    this.parts = const [],
    this.state = AiMessageState.complete,
    this.liveText,
    this.providerJson,
    this.installId,
    this.installGeneration,
    this.pluginVersion,
    this.model,
  });

  final int conversationId;
  final AiMessageRole role;
  final List<AiPart> parts;
  final AiMessageState state;
  final String? liveText;
  final String? providerJson;
  final String? installId;
  final int? installGeneration;
  final int? pluginVersion;
  final String? model;
}

/// A tool call of a finished round, stored as one row of role `tool`.
class ToolCardDraft {
  const ToolCardDraft({required this.call, required this.needsConfirm});

  final ToolCallPart call;

  /// An ask-mode write: the card starts `pending` with a confirm part.
  /// Otherwise (auto writes, reads) it starts `allowed`.
  final bool needsConfirm;
}

/// What [ConversationStore.completeRound] did.
class CompleteRoundResult {
  const CompleteRoundResult.lost()
    : won = false,
      cardIds = const [],
      blobTooLarge = false;

  const CompleteRoundResult({required this.cardIds, required this.blobTooLarge})
    : won = true;

  /// False when the message was no longer streaming (nothing was written).
  final bool won;

  /// The ids of the inserted tool rows, in the order of the drafts.
  final List<int> cardIds;

  /// The blob was over its cap and was replaced by [oversizeBlobMarker]:
  /// end the turn with `endTurn` so it is stored flattened.
  final bool blobTooLarge;
}

/// Count and size of the stored chats.
class AiChatStats {
  const AiChatStats({required this.conversations, required this.bytes});

  final int conversations;

  /// Stored JSON plus live text of every message, in bytes.
  final int bytes;
}

/// Bytes of [text] in UTF-8.
int utf8Size(String text) => utf8.encode(text).length;

/// [text] cut to [maxBytes] of UTF-8 (on a character boundary) with
/// [liveTextTruncationMarker] at the end; [text] itself when it fits.
String capLiveText(String text, int maxBytes) {
  final bytes = utf8.encode(text);
  if (bytes.length <= maxBytes) return text;
  final marker = utf8.encode(liveTextTruncationMarker);
  var end = maxBytes - marker.length;
  // Never cut inside a multi-byte character (continuation bytes are 10xxxxxx).
  while (end > 0 && (bytes[end] & 0xC0) == 0x80) {
    end--;
  }
  return utf8.decode(bytes.sublist(0, end)) + liveTextTruncationMarker;
}

/// Whether [text] was cut by [capLiveText].
bool isLiveTextTruncated(String? text) =>
    text != null && text.endsWith(liveTextTruncationMarker);

AiConversation conversationFromRow(AiConversationRow r) => AiConversation(
  id: r.id,
  title: r.title,
  titleAuto: r.titleAuto,
  installId: r.installId,
  installGeneration: r.installGeneration,
  model: r.model,
  permission: AiPermission.parse(r.permission),
  createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
  updatedAt: DateTime.fromMillisecondsSinceEpoch(r.updatedAt),
  lastMessageAt: DateTime.fromMillisecondsSinceEpoch(r.lastMessageAt),
);

StoredMessage messageFromRow(AiMessageRow r) => StoredMessage(
  message: AiMessage(
    id: r.id,
    conversationId: r.conversationId,
    seq: r.seq,
    role: AiMessageRole.parse(r.role),
    parts: decodeParts(r.partsJson),
    state: AiMessageState.parse(r.state),
    liveText: r.liveText,
    installId: r.installId,
    installGeneration: r.installGeneration,
    pluginVersion: r.pluginVersion,
    model: r.model,
    createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
  ),
  providerJson: r.providerJson,
  error: AiStoredError.tryParse(r.errorJson),
  liveTextTruncated: isLiveTextTruncated(r.liveText),
);
