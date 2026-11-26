import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/chat_messages_provider.dart';
import '../state/chat_providers.dart';
import '../state/chat_session.dart';
import '../state/chat_view/chat_view_state.dart';
import 'chat_history_slot.dart';
import 'empty_states.dart';

/// The chat below its header, the same on the desktop panel and the phone
/// page: the body (history, the no-plugin guide, the empty greeting, later the
/// message list) over the composer.
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
    return Column(
      children: [
        Expanded(child: historyOpen ? const ChatHistorySlot() : _body()),
        // The composer sits here.
      ],
    );
  }

  Widget _body() {
    final id = ref.watch(chatSessionProvider.select((s) => s.conversationId));
    if (id == null) return const SizedBox.shrink();
    final messages = ref.watch(chatMessagesProvider(id)).value;
    // Loading or failed read: nothing to say yet.
    if (messages == null) return const SizedBox.shrink();
    if (messages.messages.isNotEmpty) {
      // The message list goes here.
      return const SizedBox.shrink();
    }
    final plugins = ref.watch(chatPluginsProvider).value;
    if (plugins != null && plugins.isEmpty) return const ChatNoPluginGuide();
    return const ChatEmptyGreeting();
  }
}
