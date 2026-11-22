import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/state/database_providers.dart';
import '../data/saved_queue_writer.dart';
import 'saved_queue_recorder.dart';

/// Keeps the queues the player replaces or clears. Its own provider so the
/// exit flush can wait for it without building the player.
final savedQueueRecorderProvider = Provider<SavedQueueRecorder>((ref) {
  final recorder = SavedQueueRecorder(
    writer: SavedQueueWriter(ref.read(appDatabaseProvider)),
    now: () => DateTime.now().millisecondsSinceEpoch,
  );
  // Stopped with its own provider, so a rebuilt player keeps saving.
  ref.onDispose(recorder.dispose);
  return recorder;
});
