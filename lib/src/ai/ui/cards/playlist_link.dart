import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../library/state/playlists/playlist_providers.dart';
import '../../../library/ui/library_locations.dart';
import '../../domain/conversation/parts.dart';

/// Where a done card's "Xem" goes for the playlist a call changed: that
/// playlist's page, or the playlists list when the call did not name one (or
/// it is gone). Behind a provider so tests need no library.
final chatPlaylistLocationProvider =
    Provider<Future<String> Function(int? playlistId)>((ref) {
      return (playlistId) async {
        if (playlistId == null) return LibraryLocations.playlists;
        final uids = await ref.read(playlistStoreProvider).resolvePlaylistIds([
          playlistId,
        ]);
        final uid = uids[playlistId];
        return uid == null
            ? LibraryLocations.playlists
            : LibraryLocations.playlist(uid);
      };
    });

/// The `playlistId` a playlist tool's result names (0 is Favorites); null
/// when it names none (a create whose id could not be read back).
int? playlistIdOfResult(ToolResultPart? result) {
  if (result == null) return null;
  for (final part in result.content.whereType<TextPart>()) {
    try {
      final json = jsonDecode(part.text);
      if (json is Map && json['playlistId'] is int) {
        return json['playlistId'] as int;
      }
    } on FormatException {
      // Not JSON: the result names no playlist.
    }
  }
  return null;
}
