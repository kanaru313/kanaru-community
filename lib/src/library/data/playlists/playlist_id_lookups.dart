import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../../../media/domain/track_id.dart';
import '../../../playback/data/track_info_rows.dart';
import '../../domain/playlists/playlist_ids.dart';
import '../../domain/playlists/playlist_models.dart';
import 'playlist_sql.dart';

/// Playlist and entry id lookups for the AI tools (ids are what the model
/// sees; the store resolves them to uids). Every guard uses
/// [writablePlaylistPredicate], like the UI writes.

/// uid of each live, writable playlist in [ids]; id 0 is Favorites, resolved
/// before SQL (the real row's id never resolves).
Future<Map<int, String>> resolvePlaylistIdsQuery(
  AppDatabase db,
  List<int> ids,
) async {
  final result = <int, String>{
    if (ids.contains(favoritesPlaylistId))
      favoritesPlaylistId: PlaylistUids.favorites,
  };
  final rowIds = ids.toSet()..remove(favoritesPlaylistId);
  if (rowIds.isEmpty) return result;
  final rows = await db
      .customSelect(
        'SELECT id, uid FROM playlists WHERE id IN $jsonEach '
        'AND uid != ? AND $writablePlaylistPredicate',
        variables: [
          jsonList(rowIds),
          Variable.withString(PlaylistUids.favorites),
        ],
      )
      .get();
  for (final r in rows) {
    result[r.read<int>('id')] = r.read<String>('uid');
  }
  return result;
}

/// Favorites first, then every other live writable playlist by creation.
Future<List<WritablePlaylist>> listWritableQuery(AppDatabase db) async {
  final rows = await db
      .customSelect(
        'SELECT id, uid, name FROM playlists WHERE uid != ? '
        'AND $writablePlaylistPredicate ORDER BY created_at, id',
        variables: [Variable.withString(PlaylistUids.favorites)],
      )
      .get();
  return [
    const WritablePlaylist(
      id: favoritesPlaylistId,
      uid: PlaylistUids.favorites,
      name: favoritesPlaylistName,
    ),
    for (final r in rows)
      WritablePlaylist(
        id: r.read<int>('id'),
        uid: r.read<String>('uid'),
        name: r.read<String>('name'),
      ),
  ];
}

/// uid of each live entry in [entryIds] that belongs to the live playlist
/// [playlistUid]. In Favorites, entries of duplicate-hidden tracks are not
/// resolved (the detail view hides them too).
Future<Map<int, String>> resolveEntryIdsQuery(
  AppDatabase db,
  String playlistUid,
  List<int> entryIds,
) => db.transaction(() async {
  final playlistId = await livePlaylistId(db, playlistUid);
  if (playlistId == null || entryIds.isEmpty) return const <int, String>{};
  final rows = await db
      .customSelect(
        'SELECT e.id AS id, e.uid AS uid FROM playlist_entries e '
        'JOIN tracks t ON t.id = e.track_id '
        'WHERE e.playlist_id = ? AND e.deleted_at IS NULL '
        'AND e.id IN $jsonEach '
        // Same rule as `loadDetail`: only Favorites follows duplicate hiding.
        'AND (? = 0 OR t.dup_hidden = 0)',
        variables: [
          Variable.withInt(playlistId),
          jsonList(entryIds.toSet()),
          Variable.withInt(playlistUid == PlaylistUids.favorites ? 1 : 0),
        ],
      )
      .get();
  return {for (final r in rows) r.read<int>('id'): r.read<String>('uid')};
});

/// Entries `[entryUids]` of playlist [playlistId] that are live, in playlist
/// order, as [PlaylistEntryView]s (no duplicate-hiding filter: used to report
/// what a removal touched).
Future<List<PlaylistEntryView>> liveEntryViews(
  AppDatabase db,
  int playlistId,
  List<String> entryUids,
) async {
  if (entryUids.isEmpty) return const [];
  final rows = await db
      .customSelect(
        'SELECT id, uid, track_id FROM playlist_entries '
        'WHERE playlist_id = ? AND deleted_at IS NULL AND uid IN $jsonEach '
        'ORDER BY sort_key, uid',
        variables: [Variable.withInt(playlistId), jsonList(entryUids.toSet())],
      )
      .get();
  final infos = await loadTrackInfos(db, [
    for (final r in rows) TrackId(r.read<int>('track_id')),
  ]);
  final byId = {for (final i in infos) i.id: i};
  return [
    for (final r in rows)
      PlaylistEntryView(
        id: r.read<int>('id'),
        uid: r.read<String>('uid'),
        // `tracks` rows outlive their entries (FK RESTRICT): never absent.
        info: byId[TrackId(r.read<int>('track_id'))]!,
      ),
  ];
}
