import 'dart:convert';

import 'package:drift/drift.dart';

import '../foundation/ids/ulid.dart';
import '../foundation/ordering/fractional_keys.dart';
import 'app_database.dart';
import 'tables.dart';

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

/// Inserts a live playlist row and returns its id. [kind], [savedAt] and the
/// `context*` columns are for saved queues (`PlaylistKind.queue`); the
/// defaults insert a normal playlist.
Future<int> insertPlaylistRow(
  AppDatabase db, {
  required String name,
  String description = '',
  required int now,
  int? originSourceId,
  String? originLocator,
  String? kind,
  int? savedAt,
  String? contextKind,
  String? contextRef,
  String? contextLabel,
}) async {
  final uid = newUlid();
  final id = await db
      .into(db.playlists)
      .insert(
        PlaylistsCompanion.insert(
          uid: uid,
          name: name,
          kind: Value(kind),
          description: Value(description),
          originSourceId: Value(originSourceId),
          originLocator: Value(originLocator),
          savedAt: Value(savedAt),
          contextKind: Value(contextKind),
          contextRef: Value(contextRef),
          contextLabel: Value(contextLabel),
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
