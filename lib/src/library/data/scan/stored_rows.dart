import 'package:drift/drift.dart' show Variable;

import '../../../database/database.dart';
import '../../domain/scan/scan_diff.dart';
import 'scan_yield.dart';

/// Rows per page of [storedRowsOf].
const int storedRowsPageSize = 1000;

/// The `present` and `missing` rows of [sourceId], ordered by locator, read
/// in pages of [pageSize] with a yield between pages (the rows of a big
/// library are never one result). [onPage] is called once per page read.
Future<List<StoredTrackRow>> storedRowsOf(
  AppDatabase db,
  int sourceId, {
  int pageSize = storedRowsPageSize,
  void Function()? onPage,
  ScanYield? yielder,
}) async {
  final rows = <StoredTrackRow>[];
  final pause = yielder ?? ScanYield();
  var after = '';
  while (true) {
    final page = await db
        .customSelect(
          'SELECT t.id, t.locator, t.mtime_ms, t.size_bytes, t.revision, '
          't.tags_version, t.keys_version, t.status, d.lrc_locator, '
          'd.lrc_revision, d.track_id IS NOT NULL AS has_details '
          'FROM tracks t LEFT JOIN track_details d ON d.track_id = t.id '
          "WHERE t.source_id = ?1 AND t.status IN ('present', 'missing') "
          'AND t.locator > ?2 ORDER BY t.locator LIMIT ?3',
          variables: [
            Variable.withInt(sourceId),
            Variable.withString(after),
            Variable.withInt(pageSize),
          ],
          readsFrom: {db.tracks, db.trackDetails},
        )
        .get();
    onPage?.call();
    for (final r in page) {
      rows.add(
        StoredTrackRow(
          id: r.read<int>('id'),
          locator: r.read<String>('locator'),
          mtimeMs: r.readNullable<int>('mtime_ms'),
          sizeBytes: r.readNullable<int>('size_bytes'),
          revision: r.readNullable<String>('revision'),
          tagsVersion: r.read<int>('tags_version'),
          keysVersion: r.read<int>('keys_version'),
          status: r.read<String>('status'),
          lrcLocator: r.readNullable<String>('lrc_locator'),
          lrcRevision: r.readNullable<String>('lrc_revision'),
          hasDetails: r.read<bool>('has_details'),
        ),
      );
    }
    if (page.length < pageSize) return rows;
    after = rows.last.locator;
    await pause.now();
  }
}
