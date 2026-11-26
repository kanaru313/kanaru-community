import 'dart:convert';

import '../../plugins/data/run/plugin_runner.dart';
import '../../plugins/data/run/run_cancel.dart';
import '../../plugins/domain/package/plugin_kind.dart';
import '../../plugins/domain/run/run_outcome.dart';
import '../../plugins/domain/run/run_request.dart';
import '../domain/loop/loop_ports.dart';

/// Longest wall time of one chat run (the runtime's own cap for a stream).
const Duration chatRunTimeout = Duration(seconds: 300);

/// What a streaming chat script says it is doing.
enum ChatStreamStatus { thinking, generating }

/// One `emit` of the chat script, parsed. Unknown or damaged events are
/// ignored (`null`): the contract says an unknown `t` is ignored.
sealed class ChatStreamEvent {
  const ChatStreamEvent();
}

final class ChatTextEvent extends ChatStreamEvent {
  const ChatTextEvent(this.delta);

  final String delta;
}

final class ChatStatusEvent extends ChatStreamEvent {
  const ChatStatusEvent(this.status);

  final ChatStreamStatus status;
}

/// Parses the JSON text of an emit: `{"t":"text","d":"…"}` or
/// `{"t":"status","s":"thinking"|"generating"}`.
ChatStreamEvent? parseChatStreamEvent(String json) {
  final Object? value;
  try {
    value = jsonDecode(json);
  } on FormatException {
    return null;
  }
  if (value is! Map<String, Object?>) return null;
  switch (value['t']) {
    case 'text':
      final d = value['d'];
      return d is String && d.isNotEmpty ? ChatTextEvent(d) : null;
    case 'status':
      for (final s in ChatStreamStatus.values) {
        if (s.name == value['s']) return ChatStatusEvent(s);
      }
      return null;
  }
  return null;
}

/// [ModelRoundRunner] on the plugin runner: one streaming run of the `chat`
/// script per round.
///
/// Events reach the caller only while the round is in flight: a cancel or the
/// outcome bumps a generation counter, so a late event of an older round is
/// dropped even if the runtime delivers it.
class ChatTurnRunner implements ModelRoundRunner {
  ChatTurnRunner({
    required this._runner,
    required this._idleTimeout,
    this.onStatus,
    this.timeout = chatRunTimeout,
  });

  final PluginRunner _runner;

  /// The manifest's `chat.idleTimeoutSec` of the plugin.
  final Future<Duration> Function(String installId) _idleTimeout;

  /// Called for each `status` event of the round in flight.
  final void Function(ChatStreamStatus status)? onStatus;
  final Duration timeout;

  int _generation = 0;
  RunCancel? _cancel;

  @override
  Future<RunOutcome> run(
    ModelRoundRequest request, {
    required void Function(String delta) onDelta,
  }) async {
    final installId = request.conversation.installId;
    if (installId == null) {
      return const RunUnavailable(RunUnavailableReason.notInstalled);
    }
    final generation = ++_generation;
    final cancel = _cancel = RunCancel();
    try {
      final idle = await _idleTimeout(installId);
      if (cancel.isCancelled) return const RunCancelled(RunCancelReason.caller);
      return await _runner.run(
        PluginRunRequest(
          installId: installId,
          script: 'chat',
          input: request.input,
          timeout: timeout,
          kinds: const {PluginKind.aiChat},
          logInput: false,
          persistStorage: false,
          stream: StreamOptions(
            idle: idle,
            onEvent: (json) {
              if (generation != _generation || cancel.isCancelled) return;
              final event = parseChatStreamEvent(json);
              switch (event) {
                case ChatTextEvent(:final delta):
                  onDelta(delta);
                case ChatStatusEvent(:final status):
                  onStatus?.call(status);
                case null:
                  break;
              }
            },
          ),
        ),
        cancel: cancel,
      );
    } finally {
      // Events that arrive after the outcome belong to no round.
      if (generation == _generation) _generation++;
      if (identical(_cancel, cancel)) _cancel = null;
    }
  }

  @override
  void cancel() {
    _generation++;
    _cancel?.cancel();
  }
}
