import 'dart:async';

import '../conversation/ai_message.dart';
import '../conversation/parts.dart';
import '../output/chat_output_parser.dart';
import '../tools/ai_tool.dart';
import 'card_results.dart';
import 'loop_context.dart';
import 'loop_ports.dart';
import 'may_execute.dart';

/// Runs the allowed calls of one round in the model's order, one at a time.
class ToolBatch {
  ToolBatch(this.ctx);

  final LoopContext ctx;

  /// Runs [cards]. Returns true when a call hit the turn's item limit: the
  /// rest of the batch is skipped and the turn ends with the limit card.
  /// After a stop request the call being run finishes and every later call
  /// is skipped with the fixed text.
  Future<bool> run(List<AiMessage> cards) async {
    var limitHit = false;
    for (final card in cards) {
      if (limitHit) {
        await _skip(card, limitSkippedText);
      } else if (ctx.stopRequested) {
        await _skip(card, stoppedByUserText, reason: 'stopped');
      } else if (await _runOne(card)) {
        limitHit = true;
      }
    }
    return limitHit;
  }

  Future<void> _skip(
    AiMessage card,
    String text, {
    String? reason,
    AiMessageState from = AiMessageState.allowed,
  }) async {
    final call = callOf(card);
    if (call == null) return;
    await _guard(
      () => ctx.store.transition(
        card.id,
        from: from,
        to: AiMessageState.skipped,
        parts: skippedParts(card, call, text, reason: reason),
      ),
    );
  }

  Future<void> _guard(Future<Object?> Function() body) async {
    try {
      await body();
    } on Object catch (e, s) {
      ctx.report(e, s);
    }
  }

  /// Returns true when the call hit the item limit.
  Future<bool> _runOne(AiMessage listed) async {
    final snap = await ctx.snapshot();
    if (snap == null) return false;
    final card = ctx.cardById(snap, listed.id);
    // Another caller moved it (a permission switch denied it, say).
    if (card == null || card.state != AiMessageState.allowed) return false;
    final call = callOf(card);
    if (call == null) return false;
    final settings = await ctx.env.settings();
    final tool = ctx.env.registry.byName(call.name);

    final refusal = _storedRefusal(call, tool, settings.maxRounds);
    if (refusal != null) {
      await _skip(card, refusalText(refusal));
      return false;
    }

    final conversation = snap.conversation;
    final plugin = await ctx.env.plugin(conversation);
    final round = ctx.roundOf(snap, card);
    final approval = ctx.approvals[call.id];
    final decision = mayExecute(
      call: call,
      tool: tool,
      permission: conversation.permission,
      groupEnabled: settings.groupEnabled,
      round: RoundBinding(
        installId: round?.installId,
        installGeneration: round?.installGeneration,
        model: round?.model,
      ),
      current: plugin == null
          ? null
          : RoundBinding(
              installId: plugin.installId,
              installGeneration: plugin.installGeneration,
              model: plugin.model,
            ),
      // An Allow given for another conversation never matches.
      approvedHash: approval == null
          ? null
          : approval.conversationId == ctx.conversationId
          ? approval.hash
          : '',
    );
    if (decision is ExecRefused) {
      ctx.approvals.remove(call.id);
      await _skip(
        card,
        notAllowedNowText(decision.reason),
        reason: decision.reason.code,
      );
      return false;
    }

    final started = await ctx.store.transition(
      card.id,
      from: AiMessageState.allowed,
      to: AiMessageState.running,
    );
    if (!started) return false;
    ctx.approvals.remove(call.id);
    return _execute(card, call, tool!);
  }

  Future<bool> _execute(AiMessage card, ToolCallPart call, AiTool tool) async {
    final env = ctx.env.toolEnv.copyWith(turnUsage: ctx.turnUsage);
    final isWrite = tool.risk == ToolRisk.write;
    ToolOutcome? outcome;
    var timedOut = false;
    try {
      outcome = await tool
          .run(call.args ?? const {}, env)
          .timeout(ctx.toolTimeout);
    } on TimeoutException {
      timedOut = true;
    } on Object catch (e, s) {
      ctx.report(e, s);
      outcome = const ToolOutcome.error('tool failed');
    }

    final AiMessageState to;
    final List<AiPart> parts;
    LoopError? error;
    var limit = false;
    if (timedOut) {
      // A write that was cut off may still have happened.
      to = isWrite ? AiMessageState.unknown : AiMessageState.error;
      parts = finishedParts(
        card,
        call,
        errorResult(call, isWrite ? writeTimedOutText : toolTimedOutText),
      );
    } else if (outcome!.limitReached) {
      limit = true;
      to = AiMessageState.error;
      error = const LoopError(code: limitReachedCode, kind: 'invalidResponse');
      parts = [
        ...finishedParts(card, call, errorResult(call, outcome.text)),
        const ErrorPart(code: limitReachedCode, kind: 'invalidResponse'),
      ];
    } else if (outcome.isError) {
      to = AiMessageState.error;
      parts = finishedParts(card, call, errorResult(call, outcome.text));
    } else {
      to = AiMessageState.done;
      parts = finishedParts(
        card,
        call,
        ToolResultPart(
          id: call.id,
          providerId: call.providerId,
          name: call.name,
          content: [TextPart(outcome.text)],
        ),
        done: outcome.done?.toPart(call.id),
      );
    }
    await _guard(
      () => ctx.store.transition(
        card.id,
        from: AiMessageState.running,
        to: to,
        parts: parts,
        error: error,
      ),
    );
    return limit;
  }
}

final _callRound = RegExp(r'^t\d+-r(\d+)-\d+$');

/// Why a stored call must be answered with an error instead of running: it
/// names no tool, its arguments never parsed, or it came in the final round.
ChatCallRefusal? _storedRefusal(
  ToolCallPart call,
  AiTool? tool,
  int maxRounds,
) {
  if (tool == null) return ChatCallRefusal.unknownTool;
  final round = int.tryParse(_callRound.firstMatch(call.id)?.group(1) ?? '');
  if (round != null && round > maxRounds) {
    return ChatCallRefusal.noToolsInThisRound;
  }
  if (call.rawArgs != null) return ChatCallRefusal.rawArguments;
  return null;
}
