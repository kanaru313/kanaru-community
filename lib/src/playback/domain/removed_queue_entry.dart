import '../../media/domain/track_id.dart';

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
