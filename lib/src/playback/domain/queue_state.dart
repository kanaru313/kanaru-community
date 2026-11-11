import '../../media/domain/track_id.dart';
import 'repeat_mode.dart';

/// One queue entry: `queue_entries` row in memory. Identity is [entryId];
/// the same track may appear in several entries. Entries made by an edit and
/// not written yet carry a negative provisional id until the repository
/// replaces it with the real one.
class QueueItem {
  const QueueItem({
    required this.entryId,
    required this.trackId,
    required this.sortKey,
    this.shuffleKey,
  });

  final int entryId;
  final TrackId trackId;

  /// Fractional key of the order the user sees (shuffle off).
  final String sortKey;

  /// Fractional key of the shuffled order; null while shuffle is off.
  final String? shuffleKey;

  QueueItem withKeys({String? sortKey, String? shuffleKey}) => QueueItem(
    entryId: entryId,
    trackId: trackId,
    sortKey: sortKey ?? this.sortKey,
    shuffleKey: shuffleKey ?? this.shuffleKey,
  );

  QueueItem withoutShuffleKey() =>
      QueueItem(entryId: entryId, trackId: trackId, sortKey: sortKey);

  QueueItem withEntryId(int id) => QueueItem(
    entryId: id,
    trackId: trackId,
    sortKey: sortKey,
    shuffleKey: shuffleKey,
  );

  @override
  bool operator ==(Object other) =>
      other is QueueItem &&
      other.entryId == entryId &&
      other.trackId == trackId &&
      other.sortKey == sortKey &&
      other.shuffleKey == shuffleKey;

  @override
  int get hashCode => Object.hash(entryId, trackId, sortKey, shuffleKey);

  @override
  String toString() =>
      'QueueItem($entryId, track $trackId, $sortKey/$shuffleKey)';
}

const Object _keep = Object();

/// The queue in memory: [items] in play order (`shuffle_key` order while
/// [shuffled], else `sort_key` order) and the index of the loaded entry.
/// Immutable; every edit in `queue_logic.dart` returns a new state.
class QueueState {
  const QueueState({
    this.items = const [],
    this.current,
    this.shuffled = false,
    this.repeat = RepeatMode.off,
    this.playNextRun = 0,
  });

  final List<QueueItem> items;

  /// Index into [items] of the loaded entry; null when nothing is loaded.
  final int? current;
  final bool shuffled;
  final RepeatMode repeat;

  /// Entries right after the current one that came from "play next", as one
  /// contiguous run, so the next "play next" lands behind them.
  final int playNextRun;

  int get length => items.length;
  QueueItem? get currentItem => current == null ? null : items[current!];

  int indexOfEntry(int entryId) =>
      items.indexWhere((i) => i.entryId == entryId);

  /// Entry ids of the play-next run.
  Set<int> get playNextRunIds {
    final c = current;
    if (c == null || playNextRun == 0) return const {};
    return {for (var i = c + 1; i <= c + playNextRun; i++) items[i].entryId};
  }

  QueueState copyWith({
    List<QueueItem>? items,
    Object? current = _keep,
    bool? shuffled,
    RepeatMode? repeat,
    int? playNextRun,
  }) => QueueState(
    items: items ?? this.items,
    current: identical(current, _keep) ? this.current : current as int?,
    shuffled: shuffled ?? this.shuffled,
    repeat: repeat ?? this.repeat,
    playNextRun: playNextRun ?? this.playNextRun,
  );

  /// The state with [current] set and the play-next run recomputed as the
  /// entries of [runIds] that follow it without a gap.
  QueueState withCurrent(int? current, Set<int> runIds) => copyWith(
    current: current,
    playNextRun: runLength(items, current, runIds),
  );

  @override
  bool operator ==(Object other) {
    if (other is! QueueState ||
        other.current != current ||
        other.shuffled != shuffled ||
        other.repeat != repeat ||
        other.playNextRun != playNextRun ||
        other.items.length != items.length) {
      return false;
    }
    for (var i = 0; i < items.length; i++) {
      if (other.items[i] != items[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(items),
    current,
    shuffled,
    repeat,
    playNextRun,
  );

  @override
  String toString() =>
      'QueueState(${items.length} items, current $current, '
      'shuffled $shuffled, $repeat, run $playNextRun)';
}

/// How many entries of [runIds] follow [current] in [items] without a gap.
int runLength(List<QueueItem> items, int? current, Set<int> runIds) {
  if (current == null || runIds.isEmpty) return 0;
  var n = 0;
  for (var i = current + 1; i < items.length; i++) {
    if (!runIds.contains(items[i].entryId)) break;
    n++;
  }
  return n;
}
