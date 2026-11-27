import 'dart:convert';

import '../../../l10n/gen/app_localizations.dart';

import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:flutter/widgets.dart' show IconData;

/// What the user reads for the tool [name] on a tool card: the built-in tools
/// have a translated name, any other tool shows its own name.
String toolDisplayName(AppLocalizations l10n, String name) => switch (name) {
  'play_tracks' => l10n.aiChatToolPlayTracks,
  'queue_tracks' => l10n.aiChatToolQueueTracks,
  'remove_from_queue' => l10n.aiChatToolRemoveFromQueue,
  'list_playlists' => l10n.aiChatToolListPlaylists,
  'get_playlist_tracks' => l10n.aiChatToolGetPlaylistTracks,
  'get_lyrics' => l10n.aiChatToolGetLyrics,
  'get_listening_stats' => l10n.aiChatToolGetListeningStats,
  'create_playlist' => l10n.aiChatToolCreatePlaylist,
  'add_to_playlist' => l10n.aiChatToolAddToPlaylist,
  'remove_from_playlist' => l10n.aiChatToolRemoveFromPlaylist,
  'get_now_playing' => l10n.aiChatToolGetNowPlaying,
  'get_queue' => l10n.aiChatToolGetQueue,
  'search_library' => l10n.aiChatToolSearchLibrary,
  'get_track_info' => l10n.aiChatToolGetTrackInfo,
  _ => name,
};

/// Icon of the tool on its card.
IconData toolIcon(String name) => switch (name) {
  'search_library' || 'get_track_info' => KIcons.search,
  'get_lyrics' => KIcons.lyrics,
  'get_queue' || 'queue_tracks' || 'remove_from_queue' => KIcons.queue,
  'get_now_playing' || 'play_tracks' => KIcons.play,
  'list_playlists' ||
  'get_playlist_tracks' ||
  'create_playlist' ||
  'add_to_playlist' ||
  'remove_from_playlist' => KIcons.playlists,
  'get_listening_stats' => KIcons.stats,
  _ => KIcons.advanced,
};

/// Rows of a list result, or null when [text] is not one.
List<String>? _itemsOf(String text) {
  try {
    final json = jsonDecode(text);
    if (json is Map && json['items'] is List) {
      return [for (final r in json['items'] as List) '$r'];
    }
  } on FormatException {
    // Not JSON: shown as text.
  }
  return null;
}

/// One line for the card header: "50 / 1,284 songs" for a list ("· the AI can
/// look further" when the total is larger than the rows returned), else the
/// first line.
String toolSummary(AppLocalizations l10n, String resultText) {
  final text = resultText.trim();
  if (text.isEmpty) return '';
  final items = _itemsOf(text);
  if (items != null) {
    Object? total;
    try {
      total = (jsonDecode(text) as Map)['total'];
    } on FormatException {
      total = null;
    }
    if (total is! int) return l10n.aiChatToolSummaryCount(items.length);
    return total > items.length
        ? l10n.aiChatToolSummaryListMore(items.length, total)
        : l10n.aiChatToolSummaryList(items.length, total);
  }
  final first = text.split('\n').first;
  return first.length > 80 ? '${first.substring(0, 79)}…' : first;
}

const _maxPreviewRows = 30;
const _maxPreviewChars = 1500;

/// The result as the open card shows it: a list one row per line, other text
/// cut to a size a card can hold.
String toolResultPreview(String resultText) {
  final text = resultText.trim();
  final items = _itemsOf(text);
  if (items != null) {
    final shown = items
        .take(_maxPreviewRows)
        .map((r) => r.replaceAll('|', ' | '));
    return [...shown, if (items.length > _maxPreviewRows) '…'].join('\n');
  }
  return text.length > _maxPreviewChars
      ? '${text.substring(0, _maxPreviewChars)}…'
      : text;
}

/// Arguments of a call as the open card shows them.
String toolArgsPreview(Map<String, Object?>? args, String? rawArgs) {
  if (args != null) {
    if (args.isEmpty) return '';
    return const JsonEncoder.withIndent('  ').convert(args);
  }
  return rawArgs ?? '';
}
