import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/state/database_providers.dart';
import '../../data/saved_queues/saved_queue_repository.dart';
import '../../domain/saved_queues/saved_queue_store.dart';

/// The saved queue store. Tests override it with a fake.
final savedQueueStoreProvider = Provider<SavedQueueStore>(
  (ref) => SavedQueueRepository(ref.watch(appDatabaseProvider)),
);
