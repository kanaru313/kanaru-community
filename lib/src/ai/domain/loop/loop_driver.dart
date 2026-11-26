export 'driver_results.dart';

import 'dart:async';

import '../../../plugins/domain/package/chat_spec.dart';
import '../conversation/ai_message.dart';
import '../conversation/parts.dart';
import '../input/system_prompt.dart';
import '../output/chat_outcome.dart';
import '../permission.dart';
import '../tools/ai_tool.dart';
import 'card_answers.dart';
import 'card_results.dart';
import 'chat_loop.dart';
import 'driver_results.dart';
import 'flight_gate.dart';
import 'loop_context.dart';
import 'loop_ports.dart';
import 'loop_state.dart';
import 'may_execute.dart';
import 'model_round.dart';
import 'tool_batch.dart';

/// Runs the turns of one conversation. One in-flight future at most: a
/// second trigger while it runs is dropped, so two model rounds never run
/// at once. Pure Dart; the store, the plugin runner and the settings come in
/// as ports.
///
/// The flight ends when the turn is done, failed, stopped, or waits for the
/// user's answer on a card. Allow, Deny and Retry start the next flight.
/// Nothing starts a model round on its own after launch.
class LoopDriver {
  LoopDriver({
    required this.conversationId,
    required LoopStore store,
    required ModelRoundRunner runner,
    required LoopEnvironment env,
    DateTime Function()? now,
    Duration toolTimeout = const Duration(seconds: 30),
    Duration liveFlushInterval = const Duration(seconds: 1),
    String Function()? newBoundary,
    this.onInternalError,
    this.loop = const ChatLoop(),
  }) : _store = store,
       _env = env,
       _runner = runner {
    _ctx = LoopContext(
      conversationId: conversationId,
      store: store,
      runner: runner,
      env: env,
      now: now ?? DateTime.now,
      toolTimeout: toolTimeout,
      newBoundary: newBoundary ?? newChatBoundary,
      report: _report,
      emitLive: (id, text) {
        if (!_live.isClosed) _live.add((messageId: id, text: text));
      },
      liveFlushInterval: liveFlushInterval,
    );
    _round = ModelRound(_ctx);
    _tools = ToolBatch(_ctx);
    _cards = CardAnswers(_ctx);
  }

  final int conversationId;
  final ChatLoop loop;
  final LoopStore _store;
  final LoopEnvironment _env;
  final ModelRoundRunner _runner;

  /// Called with every failure the driver caught instead of throwing.
  final void Function(Object error, StackTrace stack)? onInternalError;
  late final LoopContext _ctx;
  late final ModelRound _round;
  late final ToolBatch _tools;
  late final CardAnswers _cards;

  final _states = StreamController<TurnState>.broadcast();
  final _live = StreamController<({int messageId, String text})>.broadcast();
  TurnState _state = TurnState.idle;
  ChatOutcomeView? _lastView;

  final _gate = FlightGate();
  bool _disposed = false;

  TurnState get turnState => _state;

  /// Changes of [turnState].
  Stream<TurnState> get states => _states.stream;

  /// Streamed text of the round in flight, so the list need not rebuild per
  /// delta.
  Stream<({int messageId, String text})> get liveText => _live.stream;

  /// The card the last round ended with (an error or a block), if any.
  ChatOutcomeView? get lastView => _lastView;

  /// The one in-flight future; null when no turn runs.
  Future<void>? get inFlight => _gate.current?.future;

  // ── Triggers ───────────────────────────────────────────────────────────

  /// Sends a user message and runs the turn. Refused ([DriverBusy]) while a
  /// turn is in flight. Cards still pending are denied: they are valid until
  /// the next user message.
  Future<DriverStart> send(List<AiPart> parts) async {
    if (_disposed) return const DriverClosed();
    final flight = _reserve();
    if (flight == null) return const DriverBusy();
    final int id;
    try {
      await _cards.skipOpen(newMessageText, ConfirmStatus.deniedByNewMessage);
      id = await _store.appendUser(conversationId, parts);
    } on Object catch (e, s) {
      _report(e, s);
      _release(flight);
      return const DriverFailed();
    }
    unawaited(_fly(flight));
    return DriverStarted(flight.future, userMessageId: id);
  }

  /// Goes on with the latest turn: runs the round that failed or was
  /// stopped, runs calls the user allowed, or starts the next round.
  Future<DriverStart> retry() async {
    if (_disposed) return const DriverClosed();
    final flight = _reserve();
    if (flight == null) return const DriverBusy();
    try {
      await _healStrayStreaming();
    } on Object catch (e, s) {
      _report(e, s);
    }
    unawaited(_fly(flight));
    return DriverStarted(flight.future);
  }

  /// The user allows the pending call [callId]. The Allow is bound to the
  /// call as stored now: its name and arguments, in this conversation; the
  /// tool does not run if they differ at execution.
  Future<CardAnswer> allow(String callId) async {
    final found = await _cards.pendingCard(callId);
    if (found == null) return CardAnswer.notPending;
    final (snap, card, call) = found;
    if (cardExpired(card.createdAt, _ctx.now())) {
      await _cards.answer(card, call, expiredText, ConfirmStatus.expired);
      return CardAnswer.expired;
    }
    final tool = _env.registry.byName(call.name);
    if (tool != null &&
        tool.risk == ToolRisk.write &&
        snap.conversation.permission == AiPermission.readOnly) {
      await _cards.answer(
        card,
        call,
        notAllowedNowText(ExecRefusal.readOnly),
        ConfirmStatus.denied,
        reason: ExecRefusal.readOnly.code,
      );
      return CardAnswer.refused;
    }
    final won = await _store.approve(card.id, approvalHash: callHash(call));
    if (!won) return CardAnswer.notPending;
    _kick();
    return CardAnswer.accepted;
  }

  /// The user declines the pending call [callId]; the model is told.
  Future<CardAnswer> deny(String callId) async {
    final found = await _cards.pendingCard(callId);
    if (found == null) return CardAnswer.notPending;
    final (_, card, call) = found;
    final won = await _cards.answer(
      card,
      call,
      deniedByUserText,
      ConfirmStatus.denied,
      reason: 'user',
    );
    if (!won) return CardAnswer.notPending;
    _kick();
    return CardAnswer.accepted;
  }

  /// Stops the turn: the text streamed so far stays, the call being run
  /// finishes, later calls are `skipped`, no next round starts. Completes
  /// when the turn future has ended.
  Future<void> stop() async {
    final flight = _gate.current;
    if (flight != null) {
      _ctx.stopRequested = true;
      _runner.cancel();
      await flight.future;
      return;
    }
    final parked = _reserve();
    if (parked == null) {
      await _gate.current?.future;
      return;
    }
    await _fly(
      parked,
      body: () async {
        await _cards.skipOpen(stoppedByUserText, ConfirmStatus.denied);
        await _finish(TurnState.idle, endTurn: true);
      },
    );
  }

  /// The chat's permission was changed to read-only: write calls still
  /// pending or allowed and not run are denied at once.
  Future<void> applyPermission() async {
    await _cards.denyOpenWrites();
    await inspect();
  }

  /// Reads the stored turn and sets [turnState] without running anything
  /// (call it when a conversation opens). Cards past 24 hours are marked
  /// expired. Returns what a tap could do next; null while a turn runs.
  Future<LoopAction?> inspect() async {
    if (_gate.busy) return null;
    try {
      var action = await _peek();
      if (action is ExpireCards) {
        final snap = await _ctx.snapshot();
        if (snap != null && !_gate.busy) {
          await _cards.expire(snap, action.cardIds);
          action = await _peek();
        }
      }
      return action;
    } on Object catch (e, s) {
      _report(e, s);
      return const Done();
    }
  }

  /// Writes the streamed text so far (the app goes to the background).
  Future<void> flushLive() => _round.flushLive();

  /// Stops the turn and closes the streams. Awaits the turn future.
  Future<void> dispose() async {
    if (_disposed) return;
    await stop();
    _disposed = true;
    await _states.close();
    await _live.close();
  }

  // ── Flight ─────────────────────────────────────────────────────────────

  /// Claims the single flight, or null when one is running.
  Completer<void>? _reserve() =>
      _gate.reserve(onClaim: () => _ctx.stopRequested = false);

  void _release(Completer<void> flight) => _gate.release(flight);

  /// A user answer arrived: start a flight, or tell the one running to look
  /// again before it parks.
  void _kick() {
    if (_disposed) return;
    final flight = _reserve();
    if (flight == null) {
      _gate.wakeRunning();
      return;
    }
    unawaited(_fly(flight));
  }

  Future<void> _fly(
    Completer<void> flight, {
    Future<void> Function()? body,
  }) async {
    try {
      await (body ?? _pump)();
    } on Object catch (e, s) {
      _report(e, s);
      _setState(TurnState.error);
    } finally {
      _release(flight);
    }
  }

  Future<void> _pump() async {
    while (true) {
      final snap = await _ctx.snapshot();
      final transcript = snap?.transcript;
      if (snap == null || transcript == null) {
        _setState(TurnState.idle);
        return;
      }
      if (_ctx.stopRequested) {
        await _cards.skipOpen(stoppedByUserText, ConfirmStatus.denied);
        await _finish(TurnState.idle, endTurn: true, turnId: transcript.turnId);
        return;
      }
      final plugin = await _env.plugin(snap.conversation);
      final settings = await _env.settings();
      final action = loop.next(
        transcript,
        settings,
        plugin?.capabilities ?? const ChatCapabilities(),
        armed: true,
        now: _ctx.now(),
      );
      switch (action) {
        case Done():
          await _finish(
            TurnState.idle,
            endTurn: true,
            turnId: transcript.turnId,
          );
          return;
        case NeedsUserTap():
          await _finish(TurnState.idle);
          return;
        case ExpireCards(:final cardIds):
          await _cards.expire(snap, cardIds);
        case AwaitConfirms():
          // An answer that came in while this step ran is picked up here;
          // the flight is released in the same step as the check.
          if (_gate.takeWake()) continue;
          _setState(TurnState.awaitingConfirm);
          _release(_gate.current!);
          return;
        case RunTools(:final cards):
          _setState(TurnState.runningTools);
          final limit = await _tools.run(cards);
          if (limit) {
            _lastView = const ChatOutcomeView(
              end: ChatMessageEnd.error,
              card: ChatCardKind.limitReached,
            );
            await _finish(
              TurnState.error,
              endTurn: true,
              turnId: transcript.turnId,
            );
            return;
          }
        case RunModel():
          _setState(TurnState.streaming);
          final result = await _round.run(snap, action);
          if (!result.goOn) {
            _lastView = result.view;
            await _finish(
              result.state,
              endTurn: true,
              turnId: transcript.turnId,
            );
            return;
          }
      }
    }
  }

  Future<void> _finish(
    TurnState state, {
    bool endTurn = false,
    int? turnId,
  }) async {
    if (endTurn) {
      final id = turnId ?? (await _ctx.snapshot())?.transcript?.turnId;
      if (id != null) {
        try {
          await _store.endTurn(id);
        } on Object catch (e, s) {
          _report(e, s);
        }
      }
    }
    _setState(state);
  }

  // ── Cards ──────────────────────────────────────────────────────────────

  /// A message left `streaming` that no round of this app owns is closed.
  Future<void> _healStrayStreaming() async {
    final snap = await _ctx.snapshot();
    final last = snap?.transcript?.assistants.lastOrNull;
    if (last != null && last.state == AiMessageState.streaming) {
      await _store.endRound(last.id, to: AiMessageState.stopped);
    }
  }

  Future<LoopAction> _peek() async {
    final snap = await _ctx.snapshot();
    final transcript = snap?.transcript;
    if (snap == null || transcript == null) {
      _setState(TurnState.idle);
      return const Done();
    }
    final plugin = await _env.plugin(snap.conversation);
    final settings = await _env.settings();
    final action = loop.next(
      transcript,
      settings,
      plugin?.capabilities ?? const ChatCapabilities(),
      armed: false,
      now: _ctx.now(),
    );
    final last = transcript.assistants.lastOrNull;
    _setState(switch (action) {
      AwaitConfirms() => TurnState.awaitingConfirm,
      _ when last != null && last.state == AiMessageState.error =>
        TurnState.error,
      _ => TurnState.idle,
    });
    return action;
  }

  void _setState(TurnState state) {
    if (_state == state) return;
    _state = state;
    if (!_states.isClosed) _states.add(state);
  }

  void _report(Object error, StackTrace stack) {
    final sink = onInternalError;
    if (sink != null) sink(error, stack);
  }
}
