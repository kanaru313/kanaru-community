import 'dart:io';

import 'package:drift/drift.dart' show Variable;

import '../../../database/database.dart';
import '../../../media/domain/cover_colors.dart' show coverColorsVersion;
import '../../domain/scan/scan_versions.dart';

/// Keys per query in [coverWorkSet].
const int coverKeyChunk = 200;

/// Ids of the present rows (of enabled mounts) whose `cover_scan_version` is
/// below the pass version, ordered by source and locator; optionally limited
/// to [sourceIds] or to rows holding one of [onlyKeys].
Future<List<int>> coverWorkSet(
  AppDatabase db,
  Set<int>? sourceIds,
  Set<String>? onlyKeys,
) async {
  if (onlyKeys == null || onlyKeys.isEmpty) {
    return _workSetFor(db, sourceIds, const []);
  }
  // Key lists are cut to 200 placeholders per query (a miss storm can report
  // thousands of keys); each row holds one key, so chunks do not overlap.
  final keys = onlyKeys.toList();
  final ids = <int>[];
  for (var i = 0; i < keys.length; i += coverKeyChunk) {
    final end = i + coverKeyChunk > keys.length
        ? keys.length
        : i + coverKeyChunk;
    ids.addAll(await _workSetFor(db, sourceIds, keys.sublist(i, end)));
  }
  return ids;
}

Future<List<int>> _workSetFor(
  AppDatabase db,
  Set<int>? sourceIds,
  List<String> keys,
) async {
  final sourceFilter = sourceIds == null || sourceIds.isEmpty
      ? ''
      : 'AND t.source_id IN (${List.filled(sourceIds.length, '?').join(',')}) ';
  final keyFilter = keys.isEmpty
      ? ''
      : 'AND t.cover_key IN (${List.filled(keys.length, '?').join(',')}) ';
  final rows = await db
      .customSelect(
        'SELECT t.id FROM tracks t JOIN source_mounts m '
        'ON m.source_id = t.source_id '
        "WHERE t.status = 'present' AND t.cover_scan_version < ? "
        'AND m.enabled = 1 AND m.root IS NOT NULL $sourceFilter$keyFilter'
        'ORDER BY t.source_id, t.locator',
        variables: [
          Variable.withInt(coverPassVersion),
          for (final s in sourceIds ?? const <int>{}) Variable.withInt(s),
          for (final k in keys) Variable.withString(k),
        ],
        readsFrom: {db.tracks, db.sourceMounts},
      )
      .get();
  return [for (final r in rows) r.read<int>('id')];
}

Future<List<({int id, String path})>> coverItemsOf(
  AppDatabase db,
  List<int> ids,
) async {
  final rows = await db
      .customSelect(
        'SELECT t.id, t.locator, m.root FROM tracks t JOIN source_mounts m '
        'ON m.source_id = t.source_id '
        "WHERE t.status = 'present' AND t.id IN "
        '(${List.filled(ids.length, '?').join(',')})',
        variables: [for (final id in ids) Variable.withInt(id)],
        readsFrom: {db.tracks, db.sourceMounts},
      )
      .get();
  final byId = {
    for (final r in rows)
      r.read<int>('id'): _join(
        r.read<String>('root'),
        r.read<String>('locator'),
      ),
  };
  return [
    for (final id in ids)
      if (byId[id] case final path?) (id: id, path: path),
  ];
}

String _join(String root, String locator) =>
    root.endsWith(Platform.pathSeparator) ? '$root$locator' : '$root/$locator';

/// The subset of [keys] (at most [coverKeyChunk]) that has a colour row of
/// the current version.
Future<Set<String>> currentColorKeys(AppDatabase db, List<String> keys) async {
  final rows = await db
      .customSelect(
        'SELECT cover_key FROM cover_colors WHERE version >= ? '
        'AND cover_key IN (${List.filled(keys.length, '?').join(',')})',
        variables: [
          Variable.withInt(coverColorsVersion),
          for (final k in keys) Variable.withString(k),
        ],
        readsFrom: {db.coverColors},
      )
      .get();
  return {for (final r in rows) r.read<String>('cover_key')};
}
