import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../../../media/domain/track_id.dart';
import '../../domain/playlists/playlist_ids.dart';
import '../../domain/playlists/playlist_models.dart';
import 'playlist_add_writes.dart';
import 'playlist_sql.dart';

/// Copies playlist [uid] (Favorites included) under [name] (already cleaned
/// and capped), in the caller's transaction; null when the source is gone.
Future<String?> duplicatePlaylistWrite(
  AppDatabase db,
  String uid, {
  required String name,
  required bool copyCover,
  required int now,
}) async {
  final sourceId = await livePlaylistId(db, uid);
  if (sourceId == null) return null;
  final description =
      (await db
              .customSelect(
                'SELECT description FROM playlists WHERE id = ?',
                variables: [Variable.withInt(sourceId)],
              )
              .getSingle())
          .read<String>('description');
  final tracks = await db
      .customSelect(
        'SELECT track_id FROM playlist_entries WHERE playlist_id = ? '
        'AND deleted_at IS NULL ORDER BY sort_key, uid',
        variables: [Variable.withInt(sourceId)],
      )
      .get();
  final id = await insertPlaylistRow(
    db,
    name: name,
    description: description,
    now: now,
  );
  await appendEntries(db, id, [
    for (final r in tracks) r.read<int>('track_id'),
  ], now);
  final newUid = await playlistUidOf(db, id);
  if (copyCover && uid != PlaylistUids.favorites) {
    // Covers are content-addressed: the copy shares the stored files.
    final key = await customCoverKey(db, CustomCoverKinds.playlist, uid);
    if (key != null) {
      await setCustomCover(
        db,
        CustomCoverKinds.playlist,
        newUid,
        key,
        now: now,
      );
    }
  }
  return newUid;
}

/// Adds the available tracks of playlist [uid], in playlist order, to
/// Favorites; a source that is gone is reported in `goneUids`.
Future<AddToPlaylistsResult> addAllToFavoritesWrite(
  AppDatabase db,
  String uid,
  int now,
) async {
  final sourceId = await livePlaylistId(db, uid);
  if (sourceId == null) {
    return AddToPlaylistsResult(
      outcomes: const [],
      goneUids: [uid],
      addedTrackCount: 0,
      skippedTrackCount: 0,
    );
  }
  final rows = await db
      .customSelect(
        'SELECT e.track_id FROM playlist_entries e '
        'JOIN tracks t ON t.id = e.track_id '
        'WHERE e.playlist_id = ? AND e.deleted_at IS NULL '
        "AND t.status NOT IN ('${TrackStatus.missing}', '${TrackStatus.hidden}') "
        'ORDER BY e.sort_key, e.uid',
        variables: [Variable.withInt(sourceId)],
      )
      .get();
  return addToPlaylistsWrite(
    db,
    tracks: [for (final r in rows) TrackId(r.read<int>('track_id'))],
    playlistUids: const [PlaylistUids.favorites],
    newPlaylistNames: const [],
    policy: DuplicatePolicy.skipExisting,
    now: now,
  );
}
