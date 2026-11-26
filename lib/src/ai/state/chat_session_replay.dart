import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/conversation_store.dart';
import '../domain/conversation/ai_message.dart';
import '../domain/conversation/parts.dart';
import 'chat_session_env.dart';

/// What "play the old queue again" did.
enum ReplayResult {
  /// The queue was restored and plays.
  played,

  /// The call replaced no queue, or none of its tracks can be played now.
  nothingToRestore,

  /// The call belongs to an earlier turn; only the latest turn can be undone.
  notLatestTurn,

  /// No such tool row in the open conversation.
  unavailable,

  /// The player refused or failed.
  failed,
}

/// Restores the queue that the tool row [messageId] replaced.
///
/// The old queue is rebuilt in the order it played, from the tracks that are
/// still visible; playback starts at the entry that was playing (the first
/// one when none was loaded). The shuffle flag is not restored.
Future<ReplayResult> replayReplacedQueue(
  Ref ref, {
  required ConversationStore store,
  required int conversationId,
  required int messageId,
}) async {
  final stored = await store.message(messageId);
  final message = stored?.message;
  if (message == null ||
      message.conversationId != conversationId ||
      message.role != AiMessageRole.tool) {
    return ReplayResult.unavailable;
  }
  final snapshot = message.parts
      .whereType<DonePart>()
      .map((d) => d.replacedQueue)
      .nonNulls
      .firstOrNull;
  if (snapshot == null || snapshot.tracks.isEmpty) {
    return ReplayResult.nothingToRestore;
  }
  // A turn is a user message and the rows after it: the call is in the
  // latest turn when no user message follows it.
  final tail = await store.messages(conversationId, limit: _tailRows);
  final lastUser = tail.where((m) => m.message.role == AiMessageRole.user);
  if (lastUser.isNotEmpty && lastUser.last.message.seq > message.seq) {
    return ReplayResult.notLatestTurn;
  }

  final env = sessionToolEnv(ref);
  final visible = await env.library.visibleOf(snapshot.tracks);
  final playable = {for (final t in visible.visible) t.id};
  final ids = [
    for (final id in snapshot.tracks)
      if (playable.contains(id)) id,
  ];
  if (ids.isEmpty) return ReplayResult.nothingToRestore;
  final index = snapshot.previousIndex;
  final wasPlaying = index != null && index < snapshot.tracks.length
      ? snapshot.tracks[index]
      : null;
  final start = wasPlaying == null ? 0 : ids.indexOf(wasPlaying);
  await env.playbackWrite.play(
    ids,
    startIndex: start < 0 ? 0 : start,
    contextLabel: env.playContextLabel,
  );
  return ReplayResult.played;
}

/// Rows read from the end of the chat to find the latest user message (a
/// turn holds at most a few dozen rows).
const int _tailRows = 200;
