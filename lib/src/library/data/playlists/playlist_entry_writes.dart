import 'package:drift/drift.dart';
import 'package:logging/logging.dart';

import '../../../database/database.dart';
import '../../../foundation/ordering/fractional_keys.dart';
import '../../domain/playlists/playlist_models.dart';
import 'playlist_id_lookups.dart';
import 'playlist_sql.dart';

final _log = Logger('library.playlists');

/// A removed entry stays a tombstone this long (ms) before the GC purges it.
const removedEntryGraceMs = 60 * 60 * 1000;

/// Moves entry [entryUid] just after [afterUid] (null: to the start) by
/// rewriting that one row. The new key lies strictly between the key of
/// `after` and the next key of **any** row (tombstones included) above it, so
/// it never equals a pending removal's key. Runs in the caller's transaction.
Future<PlaylistMove> moveEntryWrite(
  AppDatabase db,
  String playlistUid,
  String entryUid,
  String? afterUid,
  int now,
) async {
  final playlistId = await livePlaylistId(db, playlistUid);
  if (playlistId == null) return PlaylistMove.gone;
  final entry = await _liveEntry(db, playlistId, entryUid);
  if (entry == null) return PlaylistMove.gone;
  ({int id, String key})? after;
  if (afterUid != null) {
    after = await _liveEntry(db, playlistId, afterUid);
    if (after == null) return PlaylistMove.gone;
    if (afterUid == entryUid) return PlaylistMove.unchanged;
  }
  final previous = await db
      .customSelect(
        'SELECT uid FROM playlist_entries WHERE playlist_id = ? '
        'AND deleted_at IS NULL AND (sort_key, uid) < (?, ?) '
        'ORDER BY sort_key DESC, uid DESC LIMIT 1',
        variables: [
          Variable.withInt(playlistId),
          Variable.withString(entry.key),
          Variable.withString(entryUid),
        ],
      )
      .get();
  if (previous.firstOrNull?.read<String>('uid') == afterUid) {
    return PlaylistMove.unchanged;
  }
  final next = await db
      .customSelect(
        after == null
            ? 'SELECT MIN(sort_key) AS k FROM playlist_entries '
                  'WHERE playlist_id = ? AND id != ?'
            : 'SELECT MIN(sort_key) AS k FROM playlist_entries '
                  'WHERE playlist_id = ? AND id != ? '
                  'AND (sort_key, uid) > (?, ?)',
        variables: [
          Variable.withInt(playlistId),
          Variable.withInt(entry.id),
          if (after != null) ...[
            Variable.withString(after.key),
            Variable.withString(afterUid!),
          ],
        ],
      )
      .getSingle();
  final nextKey = next.readNullable<String>('k');
  if (after != null && nextKey != null && after.key.compareTo(nextKey) >= 0) {
    _log.severe('playlist $playlistUid: keys out of order near $afterUid');
    throw StateError('playlist entry keys are not strictly ordered');
  }
  final key = generateKeyBetween(after?.key, nextKey);
  await db.customUpdate(
    'UPDATE playlist_entries SET sort_key = ?, updated_at = ? WHERE id = ?',
    variables: [
      Variable.withString(key),
      Variable.withInt(now),
      Variable.withInt(entry.id),
    ],
    updates: {db.playlistEntries},
    updateKind: UpdateKind.update,
  );
  await touchPlaylist(db, playlistId, now);
  return PlaylistMove.moved;
}

Future<({int id, String key})?> _liveEntry(
  AppDatabase db,
  int playlistId,
  String uid,
) async {
  final rows = await db
      .customSelect(
        'SELECT id, sort_key FROM playlist_entries '
        'WHERE uid = ? AND playlist_id = ? AND deleted_at IS NULL',
        variables: [Variable.withString(uid), Variable.withInt(playlistId)],
      )
      .get();
  if (rows.isEmpty) return null;
  return (
    id: rows.single.read<int>('id'),
    key: rows.single.read<String>('sort_key'),
  );
}

/// Tombstones the live entries [entryUids] of the playlist; null when none
/// of them is live there.
Future<PlaylistRemoval?> removeEntriesWrite(
  AppDatabase db,
  String playlistUid,
  List<String> entryUids,
  int now,
) async {
  final playlistId = await livePlaylistId(db, playlistUid);
  if (playlistId == null || entryUids.isEmpty) return null;
  final rows = await db
      .customSelect(
        'SELECT uid FROM playlist_entries WHERE playlist_id = ? '
        'AND deleted_at IS NULL AND uid IN $jsonEach '
        'ORDER BY sort_key, uid',
        variables: [Variable.withInt(playlistId), jsonList(entryUids.toSet())],
      )
      .get();
  return _tombstone(db, playlistId, playlistUid, [
    for (final r in rows) r.read<String>('uid'),
  ], now);
}

/// Removes the live [entryUids] and deletes them for good in the caller's
/// transaction; returns the entries removed. Only rows that were live are
/// touched, so another call's pending (tombstoned) removal stays as it is.
Future<List<PlaylistEntryView>> removeEntriesNowWrite(
  AppDatabase db,
  String playlistUid,
  List<String> entryUids,
  int now,
) async {
  final playlistId = await livePlaylistId(db, playlistUid);
  if (playlistId == null || entryUids.isEmpty) return const [];
  // Read the live rows first: tombstoned rows no longer count as live.
  final views = await liveEntryViews(db, playlistId, entryUids);
  final removal = await removeEntriesWrite(db, playlistUid, entryUids, now);
  if (removal == null) return const [];
  await commitRemovalWrite(db, removal);
  final removed = removal.entryUids.toSet();
  return [
    for (final v in views)
      if (removed.contains(v.uid)) v,
  ];
}

/// Tombstones every live entry that repeats an earlier track of the playlist.
Future<PlaylistRemoval?> removeDuplicatesWrite(
  AppDatabase db,
  String playlistUid,
  int now,
) async {
  final playlistId = await livePlaylistId(db, playlistUid);
  if (playlistId == null) return null;
  final rows = await db
      .customSelect(
        'SELECT uid FROM (SELECT uid, sort_key, ROW_NUMBER() OVER '
        '(PARTITION BY track_id ORDER BY sort_key, uid) AS n '
        'FROM playlist_entries WHERE playlist_id = ? AND deleted_at IS NULL) '
        'WHERE n > 1 ORDER BY sort_key, uid',
        variables: [Variable.withInt(playlistId)],
      )
      .get();
  return _tombstone(db, playlistId, playlistUid, [
    for (final r in rows) r.read<String>('uid'),
  ], now);
}

Future<PlaylistRemoval?> _tombstone(
  AppDatabase db,
  int playlistId,
  String playlistUid,
  List<String> uids,
  int now,
) async {
  if (uids.isEmpty) return null;
  await db.customUpdate(
    'UPDATE playlist_entries SET deleted_at = ?, updated_at = ? '
    'WHERE playlist_id = ? AND deleted_at IS NULL AND uid IN $jsonEach',
    variables: [
      Variable.withInt(now),
      Variable.withInt(now),
      Variable.withInt(playlistId),
      jsonList(uids),
    ],
    updates: {db.playlistEntries},
    updateKind: UpdateKind.update,
  );
  await touchPlaylist(db, playlistId, now);
  return PlaylistRemoval(
    playlistUid: playlistUid,
    entryUids: uids,
    removedAt: now,
  );
}

/// Revives the tombstones of [removal] (same `deleted_at` only: an entry
/// removed again or purged since stays as it is). Returns how many came back.
Future<int> undoRemovalWrite(
  AppDatabase db,
  PlaylistRemoval removal,
  int now,
) async {
  final playlistId = await livePlaylistId(db, removal.playlistUid);
  if (playlistId == null || removal.entryUids.isEmpty) return 0;
  final revived = await db.customUpdate(
    'UPDATE playlist_entries SET deleted_at = NULL, updated_at = ? '
    'WHERE playlist_id = ? AND deleted_at = ? AND uid IN $jsonEach',
    variables: [
      Variable.withInt(now),
      Variable.withInt(playlistId),
      Variable.withInt(removal.removedAt),
      jsonList(removal.entryUids),
    ],
    updates: {db.playlistEntries},
    updateKind: UpdateKind.update,
  );
  if (revived > 0) await touchPlaylist(db, playlistId, now);
  return revived;
}

/// Deletes the tombstones of [removal] for good; no table update when none
/// is left.
Future<void> commitRemovalWrite(AppDatabase db, PlaylistRemoval removal) async {
  if (removal.entryUids.isEmpty) return;
  await writeNotifyingOnChange(
    db,
    'DELETE FROM playlist_entries WHERE deleted_at = ? AND uid IN $jsonEach',
    [Variable.withInt(removal.removedAt), jsonList(removal.entryUids)],
    {db.playlistEntries},
    UpdateKind.delete,
  );
}

/// Deletes every entry tombstone made at or before [before] (epoch ms), so a
/// removal nobody committed does not pin its track forever. Returns the
/// number of rows deleted; no table update when there were none.
Future<int> purgeRemovedPlaylistEntries(
  AppDatabase db, {
  required int before,
}) => writeNotifyingOnChange(
  db,
  'DELETE FROM playlist_entries WHERE deleted_at IS NOT NULL '
  'AND deleted_at <= ?',
  [Variable.withInt(before)],
  {db.playlistEntries},
  UpdateKind.delete,
);
