import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/conversation_store.dart';
import 'ai_conversation_store_provider.dart';

/// Number of chats and stored bytes. Reloads after a message is appended, a
/// round completes, or a conversation is deleted.
final aiChatStatsProvider = FutureProvider<AiChatStats>((ref) {
  final store = ref.watch(aiConversationStoreProvider);
  final sub = store.changes.listen((_) => ref.invalidateSelf());
  ref.onDispose(() => unawaited(sub.cancel()));
  return store.stats();
});
