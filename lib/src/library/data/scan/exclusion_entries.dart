import '../../../database/database.dart';
import '../../domain/scan/folder_edit_results.dart';

/// Live exclusions of every chosen music folder, ordered by folder and key.
Stream<List<ExclusionEntry>> watchExclusionEntries(AppDatabase db) => db
    .customSelect(
      'SELECT e.source_id, e.folder_key, e.display_path '
      'FROM excluded_folders e JOIN sources s ON s.id = e.source_id '
      'JOIN source_mounts m ON m.source_id = s.id '
      'WHERE e.deleted_at IS NULL AND s.deleted_at IS NULL '
      'AND m.enabled = 1 AND m.root IS NOT NULL '
      'ORDER BY m.root, e.folder_key',
      readsFrom: {db.excludedFolders, db.sources, db.sourceMounts},
    )
    .watch()
    .map(
      (rows) => [
        for (final r in rows)
          ExclusionEntry(
            sourceId: r.read<int>('source_id'),
            folderKey: r.read<String>('folder_key'),
            displayPath: r.read<String>('display_path'),
          ),
      ],
    );
