import 'dart:math';

import 'queue_edit.dart';
import 'queue_keys.dart';
import 'queue_state.dart';

/// Turns shuffle on and shuffles the entries after the current one. Entries
/// before it and the current one keep their place. The first time (no shuffle
/// keys yet) every entry gets a key, in its present order for the kept ones.
/// The play-next run is shuffled with the rest.
QueueEdit shuffleUpcoming(QueueState s, Random random, KeyGen keys) {
  final c = s.current;
  final keptCount = c == null ? 0 : c + 1;
  final kept = s.items.sublist(0, keptCount);
  final upcoming = s.items.sublist(keptCount)..shuffle(random);
  final hasKeys = s.shuffled && kept.every((i) => i.shuffleKey != null);
  final rekeyed = <int, KeyChange>{};
  var items = kept;
  String? after;
  if (hasKeys) {
    after = kept.isEmpty ? null : kept.last.shuffleKey;
  } else {
    final fresh = keys.betweenN(null, null, kept.length);
    items = [
      for (var i = 0; i < kept.length; i++)
        kept[i].withKeys(shuffleKey: fresh[i]),
    ];
    for (final i in items) {
      rekeyed[i.entryId] = (sortKey: null, shuffleKey: i.shuffleKey);
    }
    after = fresh.isEmpty ? null : fresh.last;
  }
  final upKeys = keys.betweenN(after, null, upcoming.length);
  final shuffled = [
    for (var i = 0; i < upcoming.length; i++)
      upcoming[i].withKeys(shuffleKey: upKeys[i]),
  ];
  for (final i in shuffled) {
    rekeyed[i.entryId] = (sortKey: null, shuffleKey: i.shuffleKey);
  }
  return QueueEdit(
    next: QueueState(
      items: [...items, ...shuffled],
      current: c,
      shuffled: true,
      repeat: s.repeat,
    ),
    rekeyed: rekeyed,
  );
}

/// Turns shuffle off: sort-key order, the current entry kept, shuffle keys
/// cleared.
QueueEdit unshuffle(QueueState s) {
  if (!s.shuffled && s.items.every((i) => i.shuffleKey == null)) {
    return QueueEdit.none(s);
  }
  final items = [for (final i in s.items) i.withoutShuffleKey()]
    ..sort((a, b) {
      final k = a.sortKey.compareTo(b.sortKey);
      return k != 0 ? k : a.entryId.compareTo(b.entryId);
    });
  final curId = s.currentItem?.entryId;
  final cur = curId == null
      ? null
      : items.indexWhere((i) => i.entryId == curId);
  return QueueEdit(
    next: QueueState(
      items: items,
      shuffled: false,
      repeat: s.repeat,
    ).withCurrent(cur, s.playNextRunIds),
    clearShuffleKeys: true,
  );
}
