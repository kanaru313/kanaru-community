import 'package:drift/drift.dart';

/// One schema object: its normalized SQL and the table it belongs to.
typedef SchemaObject = ({String sql, String table});

/// Tables, indexes and triggers of [db] as `type:name` -> [SchemaObject],
/// without SQLite internals and FTS5 shadow tables.
Future<Map<String, SchemaObject>> dumpSchema(DatabaseConnectionUser db) async {
  final rows = await db.customSelect('''
    SELECT type, name, tbl_name, sql FROM sqlite_master AS m
    WHERE name NOT LIKE 'sqlite\\_%' ESCAPE '\\'
      AND sql IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM sqlite_master AS v
        WHERE v.sql LIKE 'CREATE VIRTUAL TABLE%'
          AND m.name IN (v.name || '_data', v.name || '_idx',
                         v.name || '_content', v.name || '_docsize',
                         v.name || '_config')
      )
  ''').get();
  return {
    for (final r in rows)
      '${r.read<String>('type')}:${r.read<String>('name')}': (
        sql: r.read<String>('sql').replaceAll(RegExp(r'\s+'), ' ').trim(),
        table: r.read<String>('tbl_name'),
      ),
  };
}

/// Path of the main database file of [db]; empty when it lives in memory.
Future<String> databaseFilePath(DatabaseConnectionUser db) async {
  final rows = await db
      .customSelect("SELECT file FROM pragma_database_list WHERE name = 'main'")
      .get();
  return rows.isEmpty ? '' : (rows.first.read<String?>('file') ?? '');
}

/// Development guard: fails when the database file was created by an older
/// build of schema v1, which keeps `schemaVersion` at 1 while tables change.
///
/// Compares every table, index and trigger of the reference schema (a fresh
/// in-memory database from [openReference]) with [db]. Tables that only [db]
/// has are ignored, with their own indexes and triggers: extension databases
/// add their tables to the same file. An index or trigger that only [db] has
/// on a table of the reference schema is reported as extra. In-memory
/// databases are skipped. Throws [StateError] naming the file and the
/// differing objects.
Future<void> verifyDevSchema(
  DatabaseConnectionUser db, {
  required GeneratedDatabase Function() openReference,
}) async {
  final path = await databaseFilePath(db);
  if (path.isEmpty) return;
  final reference = openReference();
  final Map<String, SchemaObject> expected;
  try {
    expected = await dumpSchema(reference);
  } finally {
    await reference.close();
  }
  final actual = await dumpSchema(db);
  final differing = [
    for (final e in expected.entries)
      if (actual[e.key] != e.value) e.key,
    for (final e in actual.entries)
      if (!e.key.startsWith('table:') &&
          !expected.containsKey(e.key) &&
          expected.containsKey('table:${e.value.table}'))
        'extra ${e.key}',
    if (actual.containsKey('table:play_stats_ctl') && !await _hasStatsSeed(db))
      'missing seed row of play_stats_ctl',
  ]..sort();
  if (differing.isEmpty) return;
  throw StateError(
    'kanaru.db was created by an older build of schema v1; delete it '
    '(dev builds only): $path. Differing schema objects: ${differing.join(', ')}',
  );
}

/// The stats triggers only run while `play_stats_ctl` has its row 1.
Future<bool> _hasStatsSeed(DatabaseConnectionUser db) async {
  final rows = await db
      .customSelect('SELECT 1 FROM play_stats_ctl WHERE id = 1')
      .get();
  return rows.isNotEmpty;
}
