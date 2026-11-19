import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../playlists/playlist_sql.dart';

/// Hard-deletes saved queue [uid]; entries cascade. A uid of any other kind
/// of playlist deletes nothing. Notifies only when a row went.
Future<bool> deleteSavedQueueRow(AppDatabase db, String uid) async =>
    await writeNotifyingOnChange(
      db,
      "DELETE FROM playlists WHERE uid = ? AND kind = 'queue'",
      [Variable.withString(uid)],
      {db.playlists, db.playlistEntries, db.customCovers},
      UpdateKind.delete,
    ) >
    0;

/// Hard-deletes the entries of saved queue [uid] whose track is `missing` or
/// `hidden` at the time of the call, and returns how many went. No tombstone:
/// a saved queue is not synced. Does not touch `saved_at` or `updated_at`.
Future<int> removeMissingEntries(AppDatabase db, String uid) =>
    writeNotifyingOnChange(
      db,
      'DELETE FROM playlist_entries WHERE playlist_id = '
      "(SELECT id FROM playlists WHERE uid = ? AND kind = 'queue') "
      'AND track_id IN (SELECT id FROM tracks '
      "WHERE status IN ('missing', 'hidden'))",
      [Variable.withString(uid)],
      {db.playlistEntries},
      UpdateKind.delete,
    );
