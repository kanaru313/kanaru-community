import '../../../plugins/domain/package/chat_spec.dart';
import '../conversation/ai_message.dart';
import 'card_answers.dart';
import 'chat_loop.dart';
import 'loop_context.dart';
import 'loop_state.dart';

/// Reads the stored latest turn and reports what the chat is doing, without
/// running anything. Used when a conversation opens and after a change made
/// outside a flight.
class TurnInspector {
  const TurnInspector({
    required this.ctx,
    required this.loop,
    required this.cards,
    required this.busy,
    required this.setState,
    required this.report,
  });

  final LoopContext ctx;
  final ChatLoop loop;
  final CardAnswers cards;

  /// Whether a flight runs (it owns the state then).
  final bool Function() busy;
  final void Function(TurnState state) setState;
  final void Function(Object error, StackTrace stack) report;

  /// Sets the turn state from the store. Cards past 24 hours are marked
  /// expired. Returns what a tap could do next; null while a turn runs.
  Future<LoopAction?> inspect() async {
    if (busy()) return null;
    try {
      var action = await _peek();
      if (action is ExpireCards) {
        final snap = await ctx.snapshot();
        if (snap != null && !busy()) {
          await cards.expire(snap, action.cardIds);
          action = await _peek();
        }
      }
      return action;
    } on Object catch (e, s) {
      report(e, s);
      return const Done();
    }
  }

  Future<LoopAction> _peek() async {
    final snap = await ctx.snapshot();
    final transcript = snap?.transcript;
    if (snap == null || transcript == null) {
      if (!busy()) setState(TurnState.idle);
      return const Done();
    }
    final plugin = await ctx.env.plugin(snap.conversation);
    final settings = await ctx.env.settings();
    final action = loop.next(
      transcript,
      settings,
      plugin?.capabilities ?? const ChatCapabilities(),
      armed: false,
      now: ctx.now(),
    );
    final last = transcript.assistants.lastOrNull;
    if (!busy()) {
      setState(switch (action) {
        AwaitConfirms() => TurnState.awaitingConfirm,
        _ when last != null && last.state == AiMessageState.error =>
          TurnState.error,
        _ => TurnState.idle,
      });
    }
    return action;
  }
}
