import '../../media/domain/library_keys.dart';
import '../../media/domain/track_id.dart';
import 'queue_logic.dart';
import 'queue_neighbours.dart';
import 'sleep_stop_policy.dart';
import 'sleep_timer_state.dart';

/// What is known about the album of a track.
sealed class AlbumLookupResult {
  const AlbumLookupResult();
}

/// Not loaded yet: the answer comes later.
class AlbumUnknown extends AlbumLookupResult {
  const AlbumUnknown();
}

/// Loaded. [key] is null for a track without an album, which is an album of
/// its own.
class AlbumKnown extends AlbumLookupResult {
  const AlbumKnown(this.key);

  final AlbumKey? key;
}

/// Stops after every entry.
class EndOfTrackPolicy implements SleepStopPolicy {
  const EndOfTrackPolicy();

  @override
  bool stopsAfterCurrent(QueueState queue, int repeatTimes) => true;

  @override
  void trackEnded() {}
}

/// Stops after the last entry in play order, whatever repeat says.
class EndOfQueuePolicy implements SleepStopPolicy {
  const EndOfQueuePolicy();

  @override
  bool stopsAfterCurrent(QueueState queue, int repeatTimes) {
    final current = queue.current;
    return current != null && current == queue.items.length - 1;
  }

  @override
  void trackEnded() {}
}

/// Stops after the [left]-th entry that ends by itself, the current one
/// included. [left] changes with the user's +/- and with every natural end.
class TracksPolicy implements SleepStopPolicy {
  TracksPolicy(int left)
    : left = left.clamp(sleepTimerMinTracks, sleepTimerMaxTracks);

  int left;

  @override
  bool stopsAfterCurrent(QueueState queue, int repeatTimes) => left <= 1;

  @override
  void trackEnded() {
    if (left > 1) left--;
  }
}

/// Stops after the last entry of the current album in play order. The album
/// of an entry is asked through [albumOf]; ids it does not know yet are
/// passed to [want] so the owner loads them and calls the player again.
///
/// Safe by default: a key that is not known yet, no entry after the current
/// one, a reshuffled pass that ends here, and a track without an album all
/// stop.
class EndOfAlbumPolicy implements SleepStopPolicy {
  EndOfAlbumPolicy({required this.albumOf, required this.want});

  final AlbumLookupResult Function(TrackId id) albumOf;
  final void Function(List<TrackId> ids) want;

  @override
  bool stopsAfterCurrent(QueueState queue, int repeatTimes) {
    final current = queue.current;
    if (current == null || current >= queue.items.length) return true;
    final next = neighboursOf(queue.items, current, queue.repeat).next;
    if (next is! KnownNeighbour) return true;
    final currentId = queue.items[current].trackId;
    final nextId = next.item.trackId;
    final a = albumOf(currentId);
    final b = albumOf(nextId);
    final ahead = _afterNext(queue);
    // Ask for the pair and the entry after it together, so moving on inside
    // an album finds the next pair already known.
    final missing = [
      if (a is AlbumUnknown) currentId,
      if (b is AlbumUnknown) nextId,
      if (ahead != null && albumOf(ahead) is AlbumUnknown) ahead,
    ];
    if (missing.isNotEmpty) want(missing);
    if (a is! AlbumKnown || b is! AlbumKnown) return true;
    final key = a.key;
    if (key == null) return true;
    return key != b.key;
  }

  /// The track two steps on in play order, or null when none is known.
  TrackId? _afterNext(QueueState queue) {
    final nextIdx = nextIndex(queue, auto: false);
    if (nextIdx == null) return null;
    final after = neighboursOf(queue.items, nextIdx, queue.repeat).next;
    return after is KnownNeighbour ? after.item.trackId : null;
  }

  @override
  void trackEnded() {}
}
