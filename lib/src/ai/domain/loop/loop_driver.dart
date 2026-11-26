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
import 'turn_inspector.dart';

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
    _inspector = TurnInspector(
      ctx: _ctx,
      loop: loop,
      cards: _cards,
      busy: () => _gate.busy,
      setState: _setState,
      report: _report,
    );
  }

  final int conversationId;
  final ChatLoop loop;
  final LoopStore _store;
  final LoopEnvironment _env;
  final ModelRoundRunner _runner;

  final void Function(Object error, StackTrace stack)? onInternalError;
  late final LoopContext _ctx;
  late final ModelRound _round;
  late final ToolBatch _tools;
  late final CardAnswers _cards;
  late final TurnInspector _inspector;

  final _states = StreamController<TurnState>.broadcast();
  final _live = StreamController<({int messageId, String text})>.broadcast();
  TurnState _state = TurnState.idle;
  ChatOutcomeView? _lastView;

  final _gate = FlightGate();
  bool _disposed = false;

  bool _userStop = false;

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
      _gate.takeUserStop();
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
      // The answer may have been the last one the turn waited for.
      _kick(callId);
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
    _kick(callId);
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
    _kick(callId);
    return CardAnswer.accepted;
  }

  /// Stops the turn: the text streamed so far stays, the call being run
  /// finishes, later calls are `skipped`, no next round starts. Completes
  /// when the turn future has ended.
  Future<void> stop() async {
    if (_disposed) return;
    if (_gate.busy) {
      _gate.userStopPending = true; // the releaser acts on it
      await _stopActive(byUser: true);
      await _gate.current?.future; // the parked-stop flight, if started
      return;
    }
    final parked = _reserve();
    if (parked == null) {
      await _gate.current?.future;
      return;
    }
    await _fly(parked, body: _stopBody);
  }

  Future<void> _stopBody() async {
    await _cards.skipOpen(stoppedByUserText, ConfirmStatus.denied);
    await _finish(TurnState.idle, endTurn: true);
  }

  /// Acts on a user Stop recorded while the gate was taken (call right after
  /// releasing it): drops waiting answers and ends the turn.
  Future<void> _endPendingUserStop() async {
    _gate.consumeUserStop();
    if (_disposed) return;
    final parked = _reserve();
    if (parked == null) return;
    await _fly(parked, body: _stopBody);
  }

  /// Runs [body] while no turn step runs and none can start. A round or tool
  /// run in flight is stopped and awaited first; a turn that only waits on
  /// cards is left as it is. Null when the driver is closed.
  Future<T?> runExclusive<T>(Future<T> Function() body) async {
    if (_disposed) return null;
    var flight = _reserve();
    _gate.exclusiveWaiting++;
    try {
      while (flight == null) {
        await _stopActive();
        if (_disposed) return null;
        flight = _reserve();
      }
    } finally {
      _gate.exclusiveWaiting--;
    }
    try {
      return await body();
    } finally {
      _release(flight);
      if (_gate.userStopPending) {
        await _endPendingUserStop();
      } else {
        // An answer that landed during the body found the gate taken: run it.
        final woke = _gate.takeWake() | _gate.takeDeferred();
        if (woke) {
          if (_gate.startNow()) _kick();
        } else {
          await inspect();
        }
      }
    }
  }

  /// Stops the flight in flight, if any, and waits for it.
  Future<void> _stopActive({bool byUser = false}) async {
    final flight = _gate.current;
    if (flight == null) return;
    if (byUser) _userStop = true;
    _ctx.stopRequested = true;
    _runner.cancel();
    await flight.future;
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
  Future<LoopAction?> inspect() => _inspector.inspect();

  /// Writes the streamed text so far (the app goes to the background).
  Future<void> flushLive() => _round.flushLive();

  /// Closes the driver: a round or tool run in flight is stopped and awaited;
  /// cards waiting for an answer stay pending. Nothing starts afterwards.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _stopActive();
    await _states.close();
    await _live.close();
  }

  // ── Flight ─────────────────────────────────────────────────────────────

  /// Claims the single flight, or null when one is running.
  Completer<void>? _reserve() => _gate.reserve(
    onClaim: () {
      _ctx.stopRequested = false;
      _userStop = false;
      _lastView = null;
    },
  );

  void _release(Completer<void> flight) => _gate.release(flight);

  /// A user answer arrived: start a flight, or tell the one running to look
  /// again before it parks.
  void _kick([String? callId]) {
    if (_disposed) return;
    final flight = _reserve();
    if (flight == null) {
      _gate.wakeRunning(callId ?? '');
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
      _lastView = internalErrorView;
      _setState(TurnState.error);
    } finally {
      _round.resetLost();
      _release(flight);
      if (_gate.userStopPending) {
        await _endPendingUserStop();
      } else if (_gate.stopParked && _gate.takeWake() && _gate.startNow()) {
        // A wake after a parking stop branch's last look runs now; any
        // other wake is left alone.
        _kick();
      }
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
        // Answers recorded before the read are covered by it; an Allow that
        // shows as an allowed card there is skipped, so its wake goes too.
        _gate.takeWake();
        final userAtStart = _userStop;
        await _cards.skipOpen(
          stoppedByUserText,
          ConfirmStatus.denied,
          onlyAllowed: !userAtStart,
          onRead: (open) => _gate.dropWakesFor({
            for (final c in open)
              if (c.state == AiMessageState.allowed) ?callOf(c)?.id,
          }),
        );
        if (_userStop && !userAtStart) {
          // Stop came in during the read: deny what is left.
          await _cards.skipOpen(stoppedByUserText, ConfirmStatus.denied);
        }
        if (_userStop) _gate.takeUserStop();
        final waiting =
            !_userStop &&
            (_gate.hasWake ||
                (await _store.openCards(conversationId)).isNotEmpty);
        if (waiting) {
          _gate.stopParked = true;
          await _finish(TurnState.awaitingConfirm);
        } else {
          await _finish(
            TurnState.idle,
            endTurn: true,
            turnId: transcript.turnId,
          );
        }
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
          // An answer that came in meanwhile is picked up here (the flight
          // is released in the same step); a stop is handled at the top.
          if (_ctx.stopRequested || _gate.takeWake()) continue;
          _setState(TurnState.awaitingConfirm);
          _release(_gate.current!);
          return;
        case HealRunning(:final cards):
          // Never loop on a row that cannot be moved.
          if (!await _tools.healRunning(cards)) {
            _setState(TurnState.error);
            return;
          }
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
