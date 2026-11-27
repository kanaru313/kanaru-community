import 'package:flutter/widgets.dart' show IconData;
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/conversation/parts.dart';
import '../tool_text.dart';

/// What a write call asked for, read from its arguments: the numbers and the
/// name the card words. A call whose arguments do not parse reads as nothing.
class CardRequest {
  const CardRequest({required this.tool, this.count = 0, this.name});

  /// A request read from [call] (null: an unknown call).
  factory CardRequest.of(ToolCallPart? call) {
    final args = call?.args;
    if (call == null || args == null) {
      return CardRequest(tool: call?.name ?? '');
    }
    final ids = args['trackIds'] ?? args['entryIds'];
    final name = args['name'];
    return CardRequest(
      tool: call.name,
      count: ids is List ? ids.toSet().length : 0,
      name: name is String && name.trim().isNotEmpty ? name.trim() : null,
    );
  }

  final String tool;
  final int count;

  /// The playlist name the call carries (`create_playlist`).
  final String? name;

  CardRequest copyWith({int? count, String? name}) => CardRequest(
    tool: tool,
    count: count ?? this.count,
    name: name ?? this.name,
  );

  bool get isPlaylistTool =>
      tool == 'create_playlist' ||
      tool == 'add_to_playlist' ||
      tool == 'remove_from_playlist';

  bool get isRemoval =>
      tool == 'remove_from_queue' || tool == 'remove_from_playlist';
}

/// What the call does as a phrase that starts in lower case ("thêm 6 bài vào
/// hàng đợi"); [sentenceCase] lifts it when it leads a line.
String actionPhrase(AppLocalizations l10n, CardRequest r) => switch (r.tool) {
  'create_playlist' => l10n.aiChatActCreatePlaylist(r.name ?? '', r.count),
  'add_to_playlist' =>
    r.name == null
        ? l10n.aiChatActAddToPlaylist(r.count)
        : l10n.aiChatActAddToPlaylistNamed(r.name!, r.count),
  'remove_from_playlist' =>
    r.name == null
        ? l10n.aiChatActRemoveFromPlaylist(r.count)
        : l10n.aiChatActRemoveFromPlaylistNamed(r.name!, r.count),
  'play_tracks' => l10n.aiChatActPlay(r.count),
  'queue_tracks' => l10n.aiChatActQueue(r.count),
  'remove_from_queue' => l10n.aiChatActRemoveFromQueue(r.count),
  _ => toolDisplayName(l10n, r.tool),
};

/// [text] with its first letter in upper case.
String sentenceCase(String text) {
  if (text.isEmpty) return text;
  final first = String.fromCharCode(text.runes.first);
  return first.toUpperCase() + text.substring(first.length);
}

/// The settings group a write tool belongs to, as the user knows it.
String toolGroupLabel(AppLocalizations l10n, String tool) => switch (tool) {
  'play_tracks' => l10n.aiChatGroupPlay,
  'queue_tracks' || 'remove_from_queue' => l10n.aiChatGroupQueueEdit,
  'create_playlist' => l10n.aiChatGroupPlaylistCreate,
  'add_to_playlist' || 'remove_from_playlist' => l10n.aiChatGroupPlaylistEdit,
  _ => toolDisplayName(l10n, tool),
};

/// The round icon of a card about [tool].
IconData actionIcon(String tool) => switch (tool) {
  'create_playlist' || 'add_to_playlist' => KIcons.playlistAdd,
  'remove_from_playlist' || 'remove_from_queue' => KIcons.playlistRemove,
  'play_tracks' => KIcons.play,
  'queue_tracks' => KIcons.queueMusic,
  _ => KIcons.advanced,
};

/// Lines of a second line, joined the way the mockup writes them.
String joinLine(Iterable<String?> parts) =>
    parts.whereType<String>().where((p) => p.isNotEmpty).join(' · ');
