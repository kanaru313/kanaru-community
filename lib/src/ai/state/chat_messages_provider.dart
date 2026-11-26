import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/conversation/ai_message.dart';
import 'ai_conversation_store_provider.dart';

/// Messages shown per page.
const int chatMessagePage = 50;

/// The newest messages of a conversation, oldest first.
class ChatMessages {
  const ChatMessages(this.messages, {required this.hasMore});

  final List<AiMessage> messages;

  /// Older messages exist; `loadOlder` adds a page.
  final bool hasMore;
}

/// Paged messages of one conversation, without provider blobs. Reloads when
/// the store reports a change (a message, a card moving to another state, a
/// rename). The streamed text of the running round is not here: it comes from
/// `liveTextProvider`, so a delta does not rebuild the list.
class ChatMessagesNotifier extends AsyncNotifier<ChatMessages> {
  ChatMessagesNotifier(this.conversationId);

  final int conversationId;
  int _limit = chatMessagePage;
  int _reads = 0;

  @override
  Future<ChatMessages> build() async {
    final store = ref.watch(aiConversationStoreProvider);
    final sub = store.changes.listen((_) => unawaited(_refresh()));
    ref.onDispose(() => unawaited(sub.cancel()));
    return _load();
  }

  Future<ChatMessages> _load() async {
    final store = ref.read(aiConversationStoreProvider);
    final rows = await store.messages(
      conversationId,
      limit: _limit + 1,
      blobs: false,
    );
    final more = rows.length > _limit;
    return ChatMessages([
      for (final r in more ? rows.skip(1) : rows) r.message,
    ], hasMore: more);
  }

  Future<void> _refresh() async {
    if (!ref.mounted) return;
    final mine = ++_reads;
    try {
      final next = await _load();
      // A newer read started meanwhile: its result is the fresher one.
      if (ref.mounted && mine == _reads) state = AsyncData(next);
    } on Object catch (e, s) {
      if (ref.mounted && mine == _reads) state = AsyncError(e, s);
    }
  }

  /// Adds the page before the oldest loaded message.
  Future<void> loadOlder() async {
    if (state.value?.hasMore != true) return;
    _limit += chatMessagePage;
    await _refresh();
  }
}

final chatMessagesProvider = AsyncNotifierProvider.autoDispose
    .family<ChatMessagesNotifier, ChatMessages, int>(ChatMessagesNotifier.new);
