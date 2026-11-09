import 'package:logging/logging.dart';

import '../../database/database.dart';
import '../../platform/domain/storage_volumes.dart';
import '../domain/music_folder.dart';

/// Live local sources that have an enabled mount, ordered by root. Mounts
/// without a root are skipped (nothing to show or scan).
Stream<List<MusicFolder>> watchMusicFolders(
  AppDatabase db,
  StorageVolumes volumes,
) {
  return db
      .customSelect(
        'SELECT s.id, s.uid, s.name, m.root FROM sources s '
        'JOIN source_mounts m ON m.source_id = s.id '
        "WHERE s.kind = '${SourceKind.local}' AND s.deleted_at IS NULL "
        'AND m.enabled = 1 AND m.root IS NOT NULL ORDER BY m.root, s.id',
        readsFrom: {db.sources, db.sourceMounts},
      )
      .watch()
      .asyncMap((rows) async {
        // A volume can be mounted or removed between emissions; volumeOf
        // answers from the last listing.
        try {
          await volumes.list();
        } on Object catch (e, st) {
          Logger('library.folders').warning('listing volumes failed', e, st);
        }
        return [
          for (final r in rows)
            MusicFolder(
              sourceId: r.read<int>('id'),
              sourceUid: r.read<String>('uid'),
              root: r.read<String>('root'),
              volume: volumes.volumeOf(r.read<String>('root')),
              name: r.read<String>('name'),
            ),
        ];
      });
}
