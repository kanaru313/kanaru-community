import 'queue_state.dart';

/// How many entries each "clean up" choice would remove.
class CleanupCounts {
  const CleanupCounts({
    required this.duplicates,
    required this.before,
    required this.after,
    required this.allButCurrent,
  });

  final int duplicates;
  final int before;
  final int after;
  final int allButCurrent;

  @override
  bool operator ==(Object other) =>
      other is CleanupCounts &&
      other.duplicates == duplicates &&
      other.before == before &&
      other.after == after &&
      other.allButCurrent == allButCurrent;

  @override
  int get hashCode => Object.hash(duplicates, before, after, allButCurrent);

  @override
  String toString() =>
      'CleanupCounts(duplicates $duplicates, before $before, after $after, '
      'all but current $allButCurrent)';
}

/// Entries of a track that appears again: the first one in play order stays,
/// except that the current entry always stays and stands for its track (every
/// other entry of the current track is a duplicate, also one before it).
Set<int> duplicateEntryIds(QueueState s) {
  final currentTrack = s.currentItem?.trackId;
  final seen = <int>{};
  final out = <int>{};
  for (final item in s.items) {
    if (item.entryId == s.currentItem?.entryId) continue;
    if (item.trackId == currentTrack || !seen.add(item.trackId.value)) {
      out.add(item.entryId);
    }
  }
  return out;
}

/// Entries before the current one (played).
Set<int> entriesBefore(QueueState s) {
  final c = s.current;
  if (c == null) return const {};
  return {for (var i = 0; i < c; i++) s.items[i].entryId};
}

/// Entries after the current one (upcoming).
Set<int> entriesAfter(QueueState s) {
  final c = s.current;
  if (c == null) return const {};
  return {for (var i = c + 1; i < s.length; i++) s.items[i].entryId};
}

/// Every entry except the current one (all of them with nothing current).
Set<int> allButCurrent(QueueState s) => {
  for (final i in s.items)
    if (i.entryId != s.currentItem?.entryId) i.entryId,
};

CleanupCounts cleanupCounts(QueueState s) => CleanupCounts(
  duplicates: duplicateEntryIds(s).length,
  before: entriesBefore(s).length,
  after: entriesAfter(s).length,
  allButCurrent: allButCurrent(s).length,
);
