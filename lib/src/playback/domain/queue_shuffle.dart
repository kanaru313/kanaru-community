import 'dart:math';

import 'queue_edit.dart';
import 'queue_keys.dart';
import 'queue_state.dart';

/// Turns shuffle on and shuffles the entries after the current one. Entries
/// before it and the current one keep their place. The first time (no shuffle
/// keys yet) every entry gets a key, in its present order for the kept ones.
/// The play-next run (the entries added with "play next", right after the
/// current one) keeps its order and its place; only the entries behind it are
/// shuffled.
QueueEdit shuffleUpcoming(QueueState s, Random random, KeyGen keys) {
  final c = s.current;
  final keptCount = c == null ? 0 : c + 1;
  final kept = s.items.sublist(0, keptCount);
  final runEnd = c == null ? 0 : min(keptCount + s.playNextRun, s.length);
  final run = s.items.sublist(keptCount, runEnd);
  final upcoming = s.items.sublist(runEnd)..shuffle(random);
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
  // The run and the shuffled rest take consecutive keys behind the kept ones.
  final ordered = [...run, ...upcoming];
  final upKeys = keys.betweenN(after, null, ordered.length);
  final shuffled = [
    for (var i = 0; i < ordered.length; i++)
      ordered[i].withKeys(shuffleKey: upKeys[i]),
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
      playNextRun: run.length,
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

/// The next pass of "repeat all, reshuffled": every entry gets a fresh random
/// position, shuffle turns on and the first entry is current. With two or
/// more entries the first one is never the entry that just played (the
/// current one). Sort keys stay, so turning shuffle off gives back the order
/// the user built. Fewer than two entries have nothing to reorder: no change.
QueueEdit reshufflePass(QueueState s, Random random, KeyGen keys) {
  if (s.length < 2) return QueueEdit.none(s);
  final fresh = [...s.items]..shuffle(random);
  if (fresh.first.entryId == s.currentItem?.entryId) {
    final j = 1 + random.nextInt(fresh.length - 1);
    final first = fresh[0];
    fresh[0] = fresh[j];
    fresh[j] = first;
  }
  final shuffleKeys = keys.betweenN(null, null, fresh.length);
  final items = [
    for (var i = 0; i < fresh.length; i++)
      fresh[i].withKeys(shuffleKey: shuffleKeys[i]),
  ];
  return QueueEdit(
    next: QueueState(
      items: items,
      current: 0,
      shuffled: true,
      repeat: s.repeat,
    ),
    rekeyed: {
      for (final i in items)
        i.entryId: (sortKey: null, shuffleKey: i.shuffleKey),
    },
  );
}
