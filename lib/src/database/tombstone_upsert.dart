import 'package:drift/drift.dart';

/// Columns [insertOrRevive] never lets a caller list as revive columns.
const _reserved = {'id', 'uid', 'deleted_at', 'updated_at'};

/// Inserts [row] or, when a row with the same `uid` exists, updates it:
/// `INSERT ... ON CONFLICT(uid) DO UPDATE SET deleted_at = NULL,
/// updated_at = now, ...`. Returns the stored row; a conflict keeps the
/// original `id`. Only that one row is touched, so reviving a playlist does
/// not bring back its entries.
///
/// For tables whose uid is deterministic (Favorites, favorite entries,
/// remote sources, excluded folders, saved items).
///
/// [reviveColumns] names columns taken from [row] when a tombstoned row is
/// revived. A live row keeps its own values there (a second favorite of the
/// same track keeps its place); only `updated_at` changes.
///
/// Throws [ArgumentError] (as a failed future) when [table] lacks `uid`,
/// `deleted_at` or `updated_at`, when [reviveColumns] names an unknown
/// column, `id`, `uid`, `deleted_at` or `updated_at`, or when a listed
/// column is absent from [row] (the revive would take the column default).
Future<D> insertOrRevive<T extends Table, D>(
  DatabaseConnectionUser db,
  TableInfo<T, D> table,
  Insertable<D> row, {
  required int now,
  Set<String> reviveColumns = const {},
}) async {
  final columns = table.columnsByName;
  for (final name in const ['uid', 'deleted_at', 'updated_at']) {
    if (!columns.containsKey(name)) {
      throw ArgumentError.value(
          table.actualTableName, 'table', 'has no $name column');
    }
  }
  final given = row.toColumns(false);
  for (final name in reviveColumns) {
    if (!columns.containsKey(name) || _reserved.contains(name)) {
      throw ArgumentError.value(name, 'reviveColumns', 'not a revivable column');
    }
    if (!given.containsKey(name)) {
      throw ArgumentError.value(name, 'reviveColumns', 'missing from the row');
    }
  }
  final t = '"${table.actualTableName}"';
  final update = <String, Expression<Object>>{
    'deleted_at': const Constant<int>(null),
    'updated_at': Variable<int>(now),
    for (final c in reviveColumns)
      c: CustomExpression<Object>(
          'CASE WHEN $t."deleted_at" IS NULL THEN $t."$c" '
          'ELSE excluded."$c" END'),
  };
  return db.into(table).insertReturning(
        row,
        onConflict: DoUpdate(
          (_) => RawValuesInsertable<D>(update),
          target: [columns['uid']!],
        ),
      );
}
