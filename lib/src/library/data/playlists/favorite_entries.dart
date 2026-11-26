import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../../../foundation/ordering/fractional_keys.dart';
import '../../domain/playlists/playlist_models.dart';
import 'playlist_sql.dart';

/// Adds [trackIds] to Favorites; a track that is already a live favorite
/// keeps its place. Creates the Favorites row lazily. Throws [ArgumentError]
/// (nothing written) for an id with no `tracks` row. Runs inside the caller's
/// transaction. Returns the distinct tracks added and the distinct tracks
/// that were already favorites.
///
/// New keys come after **every** row of the playlist, tombstones included, so
/// a pending removal never shares a key with a new entry; a revived entry
/// takes a fresh key too.
Future<({List<int> added, List<int> skipped})> appendFavoriteEntries(
  AppDatabase db,
  Iterable<int> trackIds,
  int now,
) async {
  final ids = {...trackIds}.toList();
  if (ids.isEmpty) return (added: const <int>[], skipped: const <int>[]);
  final uids = await trackUidsById(db, ids);
  final unknown = ids.where((id) => !uids.containsKey(id)).toList();
  if (unknown.isNotEmpty) {
    throw ArgumentError.value(unknown, 'tracks', 'no such track');
  }
  final live = await _liveFavorites(db, ids);
  final missing = [
    for (final id in ids)
      if (!live.contains(id)) id,
  ];
  final skipped = [
    for (final id in ids)
      if (live.contains(id)) id,
  ];
  if (missing.isEmpty) return (added: const <int>[], skipped: skipped);
  await _dropStaleEntriesOfDeletedPlaylist(db);
  final previous = await _updatedAt(db);
  final playlist = await insertOrRevive(
    db,
    db.playlists,
    PlaylistsCompanion.insert(
      uid: favoritesPlaylistUid,
      name: favoritesPlaylistName,
      kind: const Value(PlaylistKind.favorites),
      createdAt: now,
      updatedAt: now,
    ),
    now: now,
  );
  if (previous != null) {
    await db.customUpdate(
      'UPDATE playlists SET updated_at = MAX(?, ?) WHERE id = ?',
      variables: [
        Variable.withInt(now),
        Variable.withInt(previous + 1),
        Variable.withInt(playlist.id),
      ],
    );
  }
  final keys = generateNKeysBetween(
    await maxSortKey(db, playlist.id),
    null,
    missing.length,
  );
  for (var i = 0; i < missing.length; i++) {
    await insertOrRevive(
      db,
      db.playlistEntries,
      PlaylistEntriesCompanion.insert(
        uid: favoriteEntryUid(favoritesPlaylistUid, uids[missing[i]]!),
        playlistId: playlist.id,
        trackId: missing[i],
        sortKey: keys[i],
        addedAt: now,
        updatedAt: now,
      ),
      now: now,
      reviveColumns: {'sort_key', 'added_at'},
    );
  }
  return (added: missing, skipped: skipped);
}

Future<Set<int>> _liveFavorites(AppDatabase db, List<int> ids) async {
  final rows = await db
      .customSelect(
        'SELECT e.track_id FROM playlist_entries e '
        'JOIN playlists p ON p.id = e.playlist_id '
        'WHERE p.uid = ? AND p.deleted_at IS NULL AND e.deleted_at IS NULL '
        'AND e.track_id IN $jsonEach',
        variables: [Variable.withString(favoritesPlaylistUid), jsonList(ids)],
      )
      .get();
  return {for (final r in rows) r.read<int>('track_id')};
}

/// A tombstoned Favorites playlist is revived by the next favorite; its old
/// entries must not come back with it.
Future<void> _dropStaleEntriesOfDeletedPlaylist(AppDatabase db) =>
    db.customUpdate(
      'DELETE FROM playlist_entries WHERE playlist_id IN '
      '(SELECT id FROM playlists WHERE uid = ? AND deleted_at IS NOT NULL)',
      variables: [Variable.withString(favoritesPlaylistUid)],
      updates: {db.playlistEntries},
      updateKind: UpdateKind.delete,
    );

Future<int?> _updatedAt(AppDatabase db) async {
  final rows = await db
      .customSelect(
        'SELECT updated_at FROM playlists WHERE uid = ?',
        variables: [Variable.withString(favoritesPlaylistUid)],
      )
      .get();
  return rows.isEmpty ? null : rows.single.read<int>('updated_at');
}
