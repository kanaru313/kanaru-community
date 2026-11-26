import '../conversation/ai_conversation.dart';
import '../conversation/ai_message.dart';
import '../conversation/parts.dart';
import '../input/history_turns.dart';
import '../tools/item_caps.dart';
import 'loop_ports.dart';
import 'loop_state.dart';

/// The conversation as one loop step read it.
class LoopSnapshot {
  const LoopSnapshot({
    required this.conversation,
    required this.history,
    required this.turn,
  });

  final AiConversation conversation;
  final List<HistoryRow> history;

  /// The latest turn; null while the conversation has no user message.
  final HistoryTurn? turn;

  /// The `seq` of the newest row: what the next round's append compares.
  int get revision => history.isEmpty ? 0 : history.last.message.seq;

  LoopTranscript? get transcript => turn == null
      ? null
      : LoopTranscript(
          turnId: turn!.user.message.id,
          rows: [for (final r in turn!.rows) r.message],
        );

  /// The call parts and the tool rows' parts of the turn, for item usage.
  Iterable<AiPart> get turnParts => [
    for (final r in turn?.rows ?? const <HistoryRow>[]) ...r.message.parts,
  ];
}

/// State and ports the driver, the round and the tool batch share. One per
/// conversation.
class LoopContext {
  LoopContext({
    required this.conversationId,
    required this.store,
    required this.runner,
    required this.env,
    required this.now,
    required this.toolTimeout,
    required this.newBoundary,
    required this.report,
    required this.emitLive,
    required this.liveFlushInterval,
  });

  final int conversationId;
  final LoopStore store;
  final ModelRoundRunner runner;
  final LoopEnvironment env;
  final DateTime Function() now;
  final Duration toolTimeout;
  final String Function() newBoundary;
  final void Function(Object error, StackTrace stack) report;
  final void Function(int messageId, String text) emitLive;
  final Duration liveFlushInterval;

  /// The user asked to stop the turn.
  bool stopRequested = false;

  /// Reads the conversation; null when it is gone.
  Future<LoopSnapshot?> snapshot() async {
    final conversation = await store.conversation(conversationId);
    if (conversation == null) return null;
    final history = await store.history(conversationId);
    final turns = groupTurns(history);
    return LoopSnapshot(
      conversation: conversation,
      history: history,
      turn: turns.isEmpty ? null : turns.last,
    );
  }

  /// What the assistant changed in the latest turn, from stored rows.
  Future<TurnItemUsage> turnUsage() async {
    final snap = await snapshot();
    return snap == null
        ? TurnItemUsage.none
        : TurnItemUsage.fromParts(snap.turnParts);
  }

  /// The stored message of [cardId] in the latest turn, if any.
  AiMessage? cardById(LoopSnapshot snap, int cardId) {
    for (final r in snap.turn?.rows ?? const <HistoryRow>[]) {
      if (r.message.id == cardId) return r.message;
    }
    return null;
  }

  /// The assistant row whose round [card] belongs to: the newest assistant
  /// row before it.
  AiMessage? roundOf(LoopSnapshot snap, AiMessage card) {
    AiMessage? found;
    for (final r in snap.turn?.rows ?? const <HistoryRow>[]) {
      if (r.message.seq >= card.seq) break;
      if (r.message.role == AiMessageRole.assistant) found = r.message;
    }
    return found;
  }
}

/// The binding of the plugin and model a round runs with.
ChatBinding bindingOf(LoopPlugin plugin) => ChatBinding(
  installId: plugin.installId,
  installGeneration: plugin.installGeneration,
  pluginVersion: plugin.version,
  model: plugin.model,
);
