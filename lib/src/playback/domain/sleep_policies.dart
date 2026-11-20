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
  // Not const: every start installs its own instance, so a stop event can be
  // matched to the install it belongs to.
  EndOfTrackPolicy();

  @override
  bool stopsAfterCurrent(QueueState queue, int repeatTimes) => true;

  @override
  void trackEnded() {}
}

/// Stops after the last entry in play order, whatever repeat says.
class EndOfQueuePolicy implements SleepStopPolicy {
  // Not const, see [EndOfTrackPolicy].
  EndOfQueuePolicy();

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
    // One step is enough to decide; the walk reports what it found missing.
    final walk = albumRunFrom(queue, albumOf, limit: 2);
    final ahead = _afterNext(queue);
    // Ask for the pair and the entry after it together, so moving on inside
    // an album finds the next pair already known.
    final missing = [
      ...walk.unknown,
      if (ahead != null && albumOf(ahead) is AlbumUnknown) ahead,
    ];
    if (missing.isNotEmpty) want(missing);
    return walk.length <= 1;
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

/// The entries from the current one on, in play order, that share its album.
class AlbumWalk {
  const AlbumWalk({
    required this.entries,
    required this.unknown,
    required this.capped,
  });

  /// The current entry and the ones after it of the same album; empty when
  /// nothing is current.
  final List<QueueItem> entries;

  /// Tracks whose album was asked for and is not known yet, in the order the
  /// walk met them.
  final List<TrackId> unknown;

  /// The walk stopped at its limit with somewhere left to go: the run is at
  /// least this long.
  final bool capped;

  int get length => entries.length;
}

/// Walks the play order from the current entry while the next entry has the
/// same album ([keyOf] answers per track), the way a sleep timer that stops
/// at the end of the album sees the queue. It stops at an entry of another
/// album, at one whose album is unknown ([AlbumWalk.unknown]), at a track
/// without an album (an album of its own), where Next has nowhere to go and
/// at the end of a reshuffled pass. It never goes past one queue length (a
/// queue that is one album under repeat all wraps forever) or [limit] entries.
AlbumWalk albumRunFrom(
  QueueState queue,
  AlbumLookupResult Function(TrackId id) keyOf, {
  int? limit,
}) {
  final items = queue.items;
  final start = queue.current;
  if (start == null || start < 0 || start >= items.length) {
    return const AlbumWalk(entries: [], unknown: [], capped: false);
  }
  final cap = limit == null || limit > items.length ? items.length : limit;
  final entries = [items[start]];
  final unknown = <TrackId>[];
  void lookedUp(TrackId id, AlbumLookupResult r) {
    if (r is AlbumUnknown && !unknown.contains(id)) unknown.add(id);
  }

  var at = start;
  AlbumLookupResult? first;
  while (entries.length < cap) {
    final next = neighboursOf(items, at, queue.repeat).next;
    if (next is! KnownNeighbour) break;
    // Both ends of the pair are looked up before deciding, so every missing
    // key of the step is reported together.
    final a = first ??= keyOf(entries.first.trackId);
    if (entries.length == 1) lookedUp(entries.first.trackId, a);
    final b = keyOf(next.item.trackId);
    lookedUp(next.item.trackId, b);
    if (a is! AlbumKnown || a.key == null) break;
    if (b is! AlbumKnown || b.key != a.key) break;
    entries.add(next.item);
    at = nextIndex(
      QueueState(items: items, current: at, repeat: queue.repeat),
      auto: false,
    )!;
  }
  final atLimit =
      entries.length >= cap &&
      neighboursOf(items, at, queue.repeat).next is KnownNeighbour;
  return AlbumWalk(entries: entries, unknown: unknown, capped: atLimit);
}
