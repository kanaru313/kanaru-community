import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:kanaru/src/ai/domain/conversation/ai_conversation.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/loop/loop_state.dart';
import 'package:kanaru/src/ai/domain/output/chat_readiness.dart';
import 'package:kanaru/src/ai/domain/permission.dart';
import 'package:kanaru/src/ai/state/chat_conversation_providers.dart';
import 'package:kanaru/src/ai/state/chat_messages_provider.dart';
import 'package:kanaru/src/ai/state/chat_providers.dart';
import 'package:kanaru/src/ai/state/chat_session.dart';
import 'package:kanaru/src/ai/state/chat_view/composer_inputs.dart';
import 'package:kanaru/src/ai/state/live_text_provider.dart';
import 'package:kanaru/src/plugins/state/store_ops.dart';
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

  /// Moves the turn to [turn] (the dots follow it).
  void setTurn(TurnState turn) => state = ChatSessionState(
    conversationId: state.conversationId,
    turnState: turn,
  );

  /// Conversations that already hold a message.
  final used = <int>{};

  /// What `send` answers; null is an accepted message.
  SendResult? sendResult;

  @override
  Future<SendResult> send(String text, {bool shortVersion = false}) async {
    calls.add(shortVersion ? 'send short $text' : 'send $text');
    return sendResult ?? SendSent(Future.value());
  }

  @override
  Future<void> stop() async => calls.add('stop');

  @override
  Future<bool> switchPlugin(String installId) async {
    calls.add('switchPlugin $installId');
    ref
        .read(fakeChatBindingProvider.notifier)
        .set(installId: installId, model: null);
    return true;
  }

  @override
  Future<void> switchModel(String model) async {
    calls.add('switchModel $model');
    ref.read(fakeChatBindingProvider.notifier).set(model: model);
  }

  @override
  Future<void> setPermission(AiPermission permission) async {
    calls.add('permission ${permission.name}');
    ref.read(fakeChatBindingProvider.notifier).set(permission: permission);
  }

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

/// The messages every fake conversation shows; tests set them and the list
/// follows, like the real notifier after a store change.
class FakeChatMessagesData extends Notifier<ChatMessages> {
  @override
  ChatMessages build() => const ChatMessages([], hasMore: false);

  /// How often the list asked for an older page.
  int olderRequests = 0;

  void set(List<AiMessage> messages, {bool hasMore = false}) =>
      state = ChatMessages(messages, hasMore: hasMore);
}

final fakeChatMessagesProvider =
    NotifierProvider<FakeChatMessagesData, ChatMessages>(
      FakeChatMessagesData.new,
    );

/// Makes reading the messages fail.
final fakeMessagesFailProvider = Provider<bool>((ref) => false);

class _FakeMessages extends ChatMessagesNotifier {
  _FakeMessages(super.conversationId);

  @override
  Future<ChatMessages> build() async {
    if (ref.watch(fakeMessagesFailProvider)) throw StateError('store failed');
    return ref.watch(fakeChatMessagesProvider);
  }

  @override
  Future<void> loadOlder() async =>
      ref.read(fakeChatMessagesProvider.notifier).olderRequests++;
}

/// The text streamed into the live message, as the controller publishes it.
class FakeLiveText extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? text) => state = text;
}

final fakeLiveTextProvider = NotifierProvider<FakeLiveText, String?>(
  FakeLiveText.new,
);

class _FakeLive extends LiveTextNotifier {
  _FakeLive(super.messageId);

  @override
  String? build() => ref.watch(fakeLiveTextProvider);
}

/// A stored message for the list tests.
AiMessage chatMessage(
  int id, {
  AiMessageRole role = AiMessageRole.assistant,
  List<AiPart> parts = const [],
  AiMessageState state = AiMessageState.complete,
  String? model,
  DateTime? at,
}) => AiMessage(
  id: id,
  conversationId: 1,
  seq: id,
  role: role,
  parts: parts,
  state: state,
  model: model,
  createdAt: at ?? DateTime(2026, 11, 27, 14, 32),
);

/// What a fake conversation is bound to: plugin, model and permission.
class FakeChatBinding {
  const FakeChatBinding({
    this.installId,
    this.model,
    this.permission = AiPermission.ask,
  });

  final String? installId;
  final String? model;
  final AiPermission permission;
}

class FakeChatBindingNotifier extends Notifier<FakeChatBinding> {
  @override
  FakeChatBinding build() => const FakeChatBinding();

  /// Changes the given fields; `model: null` clears the model (a plugin
  /// switch does), so the arguments are told apart from "not given".
  void set({
    Object? installId = _keep,
    Object? model = _keep,
    AiPermission? permission,
  }) => state = FakeChatBinding(
    installId: identical(installId, _keep)
        ? state.installId
        : installId as String?,
    model: identical(model, _keep) ? state.model : model as String?,
    permission: permission ?? state.permission,
  );
}

const Object _keep = Object();

final fakeChatBindingProvider =
    NotifierProvider<FakeChatBindingNotifier, FakeChatBinding>(
      FakeChatBindingNotifier.new,
    );

/// What the readiness of every fake conversation says.
class FakeReadiness extends Notifier<ChatReadiness> {
  @override
  ChatReadiness build() => const ChatReady();

  void set(ChatReadiness readiness) => state = readiness;
}

final fakeChatReadinessProvider =
    NotifierProvider<FakeReadiness, ChatReadiness>(FakeReadiness.new);

/// The settings the composer reads (groups, prompts).
class FakeComposerSettings extends Notifier<ComposerSettings> {
  @override
  ComposerSettings build() => ComposerSettings();

  void set(ComposerSettings settings) => state = settings;
}

final fakeComposerSettingsProvider =
    NotifierProvider<FakeComposerSettings, ComposerSettings>(
      FakeComposerSettings.new,
    );

/// Whether a song plays and the queue has entries.
class FakePromptData extends Notifier<ChatPromptData> {
  @override
  ChatPromptData build() => const ChatPromptData();

  void set(ChatPromptData data) => state = data;
}

final fakePromptDataProvider = NotifierProvider<FakePromptData, ChatPromptData>(
  FakePromptData.new,
);

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
  List<ChatPluginInfo>? plugins,
}) => [
  chatSessionProvider.overrideWith(() => session),
  chatPluginsProvider.overrideWithValue(
    AsyncData(plugins ?? (withPlugin ? const [fakeChatPlugin] : const [])),
  ),
  chatReadinessProvider.overrideWith(
    (ref, id) => AsyncData(ref.watch(fakeChatReadinessProvider)),
  ),
  composerSettingsProvider.overrideWith(
    (ref) => ref.watch(fakeComposerSettingsProvider),
  ),
  chatPromptDataProvider.overrideWith(
    (ref) => ref.watch(fakePromptDataProvider),
  ),
  pluginIconProvider.overrideWith((ref, id) async => null),
  chatMessagesProvider.overrideWith2(_FakeMessages.new),
  liveTextProvider.overrideWith2(_FakeLive.new),
  chatConversationProvider.overrideWith((ref, id) {
    final title = ref.watch(fakeChatTitlesProvider)[id] ?? '';
    final binding = ref.watch(fakeChatBindingProvider);
    final at = DateTime.utc(2026, 11, 27);
    return AiConversation(
      id: id,
      title: title,
      titleAuto: title.isEmpty,
      installId: binding.installId,
      model: binding.model,
      permission: binding.permission,
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
