import '../../../plugins/domain/package/chat_spec.dart';
import '../../../plugins/domain/run/run_outcome.dart';
import '../conversation/ai_conversation.dart';
import '../conversation/ai_message.dart';
import '../conversation/parts.dart';
import '../input/chat_input_builder.dart';
import '../settings/tool_groups.dart';
import '../tools/ai_tool_registry.dart';
import '../tools/tool_env.dart';

bool _allGroupsOn(AiToolGroup group) => true;

/// The user's settings a round or a tool run reads. Read fresh before every
/// round and every call.
class LoopSettings {
  const LoopSettings({
    this.groupEnabled = _allGroupsOn,
    this.instructions = '',
    this.maxRounds = 6,
  });

  final bool Function(AiToolGroup group) groupEnabled;

  /// The user's general instructions (`ai.instructions`).
  final String instructions;

  /// Rounds that offer tools before the final round.
  final int maxRounds;
}

/// The installed chat plugin a conversation is bound to, as of now.
class LoopPlugin {
  const LoopPlugin({
    required this.installId,
    required this.installGeneration,
    required this.version,
    required this.model,
    required this.capabilities,
    this.maxOutputTokens,
    this.host,
    this.pausedUntil,
  });

  final String installId;
  final int installGeneration;
  final int version;

  /// The model a request uses: the conversation's, else the plugin's own.
  final String model;
  final ChatCapabilities capabilities;
  final int? maxOutputTokens;

  /// The host a network card names.
  final String? host;

  /// End of the plugin's pause, if it is paused.
  final DateTime? pausedUntil;
}

/// What the loop needs from the app besides the store and the runner.
abstract interface class LoopEnvironment {
  AiToolRegistry get registry;

  /// The ports tools use (the driver adds the turn's item usage).
  ToolEnv get toolEnv;

  Future<LoopSettings> settings();

  /// The plugin [conversation] is bound to now; null when it is not
  /// installed (any more).
  Future<LoopPlugin?> plugin(AiConversation conversation);
}

/// One model round.
class ModelRoundRequest {
  const ModelRoundRequest({required this.conversation, required this.input});

  final AiConversation conversation;

  /// The plugin's `input` object (chat contract).
  final Map<String, Object?> input;
}

/// Runs one model round on the plugin.
abstract interface class ModelRoundRunner {
  /// Runs the round; [onDelta] gets each piece of streamed text. Never
  /// throws for a failed run: that is a [RunOutcome].
  Future<RunOutcome> run(
    ModelRoundRequest request, {
    required void Function(String delta) onDelta,
  });

  /// Cancels the run in flight (the user stopped); a no-op when none runs.
  void cancel();
}

/// What is stored of a failed message: the contract code and kind only.
class LoopError {
  const LoopError({required this.code, required this.kind, this.retryAfterSec});

  final String code;
  final String kind;
  final int? retryAfterSec;
}

/// A call of a finished round, to be stored as a tool row.
class CardDraft {
  const CardDraft({required this.call, required this.needsConfirm});

  final ToolCallPart call;
  final bool needsConfirm;
}

class RoundCommit {
  const RoundCommit({required this.cardIds, required this.blobTooLarge});

  /// The ids of the stored tool rows, in the order of the drafts.
  final List<int> cardIds;

  /// The provider blob was over its cap; the turn is flattened at its end.
  final bool blobTooLarge;
}

/// A write went over a size cap (the row is marked `error(too_large)`).
class LoopStoreTooLarge implements Exception {
  const LoopStoreTooLarge(this.what);

  final String what;

  @override
  String toString() => 'LoopStoreTooLarge: $what';
}

/// How [LoopStore.startCall] ended.
enum CallStart { started, moved, readOnly }

/// The conversation store as the loop uses it. `data/loop_store_adapter.dart`
/// implements it on `ConversationStore`.
abstract interface class LoopStore {
  Future<AiConversation?> conversation(int id);

  /// Every row of the conversation in `seq` order, with blob text. Only the
  /// model input needs this: it can be megabytes.
  Future<List<HistoryRow>> history(int conversationId);

  /// The latest turn (its user message and what followed), without blobs;
  /// empty when the chat has no user message. Every loop decision reads this.
  Future<List<HistoryRow>> latestTurn(int conversationId);

  /// The tool rows of the whole chat still `pending` or `allowed`.
  Future<List<AiMessage>> openCards(int conversationId);

  /// `allowed -> running` in one step. A write is refused while the chat is
  /// read-only; the permission is read in the same step.
  Future<CallStart> startCall(int messageId, {required bool write});

  /// Appends a user message; returns its id.
  Future<int> appendUser(int conversationId, List<AiPart> parts);

  /// Appends the streaming assistant message of a round, only when the newest
  /// row still has `seq == expectedRevision` (the transcript the input was
  /// built from). Returns its id, or null when another write got in first.
  Future<int?> beginRound(
    int conversationId, {
    required int expectedRevision,
    required ChatBinding binding,
  });

  /// False when the message is no longer streaming.
  Future<bool> updateLiveText(int messageId, String text);

  /// Ends a streaming round with its parts, blob and calls in one step; null
  /// when the message was no longer streaming. Throws [LoopStoreTooLarge].
  Future<RoundCommit?> completeRound(
    int messageId, {
    required List<AiPart> parts,
    String? blob,
    List<CardDraft> calls = const [],
  });

  /// Moves a streaming message to `stopped` or `error`.
  Future<bool> endRound(
    int messageId, {
    required AiMessageState to,
    List<AiPart> parts = const [],
    LoopError? error,
  });

  /// Records the plugin version that really ran the round.
  Future<bool> stampPluginVersion(int messageId, int version);

  /// Compare-and-set move of a message; false when it was not in [from].
  /// Throws [LoopStoreTooLarge].
  Future<bool> transition(
    int messageId, {
    required AiMessageState from,
    required AiMessageState to,
    List<AiPart>? parts,
    LoopError? error,
  });

  /// `pending -> allowed` (the confirm part takes the status and the
  /// [approvalHash] of the call the user saw); false when the card was not
  /// pending.
  Future<bool> approve(int messageId, {required String approvalHash});

  /// Call when a turn ends (flattens it when a blob was too large).
  Future<void> endTurn(int turnId);
}
