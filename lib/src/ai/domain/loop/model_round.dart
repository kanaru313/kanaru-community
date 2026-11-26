import '../../../plugins/domain/run/run_outcome.dart';
import '../conversation/ai_message.dart';
import '../conversation/parts.dart';
import '../input/chat_input_builder.dart';
import '../input/system_prompt.dart';
import '../input/tool_selection.dart';
import '../output/ai_error_code.dart';
import '../output/chat_outcome.dart';
import '../output/chat_output_parser.dart';
import '../output/outcome_mapper.dart';
import '../permission.dart';
import '../tools/ai_tool.dart';
import 'card_results.dart';
import 'loop_context.dart';
import 'loop_ports.dart';
import 'loop_state.dart';

const _tooLargeView = ChatOutcomeView(
  end: ChatMessageEnd.error,
  card: ChatCardKind.tooLarge,
  action: ChatCardAction.newConversation,
  errorCode: AiErrorCode.tooLarge,
);

/// How a model round ended, for the pump.
class RoundResult {
  const RoundResult.next() : goOn = true, state = TurnState.idle, view = null;

  const RoundResult.end(this.state, [this.view]) : goOn = false;

  /// The reply is stored and the turn goes on.
  final bool goOn;

  /// The turn state when it does not go on.
  final TurnState state;

  /// The card the round ended with, when it ended without a reply.
  final ChatOutcomeView? view;
}

/// One model round: build the input, append the streaming message with a
/// revision check, run the plugin, store the reply or the failure.
class ModelRound {
  ModelRound(this.ctx);

  final LoopContext ctx;

  int _generation = 0;
  int _busyInARow = 0;
  _LiveText? _live;

  /// Writes the streamed text so far (the app is going to the background).
  Future<void> flushLive() => _live?.flush() ?? Future.value();

  Future<RoundResult> run(LoopSnapshot snap, RunModel action) async {
    final conversation = snap.conversation;
    final transcript = snap.transcript!;
    final plugin = await ctx.env.plugin(conversation);
    if (plugin == null) {
      // Nothing to attach a card to: the readiness of the chat shows it.
      return RoundResult.end(
        TurnState.error,
        mapChatOutcome(
          const RunUnavailable(RunUnavailableReason.notInstalled),
          ChatOutcomeContext(now: ctx.now()),
        ),
      );
    }
    final settings = await ctx.env.settings();
    final offered = offeredTools(
      ctx.env.registry,
      permission: conversation.permission,
      groupEnabled: settings.groupEnabled,
      modelSupportsTools: plugin.capabilities.tools,
    );
    final boundary = ctx.newBoundary();
    final built = buildChatInput(
      binding: bindingOf(plugin),
      history: snap.history,
      tools: offered,
      capabilities: plugin.capabilities,
      system: buildChatSystemPrompt(
        permission: conversation.permission,
        boundary: boundary,
        instructions: settings.instructions,
      ),
      boundary: boundary,
      finalRound: action.finalRound,
      maxOutputTokens: plugin.maxOutputTokens,
    );

    // The input was built from the transcript as read: write only if nobody
    // else has added a row since.
    final messageId = await ctx.store.beginRound(
      ctx.conversationId,
      expectedRevision: snap.revision,
      binding: bindingOf(plugin),
    );
    if (messageId == null) return const RoundResult.end(TurnState.idle);

    if (built is ChatInputTooLarge) {
      return _storeFailure(messageId, _tooLargeView);
    }
    final input = (built as ChatInputBuilt).input;

    final generation = ++_generation;
    final live = _live = _LiveText(ctx, messageId);
    RunOutcome outcome;
    try {
      outcome = await ctx.runner.run(
        ModelRoundRequest(conversation: conversation, input: input),
        onDelta: (delta) {
          // Events after the outcome (or a newer round) are dropped.
          if (generation != _generation) return;
          live.add(delta);
        },
      );
    } on Object catch (e, s) {
      ctx.report(e, s);
      outcome = const RunFailed(RunFailReason.internal);
    }
    _generation++;

    _busyInARow = outcome is RunBusy ? _busyInARow + 1 : 0;
    final view = mapChatOutcome(
      outcome,
      ChatOutcomeContext(
        now: ctx.now(),
        output: ChatOutputContext(
          turn: transcript.turnId,
          round: action.round,
          offeredNames: {for (final t in offered) t.name},
          finalRound: action.finalRound,
          callsSoFarInTurn: _callsSoFar(transcript),
        ),
        pausedUntil: plugin.pausedUntil,
        busyInARow: _busyInARow,
        host: plugin.host,
      ),
    );
    final output = view.output;
    if (view.end == ChatMessageEnd.complete && output != null) {
      await live.drain();
      final result = await _storeReply(
        messageId,
        output,
        conversation.permission,
      );
      if (result.goOn && outcome is RunOk) {
        await _stampVersion(messageId, outcome, plugin);
      }
      return result;
    }
    return _storeFailure(messageId, view);
  }

  int _callsSoFar(LoopTranscript t) => [
    for (final a in t.assistants)
      for (final p in a.parts)
        if (p is ToolCallPart) p,
  ].length;

  Future<RoundResult> _storeReply(
    int messageId,
    ChatRoundOutput output,
    AiPermission permission,
  ) async {
    final drafts = <CardDraft>[
      for (final c in output.calls)
        CardDraft(
          call: c.part,
          needsConfirm:
              c.refusal == null && await _needsConfirm(c.part, permission),
        ),
    ];
    try {
      final commit = await ctx.store.completeRound(
        messageId,
        parts: [
          if (output.text.trim().isNotEmpty) TextPart(output.text),
          for (final c in output.calls) c.part,
        ],
        blob: output.providerJson,
        calls: drafts,
      );
      // Someone else ended the message (a stop got in first).
      if (commit == null) return const RoundResult.end(TurnState.idle);
      // The blob did not fit, so this turn can never be sent whole again and
      // a running turn is never flattened: the turn ends here. Calls of the
      // round do not run (a reply without calls ends the turn on its own and
      // is flattened when it does).
      if (commit.blobTooLarge && drafts.isNotEmpty) {
        await _skipDrafts(commit.cardIds, drafts);
        return const RoundResult.end(TurnState.error, _tooLargeView);
      }
      return const RoundResult.next();
    } on LoopStoreTooLarge {
      // The store marked the message `error(too_large)`.
      return const RoundResult.end(TurnState.error);
    }
  }

  /// Moves the cards stored for [drafts] to `skipped` with the too-large
  /// text; a card someone else moved first is left alone.
  Future<void> _skipDrafts(List<int> ids, List<CardDraft> drafts) async {
    for (var i = 0; i < ids.length && i < drafts.length; i++) {
      final draft = drafts[i];
      try {
        await ctx.store.transition(
          ids[i],
          from: draft.needsConfirm
              ? AiMessageState.pending
              : AiMessageState.allowed,
          to: AiMessageState.skipped,
          parts: [
            draft.call,
            if (draft.needsConfirm)
              ConfirmPart(
                callId: draft.call.id,
                status: ConfirmStatus.denied,
                reason: AiErrorCode.tooLarge.wire,
              ),
            errorResult(draft.call, tooLargeSkippedText),
          ],
        );
      } on Object catch (e, s) {
        ctx.report(e, s);
      }
    }
  }

  /// An ask-mode write waits for the user, unless its preview is already a
  /// refusal (the model is told at run time, no card).
  Future<bool> _needsConfirm(ToolCallPart call, AiPermission permission) async {
    if (permission != AiPermission.ask) return false;
    final tool = ctx.env.registry.byName(call.name);
    if (tool == null || tool.risk != ToolRisk.write) return false;
    try {
      final preview = await tool.describe(
        call.args ?? const {},
        ctx.env.toolEnv,
      );
      return preview?.refusal == null;
    } on Object catch (e, s) {
      ctx.report(e, s);
      return true;
    }
  }

  Future<void> _stampVersion(int messageId, RunOk ok, LoopPlugin plugin) async {
    final ran = int.tryParse(ok.pluginVersion);
    if (ran == null || ran == plugin.version) return;
    try {
      await ctx.store.stampPluginVersion(messageId, ran);
    } on Object catch (e, s) {
      ctx.report(e, s);
    }
  }

  Future<RoundResult> _storeFailure(int messageId, ChatOutcomeView view) async {
    await _live?.drain();
    final code = _codeOf(view);
    final stopped = view.end == ChatMessageEnd.stopped;
    final retryAfter = view.retryAt?.difference(ctx.now()).inSeconds;
    await ctx.store.endRound(
      messageId,
      to: stopped ? AiMessageState.stopped : AiMessageState.error,
      parts: code == null
          ? const []
          : [ErrorPart(code: code, kind: _kindOf(code), retryAt: view.retryAt)],
      error: code == null
          ? null
          : LoopError(
              code: code,
              kind: _kindOf(code),
              retryAfterSec: retryAfter,
            ),
    );
    return RoundResult.end(stopped ? TurnState.idle : TurnState.error, view);
  }

  /// The code stored with a failed message: the contract code, else the
  /// card's own name in snake case (`limit_reached`, `timeout`); nothing for
  /// a plain stop.
  String? _codeOf(ChatOutcomeView view) {
    final card = view.card;
    if (card == ChatCardKind.network || card == ChatCardKind.hostNotAllowed) {
      return snakeCase(card!.name);
    }
    final code = view.errorCode?.wire;
    if (code != null) return code;
    if (card == null || card == ChatCardKind.stopped) return null;
    // A network or blocked-host failure is the contract's `server` on the
    // wire; the app stores its own code so the card survives a reload.
    return snakeCase(card.name);
  }
}

String _kindOf(String code) => switch (code) {
  'rate_limit' => 'rateLimited',
  'key' => 'auth',
  'quota' => 'quota',
  'bad_request' ||
  'context_length' ||
  'too_large' ||
  'empty' ||
  limitReachedCode => 'invalidResponse',
  _ => 'server',
};

/// The streamed text of the running round, flushed to the store at most once
/// per interval and on demand.
class _LiveText {
  _LiveText(this.ctx, this.messageId) : _lastFlush = ctx.now();

  final LoopContext ctx;
  final int messageId;
  final StringBuffer _buffer = StringBuffer();
  DateTime _lastFlush;
  Future<void> _chain = Future.value();

  void add(String delta) {
    _buffer.write(delta);
    ctx.emitLive(messageId, _buffer.toString());
    if (ctx.now().difference(_lastFlush) >= ctx.liveFlushInterval) flush();
  }

  /// Queues a write of the text as it is when the write runs, so an older
  /// write never overtakes a newer one.
  Future<void> flush() {
    _lastFlush = ctx.now();
    if (_buffer.isEmpty) return _chain;
    return _chain = _chain.then((_) async {
      try {
        await ctx.store.updateLiveText(messageId, _buffer.toString());
      } on Object catch (e, s) {
        ctx.report(e, s);
      }
    });
  }

  Future<void> drain() => flush();
}
