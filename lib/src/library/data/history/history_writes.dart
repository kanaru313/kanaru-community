import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../../domain/history/history_models.dart';
import '../playlists/playlist_sql.dart' show jsonEach, jsonList;

/// A removed play stays a tombstone at most this long (ms): a removal nobody
/// committed or undid is purged after it (see [purgeRemovedPlays]).
const removedPlayGraceMs = 60 * 60 * 1000;

const _chunk = 500;

Iterable<List<String>> _chunks(List<String> uids) sync* {
  for (var i = 0; i < uids.length; i += _chunk) {
    yield uids.sublist(i, math.min(i + _chunk, uids.length));
  }
}

/// Tombstones the live plays among [uids] with `deleted_at = now`. The stats
/// triggers subtract them. Null when none of them was live.
Future<HistoryBatch?> removePlaysWrite(
  AppDatabase db,
  List<String> uids,
  int now,
) async {
  if (uids.isEmpty) return null;
  final removed = await db.transaction(() async {
    final done = <String>[];
    for (final chunk in _chunks(uids.toSet().toList())) {
      final live = await db
          .customSelect(
            'SELECT uid FROM play_log WHERE deleted_at IS NULL '
            'AND uid IN $jsonEach',
            variables: [jsonList(chunk)],
          )
          .get();
      if (live.isEmpty) continue;
      final liveUids = [for (final r in live) r.read<String>('uid')];
      await db.customUpdate(
        'UPDATE play_log SET deleted_at = ?, updated_at = ? '
        'WHERE deleted_at IS NULL AND uid IN $jsonEach',
        variables: [
          Variable.withInt(now),
          Variable.withInt(now),
          jsonList(liveUids),
        ],
      );
      done.addAll(liveUids);
    }
    return done;
  });
  if (removed.isEmpty) return null;
  db.notifyUpdates({const TableUpdate('play_log', kind: UpdateKind.delete)});
  return HistoryBatch(uids: removed, stamp: now);
}

/// Revives the plays of every batch of [batches] in one transaction. A play is
/// revived only while its `deleted_at` is still the stamp of its own batch: one
/// removed again later, committed or purged stays as it is. Returns how many
/// came back.
Future<int> undoBatchesWrite(
  AppDatabase db,
  List<HistoryBatch> batches,
  int now,
) async {
  final revived = await db.transaction(() async {
    var n = 0;
    for (final batch in batches) {
      for (final chunk in _chunks(batch.uids)) {
        n += await db.customUpdate(
          'UPDATE play_log SET deleted_at = NULL, updated_at = ? '
          'WHERE deleted_at = ? AND uid IN $jsonEach',
          variables: [
            Variable.withInt(now),
            Variable.withInt(batch.stamp),
            jsonList(chunk),
          ],
        );
      }
    }
    return n;
  });
  if (revived > 0) {
    // Revived plays can sit in any year: tell readers of both kinds.
    db.notifyUpdates({
      const TableUpdate('play_log', kind: UpdateKind.insert),
      const TableUpdate('play_log', kind: UpdateKind.delete),
    });
  }
  return revived;
}

/// Deletes the tombstones of [batches] for good (same stamp check as an undo).
/// Idempotent: committing twice, or after an undo, deletes nothing. The stats
/// are untouched: a tombstone already left them.
Future<void> commitBatchesWrite(AppDatabase db, List<HistoryBatch> batches) =>
    db.transaction(() async {
      for (final batch in batches) {
        for (final chunk in _chunks(batch.uids)) {
          await db.customUpdate(
            'DELETE FROM play_log WHERE deleted_at = ? AND uid IN $jsonEach',
            variables: [Variable.withInt(batch.stamp), jsonList(chunk)],
          );
        }
      }
    });

/// Deletes every play tombstone older than [before] (epoch ms) and returns how
/// many went. Invariant: a `play_log` tombstone lives at most
/// [removedPlayGraceMs] (one hour): the removal toast commits or undoes it
/// within seconds, and the track GC calls this for what nobody finished, so a
/// removal never pins its track forever. This holds only while history is not
/// synced: a sync design that needs tombstones to travel must replace this
/// purge. It scans `play_log` (no index covers tombstones); it runs in the GC
/// only, never on a screen.
Future<int> purgeRemovedPlays(AppDatabase db, {required int before}) =>
    // Strictly older than the cutoff (the playlist purge uses `<=`; the same in
    // practice).
    db.customUpdate(
      'DELETE FROM play_log WHERE deleted_at IS NOT NULL AND deleted_at < ?',
      variables: [Variable.withInt(before)],
    );
