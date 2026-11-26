import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:kanaru/src/ai/domain/conversation/ai_conversation.dart';
import 'package:kanaru/src/ai/domain/output/chat_readiness.dart';
import 'package:kanaru/src/ai/domain/permission.dart';
import 'package:kanaru/src/ai/state/chat_conversation_providers.dart';
import 'package:kanaru/src/ai/state/chat_messages_provider.dart';
import 'package:kanaru/src/ai/state/chat_providers.dart';
import 'package:kanaru/src/ai/state/chat_session.dart';
import 'package:kanaru/src/ai/ui/chat_host.dart';
import 'package:kanaru/src/plugins/domain/package/chat_spec.dart';

/// Names of the conversations of [FakeChatSession], by id.
class FakeChatTitles extends Notifier<Map<int, String>> {
  @override
  Map<int, String> build() => const {};

  void set(int id, String title) => state = {...state, id: title};
}

final fakeChatTitlesProvider =
    NotifierProvider<FakeChatTitles, Map<int, String>>(FakeChatTitles.new);

/// A chat session without a database or a plugin: opens numbered
/// conversations and records what the UI asked.
class FakeChatSession extends ChatSessionController {
  FakeChatSession({int? open = 1}) : _next = open ?? 0, _initial = open;

  final int? _initial;
  int _next;
  final calls = <String>[];

  @override
  ChatSessionState build() => ChatSessionState(conversationId: _initial);

  @override
  Future<int> newConversation() async {
    calls.add('new');
    final current = state.conversationId;
    // Like the real controller: an empty conversation is reused (a fake
    // conversation counts as empty until `usedConversations` names it).
    if (current != null && !used.contains(current)) return current;
    state = ChatSessionState(conversationId: ++_next);
    return _next;
  }

  /// Conversations that already hold a message.
  final used = <int>{};

  @override
  Future<bool> open(int id) async {
    calls.add('open $id');
    state = ChatSessionState(conversationId: id);
    return true;
  }

  @override
  Future<void> rename(int id, String title) async {
    calls.add('rename $id $title');
    ref.read(fakeChatTitlesProvider.notifier).set(id, title);
  }

  @override
  Future<void> delete(int id) async {
    calls.add('delete $id');
    if (state.conversationId == id) {
      state = ChatSessionState(conversationId: ++_next);
    }
  }
}

class _NoMessages extends ChatMessagesNotifier {
  _NoMessages(super.conversationId);

  @override
  Future<ChatMessages> build() async => const ChatMessages([], hasMore: false);
}

/// One installed, ready chat plugin.
const fakeChatPlugin = ChatPluginInfo(
  installId: 'plugin-1',
  installGeneration: 1,
  name: 'Claude',
  version: 1,
  spec: ChatSpec(),
  models: [],
  defaultModel: null,
  readiness: ChatReady(),
);

/// Overrides that stand in for the engine behind the chat screens.
List<Override> chatUiOverrides({
  required FakeChatSession session,
  bool withPlugin = true,
}) => [
  chatSessionProvider.overrideWith(() => session),
  chatPluginsProvider.overrideWithValue(
    AsyncData(withPlugin ? const [fakeChatPlugin] : const []),
  ),
  chatMessagesProvider.overrideWith2(_NoMessages.new),
  chatConversationProvider.overrideWith((ref, id) {
    final title = ref.watch(fakeChatTitlesProvider)[id] ?? '';
    final at = DateTime.utc(2026, 11, 27);
    return AiConversation(
      id: id,
      title: title,
      titleAuto: title.isEmpty,
      permission: AiPermission.ask,
      createdAt: at,
      updatedAt: at,
      lastMessageAt: at,
    );
  }),
];

/// A [ChatHost] that records what the chat asked of the app.
class RecordingChatHost implements ChatHost {
  RecordingChatHost({this.isPanel = true});

  @override
  final bool isPanel;
  final calls = <String>[];

  @override
  void close() => calls.add('close');

  @override
  void openQueue() => calls.add('openQueue');

  @override
  void openSettings(String location) => calls.add('openSettings $location');
}
