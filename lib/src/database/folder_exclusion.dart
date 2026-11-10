import 'package:drift/drift.dart';

import 'exclusion_sql.dart';
import 'folder_range.dart';
import 'row_uids.dart';
import 'tables.dart';

final _touched = {
  const TableUpdate('tracks'),
  const TableUpdate('excluded_folders'),
  const TableUpdate('source_mounts'),
};

/// Inserts or revives the excluded folder and hides the `present` and
/// `missing` rows in its range, in one transaction. A live exclusion keeps
/// its `display_path`; a revived one takes the new one. Returns the
/// `excluded_folders` id. Throws [StateError] for a removed or unknown
/// source and [ArgumentError] for a malformed [folderKey].
Future<int> applyFolderExclusion(
  DatabaseConnectionUser db, {
  required int sourceId,
  required String folderKey,
  required String displayPath,
  required int now,
}) {
  final range = folderLocatorRange(folderKey);
  return db.transaction(() async {
    final live = await db
        .customSelect(
          'SELECT uid FROM sources WHERE id = ? AND deleted_at IS NULL',
          variables: [Variable.withInt(sourceId)],
        )
        .get();
    if (live.isEmpty) {
      throw StateError('source $sourceId is removed or unknown');
    }
    final sourceUid = live.single.read<String>('uid');
    final rows = await db.customWriteReturning(
      'INSERT INTO excluded_folders '
      '(uid, source_id, folder_key, display_path, added_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?) '
      'ON CONFLICT (uid) DO UPDATE SET '
      'display_path = CASE WHEN excluded_folders.deleted_at IS NULL '
      'THEN excluded_folders.display_path ELSE excluded.display_path END, '
      'deleted_at = NULL, updated_at = excluded.updated_at '
      'RETURNING id',
      variables: [
        Variable.withString(excludedFolderUid(sourceUid, folderKey)),
        Variable.withInt(sourceId),
        Variable.withString(folderKey),
        Variable.withString(displayPath),
        Variable.withInt(now),
        Variable.withInt(now),
      ],
    );
    await db.customStatement(
      "UPDATE tracks SET status = '${TrackStatus.hidden}', updated_at = ? "
      "WHERE source_id = ? AND status IN ('${TrackStatus.present}', "
      "'${TrackStatus.missing}')"
      '${range == null ? '' : ' AND locator >= ? AND locator < ?'}',
      [
        now,
        sourceId,
        if (range != null) ...[range.from, range.to],
      ],
    );
    db.notifyUpdates(_touched);
    return rows.single.read<int>('id');
  });
}

/// Tombstones the live exclusion of [folderKey] and unhides its range, in
/// one transaction. Does nothing when there is no live exclusion.
///
/// The unhide is exclusion-aware: a `hidden` row in the range becomes
/// `missing` (`missing_since = now`, for the next scan to confirm) only when
/// no other live exclusion of the source still covers it, and only while the
/// source is live and its mount is enabled; otherwise the row stays hidden
/// for its own reason. The scan cursor of an enabled mount resets,
/// so the next scan looks at the folder again.
Future<void> removeFolderExclusion(
  DatabaseConnectionUser db, {
  required int sourceId,
  required String folderKey,
  required int now,
}) {
  final range = folderLocatorRange(folderKey);
  return db.transaction(() async {
    final gone = await db.customUpdate(
      'UPDATE excluded_folders SET deleted_at = ?, updated_at = ? '
      'WHERE source_id = ? AND folder_key = ? AND deleted_at IS NULL',
      variables: [
        Variable.withInt(now),
        Variable.withInt(now),
        Variable.withInt(sourceId),
        Variable.withString(folderKey),
      ],
    );
    if (gone == 0) return;
    const mountOn =
        'EXISTS (SELECT 1 FROM sources s JOIN source_mounts m '
        'ON m.source_id = s.id WHERE s.id = ?1 AND s.deleted_at IS NULL '
        'AND m.enabled = 1)';
    // The removed exclusion is tombstoned above, so it no longer counts.
    final covered = liveExclusionCovers('?1', 'tracks.locator');
    await db.customUpdate(
      "UPDATE tracks SET status = '${TrackStatus.missing}', "
      'missing_since = ?2, updated_at = ?2 '
      "WHERE source_id = ?1 AND status = '${TrackStatus.hidden}' "
      '${range == null ? '' : 'AND locator >= ?3 AND locator < ?4 '}'
      'AND NOT $covered AND $mountOn',
      variables: [
        Variable.withInt(sourceId),
        Variable.withInt(now),
        if (range != null) ...[
          Variable.withString(range.from),
          Variable.withString(range.to),
        ],
      ],
    );
    await db.customUpdate(
      'UPDATE source_mounts SET scan_cursor = NULL, last_scan_at = NULL '
      'WHERE source_id = ? AND enabled = 1',
      variables: [Variable.withInt(sourceId)],
    );
    db.notifyUpdates(_touched);
  });
}

/// Folder keys of the live exclusions of [sourceId], for listing to skip.
Future<List<String>> excludedFolderKeys(
  DatabaseConnectionUser db,
  int sourceId,
) async {
  final rows = await db
      .customSelect(
        'SELECT folder_key FROM excluded_folders '
        'WHERE source_id = ? AND deleted_at IS NULL ORDER BY folder_key',
        variables: [Variable.withInt(sourceId)],
      )
      .get();
  return [for (final r in rows) r.read<String>('folder_key')];
}
