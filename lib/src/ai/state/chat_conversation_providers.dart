import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../plugins/data/store/plugin_config_values.dart';
import '../../plugins/state/plugin_store_providers.dart';
import '../domain/conversation/ai_conversation.dart';
import '../domain/output/chat_readiness.dart';
import 'ai_conversation_store_provider.dart';

/// One conversation row; null when it does not exist (deleted). Reloads when
/// the store reports a change (renames, permission and plugin switches
/// included).
final chatConversationProvider = FutureProvider.autoDispose
    .family<AiConversation?, int>((ref, id) {
      final store = ref.watch(aiConversationStoreProvider);
      final sub = store.changes.listen((_) => ref.invalidateSelf());
      ref.onDispose(() => unawaited(sub.cancel()));
      return store.conversation(id);
    });

/// Whether a conversation can send now, from the live plugin row and its
/// settings. Loading while either loads; a missing conversation or plugin
/// reads as removed.
final chatReadinessProvider = Provider.autoDispose
    .family<AsyncValue<ChatReadiness>, int>((ref, id) {
      final conversation = ref.watch(chatConversationProvider(id));
      if (conversation.hasError) {
        return AsyncError(conversation.error!, conversation.stackTrace!);
      }
      if (!conversation.hasValue) return const AsyncLoading();
      final c = conversation.requireValue;
      final installId = c?.installId;
      if (c == null || installId == null) {
        return const AsyncData(ChatPluginRemoved());
      }
      final status = ref.watch(pluginConfigStatusProvider(installId));
      if (status.hasError) {
        return AsyncError(status.error!, status.stackTrace!);
      }
      if (!status.hasValue) return const AsyncLoading();
      final s = status.requireValue;
      return AsyncData(
        chatReadiness(
          manifest: s?.manifest,
          storedConfig: s == null || s.manifest == null
              ? const {}
              : resolveRunConfig(s.manifest!.config, s.data),
          conversationModel: c.model,
          reinstalled: s != null && s.row.installedAt != c.installGeneration,
        ),
      );
    });
