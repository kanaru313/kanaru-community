import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/chat_messages_provider.dart';
import '../state/chat_providers.dart';
import '../state/chat_session.dart';
import '../state/chat_view/chat_view_state.dart';
import '../state/chat_view/composer_view.dart';
import 'chat_suggestions_sync.dart';
import 'composer/composer.dart';
import 'composer/prompt_chips.dart';
import 'empty_states.dart';
import 'history_page.dart';
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
  late final ChatViewNotifier _view;

  @override
  void initState() {
    super.initState();
    _view = ref.read(chatViewProvider.notifier);
    // After the first frame: opening a conversation changes providers.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(chatViewProvider.notifier).ensureConversation());
    });
    // Another conversation (new, deleted, opened from the history): the note of a refused send and the scroll
    // place, which described the old one.
    ref.listenManual(chatSessionProvider.select((s) => s.conversationId), (
      previous,
      next,
    ) {
      if (previous != null && previous != next) {
        ref.read(composerSendNoticeProvider.notifier).clear();
        ref.read(chatScrollAnchorProvider.notifier).set(null);
      }
    });
  }

  @override
  void dispose() {
    // The panel or page went away (closed, swapped to the queue, handed over
    // to the other shell): a half-typed rename does not wait for the next
    // time the chat opens. Deferred, a provider cannot change while the tree
    // is being torn down; a container already disposed has nothing to reset.
    final view = _view;
    scheduleMicrotask(() {
      try {
        view.cancelRename();
      } on StateError {
        // The container is gone with the app or the test.
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(chatMessagesHoldProvider);
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
        const ChatSuggestionsSync(),
        Expanded(child: historyOpen ? const ChatHistoryPage() : _body()),
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
