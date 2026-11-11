import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/ordering/fractional_keys.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/domain/queue_logic.dart';

/// A queue of [n] entries (entry id i + 1, track id i) in sort order.
/// With [shuffled], the shuffle order is [shuffleOrder] (indexes into the
/// entries, default reversed) and `items` follows it.
QueueState makeQueue(
  int n, {
  int? current,
  bool shuffled = false,
  List<int>? shuffleOrder,
  RepeatMode repeat = RepeatMode.off,
  int playNextRun = 0,
}) {
  final sortKeys = n == 0 ? <String>[] : generateNKeysBetween(null, null, n);
  final items = [
    for (var i = 0; i < n; i++)
      QueueItem(entryId: i + 1, trackId: TrackId(i), sortKey: sortKeys[i]),
  ];
  if (!shuffled) {
    return QueueState(
      items: items,
      current: current,
      repeat: repeat,
      playNextRun: playNextRun,
    );
  }
  final order = shuffleOrder ?? [for (var i = n - 1; i >= 0; i--) i];
  final shuffleKeys = n == 0 ? <String>[] : generateNKeysBetween(null, null, n);
  return QueueState(
    items: [
      for (var k = 0; k < n; k++)
        items[order[k]].withKeys(shuffleKey: shuffleKeys[k]),
    ],
    current: current,
    shuffled: true,
    repeat: repeat,
    playNextRun: playNextRun,
  );
}

/// Track ids in play order.
List<int> tracks(QueueState s) => [for (final i in s.items) i.trackId.value];

/// Entry ids in play order.
List<int> entries(QueueState s) => [for (final i in s.items) i.entryId];

/// Replaces provisional (negative) ids with fresh positive ones from
/// [nextId], like the repository does after the insert.
QueueEdit assignIds(QueueEdit edit, int Function() nextId) => edit.withRealIds({
  for (final i in edit.inserted)
    if (i.entryId < 0) i.entryId: nextId(),
});

/// Fails unless [s] is a valid queue: keys strictly ascending in the active
/// order, unique in each order, current and run in range.
void expectHealthy(QueueState s) {
  final active = [
    for (final i in s.items) s.shuffled ? i.shuffleKey : i.sortKey,
  ];
  expect(active.every((k) => k != null), isTrue, reason: 'active keys set');
  for (var i = 1; i < active.length; i++) {
    expect(
      active[i]!.compareTo(active[i - 1]!),
      greaterThan(0),
      reason: 'order at $i',
    );
  }
  final sortKeys = {for (final i in s.items) i.sortKey};
  expect(sortKeys, hasLength(s.length), reason: 'sort keys unique');
  expect({for (final i in s.items) i.entryId}, hasLength(s.length));
  if (s.current != null) {
    expect(s.current, inInclusiveRange(0, s.length - 1));
    expect(s.current! + s.playNextRun, lessThan(s.length));
  } else {
    expect(s.playNextRun, 0);
  }
}
