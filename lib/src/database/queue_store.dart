import 'package:drift/drift.dart';

import '../foundation/ordering/fractional_keys.dart';
import 'tables.dart';

const _chunk = 500;

/// The queue in play order: `sort_key` order, or [shuffled] `shuffle_key`
/// order. While shuffle is on every entry has a `shuffle_key`; a row without
/// one sorts after those that have one, in user order, so no row is ever
/// dropped from the result.
Future<List<QueueEntryRow>> readQueue(
  DatabaseConnectionUser db, {
  required bool shuffled,
}) async {
  final rows = await db
      .customSelect(
        'SELECT id, track_id, sort_key, shuffle_key, added_at '
        'FROM queue_entries '
        '${shuffled ? 'ORDER BY shuffle_key IS NULL, shuffle_key, sort_key, id' : 'ORDER BY sort_key, id'}',
      )
      .get();
  return [
    for (final r in rows)
      QueueEntryRow(
        id: r.read<int>('id'),
        trackId: r.read<int>('track_id'),
        sortKey: r.read<String>('sort_key'),
        shuffleKey: r.readNullable<String>('shuffle_key'),
        addedAt: r.read<int>('added_at'),
      ),
  ];
}

/// Replaces the whole queue with [trackIds] (repeats allowed), in one
/// transaction: fresh fractional `sort_key`s. [shuffleOrder], when given, is
/// a permutation of the indexes of [trackIds] in shuffled play order; the
/// entries get `shuffle_key`s in that order, otherwise none. Throws
/// [ArgumentError] before any write when [shuffleOrder] is not a permutation.
/// At most 500 rows per insert. An unknown track id fails the foreign key
/// and leaves the old queue untouched. Notifies `queue_entries`.
Future<void> replaceQueue(
  DatabaseConnectionUser db,
  List<int> trackIds,
  int now, {
  List<int>? shuffleOrder,
}) async {
  final n = trackIds.length;
  List<String?> shuffleKeys = List.filled(n, null);
  if (shuffleOrder != null) {
    final seen = <int>{};
    if (shuffleOrder.length != n ||
        shuffleOrder.any((i) => i < 0 || i >= n || !seen.add(i))) {
      throw ArgumentError.value(
        shuffleOrder,
        'shuffleOrder',
        'must list every index of trackIds exactly once',
      );
    }
    final pool = n == 0
        ? const <String>[]
        : generateNKeysBetween(null, null, n);
    for (var k = 0; k < n; k++) {
      shuffleKeys[shuffleOrder[k]] = pool[k];
    }
  }
  final keys = n == 0 ? const <String>[] : generateNKeysBetween(null, null, n);
  await db.transaction(() async {
    await db.customStatement('DELETE FROM queue_entries');
    for (var i = 0; i < n; i += _chunk) {
      final end = i + _chunk > n ? n : i + _chunk;
      await db.customInsert(
        'INSERT INTO queue_entries (track_id, sort_key, shuffle_key, added_at) '
        'VALUES ${List.filled(end - i, '(?, ?, ?, ?)').join(', ')}',
        variables: [
          for (var j = i; j < end; j++) ...[
            Variable.withInt(trackIds[j]),
            Variable.withString(keys[j]),
            Variable<String>(shuffleKeys[j]),
            Variable.withInt(now),
          ],
        ],
      );
    }
  });
  db.notifyUpdates({const TableUpdate('queue_entries')});
}
