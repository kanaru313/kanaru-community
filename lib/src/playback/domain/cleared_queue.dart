import '../../media/domain/play_context.dart';
import '../../media/domain/track_id.dart';

/// The queue as it was when the user cleared it: the tracks in play order and
/// where the queue was started. Saved-queue history listens to this to keep
/// what was cleared.
class ClearedQueue {
  const ClearedQueue({required this.tracks, required this.context});

  final List<TrackId> tracks;
  final PlayContext? context;
}
