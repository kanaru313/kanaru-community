import 'queue_edit.dart';
import 'queue_keys.dart';
import 'queue_state.dart';
import 'undo_token.dart';

/// Puts the entries of [token] back with the ids and keys they had.
///
/// A key is kept only if no live entry has it in that order: a "play next" or
/// a move inside the undo window can have produced the same key (the
/// generator is deterministic), and equal keys would later make it throw.
/// Such an entry gets a key between its live neighbours instead. The current
/// entry becomes the one that was current at removal time.
QueueEdit undo(QueueState s, UndoToken token, KeyGen keys) {
  final live = {for (final i in s.items) i.entryId};
  final toRestore = [
    for (final i in token.items)
      if (!live.contains(i.entryId)) i,
  ];
  if (toRestore.isEmpty) return QueueEdit.none(s);

  final bySort = s.shuffled
      ? (List.of(s.items)..sort(_bySortKey))
      : List.of(s.items);
  final byShuffle = s.shuffled ? List.of(s.items) : null;
  final restored = <QueueItem>[];
  for (final old in toRestore) {
    final sort = _slot(bySort, old.sortKey, (i) => i.sortKey, keys);
    final _Slot? shuffle = byShuffle == null
        ? null
        : _slot(byShuffle, old.shuffleKey, (i) => i.shuffleKey, keys);
    final item = QueueItem(
      entryId: old.entryId,
      trackId: old.trackId,
      sortKey: sort.key,
      shuffleKey: shuffle?.key,
    );
    bySort.insert(sort.index, item);
    if (shuffle != null) byShuffle!.insert(shuffle.index, item);
    restored.add(item);
  }

  final items = byShuffle ?? bySort;
  final curId = token.previousCurrentEntryId ?? s.currentItem?.entryId;
  var cur = curId == null ? -1 : items.indexWhere((i) => i.entryId == curId);
  if (cur < 0 && s.currentItem != null) {
    cur = items.indexWhere((i) => i.entryId == s.currentItem!.entryId);
  }
  return QueueEdit(
    next: s.copyWith(items: items).withCurrent(cur < 0 ? null : cur, {
      ...s.playNextRunIds,
      ...token.playNextRunIds,
    }),
    inserted: restored,
  );
}

int _bySortKey(QueueItem a, QueueItem b) {
  final k = a.sortKey.compareTo(b.sortKey);
  return k != 0 ? k : a.entryId.compareTo(b.entryId);
}

class _Slot {
  const _Slot(this.key, this.index);
  final String key;
  final int index;
}

/// Where an entry with [wanted] key goes in [order] (sorted by [keyOf]) and
/// the key it gets there: [wanted] if free, else a fresh one between the live
/// neighbours. A null [wanted] means "at the end".
_Slot _slot(
  List<QueueItem> order,
  String? wanted,
  String? Function(QueueItem) keyOf,
  KeyGen keys,
) {
  var index = order.length;
  if (wanted != null) {
    var lo = 0;
    var hi = order.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      final k = keyOf(order[mid]);
      if (k != null && k.compareTo(wanted) <= 0) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    index = lo;
    if (index == 0 || keyOf(order[index - 1]) != wanted) {
      return _Slot(wanted, index);
    }
  }
  final left = index > 0 ? keyOf(order[index - 1]) : null;
  final right = index < order.length ? keyOf(order[index]) : null;
  return _Slot(keys.between(left, right), index);
}
