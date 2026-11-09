import 'package:drift/drift.dart';

import 'tables.dart';

/// One-to-one rows derived from a track. The GC ignores them when deciding
/// whether a track is referenced and deletes them together with the track.
const trackOwnedChildTables = {'track_details', 'play_stats', 'track_artists'};

/// A `missing` track is kept this long (ms) after `missing_since`.
const missingGraceMs = 7 * 24 * 60 * 60 * 1000;

/// A `hidden` track is kept this long (ms) after `updated_at` (undo window).
const hiddenGraceMs = 7 * 24 * 60 * 60 * 1000;

/// A `remote` track is kept this long (ms) after `updated_at`.
const remoteGraceMs = 24 * 60 * 60 * 1000;

class _Reference {
  const _Reference(this.table, this.column, this.parentColumn);
  final String table;
  final String column;
  final String parentColumn;
}

String _quote(String identifier) => '"${identifier.replaceAll('"', '""')}"';

/// Foreign keys into `tracks` of the main schema (public and Pro tables),
/// failing closed on anything the GC cannot reason about.
Future<List<_Reference>> _discoverReferences(DatabaseConnectionUser db) async {
  final owned = trackOwnedChildTables.map((t) => "'$t'").join(', ');
  final rows = await db.customSelect('''
    SELECT m.name AS tbl, f."from" AS col, f."to" AS parent_col,
           f."table" AS parent, f.on_delete AS action, f.seq AS seq
    FROM sqlite_master AS m, pragma_foreign_key_list(m.name, 'main') AS f
    WHERE m.type = 'table'
      AND (lower(f."table") = 'tracks' OR lower(f."table") IN ($owned))
  ''').get();
  final refs = <_Reference>[];
  for (final r in rows) {
    final table = r.read<String>('tbl');
    final column = r.read<String>('col');
    final parent = r.read<String>('parent').toLowerCase();
    if (parent != 'tracks') {
      throw StateError(
        'foreign key $table.$column references $parent, an owned child of tracks',
      );
    }
    if (r.read<String>('action').toUpperCase() != 'RESTRICT') {
      throw StateError(
        'foreign key $table.$column into tracks is not ON DELETE RESTRICT',
      );
    }
    if (r.read<int>('seq') > 0) {
      throw StateError('composite foreign key in $table into tracks');
    }
    refs.add(
      _Reference(table, column, r.readNullable<String>('parent_col') ?? 'id'),
    );
  }
  return refs;
}

String _candidateSql(List<_Reference> refs) {
  final unreferenced = [
    for (final ref in refs)
      if (!trackOwnedChildTables.contains(ref.table))
        'AND NOT EXISTS (SELECT 1 FROM main.${_quote(ref.table)} r '
            'WHERE r.${_quote(ref.column)} = tracks.${_quote(ref.parentColumn)})',
  ];
  return '''
    SELECT id FROM main.tracks
    WHERE rating IS NULL AND lyrics_offset_ms = 0
      AND (
        (status = '${TrackStatus.missing}' AND missing_since <= ?1 - $missingGraceMs)
        OR (status = '${TrackStatus.hidden}' AND updated_at <= ?1 - $hiddenGraceMs
            AND NOT EXISTS (
              SELECT 1 FROM main.sources s JOIN main.source_mounts sm ON sm.source_id = s.id
              WHERE s.id = tracks.source_id AND s.deleted_at IS NULL AND sm.enabled = 0))
        OR (status = '${TrackStatus.remote}' AND updated_at <= ?1 - $remoteGraceMs)
      )
      ${unreferenced.join('\n      ')}
  ''';
}

/// Deletes tracks nobody references and that carry no user data, once their
/// grace period (by status) has passed; returns how many were deleted.
///
/// Foreign keys into `tracks` are discovered at run time, so tables of
/// extension databases on the same connection count as references. Rows of
/// [trackOwnedChildTables] are deleted first, in the same transaction.
/// Only the main schema is inspected and every table is addressed as
/// `main.<table>`, so a temp table of the same name cannot shadow it.
/// Nothing may reference an owned child table: that also throws.
/// A `missing` row without `missing_since` is never collected.
///
/// Fails closed with [StateError]: `PRAGMA foreign_keys` is off, a foreign
/// key into `tracks` is not `ON DELETE RESTRICT`, one is composite, or a
/// foreign key points at an owned child table.
/// Nothing is deleted then. Scheduling is the caller's job.
Future<int> collectOrphanTracks(
  DatabaseConnectionUser db, {
  required int now,
}) async {
  final fk = await db.customSelect('PRAGMA foreign_keys').getSingle();
  if (fk.read<int>('foreign_keys') == 0) {
    throw StateError(
      'foreign key enforcement is off; refusing to collect tracks',
    );
  }
  final deleted = await db.transaction(() async {
    final sql = _candidateSql(await _discoverReferences(db));
    // One candidate set, so children and tracks are deleted consistently.
    await db.customStatement('DROP TABLE IF EXISTS temp.gc_candidates');
    await db.customStatement(
      'CREATE TEMP TABLE gc_candidates (id INTEGER PRIMARY KEY)',
    );
    try {
      await db.customInsert(
        'INSERT INTO temp.gc_candidates (id) $sql',
        variables: [Variable.withInt(now)],
      );
      for (final child in trackOwnedChildTables) {
        await db.customStatement(
          'DELETE FROM main.${_quote(child)} '
          'WHERE track_id IN (SELECT id FROM temp.gc_candidates)',
        );
      }
      return await db.customUpdate(
        'DELETE FROM main.tracks WHERE id IN (SELECT id FROM temp.gc_candidates)',
      );
    } finally {
      await db.customStatement('DROP TABLE IF EXISTS temp.gc_candidates');
    }
  });
  if (deleted > 0) {
    // The FTS delete trigger writes `track_search` too.
    db.notifyUpdates({
      for (final t in [
        'tracks',
        'track_details',
        'play_stats',
        'track_artists',
        'track_search',
      ])
        TableUpdate(t),
    });
  }
  return deleted;
}
