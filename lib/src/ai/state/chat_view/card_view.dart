import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../plugins/state/plugin_store_providers.dart';
import '../../domain/conversation/ai_message.dart';
import '../../domain/conversation/parts.dart';
import '../../domain/output/chat_outcome.dart';
import '../../domain/tools/ai_tool.dart';
import '../chat_messages_provider.dart';
import '../chat_providers.dart';
import '../chat_session.dart';
import '../chat_session_env.dart';

final _log = Logger('ai.card_view');

/// The clock the cards read (countdowns, "Thử lại lúc"); tests replace it.
final chatCardClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Where a card sits in its conversation.
typedef ChatCardPosition = ({int conversationId, int seq});

/// The newest user message and the newest message of the loaded window. The
/// window is always a suffix of the conversation, so a card is older than a
/// user message exactly when that message is in it.
typedef ChatTurnEdges = ({int latestUserSeq, int newestSeq});

final chatTurnEdgesProvider = Provider.autoDispose.family<ChatTurnEdges, int>((
  ref,
  conversationId,
) {
  return ref.watch(
    chatMessagesProvider(
      conversationId,
    ).select((messages) => turnEdgesOf(messages.value?.messages ?? const [])),
  );
});

/// The edges of [messages] (oldest first); -1 when there is none.
ChatTurnEdges turnEdgesOf(List<AiMessage> messages) {
  var user = -1;
  var newest = -1;
  for (final m in messages) {
    if (m.seq > newest) newest = m.seq;
    if (m.role == AiMessageRole.user && m.seq > user) user = m.seq;
  }
  return (latestUserSeq: user, newestSeq: newest);
}

/// Whether the card at [position] belongs to the latest turn. Only such a
/// card has live actions (retry, countdown, settings, replay); an older one
/// reads as history.
final chatCardLiveProvider = Provider.autoDispose
    .family<bool, ChatCardPosition>((ref, position) {
      final edges = ref.watch(chatTurnEdgesProvider(position.conversationId));
      return position.seq > edges.latestUserSeq;
    });

/// The live outcome of the round that just failed, for the newest message
/// only: it knows more than the stored error (the host a network card names,
/// a busy or timeout card the store keeps as a plain server error). Null
/// after a reload or for any older message.
final chatLiveOutcomeProvider = Provider.autoDispose
    .family<ChatOutcomeView?, ChatCardPosition>((ref, position) {
      final session = ref.watch(chatSessionProvider);
      final view = session.lastView;
      if (view == null || session.conversationId != position.conversationId) {
        return null;
      }
      final edges = ref.watch(chatTurnEdgesProvider(position.conversationId));
      return position.seq == edges.newestSeq ? view : null;
    });

/// The first host a plugin declared at install: the one a network or
/// permission card names. Null when the plugin is gone or declared none.
final chatCardHostProvider = FutureProvider.autoDispose.family<String?, String>(
  (ref, installId) async {
    final rows = ref.read(pluginRowsProvider);
    final row = await rows.liveById(installId);
    final hosts = row == null ? null : rows.manifestOf(row)?.hosts;
    return hosts == null || hosts.isEmpty ? null : hosts.first;
  },
);

/// The display name of the installed chat plugin [installId], or null when
/// it is not installed.
final chatCardPluginNameProvider = Provider.autoDispose
    .family<String?, String?>((ref, installId) {
      if (installId == null) return null;
      final plugins = ref.watch(chatPluginsProvider).value;
      if (plugins == null) return null;
      for (final p in plugins) {
        if (p.installId == installId) return p.name;
      }
      return null;
    });

/// A write call, enough to ask its tool for the card's preview again.
typedef ConfirmCall = ({String name, String argsJson});

/// The key of [call]'s preview.
ConfirmCall confirmCallOf(ToolCallPart call) =>
    (name: call.name, argsJson: jsonEncode(call.args ?? const {}));

/// What a confirmation card lists: the songs the call would change and the
/// name it carries (a playlist). It asks the tool again against the library as
/// it is now (the stored call holds ids only); null when the tool is gone or
/// refuses, and the card then shows what the call itself says.
final chatConfirmPreviewProvider = FutureProvider.autoDispose
    .family<ToolPreview?, ConfirmCall>((ref, call) async {
      final tool = ref.read(aiToolRegistryProvider).byName(call.name);
      final args = jsonDecode(call.argsJson);
      if (tool == null || args is! Map<String, Object?>) return null;
      try {
        final preview = await tool.describe(args, sessionToolEnv(ref));
        return preview?.refusal == null ? preview : null;
      } on Object catch (e, st) {
        // The card still shows the call as stored; Allow runs the tool,
        // which checks everything again.
        _log.warning('preview failed: ${e.runtimeType}', e, st);
        return null;
      }
    });
