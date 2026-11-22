import '../playlists/playlist_models.dart';

/// One saved queue in the list: its summary (`summary.savedQueue` is set) and
/// how many of its distinct tracks are no longer available.
class SavedQueueRow {
  const SavedQueueRow({required this.summary, required this.missingCount});

  final PlaylistSummary summary;

  /// Distinct tracks that are missing or hidden now.
  final int missingCount;

  @override
  bool operator ==(Object other) =>
      other is SavedQueueRow &&
      other.summary == summary &&
      other.missingCount == missingCount;

  @override
  int get hashCode => Object.hash(summary, missingCount);
}

/// Reads and edits the saved queues (`playlists.kind = 'queue'`). Writing one
/// is done by the player (`recordSavedQueue`), never here. Implemented in
/// `data/saved_queues/`. Database failures propagate.
abstract interface class SavedQueueStore {
  /// Every saved queue, newest first; emits again after any change to them.
  Stream<List<SavedQueueRow>> watchSavedQueues();

  /// Saved queue [uid] with its entries in played order; null when it does not
  /// exist or is not a saved queue (also after it is deleted).
  Stream<PlaylistDetail?> watchSavedQueue(String uid);

  /// Moves [uid] to the front of the list. Call right before playing it.
  /// False when it is gone.
  Future<bool> touch(String uid);

  /// Deletes saved queue [uid]; false when it is gone or not a saved queue.
  Future<bool> deleteSavedQueue(String uid);

  /// Removes the entries whose track is missing or hidden **now** (read at
  /// call time) and returns how many entries went.
  Future<int> removeMissingFromSavedQueue(String uid);
}
