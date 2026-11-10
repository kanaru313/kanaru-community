import 'package:drift/drift.dart' show Value, Variable;
import 'package:logging/logging.dart';

import '../../../database/database.dart';
import 'track_row_builder.dart';

/// Most rows in one write transaction.
const int writeBatchRows = 64;

/// Something the tag pass writes.
sealed class WriteItem {
  const WriteItem();
}

/// Insert or refresh one track: snapshot, artists and `track_details`.
final class SnapshotWrite extends WriteItem {
  const SnapshotWrite(this.built);
  final BuiltTrack built;
}

/// Only the `.lrc` sidecar of an unchanged track.
final class LrcWrite extends WriteItem {
  const LrcWrite({required this.trackId, required this.details});
  final int trackId;
  final DetailsPatch details;
}

/// Result of [writeBatch].
class WriteOutcome {
  const WriteOutcome({this.snapshotIds = const [], this.sourceGone = false});

  /// `tracks.id` of each [SnapshotWrite], in order.
  final List<int> snapshotIds;

  /// The source was removed or its mount disabled: nothing was written.
  final bool sourceGone;
}

final _log = Logger('library.scan.writer');

/// Whether the source is live and its mount enabled.
Future<bool> isSourceLive(AppDatabase db, int sourceId) async {
  final rows = await db
      .customSelect(
        'SELECT 1 FROM sources s JOIN source_mounts m ON m.source_id = s.id '
        'WHERE s.id = ? AND s.deleted_at IS NULL AND m.enabled = 1',
        variables: [Variable.withInt(sourceId)],
        readsFrom: {db.sources, db.sourceMounts},
      )
      .get();
  return rows.isNotEmpty;
}

Future<void> _writeDetails(AppDatabase db, int trackId, DetailsPatch patch) =>
    upsertTrackDetails(
      db,
      TrackDetailsCompanion(
        trackId: Value(trackId),
        comment: patch.comment,
        lrcLocator: Value(patch.lrcLocator),
        lrcRevision: Value(patch.lrcRevision),
      ),
    );

/// Writes [items] (at most [writeBatchRows]) in one transaction through the
/// frozen helpers. The source is checked live first, in the same
/// transaction, so rows of a source removed meanwhile are never inserted.
/// Any failure rolls the whole batch back and is rethrown.
Future<WriteOutcome> writeBatch(
  AppDatabase db,
  int sourceId,
  List<WriteItem> items,
) {
  if (items.length > writeBatchRows) {
    throw ArgumentError.value(items.length, 'items', 'over $writeBatchRows');
  }
  return db.transaction(() async {
    if (!await isSourceLive(db, sourceId)) {
      return const WriteOutcome(sourceGone: true);
    }
    final ids = <int>[];
    for (final item in items) {
      switch (item) {
        case SnapshotWrite(:final built):
          final id = await upsertTrackSnapshot(db, db.tracks, built.row);
          await replaceTrackArtists(db, id, built.artists);
          final details = built.details;
          if (details != null) await _writeDetails(db, id, details);
          ids.add(id);
        case LrcWrite(:final trackId, :final details):
          await _writeDetails(db, trackId, details);
      }
    }
    return WriteOutcome(snapshotIds: ids);
  });
}

/// Consecutive row failures after which a batch is called a database-wide
/// failure rather than a bad row.
const int systemicFailureRows = 3;

/// [writeBatch] that survives a bad row: when the batch fails it is retried
/// one item at a time, each in its own transaction, and the items that still
/// fail are logged and counted in [failed]. [ids] holds the id of each
/// [SnapshotWrite] that was written, null for one that failed.
///
/// When [systemicFailureRows] items in a row fail, the database is the problem, not a row: the retry stops and
/// `systemic` is true. Programming errors ([ArgumentError], [StateError])
/// are rethrown, not retried.
Future<({List<int?> ids, bool sourceGone, int failed, bool systemic})>
writeBatchSafely(AppDatabase db, int sourceId, List<WriteItem> items) async {
  try {
    final out = await writeBatch(db, sourceId, items);
    return (
      ids: out.snapshotIds,
      sourceGone: out.sourceGone,
      failed: 0,
      systemic: false,
    );
  } on ArgumentError {
    rethrow;
  } on StateError {
    rethrow;
  } on Object catch (e, st) {
    _log.warning('batch of ${items.length} failed, retrying one by one', e, st);
  }
  final ids = <int?>[];
  var failed = 0;
  var streak = 0;
  for (final item in items) {
    try {
      final out = await writeBatch(db, sourceId, [item]);
      if (out.sourceGone) {
        return (ids: ids, sourceGone: true, failed: failed, systemic: false);
      }
      streak = 0;
      if (item is SnapshotWrite) ids.add(out.snapshotIds.single);
    } on ArgumentError {
      rethrow;
    } on StateError {
      rethrow;
    } on Object catch (e, st) {
      failed++;
      streak++;
      if (item is SnapshotWrite) ids.add(null);
      _log.severe('could not write ${_describe(item)}', e, st);
      if (streak >= systemicFailureRows) {
        return (ids: ids, sourceGone: false, failed: failed, systemic: true);
      }
    }
  }
  return (ids: ids, sourceGone: false, failed: failed, systemic: false);
}

String _describe(WriteItem item) => switch (item) {
  SnapshotWrite(:final built) => 'row ${built.row.locator.value}',
  LrcWrite(:final trackId) => 'sidecar of track $trackId',
};
