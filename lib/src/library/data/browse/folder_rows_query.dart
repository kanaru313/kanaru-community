import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../../domain/browse/folder_tree.dart';

const _chunk = 500;

/// The visible files of [sourceIds] as tree input. Excluded folders are
/// absent because their tracks are hidden.
Future<List<FolderRow>> folderRows(AppDatabase db, List<int> sourceIds) async {
  final out = <FolderRow>[];
  for (var i = 0; i < sourceIds.length; i += _chunk) {
    final ids = sourceIds.sublist(
      i,
      i + _chunk > sourceIds.length ? sourceIds.length : i + _chunk,
    );
    final rows = await db
        .customSelect(
          'SELECT t.source_id, t.locator, t.cover_key FROM tracks t '
          'WHERE ${visibleTrackWhere('t')} '
          'AND t.source_id IN (${List.filled(ids.length, '?').join(',')})',
          variables: [for (final id in ids) Variable.withInt(id)],
          readsFrom: {db.tracks},
        )
        .get();
    for (final r in rows) {
      out.add((
        sourceId: r.read<int>('source_id'),
        locator: r.read<String>('locator'),
        coverKey: r.readNullable<String>('cover_key'),
      ));
    }
  }
  return out;
}
