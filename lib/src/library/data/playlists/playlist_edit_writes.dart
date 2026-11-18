import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../../domain/playlists/playlist_models.dart';
import '../../domain/playlists/playlist_text_rules.dart';

/// Cleaned name; [ArgumentError] when empty or too long (a typed name is
/// rejected, never cut).
String checkedPlaylistName(String raw) {
  if (checkPlaylistName(raw) != null) {
    throw ArgumentError.value(raw, 'name', 'empty or too long');
  }
  return cleanPlaylistName(raw);
}

/// Cleaned description; [ArgumentError] when too long.
String checkedPlaylistDescription(String raw) {
  if (isPlaylistDescriptionTooLong(raw)) {
    throw ArgumentError.value(raw, 'description', 'too long');
  }
  return cleanPlaylistDescription(raw);
}

/// Writes already cleaned [name] / [description] when they differ, in the
/// caller's transaction. Writes (and notifies) nothing when unchanged.
Future<PlaylistUpdate> updatePlaylistWrite(
  AppDatabase db,
  String uid, {
  required String? name,
  required String? description,
  required int now,
}) async {
  final rows = await db
      .customSelect(
        'SELECT id, name, description FROM playlists '
        'WHERE uid = ? AND deleted_at IS NULL '
        "AND (kind IS NULL OR kind = 'favorites')",
        variables: [Variable.withString(uid)],
      )
      .get();
  if (rows.isEmpty) return PlaylistUpdate.gone;
  final row = rows.single;
  final newName = name ?? row.read<String>('name');
  final newDescription = description ?? row.read<String>('description');
  if (newName == row.read<String>('name') &&
      newDescription == row.read<String>('description')) {
    return PlaylistUpdate.unchanged;
  }
  await db.customUpdate(
    'UPDATE playlists SET name = ?, description = ?, '
    'updated_at = MAX(?, updated_at + 1) '
    'WHERE id = ?',
    variables: [
      Variable.withString(newName),
      Variable.withString(newDescription),
      Variable.withInt(now),
      Variable.withInt(row.read<int>('id')),
    ],
    updates: {db.playlists},
    updateKind: UpdateKind.update,
  );
  return PlaylistUpdate.saved;
}
