import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../plugins/domain/package/chat_spec.dart';
import '../../plugins/domain/package/plugin_kind.dart';
import '../../plugins/state/plugin_logs_provider.dart';
import '../../plugins/state/plugin_run_provider.dart';
import '../../plugins/state/plugin_store_providers.dart';
import '../../database/database.dart';
import '../../plugins/data/store/plugin_row_types.dart';
import '../data/chat_turn_runner.dart';
import '../data/conversation_store.dart';
import '../data/loop_store_adapter.dart';
import '../domain/loop/loop_driver.dart';
import '../domain/loop/loop_state.dart';
import '../domain/output/chat_readiness.dart';
import '../domain/permission.dart';
import '../domain/variables/title_rule.dart';
import 'ai_conversation_store_provider.dart';
import 'ai_settings_providers.dart';
import 'chat_attachments.dart';
import 'chat_providers.dart';
import 'chat_send.dart';
import 'chat_session_env.dart';
import 'chat_session_plugin.dart';
import 'chat_session_replay.dart';
import 'chat_session_state.dart';

export 'chat_send.dart';
export 'chat_session_state.dart';
export 'chat_session_replay.dart' show ReplayResult;

final _log = Logger('ai.chat');

/// The one entry of the chat UI: opens conversations and runs their turns.
///
/// Kept alive, so a turn goes on while the user leaves the chat screen. One
/// `LoopDriver` runs the open conversation; opening, deleting or switching
/// plugin first stops the turn and waits for it to end. Every dependency is
/// read when it is needed, never kept.
class ChatSessionController extends Notifier<ChatSessionState> {
  LoopDriver? _driver;
  StreamSubscription<TurnState>? _stateSub;
  StreamSubscription<({int messageId, String text})>? _liveSub;
  final _live = StreamController<({int messageId, String text})>.broadcast();
  ({int messageId, String text})? _lastLive;
  Future<void> _queue = Future.value();
  Map<String, int>? _knownInstalls;
  bool _swept = false;

  @override
  ChatSessionState build() {
    ref.onDispose(() {
      unawaited(_closeDriver(notify: false));
      unawaited(_live.close());
    });
    // A plugin that was removed or installed again leaves provider blobs
    // that no later request may send: flatten those turns.
    ref.listen(installedPluginsProvider, (_, next) {
      final rows = next.value;
      if (rows != null) unawaited(_clearBlobsOfChangedInstalls(rows));
    }, fireImmediately: true);
    return const ChatSessionState();
  }

  // ── Streams for the UI ─────────────────────────────────────────────────

  /// Streamed text of the round in flight.
  Stream<({int messageId, String text})> get liveText => _live.stream;

  /// The text streamed so far into [messageId], if it is the live message.
  String? liveTextOf(int messageId) =>
      _lastLive?.messageId == messageId ? _lastLive!.text : null;

  // ── Conversations ──────────────────────────────────────────────────────

  /// Opens a new empty conversation (the open one when it is still empty)
  /// on the default plugin and returns its id.
  Future<int> newConversation() => _exclusive(() async {
    final current = state.conversationId;
    if (current != null &&
        await _store.conversation(current) != null &&
        await _store.latestSeq(current) == 0) {
      return current;
    }
    await _closeDriver();
    return _openNew();
  });

  /// Opens [id]. A round or tool run of the open conversation is stopped
  /// first (received text stays, calls that did not run are skipped); a turn
  /// that only waits on cards keeps them pending. False when it does not
  /// exist.
  Future<bool> open(int id) => _exclusive(() async {
    if (_driver != null && state.conversationId == id) return true;
    if (await _store.conversation(id) == null) return false;
    await _closeDriver();
    await _start(id);
    return true;
  });

  Future<void> rename(int id, String title) async {
    final clean = title.trim();
    if (clean.isEmpty) return;
    await _store.rename(id, clean);
  }

  /// Stops its turn, waits for it (the run and the tool being run), deletes
  /// [id]; when it was the open one a new empty conversation opens.
  Future<void> delete(int id) => _exclusive(() async {
    final wasOpen = state.conversationId == id;
    if (wasOpen) await _closeDriver();
    await _store.delete(id);
    if (wasOpen) await _openNew();
  });

  /// [delete] for every conversation, then clears the run log of every
  /// installed chat plugin.
  Future<void> deleteAll() => _exclusive(() async {
    await _closeDriver();
    await _store.deleteAll();
    for (final row in await installedChatRows(ref)) {
      try {
        await ref.read(pluginLogOpsProvider).clear(row.installId);
      } on Object catch (e, s) {
        _log.warning('could not clear the plugin log: ${e.runtimeType}', e, s);
      }
    }
    await _openNew();
  });

  // ── The turn ───────────────────────────────────────────────────────────

  /// Sends [text] (variables filled, attached chips resolved) and runs the
  /// turn. Attachments are cleared only when the send is accepted.
  Future<SendResult> send(String text, {bool shortVersion = false}) async {
    final attached = ref.read(chatAttachmentsProvider).attached;
    if (text.trim().isEmpty && attached.isEmpty) return const SendFailed();
    try {
      if (_driver == null) await newConversation();
      final driver = _driver;
      final id = state.conversationId;
      final conversation = id == null ? null : await _store.conversation(id);
      if (driver == null || id == null || conversation == null) {
        return const SendFailed();
      }
      final readiness = await readChatReadiness(ref, conversation);
      if (readiness is! ChatReady) return SendBlocked(readiness);

      final settings = await _env.settings();
      final prepared = await prepareMessage(
        text: text,
        chips: attached,
        env: _env.toolEnv,
        scopes: ref.read(chipScopeProvider),
        groupEnabled: settings.groupEnabled,
        varBypass: ref.read(aiVarBypassProvider),
        shortVersion: shortVersion,
      );
      if (prepared.failure != null) return prepared.failure!;

      final first = await _store.latestSeq(id) == 0;
      final start = await driver.send(prepared.parts);
      switch (start) {
        case DriverStarted(:final done, :final userMessageId):
          // Only the chips that went with this message: one attached while
          // it was being prepared stays for the next.
          ref.read(chatAttachmentsProvider.notifier).clearAttached(attached);
          if (first && conversation.titleAuto) {
            await _store.setAutoTitle(
              id,
              conversationTitle(prepared.displayText),
            );
          }
          return SendSent(done, userMessageId: userMessageId);
        case DriverBusy():
          return const SendBusy();
        case DriverFailed() || DriverClosed():
          return const SendFailed();
      }
    } on Object catch (e, s) {
      _log.warning('send failed: ${e.runtimeType}', e, s);
      return const SendFailed();
    }
  }

  /// Stops the turn: received text stays, calls that did not run are skipped.
  Future<void> stop() async => _driver?.stop();

  /// Goes on with the latest turn (a failed or stopped round, allowed calls).
  Future<DriverStart> retry() async =>
      await _driver?.retry() ?? const DriverClosed();

  Future<CardAnswer> allow(String callId) async =>
      await _driver?.allow(callId) ?? CardAnswer.notPending;

  Future<CardAnswer> deny(String callId) async =>
      await _driver?.deny(callId) ?? CardAnswer.notPending;

  /// Plays again the queue that the call of tool row [messageId] replaced.
  /// Only the latest turn's calls can be undone this way.
  Future<ReplayResult> replayQueue(int messageId) async {
    final id = state.conversationId;
    if (id == null) return ReplayResult.unavailable;
    try {
      return await replayReplacedQueue(
        ref,
        store: _store,
        conversationId: id,
        messageId: messageId,
      );
    } on Object catch (e, s) {
      _log.warning('replay failed: ${e.runtimeType}', e, s);
      return ReplayResult.failed;
    }
  }

  // ── The chat's settings ────────────────────────────────────────────────

  /// Moves the open chat to another installed chat plugin and writes a
  /// plugin-switch line into the transcript. A round or tool run in flight is
  /// stopped first and no turn starts while the chat is rebound. False when
  /// the plugin is not installed.
  Future<bool> switchPlugin(String installId) => _exclusive(() async {
    final id = state.conversationId;
    if (id == null) return false;
    final target = (await installedChatRows(ref))
        .where((r) => r.installId == installId)
        .firstOrNull;
    if (target == null) return false;
    return await _whileIdle(() async {
          final conversation = await _store.conversation(id);
          if (conversation == null) return false;
          await rebindChatPlugin(ref, _store, conversation, target);
          return true;
        }) ??
        false;
  });

  /// Changes the open chat's model (stopping a round in flight first).
  Future<void> switchModel(String model) => _exclusive(() async {
    final id = state.conversationId;
    final clean = model.trim();
    if (id == null || clean.isEmpty) return;
    await _whileIdle(() async {
      final conversation = await _store.conversation(id);
      if (conversation == null) return;
      await _store.bind(
        id,
        installId: conversation.installId,
        installGeneration: conversation.installGeneration,
        model: clean,
      );
    });
  });

  /// Sets the open chat's permission. Read-only denies every pending call
  /// and every allowed call that did not run yet, at once.
  Future<void> setPermission(AiPermission permission) async {
    final id = state.conversationId;
    if (id == null) return;
    await _store.setPermission(id, permission);
    if (permission == AiPermission.readOnly) await _driver?.applyPermission();
  }

  /// Writes the streamed text of the running round to the store (the app
  /// goes to the background or exits).
  Future<void> flush() async => _driver?.flushLive();

  // ── Internals ──────────────────────────────────────────────────────────

  ConversationStore get _store => ref.read(aiConversationStoreProvider);

  late final SessionEnvironment _env = SessionEnvironment(ref);

  /// Runs [op] while the driver runs no turn step and starts none; without a
  /// driver, just runs it.
  Future<T?> _whileIdle<T>(Future<T> Function() op) {
    final driver = _driver;
    return driver == null ? op() : driver.runExclusive(op);
  }

  /// Runs [op] after the earlier switching operations; one at a time.
  Future<T> _exclusive<T>(Future<T> Function() op) {
    final previous = _queue;
    final done = Completer<void>();
    _queue = done.future;
    return previous.then((_) => op()).whenComplete(done.complete);
  }

  Future<int> _openNew() async {
    final row = await defaultChatRow(ref);
    final conversation = await ref
        .read(aiConversationStoreProvider)
        .create(
          title: '',
          permission: ref.read(aiDefaultPermissionProvider),
          installId: row?.installId,
          installGeneration: row?.installedAt,
          model: row == null
              ? null
              : await pluginDefaultModel(ref, row.installId),
        );
    await _start(conversation.id);
    return conversation.id;
  }

  Future<void> _start(int id) async {
    if (!_swept) {
      _swept = true;
      try {
        await ref.read(aiConversationStoreProvider).sweepAfterCrash();
      } on Object catch (e, s) {
        _log.warning('startup sweep failed: ${e.runtimeType}', e, s);
      }
    }
    final driver = LoopDriver(
      conversationId: id,
      store: LoopStoreAdapter(ref.read(aiConversationStoreProvider)),
      runner: ChatTurnRunner(
        runner: ref.read(pluginRunnerProvider),
        idleTimeout: _idleTimeout,
        onStatus: (s) => ref.read(chatStreamStatusProvider.notifier).set(s),
      ),
      env: _env,
      onInternalError: (e, s) =>
          _log.warning('chat loop failure: ${e.runtimeType}', e, s),
    );
    _driver = driver;
    _stateSub = driver.states.listen(_onTurnState);
    _liveSub = driver.liveText.listen((e) {
      _lastLive = e;
      if (!_live.isClosed) _live.add(e);
    });
    state = ChatSessionState(conversationId: id);
    await driver.inspect();
  }

  void _onTurnState(TurnState turn) {
    if (!ref.mounted) return;
    if (turn != TurnState.streaming) {
      ref.read(chatStreamStatusProvider.notifier).clear();
    }
    state = ChatSessionState(
      conversationId: state.conversationId,
      turnState: turn,
      lastView: _driver?.lastView,
    );
  }

  /// Stops the turn and waits for it, then drops the driver.
  Future<void> _closeDriver({bool notify = true}) async {
    final driver = _driver;
    _driver = null;
    await driver?.dispose();
    await _stateSub?.cancel();
    await _liveSub?.cancel();
    _stateSub = _liveSub = null;
    _lastLive = null;
    if (notify && ref.mounted) {
      state = const ChatSessionState();
    }
  }

  Future<Duration> _idleTimeout(String installId) async {
    final rows = ref.read(pluginRowsProvider);
    final row = await rows.liveById(installId);
    final sec = row == null ? null : rows.manifestOf(row)?.chat?.idleTimeoutSec;
    return Duration(seconds: sec ?? chatDefaultIdleTimeoutSec);
  }

  Future<void> _clearBlobsOfChangedInstalls(List<PluginRow> rows) async {
    final now = {
      for (final r in rows)
        if (r.pluginKind == PluginKind.aiChat) r.installId: r.installedAt,
    };
    final before = _knownInstalls;
    _knownInstalls = now;
    if (before == null) return;
    for (final e in before.entries) {
      if (now[e.key] == e.value) continue;
      try {
        await ref
            .read(aiConversationStoreProvider)
            .clearProviderBlobs(installId: e.key);
      } on Object catch (error, s) {
        _log.warning('could not clear blobs: ${error.runtimeType}', error, s);
      }
    }
  }
}

final chatSessionProvider =
    NotifierProvider<ChatSessionController, ChatSessionState>(
      ChatSessionController.new,
      isAutoDispose: false,
    );
