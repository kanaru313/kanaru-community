import '../../media/domain/play_context.dart';
import '../../media/domain/track_id.dart';

/// What the library and other modules may ask the player to do. The player
/// controller implements this and more (queue edits, seek...) behind it.
/// All calls go through one serial command queue in the implementation, in
/// call order, together with media-control commands.
abstract interface class PlaybackCommands {
  /// Replaces the queue with [tracks] (new entries, in order) and starts
  /// `tracks[startIndex]`. [shuffle] = queue order shuffled, the started
  /// track first. Throws [ArgumentError] (no state change) when [tracks] is
  /// empty or [startIndex] is out of range.
  Future<void> playTracks(
    List<TrackId> tracks, {
    int startIndex = 0,
    bool shuffle = false,
    required PlayContext context,
  });

  /// Inserts new entries right after the current one, keeping their order;
  /// consecutive calls queue up behind each other (a "play next run"). With
  /// an empty queue behaves like `playTracks(tracks, context: queue)`.
  Future<void> playNext(List<TrackId> tracks);

  /// Appends new entries at the end. Same empty-queue rule.
  Future<void> enqueue(List<TrackId> tracks);
}
