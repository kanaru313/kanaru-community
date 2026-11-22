import '../../database/app_database.dart';
import '../../database/saved_queue_store.dart';
import '../domain/replaced_queue.dart';

/// Writes the queues the player lost as saved queues (`playlists` rows of kind
/// `queue`). Turns the play context into plain strings; the database layer
/// does the filtering, matching and pruning.
class SavedQueueWriter {
  SavedQueueWriter(this._db);

  final AppDatabase _db;

  /// Saves [e] (or moves the saved queue that already holds it to the front).
  Future<SavedQueueOutcome> save(ReplacedQueue e, int now) {
    final context = e.context;
    return recordSavedQueue(
      _db,
      trackIds: [for (final t in e.tracks) t.value],
      userOrderIds: [for (final t in e.userOrder) t.value],
      contextKind: context?.kind.name,
      contextRef: context?.ref,
      contextLabel: context?.label,
      now: now,
    );
  }
}
