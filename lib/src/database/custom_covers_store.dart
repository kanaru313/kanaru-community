import 'package:drift/drift.dart';

import 'app_database.dart';

import 'tables/library_cover_tables.dart';

void _checkKind(String kind) {
  if (!CustomCoverKinds.values.contains(kind)) {
    throw ArgumentError.value(kind, 'kind', 'not a custom cover kind');
  }
}

/// Sets (or replaces) the custom cover of one item and returns the cover key
/// it replaced, or null when there was none. [coverKey] is the content hash of
/// the stored image. Failed future: [ArgumentError] for an unknown [kind] or an
/// empty [itemKey] / [coverKey]; for a `playlist` whose uid has no row, a
/// `SqliteException` from the `custom_covers_playlist_exists_*` trigger
/// (`DriftRemoteException` on the file database). Notifies `custom_covers`.
Future<String?> setCustomCover(
  DatabaseConnectionUser db,
  String kind,
  String itemKey,
  String coverKey, {
  int? now,
}) async {
  _checkKind(kind);
  if (itemKey.isEmpty) throw ArgumentError.value(itemKey, 'itemKey');
  if (coverKey.isEmpty) throw ArgumentError.value(coverKey, 'coverKey');
  return db.transaction(() async {
    final previous = await customCoverKey(db, kind, itemKey);
    await db.customInsert(
      'INSERT INTO custom_covers (kind, item_key, cover_key, updated_at) '
      'VALUES (?, ?, ?, ?) ON CONFLICT (kind, item_key) DO UPDATE SET '
      'cover_key = excluded.cover_key, updated_at = excluded.updated_at',
      variables: [
        Variable.withString(kind),
        Variable.withString(itemKey),
        Variable.withString(coverKey),
        Variable.withInt(now ?? DateTime.now().millisecondsSinceEpoch),
      ],
    );
    db.notifyUpdates({const TableUpdate('custom_covers')});
    return previous;
  });
}

/// Removes the custom cover row of one item and returns its cover key, or null
/// when there was none. Notifies `custom_covers`.
Future<String?> clearCustomCover(
  DatabaseConnectionUser db,
  String kind,
  String itemKey,
) async {
  _checkKind(kind);
  return db.transaction(() async {
    final previous = await customCoverKey(db, kind, itemKey);
    if (previous == null) return null;
    await db.customUpdate(
      'DELETE FROM custom_covers WHERE kind = ? AND item_key = ?',
      variables: [Variable.withString(kind), Variable.withString(itemKey)],
    );
    db.notifyUpdates({
      const TableUpdate('custom_covers', kind: UpdateKind.delete),
    });
    return previous;
  });
}

/// The cover key of one item, or null.
Future<String?> customCoverKey(
  DatabaseConnectionUser db,
  String kind,
  String itemKey,
) async {
  final rows = await db
      .customSelect(
        'SELECT cover_key FROM custom_covers WHERE kind = ? AND item_key = ?',
        variables: [Variable.withString(kind), Variable.withString(itemKey)],
      )
      .get();
  return rows.isEmpty ? null : rows.single.read<String>('cover_key');
}

/// Live cover key of one item (emits null when there is none); re-emits only
/// when it changes. Takes the [AppDatabase] because a stream needs the typed
/// table. Also fires when the playlist trigger removes the row.
Stream<String?> watchCustomCoverKey(
  AppDatabase db,
  String kind,
  String itemKey,
) => db
    .customSelect(
      'SELECT cover_key FROM custom_covers WHERE kind = ? AND item_key = ?',
      variables: [Variable.withString(kind), Variable.withString(itemKey)],
      readsFrom: {db.customCovers},
    )
    .watch()
    .map((rows) => rows.isEmpty ? null : rows.single.read<String>('cover_key'))
    .distinct();

/// Every cover key some row references: what the file GC must keep.
Future<Set<String>> referencedCustomCoverKeys(DatabaseConnectionUser db) async {
  final rows = await db
      .customSelect('SELECT DISTINCT cover_key FROM custom_covers')
      .get();
  return {for (final r in rows) r.read<String>('cover_key')};
}

/// True when some row still references [coverKey].
Future<bool> isCustomCoverKeyReferenced(
  DatabaseConnectionUser db,
  String coverKey,
) async {
  final rows = await db
      .customSelect(
        'SELECT 1 FROM custom_covers WHERE cover_key = ? LIMIT 1',
        variables: [Variable.withString(coverKey)],
      )
      .get();
  return rows.isNotEmpty;
}
