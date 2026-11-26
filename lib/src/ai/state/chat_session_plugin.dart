import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/database.dart';
import '../../plugins/state/plugin_store_providers.dart';
import '../data/conversation_store.dart';
import '../domain/conversation/ai_conversation.dart';
import '../domain/conversation/ai_message.dart';
import '../domain/conversation/parts.dart';
import 'ai_settings_providers.dart';
import 'chat_session_env.dart';

/// Moves [conversation] to the chat plugin [target] with that plugin's own
/// model and writes the plugin-switch line into the transcript. Does nothing
/// when the chat already uses that plugin install. The caller has stopped
/// the turn.
Future<void> rebindChatPlugin(
  Ref ref,
  ConversationStore store,
  AiConversation conversation,
  PluginRow target,
) async {
  if (conversation.installId == target.installId &&
      conversation.installGeneration == target.installedAt) {
    return;
  }
  final from = conversation.installId == null
      ? null
      : await ref.read(pluginRowsProvider).byId(conversation.installId!);
  await store.bind(
    conversation.id,
    installId: target.installId,
    installGeneration: target.installedAt,
    model: await pluginDefaultModel(ref, target.installId),
  );
  await store.append(
    NewAiMessage(
      conversationId: conversation.id,
      role: AiMessageRole.event,
      parts: [
        EventPart.pluginSwitch(
          // A removed plugin keeps its name in its tombstone row.
          fromName: from?.name ?? conversation.installId ?? '',
          toName: target.name,
        ),
      ],
    ),
  );
  await ref.read(aiLastPluginProvider.notifier).set(target.installId);
}
