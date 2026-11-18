import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../../../foundation/ids/ulid.dart';
import '../../../foundation/ordering/fractional_keys.dart';

/// `IN` operand over one JSON array parameter (see [jsonList]): no SQLite
/// variable limit, whatever the number of values.
const jsonEach = '(SELECT value FROM json_each(?))';

/// A JSON array of [values], bound as the single parameter of [jsonEach].
Variable<String> jsonList(Iterable<Object> values) =>
    Variable.withString(jsonEncode(values.toList()));

/// Largest `sort_key` of the playlist over **all** its rows, tombstones
/// included. Appending after it never reuses the key of a pending removal.
Future<String?> maxSortKey(AppDatabase db, int playlistId) async {
  final row = await db
      .customSelect(
        'SELECT MAX(sort_key) AS k FROM playlist_entries WHERE playlist_id = ?',
        variables: [Variable.withInt(playlistId)],
      )
      .getSingle();
  return row.readNullable<String>('k');
}

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

/// Appends one entry per id of [trackIds] (repeats kept, any track status)
/// after every existing row of the playlist, in one statement. Does not touch
/// `playlists.updated_at`. Runs inside the caller's transaction.
Future<void> appendEntries(
  AppDatabase db,
  int playlistId,
  List<int> trackIds,
  int now,
) async {
  if (trackIds.isEmpty) return;
  final keys = generateNKeysBetween(
    await maxSortKey(db, playlistId),
    null,
    trackIds.length,
  );
  final rows = [
    for (var i = 0; i < trackIds.length; i++)
      {'u': newUlid(), 't': trackIds[i], 'k': keys[i]},
  ];
  await db.customUpdate(
    'INSERT INTO playlist_entries '
    '(uid, playlist_id, track_id, sort_key, added_at, updated_at) '
    "SELECT json_extract(value, '\$.u'), ?, json_extract(value, '\$.t'), "
    "json_extract(value, '\$.k'), ?, ? FROM json_each(?)",
    variables: [
      Variable.withInt(playlistId),
      Variable.withInt(now),
      Variable.withInt(now),
      jsonList(rows),
    ],
    updates: {db.playlistEntries},
    updateKind: UpdateKind.insert,
  );
}

/// Inserts a live playlist row and returns its id.
Future<int> insertPlaylistRow(
  AppDatabase db, {
  required String name,
  String description = '',
  required int now,
  int? originSourceId,
  String? originLocator,
}) async {
  final uid = newUlid();
  final id = await db
      .into(db.playlists)
      .insert(
        PlaylistsCompanion.insert(
          uid: uid,
          name: name,
          description: Value(description),
          originSourceId: Value(originSourceId),
          originLocator: Value(originLocator),
          createdAt: now,
          updatedAt: now,
        ),
      );
  return id;
}

/// Uid of the live playlist row [id].
Future<String> playlistUidOf(AppDatabase db, int id) async =>
    (await db
            .customSelect(
              'SELECT uid FROM playlists WHERE id = ?',
              variables: [Variable.withInt(id)],
            )
            .getSingle())
        .read<String>('uid');

/// Id of the live user playlist [uid] (normal, imported or Favorites), or
/// null. Rows of other kinds (mood, queue) count as gone for every write.
Future<int?> livePlaylistId(AppDatabase db, String uid) async {
  final rows = await db
      .customSelect(
        'SELECT id FROM playlists WHERE uid = ? AND deleted_at IS NULL '
        "AND (kind IS NULL OR kind = 'favorites')",
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
