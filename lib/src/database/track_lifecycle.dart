import 'package:drift/drift.dart';

import 'exclusion_sql.dart';
import 'tables.dart';

/// Streams over these tables re-emit after every lifecycle change.
final _touched = {
  const TableUpdate('tracks'),
  const TableUpdate('sources'),
  const TableUpdate('source_mounts'),
};

Future<T> _atomically<T>(
  DatabaseConnectionUser db,
  Future<T> Function() body,
) => db.transaction(() async {
  final result = await body();
  db.notifyUpdates(_touched);
  return result;
});

Future<void> _hideTracks(
  DatabaseConnectionUser db,
  int sourceId,
  int now,
) => db.customStatement(
  "UPDATE tracks SET status = '${TrackStatus.hidden}', updated_at = ? "
  "WHERE source_id = ? AND status IN ('${TrackStatus.present}', '${TrackStatus.missing}')",
  [now, sourceId],
);

Future<void> _setMount(DatabaseConnectionUser db, int sourceId, bool enabled) =>
    db.customStatement(
      'UPDATE source_mounts SET enabled = ?, scan_cursor = NULL, '
      'last_scan_at = NULL WHERE source_id = ?',
      [enabled ? 1 : 0, sourceId],
    );

Future<void> _requireLive(DatabaseConnectionUser db, int sourceId) async {
  final rows = await db
      .customSelect(
        'SELECT 1 FROM sources WHERE id = ? AND deleted_at IS NULL',
        variables: [Variable.withInt(sourceId)],
      )
      .get();
  if (rows.isEmpty) {
    throw StateError('source $sourceId is removed or unknown; revive it first');
  }
}

Future<void> _unhide(
  DatabaseConnectionUser db,
  int sourceId,
  int now,
  String? from,
  String? to,
) async {
  final extra = from == null ? '' : ' AND locator >= ? AND locator < ?';
  // A row inside a live folder exclusion stays hidden for that reason.
  final notExcluded =
      ' AND NOT ${liveExclusionCovers('tracks.source_id', 'tracks.locator')}';
  await db.customStatement(
    "UPDATE tracks SET status = '${TrackStatus.missing}', missing_since = ?, "
    "updated_at = ? WHERE source_id = ? AND status = '${TrackStatus.hidden}'$extra$notExcluded",
    [
      now,
      now,
      sourceId,
      if (from != null) ...[from, to],
    ],
  );
  await db.customStatement(
    'UPDATE source_mounts SET scan_cursor = NULL, last_scan_at = NULL '
    'WHERE source_id = ?',
    [sourceId],
  );
}

/// Removes a source: tombstones it, disables its mount (cursor reset) and
/// hides its `present` and `missing` tracks. `remote` rows are untouched.
Future<void> removeSource(DatabaseConnectionUser db, int sourceId, int now) =>
    _atomically(db, () async {
      await db.customStatement(
        'UPDATE sources SET deleted_at = ?, updated_at = ? WHERE id = ?',
        [now, now, sourceId],
      );
      await _setMount(db, sourceId, false);
      await _hideTracks(db, sourceId, now);
    });

/// Enables or disables the mount of a live source. Disabling hides its
/// tracks; enabling unhides them as `missing` for the next full scan. The
/// scan cursor resets either way. Rows covered by a live folder exclusion
/// stay hidden.
Future<void> setMountEnabled(
  DatabaseConnectionUser db,
  int sourceId,
  bool enabled,
  int now,
) => _atomically(db, () async {
  if (enabled) await _requireLive(db, sourceId);
  await _setMount(db, sourceId, enabled);
  if (enabled) {
    await _unhide(db, sourceId, now, null, null);
  } else {
    await _hideTracks(db, sourceId, now);
  }
});

/// Brings a tombstoned source back: rewrites its editable fields, enables
/// the mount and unhides its tracks as `missing` (never `present`; only a
/// full scan decides that). Rows covered by a live folder exclusion stay
/// hidden.
Future<void> reviveSource(
  DatabaseConnectionUser db,
  int sourceId,
  int now, {
  required String name,
  required String? account,
  required String configJson,
  required String? credentialRef,
}) => _atomically(db, () async {
  await db.customStatement(
    'UPDATE sources SET deleted_at = NULL, name = ?, account = ?, '
    'config_json = ?, credential_ref = ?, updated_at = ? WHERE id = ?',
    [name, account, configJson, credentialRef, now, sourceId],
  );
  await _setMount(db, sourceId, true);
  await _unhide(db, sourceId, now, null, null);
});

/// Turns `hidden` tracks of [sourceId] into `missing` with
/// `missing_since = now` and resets the mount cursor. [locatorFrom] and
/// [locatorTo] (both or neither) limit it to `locator >= from AND locator <
/// to`, for example the range of a folder that is no longer excluded.
/// `remote` rows never change. Throws [StateError] for a removed source:
/// only [reviveSource] brings one back. Rows covered by a live folder
/// exclusion stay hidden.
Future<void> unhideTracks(
  DatabaseConnectionUser db,
  int sourceId,
  int now, {
  String? locatorFrom,
  String? locatorTo,
}) async {
  if ((locatorFrom == null) != (locatorTo == null)) {
    throw ArgumentError('locatorFrom and locatorTo go together');
  }
  await _atomically(db, () async {
    await _requireLive(db, sourceId);
    await _unhide(db, sourceId, now, locatorFrom, locatorTo);
  });
}
