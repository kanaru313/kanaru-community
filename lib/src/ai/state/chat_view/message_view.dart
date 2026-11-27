import 'dart:convert';

import 'package:flutter/foundation.dart' show listEquals;

import '../../domain/conversation/ai_message.dart';
import '../../domain/conversation/parts.dart';

/// One thing the message list draws, derived from the stored rows. Cards for
/// confirmations, results and errors are [ChatCardItem]s: a later part draws
/// them through the card slot.
sealed class ChatItem {
  const ChatItem(this.message);

  final AiMessage message;
}

/// A message of the user.
final class ChatUserItem extends ChatItem {
  const ChatUserItem(super.message);
}

/// The text of a model round (streaming, finished or stopped).
final class ChatAssistantItem extends ChatItem {
  const ChatAssistantItem(super.message);
}

/// A foldable tool card: a tool that runs, or a read that finished.
final class ChatToolItem extends ChatItem {
  const ChatToolItem(super.message);
}

/// A row the card slot draws (confirm, done, skipped, unknown, error).
final class ChatCardItem extends ChatItem {
  const ChatCardItem(super.message);
}

/// "From here on: plugin · model" divider. [model] is the model of the next
/// answer, null when none follows yet.
final class ChatSwitchItem extends ChatItem {
  const ChatSwitchItem(super.message, {required this.toName, this.model});

  final String toName;
  final String? model;
}

/// Text of the [TextPart]s of [message], in order.
String messageText(AiMessage message) =>
    message.parts.whereType<TextPart>().map((p) => p.text).join();

/// Text to draw for [message] once it is not streaming: the stored
/// [TextPart]s, else the received [AiMessage.liveText] (a turn cut off by
/// closing keeps its partial answer there, not in a part).
String displayText(AiMessage message) {
  final stored = messageText(message);
  if (stored.isNotEmpty || message.state == AiMessageState.streaming) {
    return stored;
  }
  return message.liveText ?? '';
}

/// Rows to draw for [messages] (oldest first).
List<ChatItem> chatItemsOf(List<AiMessage> messages) {
  final items = <ChatItem>[];
  for (var i = 0; i < messages.length; i++) {
    final m = messages[i];
    switch (m.role) {
      case AiMessageRole.user:
        items.add(ChatUserItem(m));
      case AiMessageRole.assistant:
        final live = m.state == AiMessageState.streaming;
        // A failed round, or one cut short with a reason (a timeout, a plugin
        // update, the app closing): both end with a card. A plain stop does
        // not (its "Đã dừng" is part of the answer).
        final failed =
            m.state == AiMessageState.error ||
            (m.state == AiMessageState.stopped &&
                m.parts.any((p) => p is ErrorPart));
        final hasText = displayText(m).trim().isNotEmpty;
        // A round that only called tools has no text to draw.
        if (live || m.state == AiMessageState.stopped || hasText) {
          items.add(ChatAssistantItem(m));
        }
        if (failed) items.add(ChatCardItem(m));
      case AiMessageRole.tool:
        items.add(_isToolCard(m) ? ChatToolItem(m) : ChatCardItem(m));
      case AiMessageRole.event:
        final event = m.parts.whereType<EventPart>().firstOrNull;
        if (event == null) continue;
        items.add(
          ChatSwitchItem(
            m,
            toName: event.toName,
            model: _nextModel(messages, i),
          ),
        );
    }
  }
  return items;
}

String? _nextModel(List<AiMessage> messages, int from) {
  for (var j = from + 1; j < messages.length; j++) {
    final m = messages[j];
    if (m.role == AiMessageRole.assistant && m.model != null) return m.model;
  }
  return null;
}

bool _isToolCard(AiMessage m) {
  if (m.state == AiMessageState.running) return true;
  // A call that failed stays a tool card (its error text is the result); the
  // call that hit the item limit is the limit card.
  if (m.state == AiMessageState.error) {
    return !m.parts.any((p) => p is ErrorPart);
  }
  if (m.state != AiMessageState.done) return false;
  return !m.parts.any((p) => p is ConfirmPart || p is DonePart);
}

/// Tools whose result lists songs as `id|title|…` rows. A result of any other
/// tool (a plugin's, a playlist list) never makes an id known.
const _songTools = {
  'search_library',
  'get_playlist_tracks',
  'get_queue',
  'get_now_playing',
  'get_track_info',
  'get_listening_stats',
  'get_lyrics',
};

final _rowId = RegExp(r'^(\d{1,18})\|');

/// The ids one message made known, kept with the parts they were read from.
typedef KnownIdsEntry = ({List<AiPart> parts, Set<int> ids});

/// Track ids this conversation has seen: song rows of tool results, songs a
/// write tool changed, songs the user attached. `[[t:ID]]` in an answer is a
/// track row only for one of these; the model cannot make up a song row.
///
/// Only the loaded messages are read: an id seen on an older page that is not
/// loaded yet shows as plain text until the page is. With a [cache] (message
/// id to its entry) a message whose parts did not change is not decoded again.
Set<int> knownTrackIds(
  Iterable<AiMessage> messages, {
  Map<int, KnownIdsEntry>? cache,
}) {
  final ids = <int>{};
  for (final m in messages) {
    final cached = cache?[m.id];
    if (cached != null &&
        (identical(cached.parts, m.parts) ||
            listEquals(cached.parts, m.parts))) {
      ids.addAll(cached.ids);
      continue;
    }
    final own = _idsOfMessage(m);
    cache?[m.id] = (parts: m.parts, ids: own);
    ids.addAll(own);
  }
  return ids;
}

Set<int> _idsOfMessage(AiMessage m) {
  final ids = <int>{};
  for (final p in m.parts) {
    switch (p) {
      case ToolResultPart() when _songTools.contains(p.name) && !p.isError:
        for (final c in p.content.whereType<TextPart>()) {
          ids.addAll(_idsOfResult(c.text));
        }
      case DonePart():
        ids
          ..addAll(p.added.map((t) => t.trackId))
          ..addAll(p.removed.map((t) => t.trackId));
      case ChipPart():
        ids.addAll(p.tracks.map((t) => t.trackId));
      default:
    }
  }
  return ids;
}

Iterable<int> _idsOfResult(String text) sync* {
  final Object? json;
  try {
    json = jsonDecode(text);
  } on FormatException {
    return;
  }
  if (json is! Map) return;
  final rows = <Object?>[
    ...?(json['items'] is List ? json['items'] as List : null),
    json['track'],
  ];
  for (final r in rows) {
    final match = r is String ? _rowId.firstMatch(r) : null;
    if (match != null) yield int.parse(match[1]!);
  }
  final trackId = json['trackId'];
  if (trackId is int) yield trackId;
}
