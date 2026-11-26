import '../conversation/ai_message.dart';
import '../conversation/parts.dart';
import 'card_results.dart';
import 'loop_context.dart';

/// Answers the tool cards of the latest turn without running them (deny,
/// expire, skip). Every move is a compare-and-set, so a card another caller
/// moved first is left alone.
class CardAnswers {
  const CardAnswers(this.ctx);

  final LoopContext ctx;

  /// The pending card of call [callId] in the newest round, with the
  /// snapshot it was read from.
  Future<(LoopSnapshot, AiMessage, ToolCallPart)?> pendingCard(
    String callId,
  ) async {
    final snap = await ctx.snapshot();
    final transcript = snap?.transcript;
    final last = transcript?.assistants.lastOrNull;
    if (snap == null || transcript == null || last == null) return null;
    for (final card in transcript.cardsOf(last)) {
      final call = callOf(card);
      if (call != null &&
          call.id == callId &&
          card.state == AiMessageState.pending) {
        return (snap, card, call);
      }
    }
    return null;
  }

  /// Moves a pending or allowed card to `skipped` with [text] as its result;
  /// its confirm part (if any) takes [status] and [reason]. False when the
  /// card had moved.
  Future<bool> answer(
    AiMessage card,
    ToolCallPart call,
    String text,
    ConfirmStatus status, {
    String? reason,
  }) async {
    try {
      return await ctx.store.transition(
        card.id,
        from: card.state,
        to: AiMessageState.skipped,
        parts: skippedParts(card, call, text, status: status, reason: reason),
      );
    } on Object catch (e, s) {
      ctx.report(e, s);
      return false;
    }
  }

  /// Marks the cards [ids] of [snap] expired.
  Future<void> expire(LoopSnapshot snap, List<int> ids) async {
    for (final id in ids) {
      final card = ctx.cardById(snap, id);
      final call = card == null ? null : callOf(card);
      if (card != null && call != null) {
        await answer(card, call, expiredText, ConfirmStatus.expired);
      }
    }
  }

  /// Skips every pending and allowed card of the latest turn.
  Future<void> skipOpen(String text, ConfirmStatus status) async {
    final snap = await ctx.snapshot();
    final transcript = snap?.transcript;
    if (snap == null || transcript == null) return;
    for (final card in transcript.rows) {
      final open =
          card.role == AiMessageRole.tool &&
          (card.state == AiMessageState.pending ||
              card.state == AiMessageState.allowed);
      final call = callOf(card);
      if (open && call != null) {
        await answer(card, call, text, status);
      }
    }
  }
}
