import '../../../database/database.dart';
import '../../domain/scan/scan_folder.dart';

/// The folders a scan covers: live local sources whose mount is enabled and
/// has a root, ordered by root. Read from the database each time, never from
/// a cached stream.
Future<List<ScanFolder>> liveScanFolders(AppDatabase db) async {
  final rows = await db
      .customSelect(
        'SELECT s.id, s.uid, m.root FROM sources s '
        'JOIN source_mounts m ON m.source_id = s.id '
        "WHERE s.kind = '${SourceKind.local}' AND s.deleted_at IS NULL "
        'AND m.enabled = 1 AND m.root IS NOT NULL ORDER BY m.root, s.id',
        readsFrom: {db.sources, db.sourceMounts},
      )
      .get();
  return [
    for (final r in rows)
      ScanFolder(
        sourceId: r.read<int>('id'),
        sourceUid: r.read<String>('uid'),
        root: r.read<String>('root'),
      ),
  ];
}
