import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../../../media/domain/track_id.dart';
import '../../domain/playlists/playlist_ids.dart';
import '../../domain/playlists/playlist_models.dart';
import '../../domain/playlists/playlist_text_rules.dart';
import 'favorite_entries.dart';
import 'playlist_sql.dart';

/// Adds [tracks] to the existing targets and to new playlists, in the
/// caller's transaction. See `PlaylistStore.addToPlaylists`.
Future<AddToPlaylistsResult> addToPlaylistsWrite(
  AppDatabase db, {
  required List<TrackId> tracks,
  required List<String> playlistUids,
  required List<String> newPlaylistNames,
  required DuplicatePolicy policy,
  required int now,
}) async {
  final names = [for (final n in newPlaylistNames) cleanPlaylistName(n)];
  for (var i = 0; i < names.length; i++) {
    if (checkPlaylistName(names[i]) != null) {
      throw ArgumentError.value(
        newPlaylistNames[i],
        'newPlaylistNames',
        'empty or too long',
      );
    }
  }
  final ids = [for (final t in tracks) t.value];
  await requireTracksExist(db, ids);
  final distinct = {...ids}.toList();

  final outcomes = <PlaylistAddOutcome>[];
  final gone = <String>[];
  final added = <int>{};
  final skipped = <int>{};

  void record(String uid, bool created, List<int> a, List<int> s, int moved) {
    added.addAll(a);
    skipped.addAll(s);
    outcomes.add(
      PlaylistAddOutcome(
        uid: uid,
        created: created,
        added: a.length,
        skipped: s.length,
        movedToEnd: moved,
      ),
    );
  }

  for (final name in names) {
    final id = await insertPlaylistRow(
      db,
      name: capPlaylistName(name),
      now: now,
    );
    await appendEntries(db, id, ids, now);
    record(await playlistUidOf(db, id), true, distinct, const [], 0);
  }

  for (final uid in {...playlistUids}) {
    if (uid == PlaylistUids.favorites) {
      final r = await appendFavoriteEntries(db, distinct, now);
      record(uid, false, r.added, r.skipped, 0);
      continue;
    }
    final playlistId = await livePlaylistId(db, uid);
    if (playlistId == null) {
      gone.add(uid);
      continue;
    }
    final live = distinct.isEmpty
        ? <int>{}
        : await _liveTracks(db, playlistId, distinct);
    if (live.isEmpty || policy == DuplicatePolicy.addAll) {
      await appendEntries(db, playlistId, ids, now);
      record(uid, false, distinct, const [], 0);
    } else if (policy == DuplicatePolicy.skipExisting) {
      final fresh = [
        for (final id in distinct)
          if (!live.contains(id)) id,
      ];
      await appendEntries(db, playlistId, fresh, now);
      record(uid, false, fresh, live.toList(), 0);
    } else {
      await db.customUpdate(
        'DELETE FROM playlist_entries WHERE playlist_id = ? '
        'AND deleted_at IS NULL AND track_id IN $jsonEach',
        variables: [Variable.withInt(playlistId), jsonList(live)],
        updates: {db.playlistEntries},
        updateKind: UpdateKind.delete,
      );
      await appendEntries(db, playlistId, ids, now);
      record(
        uid,
        false,
        [
          for (final id in distinct)
            if (!live.contains(id)) id,
        ],
        const [],
        live.length,
      );
    }
    if (outcomes.last.added + outcomes.last.movedToEnd > 0) {
      await touchPlaylist(db, playlistId, now);
    }
  }
  return AddToPlaylistsResult(
    outcomes: outcomes,
    goneUids: gone,
    addedTrackCount: added.length,
    skippedTrackCount: skipped.length,
  );
}

Future<Set<int>> _liveTracks(
  AppDatabase db,
  int playlistId,
  List<int> ids,
) async {
  final rows = await db
      .customSelect(
        'SELECT DISTINCT track_id FROM playlist_entries '
        'WHERE playlist_id = ? AND deleted_at IS NULL '
        'AND track_id IN $jsonEach',
        variables: [Variable.withInt(playlistId), jsonList(ids)],
      )
      .get();
  return {for (final r in rows) r.read<int>('track_id')};
}
