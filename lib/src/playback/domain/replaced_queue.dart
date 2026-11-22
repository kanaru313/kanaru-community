import '../../media/domain/play_context.dart';
import '../../media/domain/track_id.dart';

/// A non-empty queue the user just lost, by clearing it or by starting a
/// different one: what it held and where it was started. Saved-queue history
/// listens to this to keep it.
class ReplacedQueue {
  const ReplacedQueue({
    required this.tracks,
    required this.userOrder,
    required this.context,
    this.next,
  });

  /// The old queue in play order (shuffled order when shuffle was on).
  final List<TrackId> tracks;

  /// The same tracks in the order the user sees (`sort_key` order).
  final List<TrackId> userOrder;

  final PlayContext? context;

  /// The tracks passed to the replacing `playTracks`; null for a clear.
  final List<TrackId>? next;

  bool get isClear => next == null;
}
