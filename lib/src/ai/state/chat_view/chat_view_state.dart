import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../chat_messages_provider.dart';
import '../chat_session.dart';
import 'composer_draft.dart';

final _log = Logger('ai.chat_view');

/// View state of the chat that must outlive the widget showing it: the right
/// panel is rebuilt when it swaps to the queue and back, and the panel and the
/// phone page replace each other when the window width crosses 1200 dp.
class ChatViewState {
  const ChatViewState({
    this.historyOpen = false,
    this.renaming = false,
    this.renameText = '',
    this.renameOriginal = '',
  });

  /// The history list replaces the conversation.
  final bool historyOpen;

  /// The title is an input; [renameText] is what it holds.
  final bool renaming;
  final String renameText;

  /// The name when rename started: saving it unchanged is not a rename.
  final String renameOriginal;

  ChatViewState copyWith({
    bool? historyOpen,
    bool? renaming,
    String? renameText,
    String? renameOriginal,
  }) => ChatViewState(
    historyOpen: historyOpen ?? this.historyOpen,
    renaming: renaming ?? this.renaming,
    renameText: renameText ?? this.renameText,
    renameOriginal: renameOriginal ?? this.renameOriginal,
  );
}

class ChatViewNotifier extends Notifier<ChatViewState> {
  @override
  ChatViewState build() => const ChatViewState();

  void openHistory() =>
      state = state.copyWith(historyOpen: true, renaming: false);

  void closeHistory() => state = state.copyWith(historyOpen: false);

  /// Turns the title into an input holding [current].
  void startRename(String current) => state = state.copyWith(
    renaming: true,
    renameText: current,
    renameOriginal: current,
  );

  void setRenameText(String text) => state = state.copyWith(renameText: text);

  void cancelRename() => state = state.copyWith(renaming: false);

  /// Saves the typed name on the open conversation and leaves rename mode. A
  /// blank or unchanged name keeps the old one (and the automatic title).
  Future<void> commitRename() async {
    final text = state.renameText.trim();
    final id = ref.read(chatSessionProvider).conversationId;
    state = state.copyWith(renaming: false);
    if (text.isEmpty || id == null || text == state.renameOriginal.trim()) {
      return;
    }
    try {
      await ref.read(chatSessionProvider.notifier).rename(id, text);
    } on Object catch (e, s) {
      _log.warning('rename failed: ${e.runtimeType}', e, s);
    }
  }

  /// One step back for the Esc key and the phone's Back: rename mode first,
  /// then the history list. True when it took a step, so the caller leaves
  /// the key alone.
  bool back() {
    if (state.renaming) {
      cancelRename();
      return true;
    }
    if (state.historyOpen) {
      closeHistory();
      return true;
    }
    return false;
  }

  /// Deletes conversation [id]: the controller stops its turn first and opens
  /// a new empty conversation when it was the open one. True when it was
  /// deleted; a failure is logged and gives false.
  Future<bool> deleteConversation(int id) async {
    state = state.copyWith(renaming: false);
    try {
      await ref.read(chatSessionProvider.notifier).delete(id);
      return true;
    } on Object catch (e, s) {
      _log.warning('delete failed: ${e.runtimeType}', e, s);
      return false;
    }
  }

  /// Makes sure a conversation is open when the chat first appears: opens a
  /// new one (nothing is open after a launch).
  Future<void> ensureConversation() async {
    if (ref.read(chatSessionProvider).conversationId != null) return;
    try {
      await ref.read(chatSessionProvider.notifier).newConversation();
    } on Object catch (e, s) {
      _log.warning('opening a conversation failed: ${e.runtimeType}', e, s);
    }
  }

  /// Opens a new conversation (the open one when it is still empty), shows it
  /// and puts the cursor in the composer.
  Future<void> startNewConversation() async {
    state = const ChatViewState();
    try {
      await ref.read(chatSessionProvider.notifier).newConversation();
    } on Object catch (e, s) {
      _log.warning('new conversation failed: ${e.runtimeType}', e, s);
      return;
    }
    ref.read(composerFocusRequestProvider.notifier).request();
  }
}

final chatViewProvider = NotifierProvider<ChatViewNotifier, ChatViewState>(
  ChatViewNotifier.new,
);

/// The message the list was scrolled to (its id), so it comes back to the
/// same place after the chat was rebuilt. Null: at the newest message.
class ChatScrollAnchor extends Notifier<int?> {
  @override
  int? build() => null;

  void set(int? messageId) => state = messageId;
}

final chatScrollAnchorProvider = NotifierProvider<ChatScrollAnchor, int?>(
  ChatScrollAnchor.new,
);

/// Keeps the open conversation's messages loaded while the chat is off screen
/// (the panel swapped to the queue, a hand-over), so coming back keeps the
/// pages already loaded and the scroll anchor stays valid. Released when
/// another conversation opens. The chat surface watches it once; it is not
/// auto-disposed, so it outlives the surface.
final chatMessagesHoldProvider = Provider<void>((ref) {
  final id = ref.watch(chatSessionProvider.select((s) => s.conversationId));
  if (id != null) ref.listen(chatMessagesProvider(id), (_, _) {});
});
