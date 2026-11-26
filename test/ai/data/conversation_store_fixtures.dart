import 'package:kanaru/src/ai/data/conversation_store.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_conversation.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/permission.dart';
import 'package:kanaru/src/database/database.dart';

import '../../database/support/test_db.dart';

AppDatabase openDb() => openTestDb();

Future<AiConversation> newChat(
  ConversationStore store, {
  String title = 'Chat',
}) => store.create(title: title, permission: AiPermission.ask);

Future<int> addUser(
  ConversationStore store,
  int chat, [
  String text = 'hi',
]) async => (await store.append(
  NewAiMessage(
    conversationId: chat,
    role: AiMessageRole.user,
    parts: [TextPart(text)],
  ),
)).message.id;

/// A streaming assistant message of [install].
Future<int> addStreaming(
  ConversationStore store,
  int chat, {
  String install = 'plug',
  String? live,
}) async => (await store.append(
  NewAiMessage(
    conversationId: chat,
    role: AiMessageRole.assistant,
    state: AiMessageState.streaming,
    installId: install,
    installGeneration: 1,
    liveText: live,
  ),
)).message.id;

ToolCallPart call(String id, [String name = 'search_library']) =>
    ToolCallPart.parsed(id: id, name: name, args: const {'q': 'x'});

/// One finished tool round of a turn: assistant text + [callId] with [blob],
/// and its tool row. Returns (assistantId, cardId).
Future<({int assistant, int card})> toolRound(
  ConversationStore store,
  int chat, {
  required String callId,
  String blob = '{"b":1}',
  String install = 'plug',
  bool needsConfirm = false,
}) async {
  final a = await addStreaming(store, chat, install: install);
  final r = await store.completeRound(
    messageId: a,
    finalParts: [TextPart('t-$callId'), call(callId)],
    blob: blob,
    calls: [ToolCardDraft(call: call(callId), needsConfirm: needsConfirm)],
  );
  return (assistant: a, card: r.cardIds.single);
}

/// Allows, runs and finishes the card with a result.
Future<void> finishCard(
  ConversationStore store,
  int card,
  String callId,
) async {
  await store.transition(
    card,
    from: AiMessageState.allowed,
    to: AiMessageState.running,
  );
  await store.transition(
    card,
    from: AiMessageState.running,
    to: AiMessageState.done,
    parts: [
      call(callId),
      ToolResultPart(
        id: callId,
        name: 'search_library',
        content: const [TextPart('ok')],
      ),
    ],
  );
}
