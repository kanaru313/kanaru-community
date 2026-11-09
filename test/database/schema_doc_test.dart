import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/test_db.dart';

/// FTS5 shadow tables of `track_search`: implementation detail, not spec.
const _ftsShadowTables = {
  'track_search_data',
  'track_search_idx',
  'track_search_content',
  'track_search_docsize',
  'track_search_config',
};

void main() {
  test('every table, index and trigger is named in the database spec', () async {
    final db = openTestDb();
    addTearDown(db.close);

    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE name NOT LIKE 'sqlite_%' "
          'AND sql IS NOT NULL',
        )
        .get();
    final names = rows
        .map((r) => r.read<String>('name'))
        .where((n) => !_ftsShadowTables.contains(n))
        .toSet();
    expect(names, isNotEmpty);

    final doc = File('docs/system-architecture-database.md').readAsStringSync();
    final missing = names.where((n) => !doc.contains(n)).toList()..sort();
    expect(
      missing,
      isEmpty,
      reason: 'Not named in docs/system-architecture-database.md: $missing',
    );
  });
}
