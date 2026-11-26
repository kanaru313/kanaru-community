import 'parts.dart';

/// Who wrote a message (`ai_messages.role`).
enum AiMessageRole {
  user,
  assistant,
  tool,
  event;

  String get wire => name;

  /// Throws [FormatException] for a stored value this build does not know.
  static AiMessageRole parse(Object? raw) => _parse(values, raw, 'role');
}

/// Where a message stands (`ai_messages.state`).
enum AiMessageState {
  complete,
  streaming,
  stopped,
  error,
  pending,
  allowed,
  running,
  done,
  skipped,
  unknown;

  String get wire => name;

  /// Throws [FormatException] for a stored value this build does not know.
  static AiMessageState parse(Object? raw) => _parse(values, raw, 'state');
}

/// How a tool call ran. Stored in the message state of the call.
enum ToolExecState {
  running,
  done,
  failed,
  skipped,

  /// The app closed while it ran: whether it took effect is not known.
  unknown;

  /// The stored message state (`failed` is stored as `error`).
  AiMessageState get messageState => switch (this) {
    running => AiMessageState.running,
    done => AiMessageState.done,
    failed => AiMessageState.error,
    skipped => AiMessageState.skipped,
    unknown => AiMessageState.unknown,
  };

  /// The exec state a stored message state means, or null when the state is
  /// not about a tool call.
  static ToolExecState? fromMessageState(AiMessageState s) => switch (s) {
    AiMessageState.running => running,
    AiMessageState.done => done,
    AiMessageState.error => failed,
    AiMessageState.skipped => skipped,
    AiMessageState.unknown => unknown,
    _ => null,
  };
}

T _parse<T extends Enum>(List<T> values, Object? raw, String what) {
  for (final v in values) {
    if (v.name == raw) return v;
  }
  throw FormatException('unknown message $what: $raw');
}

/// One message, tool call or event of a conversation.
class AiMessage {
  const AiMessage({
    required this.id,
    required this.conversationId,
    required this.seq,
    required this.role,
    required this.parts,
    required this.state,
    required this.createdAt,
    this.liveText,
    this.installId,
    this.installGeneration,
    this.pluginVersion,
    this.model,
  });

  final int id;
  final int conversationId;

  /// Position in the conversation; unique within it.
  final int seq;
  final AiMessageRole role;
  final List<AiPart> parts;
  final AiMessageState state;

  /// Text streamed so far while [state] is streaming.
  final String? liveText;

  /// The plugin that wrote it (assistant messages) and its generation and
  /// version at that time.
  final String? installId;
  final int? installGeneration;
  final int? pluginVersion;
  final String? model;
  final DateTime createdAt;
}
