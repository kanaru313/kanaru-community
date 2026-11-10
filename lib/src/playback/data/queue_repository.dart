import 'package:drift/drift.dart';

import '../../database/queue_store.dart';
import '../../foundation/ordering/fractional_keys.dart';
import '../../media/domain/track_id.dart';
import '../domain/queue_edit.dart';
import '../domain/queue_state.dart';

/// Rows per SQL statement. Every multi-row statement stays at or below it.
const _chunk = 500;

/// Reads and writes `queue_entries` for the player. All SQL of the queue
/// edits lives here; the pure decisions are in `domain/queue_logic.dart`.
class QueueRepository {
  QueueRepository(this._db);

  final DatabaseConnectionUser _db;

  /// The queue in play order.
  Future<List<QueueItem>> load({required bool shuffled}) async => [
    for (final r in await readQueue(_db, shuffled: shuffled))
      QueueItem(
        entryId: r.id,
        trackId: TrackId(r.trackId),
        sortKey: r.sortKey,
        shuffleKey: r.shuffleKey,
      ),
  ];

  /// Replaces the queue with new entries for [trackIds] in one transaction
  /// and returns them in play order (the order of [shuffleOrder] when given:
  /// `shuffleOrder[k]` is the index in [trackIds] of the k-th track to play).
  /// Keys come from one key-generation call per order and the new ids from
  /// `INSERT … RETURNING`, so nothing is read back. An unknown track fails
  /// the foreign key and keeps the old queue.
  Future<List<QueueItem>> replace(
    List<TrackId> trackIds,
    int now, {
    List<int>? shuffleOrder,
  }) async {
    final n = trackIds.length;
    if (shuffleOrder != null) _checkPermutation(shuffleOrder, n);
    final sortKeys = n == 0
        ? const <String>[]
        : generateNKeysBetween(null, null, n);
    final shuffleKeys = List<String?>.filled(n, null);
    if (shuffleOrder != null && n > 0) {
      final pool = generateNKeysBetween(null, null, n);
      for (var k = 0; k < n; k++) {
        shuffleKeys[shuffleOrder[k]] = pool[k];
      }
    }
    final items = [
      for (var i = 0; i < n; i++)
        QueueItem(
          entryId: -(i + 1),
          trackId: trackIds[i],
          sortKey: sortKeys[i],
          shuffleKey: shuffleKeys[i],
        ),
    ];
    late List<QueueItem> written;
    await _db.transaction(() async {
      await _db.customStatement('DELETE FROM queue_entries');
      written = await _insertAll(items, now);
    });
    _notify();
    return shuffleOrder == null
        ? written
        : [for (final i in shuffleOrder) written[i]];
  }

  /// Writes [edit] in one transaction: deletes, inserts, key updates. Returns
  /// the edit with the real ids of new rows. Any failure (for example an
  /// unknown track) rolls the whole edit back.
  Future<QueueEdit> apply(QueueEdit edit, int now) async {
    if (edit.isNoop) return edit;
    final real = <int, int>{};
    await _db.transaction(() async {
      for (final ids in _chunks(edit.removedIds)) {
        await _db.customUpdate(
          'DELETE FROM queue_entries WHERE id IN (${_marks(ids.length)})',
          variables: [for (final id in ids) Variable.withInt(id)],
        );
      }
      if (edit.clearShuffleKeys) {
        await _db.customUpdate('UPDATE queue_entries SET shuffle_key = NULL');
      }
      final written = await _insertAll(edit.inserted, now);
      for (var i = 0; i < written.length; i++) {
        if (edit.inserted[i].entryId != written[i].entryId) {
          real[edit.inserted[i].entryId] = written[i].entryId;
        }
      }
      await _updateKeys('sort_key', {
        for (final e in edit.rekeyed.entries)
          if (e.value.sortKey != null) e.key: e.value.sortKey!,
      });
      await _updateKeys('shuffle_key', {
        for (final e in edit.rekeyed.entries)
          if (e.value.shuffleKey != null) e.key: e.value.shuffleKey!,
      });
    });
    _notify();
    return edit.withRealIds(real);
  }

  /// Inserts [items] (500 per statement) and returns them with real ids, in
  /// the same order. Items with a positive id keep it (restored rows); the
  /// others get the table's next ids. A statement's new ids ascend in VALUES
  /// order, so sorting the returned ids restores that order whatever order
  /// `RETURNING` reports them in.
  Future<List<QueueItem>> _insertAll(List<QueueItem> items, int now) async {
    final out = List<QueueItem?>.filled(items.length, null);
    final restored = <int>[]; // indexes with a fixed id
    final fresh = <int>[];
    for (var i = 0; i < items.length; i++) {
      (items[i].entryId > 0 ? restored : fresh).add(i);
    }
    for (final part in _chunks(restored)) {
      await _db.customInsert(
        'INSERT INTO queue_entries (id, track_id, sort_key, shuffle_key, added_at) '
        'VALUES ${List.filled(part.length, '(?, ?, ?, ?, ?)').join(', ')}',
        variables: [
          for (final i in part) ...[
            Variable.withInt(items[i].entryId),
            Variable.withInt(items[i].trackId.value),
            Variable.withString(items[i].sortKey),
            Variable<String>(items[i].shuffleKey),
            Variable.withInt(now),
          ],
        ],
      );
      for (final i in part) {
        out[i] = items[i];
      }
    }
    for (final part in _chunks(fresh)) {
      final rows = await _db.customWriteReturning(
        'INSERT INTO queue_entries (track_id, sort_key, shuffle_key, added_at) '
        'VALUES ${List.filled(part.length, '(?, ?, ?, ?)').join(', ')} '
        'RETURNING id',
        variables: [
          for (final i in part) ...[
            Variable.withInt(items[i].trackId.value),
            Variable.withString(items[i].sortKey),
            Variable<String>(items[i].shuffleKey),
            Variable.withInt(now),
          ],
        ],
      );
      final ids = [for (final r in rows) r.read<int>('id')]..sort();
      if (ids.length != part.length) {
        throw StateError(
          'queue insert returned ${ids.length} ids for ${part.length} rows',
        );
      }
      for (var k = 0; k < part.length; k++) {
        out[part[k]] = items[part[k]].withEntryId(ids[k]);
      }
    }
    return [for (final i in out) i!];
  }

  /// Sets [column] of many rows with one statement per 500 rows.
  Future<void> _updateKeys(String column, Map<int, String> keys) async {
    for (final part in _chunks(keys.entries.toList())) {
      await _db.customUpdate(
        'WITH v(id, k) AS (VALUES ${List.filled(part.length, '(?, ?)').join(', ')}) '
        'UPDATE queue_entries SET $column = '
        '(SELECT k FROM v WHERE v.id = queue_entries.id) '
        'WHERE id IN (SELECT id FROM v)',
        variables: [
          for (final e in part) ...[
            Variable.withInt(e.key),
            Variable.withString(e.value),
          ],
        ],
      );
    }
  }

  void _notify() => _db.notifyUpdates({const TableUpdate('queue_entries')});
}

Iterable<List<T>> _chunks<T>(List<T> all) sync* {
  for (var i = 0; i < all.length; i += _chunk) {
    yield all.sublist(i, i + _chunk > all.length ? all.length : i + _chunk);
  }
}

String _marks(int n) => List.filled(n, '?').join(', ');

void _checkPermutation(List<int> order, int n) {
  final seen = <int>{};
  if (order.length != n || order.any((i) => i < 0 || i >= n || !seen.add(i))) {
    throw ArgumentError.value(
      order,
      'shuffleOrder',
      'must list every index of trackIds exactly once',
    );
  }
}
