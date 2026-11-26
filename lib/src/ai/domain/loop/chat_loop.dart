import '../../../plugins/domain/package/chat_spec.dart';
import '../conversation/ai_message.dart';
import '../conversation/parts.dart';
import 'loop_ports.dart';
import 'loop_state.dart';
import 'may_execute.dart';

/// Model rounds that may offer tools before the final round.
const chatMaxToolRounds = 6;

/// The turn state machine. Pure: it reads the stored rows of the latest turn
/// and says what comes next; the driver does it.
class ChatLoop {
  const ChatLoop();

  /// [armed] is true when the user did something that lets the turn go on
  /// (send, retry, allow, deny): only then a model round or a tool run is
  /// returned. Otherwise those become [NeedsUserTap], so nothing runs at
  /// launch.
  ///
  /// Order: a round's calls run only after every card of that round is
  /// resolved, then the next round starts. After [LoopSettings.maxRounds]
  /// rounds one more round runs with the tools turned off, then the turn is
  /// done.
  LoopAction next(
    LoopTranscript transcript,
    LoopSettings settings,
    ChatCapabilities capabilities, {
    required bool armed,
    required DateTime now,
  }) {
    final assistants = transcript.assistants;
    if (assistants.isEmpty) return _model(1, settings, capabilities, armed);

    final last = assistants.last;
    final completed = [
      for (final a in assistants)
        if (a.state == AiMessageState.complete) a,
    ].length;
    final nextRound = completed + 1;

    switch (last.state) {
      case AiMessageState.streaming:
        return const NeedsUserTap(TapReason.strayStreaming);
      case AiMessageState.complete:
        break;
      default:
        // Error or stopped: the user retries the round.
        return _model(nextRound, settings, capabilities, armed);
    }

    final cards = transcript.cardsOf(last);
    final expired = [
      for (final c in cards)
        if (c.state == AiMessageState.pending && cardExpired(c.createdAt, now))
          c.id,
    ];
    if (expired.isNotEmpty) return ExpireCards(expired);
    final pending = [
      for (final c in cards)
        if (c.state == AiMessageState.pending) c.id,
    ];
    if (pending.isNotEmpty) return AwaitConfirms(pending);
    final running = [
      for (final c in cards)
        if (c.state == AiMessageState.running) c,
    ];
    if (running.isNotEmpty) {
      // An armed flight runs the calls itself, one at a time, so a row still
      // `running` here is left over from a run that never stored its result.
      return armed
          ? HealRunning(running)
          : const NeedsUserTap(TapReason.strayRunning);
    }
    final allowed = [
      for (final c in cards)
        if (c.state == AiMessageState.allowed) c,
    ];
    if (allowed.isNotEmpty) {
      return armed
          ? RunTools(allowed)
          : const NeedsUserTap(TapReason.toolsWaiting);
    }
    // Every card is resolved.
    final hadCalls = last.parts.any((p) => p is ToolCallPart);
    // A flattened turn keeps tool rows for display but no calls: it is over.
    if (!hadCalls) return const Done();
    if (completed > settings.maxRounds) return const Done();
    return _model(nextRound, settings, capabilities, armed);
  }

  LoopAction _model(
    int round,
    LoopSettings settings,
    ChatCapabilities capabilities,
    bool armed,
  ) {
    if (!armed) return const NeedsUserTap(TapReason.modelRound);
    return RunModel(
      round: round,
      finalRound: capabilities.tools && round > settings.maxRounds,
    );
  }
}
