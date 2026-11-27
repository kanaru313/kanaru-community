import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/chat_messages_provider.dart';
import '../state/chat_providers.dart';
import '../state/chat_session.dart';
import '../state/chat_view/chat_view_state.dart';
import 'chat_history_slot.dart';
import 'composer/composer.dart';
import 'composer/prompt_chips.dart';
import 'empty_states.dart';
import 'messages_error.dart';
import 'message_list.dart';

/// The chat below its header, the same on the desktop panel and the phone
/// page: the body (history, the no-plugin guide, the empty greeting or the
/// message list) over the composer (none in the history and the guide).
///
/// It keeps no state of its own that must outlive it: the draft, the scroll
/// anchor, the history flag and the rename state live in keep-alive providers
/// (`state/chat_view/`), so the panel swapping to the queue and back, or the
/// panel and the page handing over, lose nothing. It reads nothing the player
/// publishes; the shell holds the panel back until the player exists anyway.
class ChatSurface extends ConsumerStatefulWidget {
  const ChatSurface({super.key});

  @override
  ConsumerState<ChatSurface> createState() => _ChatSurfaceState();
}

class _ChatSurfaceState extends ConsumerState<ChatSurface> {
  @override
  void initState() {
    super.initState();
    // After the first frame: opening a conversation changes providers.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(chatViewProvider.notifier).ensureConversation());
    });
    // Another conversation (new, deleted, opened from the history): a rename
    // of the old one ends.
    ref.listenManual(chatSessionProvider.select((s) => s.conversationId), (
      previous,
      next,
    ) {
      if (previous != null && previous != next) {
        ref.read(chatViewProvider.notifier).cancelRename();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyOpen = ref.watch(
      chatViewProvider.select((s) => s.historyOpen),
    );
    final id = ref.watch(chatSessionProvider.select((s) => s.conversationId));
    final messages = id == null
        ? null
        : ref.watch(chatMessagesProvider(id)).value;
    final plugins = ref.watch(chatPluginsProvider).value;
    final hasMessages = messages?.messages.isNotEmpty ?? false;
    // The no-plugin guide has no composer (nothing to send through).
    final guide =
        messages != null && !hasMessages && plugins != null && plugins.isEmpty;
    return Column(
      children: [
        Expanded(child: historyOpen ? const ChatHistorySlot() : _body()),
        if (!historyOpen && id != null && !guide)
          Composer(showPromptChips: hasMessages),
      ],
    );
  }

  Widget _body() {
    final id = ref.watch(chatSessionProvider.select((s) => s.conversationId));
    if (id == null) return const SizedBox.shrink();
    final read = ref.watch(chatMessagesProvider(id));
    final messages = read.value;
    if (messages == null) {
      // Still loading: nothing to say yet. A failed read says so.
      return read.hasError
          ? ChatMessagesError(
              onRetry: () => ref.invalidate(chatMessagesProvider(id)),
            )
          : const SizedBox.shrink();
    }
    if (messages.messages.isNotEmpty) {
      return ChatMessageList(
        key: ValueKey(id),
        conversationId: id,
        messages: messages,
      );
    }
    final plugins = ref.watch(chatPluginsProvider).value;
    if (plugins != null && plugins.isEmpty) return const ChatNoPluginGuide();
    return const ChatEmptyGreeting(chips: PromptChips(large: true));
  }
}
