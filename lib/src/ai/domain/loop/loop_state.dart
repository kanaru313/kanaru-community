import '../conversation/ai_message.dart';

/// What the chat is doing right now, for the screen.
enum TurnState { idle, streaming, runningTools, awaitingConfirm, error }

/// Why the loop waits for the user instead of acting.
enum TapReason {
  /// A model round would start (after launch, after a stop or an error).
  modelRound,

  /// Calls the user already allowed are waiting to run.
  toolsWaiting,

  /// A message is still `streaming` but no round of this app owns it.
  strayStreaming,

  /// A call is `running` but nothing of this app runs it.
  strayRunning,
}

/// The rows of the latest turn: the user message and what followed it.
class LoopTranscript {
  const LoopTranscript({required this.turnId, required this.rows});

  /// The id of the turn's user message.
  final int turnId;

  /// Every row after the user message, in `seq` order.
  final List<AiMessage> rows;

  /// Assistant rows (one per model round), in order.
  List<AiMessage> get assistants => [
    for (final r in rows)
      if (r.role == AiMessageRole.assistant) r,
  ];

  /// The tool rows written after [assistant] (its round's calls), in the
  /// model's order.
  List<AiMessage> cardsOf(AiMessage assistant) => [
    for (final r in rows)
      if (r.role == AiMessageRole.tool && r.seq > assistant.seq) r,
  ];
}

/// The next step of a turn, decided by `ChatLoop.next`.
sealed class LoopAction {
  const LoopAction();
}

/// Ask the model for round [round] (1-based). The last allowed round
/// ([finalRound]) offers the tools with `toolChoice: "none"`.
final class RunModel extends LoopAction {
  const RunModel({required this.round, required this.finalRound});

  final int round;
  final bool finalRound;
}

/// Calls of the round wait for the user's answer.
final class AwaitConfirms extends LoopAction {
  const AwaitConfirms(this.cardIds);

  final List<int> cardIds;
}

/// Run these allowed calls, in the model's order. Only returned once every
/// card of the round is resolved.
final class RunTools extends LoopAction {
  const RunTools(this.cards);

  final List<AiMessage> cards;
}

/// Pending cards left too long (24 h): mark them expired.
final class ExpireCards extends LoopAction {
  const ExpireCards(this.cardIds);

  final List<int> cardIds;
}

/// The turn is over.
final class Done extends LoopAction {
  const Done();
}

/// Something could run but nothing the user did asks for it.
final class NeedsUserTap extends LoopAction {
  const NeedsUserTap(this.reason);

  final TapReason reason;
}
