import '../../domain/playlists/playlist_models.dart';
import '../../domain/saved_queues/saved_queue_store.dart';

/// Longest a single read of a saved queue may take, so one stuck query cannot
/// leave a ▶ or a menu row waiting for ever.
const savedQueueReadLimit = Duration(seconds: 10);

/// Saved queue [uid] as it is right now, with its entries in played order;
/// null when it is gone or is not a saved queue. Actions read it at the moment
/// they run, never from what a page drew earlier.
Future<PlaylistDetail?> readSavedQueue(SavedQueueStore store, String uid) =>
    store.watchSavedQueue(uid).first.timeout(savedQueueReadLimit);
