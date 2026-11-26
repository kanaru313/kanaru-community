import '../../../plugins/domain/run/run_outcome.dart';
import 'ai_error_code.dart';
import 'chat_outcome.dart';
import 'chat_output_parser.dart';

/// Rate-limit wait when neither the script nor the provider named one.
const chatDefaultRateWait = Duration(seconds: 60);

/// The message the runtime gives a request body over its 1 MiB limit.
const _bodyRefusedMarker = 'larger than 1 MiB';

/// How many `RunBusy` in a row (with no stream active) mean the previous
/// turn is stuck.
const chatBusyStuckAfter = 3;

/// Everything besides the outcome the mapping needs.
class ChatOutcomeContext {
  const ChatOutcomeContext({
    required this.now,
    this.output,
    this.pausedUntil,
    this.pluginRowExists = true,
    this.busyInARow = 1,
    this.streamActive = false,
    this.host,
  });

  final DateTime now;

  /// How to read a `RunOk`: the turn, round and tools of the call. Null maps
  /// every `RunOk` as a rejected output.
  final ChatOutputContext? output;

  /// End of the plugin's pause (`PluginPauses.until`), if any.
  final DateTime? pausedUntil;

  /// For `RunCancelled(pluginChanged)`: the plugin row is still installed.
  final bool pluginRowExists;

  /// Consecutive `RunBusy` answers, this one included.
  final int busyInARow;

  /// A stream of this app is running (a busy answer is then expected).
  final bool streamActive;

  /// The plugin's host a network or permission card names.
  final String? host;
}

/// What the parser needs about the round that ran.
class ChatOutputContext {
  const ChatOutputContext({
    required this.turn,
    required this.round,
    required this.offeredNames,
    required this.finalRound,
    this.callsSoFarInTurn = 0,
    this.itemLimit,
  });

  final int turn;
  final int round;
  final Set<String> offeredNames;
  final bool finalRound;
  final int callsSoFarInTurn;
  final ChatItemLimitCheck? itemLimit;
}

/// Maps how a plugin run ended to the message state and the card. Pure: no
/// UI strings, no I/O. The switch has no default, so a new [RunOutcome]
/// variant breaks the build.
ChatOutcomeView mapChatOutcome(RunOutcome outcome, ChatOutcomeContext ctx) =>
    switch (outcome) {
      final RunOk ok => _fromOk(ok, ctx),
      final RunScriptError e => _fromScriptError(e, ctx),
      final RunFailed f => _fromFailed(f, ctx),
      final RunPaused p => ChatOutcomeView(
        end: ChatMessageEnd.error,
        card: ChatCardKind.rateLimited,
        action: ChatCardAction.retry,
        errorCode: AiErrorCode.rateLimit,
        retryAt: p.until,
      ),
      RunBusy() => _fromBusy(ctx),
      final RunNeedsConfig n => ChatOutcomeView(
        end: ChatMessageEnd.blocked,
        card: ChatCardKind.needsConfig,
        action: ChatCardAction.openPluginSettings,
        titles: n.fieldTitles,
        keepStreamedText: false,
      ),
      final RunUnavailable u => switch (u.reason) {
        RunUnavailableReason.notInstalled => _pluginRemoved(
          ChatMessageEnd.blocked,
        ),
        RunUnavailableReason.packageUnreadable ||
        RunUnavailableReason.noScript => const ChatOutcomeView(
          end: ChatMessageEnd.error,
          card: ChatCardKind.pluginBroken,
          action: ChatCardAction.openPlugin,
          errorCode: AiErrorCode.server,
        ),
      },
      final RunCancelled c => switch (c.reason) {
        RunCancelReason.caller => const ChatOutcomeView(
          end: ChatMessageEnd.stopped,
          card: ChatCardKind.stopped,
        ),
        RunCancelReason.pluginChanged =>
          ctx.pluginRowExists
              ? const ChatOutcomeView(
                  end: ChatMessageEnd.stopped,
                  card: ChatCardKind.pluginUpdated,
                  action: ChatCardAction.retry,
                )
              : _pluginRemoved(ChatMessageEnd.stopped),
      },
    };

ChatOutcomeView _pluginRemoved(ChatMessageEnd end) => ChatOutcomeView(
  end: end,
  card: ChatCardKind.pluginRemoved,
  action: ChatCardAction.choosePlugin,
  keepStreamedText: end != ChatMessageEnd.blocked,
);

ChatOutcomeView _fromBusy(ChatOutcomeContext ctx) {
  final stuck = ctx.busyInARow >= chatBusyStuckAfter && !ctx.streamActive;
  return ChatOutcomeView(
    end: ChatMessageEnd.error,
    card: stuck
        ? ChatCardKind.previousTurnStuck
        : ChatCardKind.previousTurnBusy,
    action: ChatCardAction.retry,
    errorCode: AiErrorCode.server,
    keepStreamedText: false,
  );
}

ChatOutcomeView _fromOk(RunOk ok, ChatOutcomeContext ctx) {
  final out = ctx.output;
  final result = out == null
      ? const ChatOutputRejected('no parse context')
      : parseChatOutput(
          ok.outputJson,
          turn: out.turn,
          round: out.round,
          offeredNames: out.offeredNames,
          finalRound: out.finalRound,
          callsSoFarInTurn: out.callsSoFarInTurn,
          itemLimit: out.itemLimit,
        );
  switch (result) {
    case ChatOutputOk(:final output):
      // A caught fetch failure or a 429 never discards a good answer.
      return ChatOutcomeView.complete(output);
    case ChatOutputLimit(:final limit):
      return ChatOutcomeView(
        end: ChatMessageEnd.error,
        card: ChatCardKind.limitReached,
        limit: limit,
      );
    case ChatOutputRejected():
      final seen = ok.rateLimitSeen;
      if (seen != null) return _rateLimited(ctx, seen);
      final fetch = ok.fetchFailure;
      if (fetch != null) return _fromFetch(fetch, ctx);
      return _badRequest();
  }
}

ChatOutcomeView _badRequest() => const ChatOutcomeView(
  end: ChatMessageEnd.error,
  card: ChatCardKind.badRequest,
  action: ChatCardAction.retry,
  errorCode: AiErrorCode.badRequest,
);

ChatOutcomeView _rateLimited(ChatOutcomeContext ctx, Duration? wait) {
  final byWait = ctx.now.add(wait ?? chatDefaultRateWait);
  final paused = ctx.pausedUntil;
  return ChatOutcomeView(
    end: ChatMessageEnd.error,
    card: ChatCardKind.rateLimited,
    action: ChatCardAction.retry,
    errorCode: AiErrorCode.rateLimit,
    retryAt: paused != null && paused.isAfter(byWait) ? paused : byWait,
  );
}

ChatOutcomeView _fromFetch(FetchFailureInfo fetch, ChatOutcomeContext ctx) =>
    switch (fetch.kind) {
      FetchFailureKind.network || FetchFailureKind.abandoned => ChatOutcomeView(
        end: ChatMessageEnd.error,
        card: ChatCardKind.network,
        action: ChatCardAction.retry,
        errorCode: AiErrorCode.server,
        host: ctx.host,
      ),
      FetchFailureKind.blockedHost ||
      FetchFailureKind.notConsented => ChatOutcomeView(
        end: ChatMessageEnd.error,
        card: ChatCardKind.hostNotAllowed,
        errorCode: AiErrorCode.server,
        host: ctx.host,
      ),
      FetchFailureKind.rateLimited => _rateLimited(ctx, fetch.retryAfter),
      FetchFailureKind.invalidRequest =>
        fetch.message.contains(_bodyRefusedMarker)
            ? const ChatOutcomeView(
                end: ChatMessageEnd.error,
                card: ChatCardKind.tooLarge,
                errorCode: AiErrorCode.tooLarge,
              )
            : _badRequest(),
      FetchFailureKind.invalidResponse => _badRequest(),
    };

ChatOutcomeView _fromScriptError(RunScriptError e, ChatOutcomeContext ctx) {
  final code = AiErrorCode.parse(e.message);
  // A plain server failure with a failing fetch behind it is that fetch
  // failure; every other code says more than the fetch does.
  final fetch = e.fetchFailure;
  if (code == AiErrorCode.server && fetch != null) {
    return _fromFetch(fetch, ctx);
  }
  const retry = ChatCardAction.retry;
  ChatOutcomeView card(ChatCardKind kind, [ChatCardAction action = retry]) =>
      ChatOutcomeView(
        end: ChatMessageEnd.error,
        card: kind,
        action: action,
        errorCode: code,
      );
  return switch (code) {
    AiErrorCode.key => card(
      ChatCardKind.badKey,
      ChatCardAction.openPluginSettings,
    ),
    AiErrorCode.quota => card(ChatCardKind.quota),
    AiErrorCode.rateLimit => _rateLimited(ctx, e.retryAfter),
    AiErrorCode.config => card(
      ChatCardKind.config,
      ChatCardAction.openPluginSettings,
    ),
    AiErrorCode.badRequest => card(ChatCardKind.badRequest),
    AiErrorCode.modelNotFound => card(
      ChatCardKind.modelNotFound,
      ChatCardAction.changeModel,
    ),
    AiErrorCode.contextLength => card(
      ChatCardKind.contextLength,
      ChatCardAction.newConversation,
    ),
    AiErrorCode.tooLarge => card(
      ChatCardKind.tooLarge,
      ChatCardAction.newConversation,
    ),
    AiErrorCode.blocked => card(ChatCardKind.blocked, ChatCardAction.none),
    AiErrorCode.empty => card(ChatCardKind.empty),
    AiErrorCode.server => card(ChatCardKind.server),
  };
}

ChatOutcomeView _fromFailed(RunFailed f, ChatOutcomeContext ctx) {
  final fetch = f.fetchFailure;
  final timeout = f.reason == RunFailReason.timeout;
  if (fetch != null) {
    final v = _fromFetch(fetch, ctx);
    return timeout
        ? ChatOutcomeView(
            end: ChatMessageEnd.stopped,
            card: v.card,
            action: v.action,
            errorCode: v.errorCode,
            host: v.host,
            retryAt: v.retryAt,
          )
        : v;
  }
  return timeout
      ? const ChatOutcomeView(
          end: ChatMessageEnd.stopped,
          card: ChatCardKind.timeout,
          action: ChatCardAction.retry,
          errorCode: AiErrorCode.server,
        )
      : const ChatOutcomeView(
          end: ChatMessageEnd.error,
          card: ChatCardKind.pluginError,
          action: ChatCardAction.retry,
          errorCode: AiErrorCode.server,
        );
}
