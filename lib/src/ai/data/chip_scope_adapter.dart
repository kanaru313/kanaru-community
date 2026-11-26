import '../../library/domain/browse/song_scope.dart';
import '../../library/domain/playlists/playlist_store.dart';
import '../../library/domain/search/track_lookup.dart';
import '../../media/domain/library_keys.dart';
import '../domain/conversation/parts.dart';
import '../domain/tools/tool_env.dart';
import '../domain/variables/chip_resolver.dart';

/// [ChipScopePort] on the library's public APIs: the ids of a scope come from
/// [scopeIds], the rows from the shared track lookup (visibility rules
/// included), a playlist id from the playlist store.
///
/// A chip's `ref` is the key text the "Ask AI" entry stored: album and artist
/// keys are the route-safe `AlbumKey.encode()` / `ArtistKey.encode()` text, a
/// genre is its stored `genre_key`, a language its ISO 639-3 code (empty for
/// "no language").
class ChipScopeAdapter implements ChipScopePort {
  const ChipScopeAdapter({
    required this.scopeIds,
    required this.lookup,
    required this.playlists,
  });

  /// Ordered ids of the visible tracks of a scope.
  final Future<List<int>> Function(SongScope scope) scopeIds;
  final TrackLookup lookup;
  final PlaylistStore playlists;

  @override
  Future<int?> playlistModelId(String uid) async {
    final detail = await playlists.loadPlaylist(uid);
    return detail?.summary.id;
  }

  @override
  Future<({List<TrackRow> rows, int total})?> scopeTracks(
    ChipKind kind,
    String ref,
  ) async {
    final scope = _scopeOf(kind, ref);
    if (scope == null) return null;
    final ids = await scopeIds(scope);
    if (ids.isEmpty) return (rows: const <TrackRow>[], total: 0);
    final page = ids.take(chipMaxRows).toList();
    final r = await lookup.visibleOf(page);
    final byId = {for (final t in r.visible) t.id.value: t};
    return (
      rows: [
        for (final id in page)
          if (byId[id] case final t?)
            TrackRow(
              id: t.id.value,
              title: t.title,
              artist: t.artist,
              album: t.album,
              year: t.year,
            ),
      ],
      total: ids.length,
    );
  }

  SongScope? _scopeOf(ChipKind kind, String ref) => switch (kind) {
    ChipKind.album => switch (AlbumKey.decode(ref)) {
      final key? => SongScope.album(key),
      null => null,
    },
    ChipKind.artist => switch (ArtistKey.decode(ref)) {
      final key? => SongScope.artist(key),
      null => null,
    },
    ChipKind.genre => ref.isEmpty ? null : SongScope.genre(ref),
    ChipKind.language => SongScope.language(ref.isEmpty ? null : ref),
    _ => null,
  };
}
