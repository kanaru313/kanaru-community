import '../../media/domain/track_id.dart';
import 'replaced_queue.dart';

/// A queue entry a tool removed: the entry and the track it played.
class RemovedQueueEntry {
  const RemovedQueueEntry({required this.entryId, required this.trackId});

  final int entryId;
  final TrackId trackId;

  @override
  bool operator ==(Object other) =>
      other is RemovedQueueEntry &&
      other.entryId == entryId &&
      other.trackId == trackId;

  @override
  int get hashCode => Object.hash(entryId, trackId);

  @override
  String toString() => 'RemovedQueueEntry($entryId, $trackId)';
}

/// What `PlayerController.playTracksForTool` returns: the queue it replaced
/// (null when it was empty), the position that was current in play order
/// (null when nothing was loaded) and whether shuffle was on, so `tracks` of
/// `previous` is in play order.
typedef ToolPlayResult = ({
  ReplacedQueue? previous,
  int? previousIndex,
  bool shuffled,
});
