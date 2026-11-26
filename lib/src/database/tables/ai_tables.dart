import 'package:drift/drift.dart';

/// Values of `ai_conversations.permission`: how far the assistant may act
/// without asking. Validated in Dart (no SQL CHECK), so a new level is not a
/// table rebuild.
abstract final class AiPermissionValues {
  static const readOnly = 'readOnly';
  static const ask = 'ask';
  static const auto = 'auto';
  static const values = {readOnly, ask, auto};
}

/// Values of `ai_messages.role`. Validated in Dart (no SQL CHECK).
abstract final class AiMessageRoleValues {
  static const user = 'user';
  static const assistant = 'assistant';
  static const tool = 'tool';
  static const event = 'event';
  static const values = {user, assistant, tool, event};
}

/// Values of `ai_messages.state`. Validated in Dart (no SQL CHECK).
abstract final class AiMessageStateValues {
  static const complete = 'complete';
  static const streaming = 'streaming';
  static const stopped = 'stopped';
  static const error = 'error';
  static const pending = 'pending';
  static const allowed = 'allowed';
  static const running = 'running';
  static const done = 'done';
  static const skipped = 'skipped';
  static const unknown = 'unknown';
  static const values = {
    complete,
    streaming,
    stopped,
    error,
    pending,
    allowed,
    running,
    done,
    skipped,
    unknown,
  };
}

/// A chat with an AI plugin. Per device; a hard `DELETE` removes the
/// conversation and, by cascade, its messages. No `uid` and no foreign key to
/// `plugins`: `install_id` names the plugin the chat is bound to, and
/// `install_generation` is that plugin row's `installed_at` at bind time, so a
/// removed and reinstalled plugin is told apart from the one the chat used.
///
/// Times are epoch milliseconds.
@TableIndex(name: 'ai_conversations_last_message', columns: {#lastMessageAt})
@DataClassName('AiConversationRow')
class AiConversations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();

  /// True while the title was made by the app and may be replaced by a
  /// generated one; false once the user renamed the chat.
  BoolColumn get titleAuto => boolean().withDefault(const Constant(true))();
  TextColumn get installId => text().nullable()();
  IntColumn get installGeneration => integer().nullable()();
  TextColumn get model => text().nullable()();

  /// One of [AiPermissionValues.values].
  TextColumn get permission => text()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get lastMessageAt => integer()();
}

/// One message, tool call or event of a conversation, in `seq` order.
///
/// Size caps are enforced by the engine's store, not by the table: `live_text`
/// at most 256 KiB, `provider_json` at most 256 KiB per message and 4 MiB per
/// conversation, `error_json` only `{code, kind, retryAfterSec?}` (never
/// provider text). Tracks are never referenced: parts carry
/// `{trackId, title, artist, album?}` snapshots.
///
/// Times are epoch milliseconds.
@TableIndex(
  name: 'ai_messages_conversation_seq',
  columns: {#conversationId, #seq},
  unique: true,
)
@DataClassName('AiMessageRow')
class AiMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get conversationId =>
      integer().references(AiConversations, #id, onDelete: KeyAction.cascade)();
  IntColumn get seq => integer()();

  /// One of [AiMessageRoleValues.values].
  TextColumn get role => text()();
  TextColumn get partsJson => text()();

  /// Text streamed so far, flushed on its own so a flush does not rewrite
  /// [partsJson].
  TextColumn get liveText => text().nullable()();

  /// Provider-specific data kept for the whole conversation.
  TextColumn get providerJson => text().nullable()();
  TextColumn get installId => text().nullable()();
  IntColumn get pluginVersion => integer().nullable()();
  IntColumn get installGeneration => integer().nullable()();
  TextColumn get model => text().nullable()();

  /// One of [AiMessageStateValues.values].
  TextColumn get state => text()();
  TextColumn get errorJson => text().nullable()();
  TextColumn get usageJson => text().nullable()();
  IntColumn get createdAt => integer()();
}
