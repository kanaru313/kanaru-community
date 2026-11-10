import 'package:drift/drift.dart' show Value, Variable;

import '../../../database/database.dart';
import '../../../foundation/ids/ulid.dart';

/// How [addLocalSource] stored the folder.
enum SourceWrite { added, revived, alreadyLive }

/// Stores a music folder [root] as a local source with an enabled mount, in
/// one transaction. A root that was chosen before keeps its source (same id)
/// and comes back through `reviveSource`: its tracks return as `missing`
/// for the next scan, its removed exclusions stay removed. A root that is
/// already chosen and enabled changes nothing.
Future<SourceWrite> addLocalSource(
  AppDatabase db, {
  required String root,
  required String name,
  required int now,
}) => db.transaction(() async {
  final known = await db
      .customSelect(
        'SELECT m.source_id, m.enabled, s.deleted_at FROM source_mounts m '
        'JOIN sources s ON s.id = m.source_id WHERE m.root = ?',
        variables: [Variable.withString(root)],
        readsFrom: {db.sourceMounts, db.sources},
      )
      .get();
  if (known.isNotEmpty) {
    final row = known.single;
    final id = row.read<int>('source_id');
    final tombstoned = row.read<int?>('deleted_at') != null;
    if (tombstoned) {
      await reviveSource(
        db,
        id,
        now,
        name: name,
        account: null,
        configJson: '{}',
        credentialRef: null,
      );
      return SourceWrite.revived;
    }
    if (row.read<bool>('enabled')) return SourceWrite.alreadyLive;
    await setMountEnabled(db, id, true, now);
    return SourceWrite.revived;
  }
  final id = await db
      .into(db.sources)
      .insert(
        SourcesCompanion.insert(
          uid: newUlid(),
          kind: SourceKind.local,
          name: name,
          addedAt: now,
          updatedAt: now,
        ),
      );
  await db
      .into(db.sourceMounts)
      .insert(
        SourceMountsCompanion.insert(
          sourceId: Value(id),
          root: Value(root),
          addedAt: now,
        ),
      );
  return SourceWrite.added;
});

/// Removes a music folder: its live exclusions are removed first (so adding
/// the root again does not bring them back), then the source is tombstoned
/// and its tracks hidden. One transaction.
Future<void> removeLocalSource(AppDatabase db, int sourceId, int now) =>
    db.transaction(() async {
      for (final key in await excludedFolderKeys(db, sourceId)) {
        await removeFolderExclusion(
          db,
          sourceId: sourceId,
          folderKey: key,
          now: now,
        );
      }
      await removeSource(db, sourceId, now);
    });
