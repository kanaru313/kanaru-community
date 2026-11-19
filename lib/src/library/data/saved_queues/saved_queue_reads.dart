import '../../../database/database.dart';
import '../../domain/playlists/playlist_models.dart';
import '../../domain/saved_queues/saved_queue_store.dart';
import '../playlists/playlist_reads.dart';

/// Saved queues, newest first. Counts, durations and covers come from
/// [playlistStatsSql] (shared with the playlist list); the rest is specific
/// to a queue. `missingCount` counts distinct tracks that are `missing` or
/// `hidden` now.
const _savedQueuesSql =
    '''
SELECT p.uid, p.name, p.description, p.created_at, p.updated_at,
  COALESCE(p.saved_at, p.created_at) AS saved_at, p.context_kind, p.context_ref, p.context_label,
$playlistStatsSql,
  (SELECT COUNT(DISTINCT e.track_id) FROM playlist_entries e
    JOIN tracks t ON t.id = e.track_id
    WHERE e.playlist_id = p.id AND e.deleted_at IS NULL
      AND t.status IN ('missing', 'hidden')) AS missing
FROM playlists p
WHERE p.deleted_at IS NULL AND p.kind = 'queue'
ORDER BY COALESCE(p.saved_at, p.created_at) DESC, p.id DESC
''';

/// Every saved queue, newest first.
Future<List<SavedQueueRow>> loadSavedQueues(AppDatabase db) async {
  final rows = await db.customSelect(_savedQueuesSql).get();
  return [
    for (final r in rows)
      SavedQueueRow(
        summary: summaryOfRow(
          r,
          savedQueue: SavedQueueInfo(
            savedAt: r.read<int>('saved_at'),
            contextKind: r.readNullable<String>('context_kind'),
            contextRef: r.readNullable<String>('context_ref'),
            contextLabel: r.readNullable<String>('context_label'),
          ),
        ),
        missingCount: r.read<int>('missing'),
      ),
  ];
}

/// Saved queue [uid] with its entries, or null when [uid] is not a saved queue
/// (a normal playlist uid included).
Future<PlaylistDetail?> loadSavedQueueDetail(AppDatabase db, String uid) async {
  final detail = await loadDetail(db, uid);
  return detail?.summary.savedQueue == null ? null : detail;
}
