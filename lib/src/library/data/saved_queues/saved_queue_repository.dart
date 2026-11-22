import '../../../database/database.dart';
import '../../domain/playlists/playlist_models.dart';
import '../../domain/saved_queues/saved_queue_store.dart';
import '../browse/throttled_query.dart';
import 'saved_queue_reads.dart';
import 'saved_queue_writes.dart';

/// [SavedQueueStore] on the `playlists` / `playlist_entries` tables; [now] is
/// injectable for tests.
class SavedQueueRepository implements SavedQueueStore {
  SavedQueueRepository(this._db, {int Function()? now})
    : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch);

  final AppDatabase _db;
  final int Function() _now;

  @override
  Stream<List<SavedQueueRow>> watchSavedQueues() => throttledQuery(
    _db,
    // `tracks`: a scan flips a track to missing, which changes missingCount.
    {_db.playlists, _db.playlistEntries, _db.tracks},
    () => loadSavedQueues(_db),
    equals: _sameRows,
  );

  @override
  Stream<PlaylistDetail?> watchSavedQueue(String uid) => throttledQuery(
    _db,
    {
      _db.playlists,
      _db.playlistEntries,
      _db.tracks,
      _db.trackArtists,
      _db.playStats,
    },
    () => loadSavedQueueDetail(_db, uid),
    equals: (a, b) => a == b,
  );

  @override
  Future<bool> touch(String uid) => touchSavedQueue(_db, uid, now: _now());

  @override
  Future<bool> deleteSavedQueue(String uid) => deleteSavedQueueRow(_db, uid);

  @override
  Future<int> removeMissingFromSavedQueue(String uid) =>
      removeMissingEntries(_db, uid);
}

bool _sameRows(List<SavedQueueRow> a, List<SavedQueueRow> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
