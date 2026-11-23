import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/state/database_providers.dart';
import '../../data/saved_queues/saved_queue_repository.dart';
import '../../domain/playlists/playlist_models.dart';
import '../../domain/saved_queues/saved_queue_store.dart';

/// The saved queue store. Tests override it with a fake.
final savedQueueStoreProvider = Provider<SavedQueueStore>(
  (ref) => SavedQueueRepository(ref.watch(appDatabaseProvider)),
);

/// Every saved queue, newest first. Each emission replaces the list; a failed
/// read keeps the last value and reports the error.
final savedQueuesProvider = StreamProvider.autoDispose<List<SavedQueueRow>>(
  (ref) => ref.watch(savedQueueStoreProvider).watchSavedQueues(),
);

/// One saved queue with its entries in played order. Null when [uid] does not
/// exist or is not a saved queue, also after it is deleted or dropped.
final savedQueueDetailProvider = StreamProvider.autoDispose
    .family<PlaylistDetail?, String>(
      (ref, uid) => ref.watch(savedQueueStoreProvider).watchSavedQueue(uid),
    );
