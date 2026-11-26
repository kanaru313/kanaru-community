/// Ports the write tools use. Like the read ports they speak ids and plain
/// values, never Flutter or Riverpod types; `data/tool_env_write.dart`
/// implements them on the player and the playlist store.
library;

import '../conversation/parts.dart';
import 'tool_env.dart';

abstract interface class PlaybackWritePort {
  /// Replaces the queue with [trackIds] (already visible) and plays the one
  /// at [startIndex]. Returns the queue it replaced, null when it was empty.
  Future<ReplacedQueueSnapshot?> play(
    List<int> trackIds, {
    required int startIndex,
    required String contextLabel,
  });

  /// Adds [trackIds] after the current entry ([next]) or at the end. Returns
  /// whether the queue was empty, so playback started.
  Future<({bool startedPlayback})> queue(
    List<int> trackIds, {
    required bool next,
  });

  /// Removes the queue entries [entryIds]; returns exactly those removed.
  Future<List<QueueEntryRef>> removeEntries(List<int> entryIds);
}

abstract interface class PlaylistsWritePort {
  /// Creates a playlist holding [trackIds] (already visible) and returns its
  /// id and how many tracks it holds. Once the playlist exists this never
  /// throws: a failed read-back gives a null `id` (and the requested count),
  /// so the caller reports success and the model does not create it twice.
  Future<({int? id, int count})> create(String name, List<int> trackIds);

  /// Adds [trackIds] to playlist [playlistId]; null when it is not a
  /// writable playlist. `addedTrackIds` are the tracks that went in,
  /// `skipped` the ones the playlist already held.
  Future<({String name, List<int> addedTrackIds, int skipped})?> add(
    int playlistId,
    List<int> trackIds,
  );

  /// Removes entries [entryIds] of playlist [playlistId]; null when it is not
  /// a writable playlist, else exactly the entries removed (entry id and the
  /// track it held).
  Future<({String name, List<QueueEntryRef> removed})?> removeEntries(
    int playlistId,
    List<int> entryIds,
  );
}
