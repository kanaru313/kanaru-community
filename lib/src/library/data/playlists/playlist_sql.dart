import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../../../database/playlist_entry_sql.dart';

// Shared entry helpers live in `database/` (the saved queue store needs them);
// re-exported so library callers keep one import.
export '../../../database/playlist_entry_sql.dart';

/// Sets `updated_at` of the playlist to [now], but strictly above its previous
/// value (two writes in one millisecond, or a clock step back, still order).
/// Call after a real change only.
Future<void> touchPlaylist(AppDatabase db, int playlistId, int now) =>
    db.customUpdate(
      'UPDATE playlists SET updated_at = MAX(?, updated_at + 1) WHERE id = ?',
      variables: [Variable.withInt(now), Variable.withInt(playlistId)],
      updates: {db.playlists},
      updateKind: UpdateKind.update,
    );

/// `WHERE` predicate (unqualified `playlists` columns) of a live, writable
/// playlist: normal, imported or Favorites. Rows of other kinds (mood, queue)
/// count as gone. Shared by every guard so UI and AI paths cannot drift.
const writablePlaylistPredicate =
    "deleted_at IS NULL AND (kind IS NULL OR kind = 'favorites')";

/// Id of the live user playlist [uid] (normal, imported or Favorites), or
/// null. Rows of other kinds (mood, queue) count as gone for every write.
Future<int?> livePlaylistId(AppDatabase db, String uid) async {
  final rows = await db
      .customSelect(
        'SELECT id FROM playlists WHERE uid = ? AND $writablePlaylistPredicate',
        variables: [Variable.withString(uid)],
      )
      .get();
  return rows.isEmpty ? null : rows.single.read<int>('id');
}

/// uid of every id in [ids] that has a `tracks` row, any status.
Future<Map<int, String>> trackUidsById(
  AppDatabase db,
  Iterable<int> ids,
) async {
  final list = ids.toSet();
  if (list.isEmpty) return const {};
  final rows = await db
      .customSelect(
        'SELECT id, uid FROM tracks WHERE id IN $jsonEach',
        variables: [jsonList(list)],
      )
      .get();
  return {for (final r in rows) r.read<int>('id'): r.read<String>('uid')};
}

/// Throws [ArgumentError] (before anything is written) when an id of [ids]
/// has no `tracks` row.
Future<void> requireTracksExist(AppDatabase db, Iterable<int> ids) async {
  final known = await trackUidsById(db, ids);
  final unknown = {
    for (final id in ids)
      if (!known.containsKey(id)) id,
  };
  if (unknown.isNotEmpty) {
    throw ArgumentError.value(unknown.toList(), 'tracks', 'no such track');
  }
}

/// Runs a delete / update without notifying, then notifies [tables] only when
/// rows changed, so a no-op wakes no watcher.
Future<int> writeNotifyingOnChange(
  AppDatabase db,
  String sql,
  List<Variable> variables,
  Set<TableInfo> tables,
  UpdateKind kind,
) async {
  final n = await db.customUpdate(sql, variables: variables);
  if (n > 0) {
    db.notifyUpdates({
      for (final t in tables) TableUpdate(t.actualTableName, kind: kind),
    });
  }
  return n;
}
