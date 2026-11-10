import '../../media/domain/track_id.dart';
import 'queue_edit.dart';
import 'queue_keys.dart';
import 'queue_state.dart';
import 'repeat_mode.dart';
import 'undo_token.dart';

export 'queue_cleanup.dart';
export 'queue_edit.dart';
export 'queue_keys.dart' show KeyGen;
export 'queue_shuffle.dart';
export 'queue_state.dart';
export 'queue_undo.dart';
export 'repeat_mode.dart';
export 'undo_token.dart';

/// Pure queue operations. Every function returns a [QueueEdit]: the next
/// state plus the rows to write. Nothing here touches the database or the
/// player.

/// Inserts new entries for [ids] right after the current one, behind the
/// entries already queued by earlier "play next" calls (the run). With no
/// current entry they go to the front.
QueueEdit insertPlayNext(QueueState s, List<TrackId> ids, KeyGen keys) {
  if (ids.isEmpty) return QueueEdit.none(s);
  final c = s.current;
  final pos = c == null ? 0 : c + 1 + s.playNextRun;
  final sortLeft = pos > 0 ? s.items[pos - 1].sortKey : null;
  final edit = _insert(s, pos, ids, sortLeft, keys);
  return c == null
      ? edit
      : _withRun(
          edit,
          edit.next.copyWith(playNextRun: s.playNextRun + ids.length),
        );
}

/// Appends new entries for [ids] at the end of the play order.
QueueEdit enqueue(QueueState s, List<TrackId> ids, KeyGen keys) {
  if (ids.isEmpty) return QueueEdit.none(s);
  String? maxSort;
  for (final i in s.items) {
    if (maxSort == null || i.sortKey.compareTo(maxSort) > 0) {
      maxSort = i.sortKey;
    }
  }
  return _insert(s, s.length, ids, maxSort, keys);
}

QueueEdit _withRun(QueueEdit e, QueueState next) =>
    QueueEdit(next: next, inserted: e.inserted, rekeyed: e.rekeyed);

/// Inserts [ids] at play-order index [pos]. [sortLeft] is the sort key the
/// new entries must follow; they get sort keys between it and the next larger
/// sort key, so they sit right behind it whatever the shuffle order is.
QueueEdit _insert(
  QueueState s,
  int pos,
  List<TrackId> ids,
  String? sortLeft,
  KeyGen keys,
) {
  final n = ids.length;
  final order = s.items;
  final KeySlot slot;
  final List<String> sortKeys;
  final List<String?> shuffleKeys;
  final Map<int, KeyChange> rekeyed = {};
  if (s.shuffled) {
    slot = placeKeys(order, pos, n, (i) => i.shuffleKey, keys);
    String? right;
    for (final i in order) {
      final k = i.sortKey;
      if ((sortLeft == null || k.compareTo(sortLeft) > 0) &&
          (right == null || k.compareTo(right) < 0)) {
        right = k;
      }
    }
    sortKeys = keys.betweenN(sortLeft, right, n);
    shuffleKeys = slot.keys;
    slot.rekeyed.forEach(
      (id, k) => rekeyed[id] = (sortKey: null, shuffleKey: k),
    );
  } else {
    slot = placeKeys(order, pos, n, (i) => i.sortKey, keys);
    sortKeys = slot.keys;
    shuffleKeys = List.filled(n, null);
    slot.rekeyed.forEach(
      (id, k) => rekeyed[id] = (sortKey: k, shuffleKey: null),
    );
  }
  var firstId = -1;
  for (final i in order) {
    if (i.entryId <= firstId) firstId = i.entryId - 1;
  }
  final fresh = [
    for (var i = 0; i < n; i++)
      QueueItem(
        entryId: firstId - i,
        trackId: ids[i],
        sortKey: sortKeys[i],
        shuffleKey: shuffleKeys[i],
      ),
  ];
  final merged = [
    ...applyRekeys(order.sublist(0, pos), rekeyed),
    ...fresh,
    ...applyRekeys(order.sublist(pos), rekeyed),
  ];
  final c = s.current;
  return QueueEdit(
    next: s.copyWith(items: merged, current: c != null && pos <= c ? c + n : c),
    inserted: fresh,
    rekeyed: rekeyed,
  );
}

/// [items] with the key changes of [changes] applied.
List<QueueItem> applyRekeys(
  List<QueueItem> items,
  Map<int, KeyChange> changes,
) {
  if (changes.isEmpty) return items;
  return [
    for (final i in items)
      changes.containsKey(i.entryId)
          ? i.withKeys(
              sortKey: changes[i.entryId]!.sortKey,
              shuffleKey: changes[i.entryId]!.shuffleKey,
            )
          : i,
  ];
}

/// Removes the entries of [entryIds]. When the current entry goes, the next
/// entry takes over; if it was the last, the previous one; if it was the only
/// one, nothing is current. [positionMs] and [playing] describe the player at
/// this moment and travel in the undo token.
QueueEdit remove(
  QueueState s,
  Set<int> entryIds, {
  int positionMs = 0,
  bool playing = false,
}) {
  final removed = [
    for (final i in s.items)
      if (entryIds.contains(i.entryId)) i,
  ];
  if (removed.isEmpty) return QueueEdit.none(s);
  final survivors = [
    for (final i in s.items)
      if (!entryIds.contains(i.entryId)) i,
  ];
  final c = s.current;
  int? newCurrent;
  if (c != null) {
    var before = 0; // survivors ahead of the current position
    for (var i = 0; i < c; i++) {
      if (!entryIds.contains(s.items[i].entryId)) before++;
    }
    if (!entryIds.contains(s.items[c].entryId)) {
      newCurrent = before;
    } else if (survivors.length > before) {
      newCurrent = before;
    } else {
      newCurrent = before > 0 ? before - 1 : null;
    }
  }
  final runIds = s.playNextRunIds;
  final next = QueueState(
    items: survivors,
    shuffled: s.shuffled,
    repeat: s.repeat,
  ).withCurrent(newCurrent, runIds);
  return QueueEdit(
    next: next,
    removedIds: [for (final i in removed) i.entryId],
    undo: UndoToken(
      items: removed,
      previousCurrentEntryId: s.currentItem?.entryId,
      positionMs: positionMs,
      wasPlaying: playing,
      playNextRunIds: runIds,
    ),
  );
}

/// Moves one entry to play-order index [toIndex] (index in the list after the
/// move; clamped). Only the key of the active order changes. An entry moved
/// before the end of the play-next run joins it; one moved out of it leaves.
QueueEdit move(QueueState s, int entryId, int toIndex, KeyGen keys) {
  final from = s.indexOfEntry(entryId);
  if (from < 0 || s.length < 2) return QueueEdit.none(s);
  final to = toIndex.clamp(0, s.length - 1);
  if (to == from) return QueueEdit.none(s);
  final moved = s.items[from];
  final rest = [...s.items]..removeAt(from);
  final String? Function(QueueItem) keyOf = s.shuffled
      ? (i) => i.shuffleKey
      : (i) => i.sortKey;
  final slot = placeKeys(rest, to, 1, keyOf, keys);
  final newKey = slot.keys.first;
  final changes = <int, KeyChange>{
    for (final e in slot.rekeyed.entries)
      e.key: s.shuffled
          ? (sortKey: null, shuffleKey: e.value)
          : (sortKey: e.value, shuffleKey: null),
    entryId: s.shuffled
        ? (sortKey: null, shuffleKey: newKey)
        : (sortKey: newKey, shuffleKey: null),
  };
  final items = applyRekeys([...rest]..insert(to, moved), changes);
  final curId = s.currentItem?.entryId;
  final cur = curId == null
      ? null
      : items.indexWhere((i) => i.entryId == curId);
  final runIds = {...s.playNextRunIds};
  if (cur != null && runIds.isNotEmpty && !runIds.contains(entryId)) {
    var lastRun = -1;
    for (var i = 0; i < items.length; i++) {
      if (runIds.contains(items[i].entryId)) lastRun = i;
    }
    if (to > cur && to < lastRun) runIds.add(entryId);
  }
  return QueueEdit(
    next: s.copyWith(items: items).withCurrent(cur, runIds),
    rekeyed: changes,
  );
}

/// Index to play after the current entry, or null when the queue ends (or is
/// empty). [auto] = the entry ended by itself; a manual Next ignores repeat
/// one. With nothing current, the first entry.
int? nextIndex(QueueState s, {required bool auto}) {
  if (s.items.isEmpty) return null;
  final c = s.current;
  if (c == null) return 0;
  if (auto && s.repeat == RepeatMode.one) return c;
  if (c + 1 < s.length) return c + 1;
  return s.repeat == RepeatMode.all ? 0 : null;
}

/// Index to play before the current entry; null at the first entry (the
/// caller seeks to the start) or with nothing current.
int? previousIndex(QueueState s) {
  final c = s.current;
  return c != null && c > 0 ? c - 1 : null;
}
