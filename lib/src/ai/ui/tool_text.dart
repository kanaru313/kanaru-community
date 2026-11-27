import 'dart:convert';

import '../../../l10n/gen/app_localizations.dart';

import 'tool_result_rows.dart' show isSongListTool, itemsOfToolResult;

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
  'get_library_overview' => l10n.aiChatToolGetLibraryOverview,
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
  'get_listening_stats' || 'get_library_overview' => KIcons.stats,
  _ => KIcons.advanced,
};

/// One line for the card header: "50 / 1,284 songs" ("items" for a tool
/// that does not list songs) for a list ("· the AI can
/// look further" when the total is larger than the rows returned), else the
/// first line.
String toolSummary(AppLocalizations l10n, String tool, String resultText) {
  final text = resultText.trim();
  if (text.isEmpty) return '';
  final items = itemsOfToolResult(text);
  if (items != null) {
    Object? total;
    try {
      total = (jsonDecode(text) as Map)['total'];
    } on FormatException {
      total = null;
    }
    // "songs" only for the tools that list songs; a playlist list is not.
    final songs = isSongListTool(tool);
    if (total is! int) {
      return songs
          ? l10n.aiChatToolSummaryCount(items.length)
          : l10n.aiChatToolSummaryItemsCount(items.length);
    }
    final more = total > items.length;
    if (songs) {
      return more
          ? l10n.aiChatToolSummaryListMore(items.length, total)
          : l10n.aiChatToolSummaryList(items.length, total);
    }
    return more
        ? l10n.aiChatToolSummaryItemsMore(items.length, total)
        : l10n.aiChatToolSummaryItems(items.length, total);
  }
  final first = text.split('\n').first;
  return first.length > 80 ? '${first.substring(0, 79)}…' : first;
}

/// Arguments of a call as the open card shows them.
String toolArgsPreview(Map<String, Object?>? args, String? rawArgs) {
  if (args != null) {
    if (args.isEmpty) return '';
    return const JsonEncoder.withIndent('  ').convert(args);
  }
  return rawArgs ?? '';
}
