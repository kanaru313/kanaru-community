import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/conversation/ai_message.dart';
import '../domain/loop/loop_state.dart';
import 'ai_conversation_store_provider.dart';
import 'chat_session.dart';

/// Messages shown per page.
const int chatMessagePage = 50;

/// How often the list reloads while a turn runs (the store does not report
/// card state changes).
const Duration chatMessagePoll = Duration(milliseconds: 500);

/// The newest messages of a conversation, oldest first.
class ChatMessages {
  const ChatMessages(this.messages, {required this.hasMore});

  final List<AiMessage> messages;

  /// Older messages exist; `loadOlder` adds a page.
  final bool hasMore;
}

/// Paged messages of one conversation. The streamed text of the running
/// round is not here: it comes from `liveTextProvider`, so a delta does not
/// rebuild the list.
class ChatMessagesNotifier extends AsyncNotifier<ChatMessages> {
  ChatMessagesNotifier(this.conversationId);

  final int conversationId;
  int _limit = chatMessagePage;
  Timer? _poll;

  @override
  Future<ChatMessages> build() async {
    final store = ref.watch(aiConversationStoreProvider);
    final sub = store.changes.listen((_) => unawaited(_refresh()));
    ref.onDispose(() {
      unawaited(sub.cancel());
      _poll?.cancel();
    });
    ref.listen(
      chatSessionProvider.select(
        (s) =>
            s.conversationId == conversationId &&
            (s.turnState == TurnState.streaming ||
                s.turnState == TurnState.runningTools),
      ),
      (_, running) => _setPolling(running),
      fireImmediately: true,
    );
    return _load();
  }

  Future<ChatMessages> _load() async {
    final store = ref.read(aiConversationStoreProvider);
    final rows = await store.messages(conversationId, limit: _limit + 1);
    final more = rows.length > _limit;
    return ChatMessages([
      for (final r in more ? rows.skip(1) : rows) r.message,
    ], hasMore: more);
  }

  Future<void> _refresh() async {
    if (!ref.mounted) return;
    try {
      final next = await _load();
      if (ref.mounted) state = AsyncData(next);
    } on Object catch (e, s) {
      if (ref.mounted) state = AsyncError(e, s);
    }
  }

  void _setPolling(bool on) {
    _poll?.cancel();
    _poll = on
        ? Timer.periodic(chatMessagePoll, (_) => unawaited(_refresh()))
        : null;
    // The turn ended: one last read shows its final state.
    if (!on) unawaited(_refresh());
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
