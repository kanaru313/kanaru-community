import 'dart:convert';
import 'dart:developer' as developer;

import 'package:drift/drift.dart';

/// Stores the colours of a cover: `ON CONFLICT (cover_key) DO UPDATE`, so a
/// version at least as new as the stored one replaces the row (an older
/// producer never overwrites a newer result). [colors] are ARGB ints, most dominant
/// first. Throws [ArgumentError] for an empty key or palette. Notifies
/// `cover_colors`.
Future<void> upsertCoverColors(
  DatabaseConnectionUser db, {
  required String coverKey,
  required int seed,
  required List<int> colors,
  required int version,
  required int now,
}) async {
  if (coverKey.isEmpty) throw ArgumentError.value(coverKey, 'coverKey');
  if (colors.isEmpty) throw ArgumentError.value(colors, 'colors', 'is empty');
  await db.customInsert(
    'INSERT INTO cover_colors (cover_key, seed, colors, version, updated_at) '
    'VALUES (?, ?, ?, ?, ?) '
    'ON CONFLICT (cover_key) DO UPDATE SET seed = excluded.seed, '
    'colors = excluded.colors, version = excluded.version, '
    'updated_at = excluded.updated_at '
    'WHERE excluded.version >= cover_colors.version',
    variables: [
      Variable.withString(coverKey),
      Variable.withInt(seed),
      Variable.withString(jsonEncode(colors)),
      Variable.withInt(version),
      Variable.withInt(now),
    ],
  );
  db.notifyUpdates({const TableUpdate('cover_colors')});
}

/// The stored colours of [coverKey], or null when there is no row or its
/// `colors` JSON is malformed (logged; the caller recomputes).
Future<({int seed, List<int> colors, int version})?> coverColorsFor(
  DatabaseConnectionUser db,
  String coverKey,
) async {
  final rows = await db
      .customSelect(
        'SELECT seed, colors, version FROM cover_colors WHERE cover_key = ?',
        variables: [Variable.withString(coverKey)],
      )
      .get();
  if (rows.isEmpty) return null;
  final r = rows.single;
  try {
    final decoded = jsonDecode(r.read<String>('colors'));
    if (decoded is! List || decoded.isEmpty || decoded.any((c) => c is! int)) {
      throw const FormatException('not a non-empty list of ints');
    }
    return (
      seed: r.read<int>('seed'),
      colors: decoded.cast<int>(),
      version: r.read<int>('version'),
    );
  } on FormatException catch (e) {
    developer.log(
      'malformed cover_colors row for $coverKey: $e',
      name: 'kanaru.database',
    );
    return null;
  }
}
