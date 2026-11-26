import '../domain/loop/loop_state.dart';
import '../domain/output/chat_outcome.dart';

/// What the chat screen shows of the session.
class ChatSessionState {
  const ChatSessionState({
    this.conversationId,
    this.turnState = TurnState.idle,
    this.lastView,
  });

  /// The open conversation; null before the first one opens.
  final int? conversationId;
  final TurnState turnState;

  /// The card the last failed round ended with (live only; after a reload
  /// the card comes from the stored error, see `cardOfStoredError`).
  final ChatOutcomeView? lastView;

  ChatSessionState copyWith({
    int? conversationId,
    TurnState? turnState,
    ChatOutcomeView? lastView,
  }) => ChatSessionState(
    conversationId: conversationId ?? this.conversationId,
    turnState: turnState ?? this.turnState,
    lastView: lastView ?? this.lastView,
  );

  @override
  bool operator ==(Object other) =>
      other is ChatSessionState &&
      other.conversationId == conversationId &&
      other.turnState == turnState &&
      identical(other.lastView, lastView);

  @override
  int get hashCode =>
      Object.hash(conversationId, turnState, identityHashCode(lastView));
}
