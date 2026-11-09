// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:kanaru/src/database/tables/extension_tables.drift.dart' as i1;
import 'package:kanaru/src/database/tables/library_source_tables.drift.dart'
    as i2;
import 'package:kanaru/src/database/tables/library_track_tables.drift.dart'
    as i3;

abstract class $AppDatabase extends i0.GeneratedDatabase {
  $AppDatabase(i0.QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final i1.$ExtensionSchemaTable extensionSchema = i1
      .$ExtensionSchemaTable(this);
  late final i2.$SourcesTable sources = i2.$SourcesTable(this);
  late final i2.$SourceMountsTable sourceMounts = i2.$SourceMountsTable(this);
  late final i2.$ExcludedFoldersTable excludedFolders = i2
      .$ExcludedFoldersTable(this);
  late final i3.$TracksTable tracks = i3.$TracksTable(this);
  late final i3.$TrackDetailsTable trackDetails = i3.$TrackDetailsTable(this);
  @override
  Iterable<i0.TableInfo<i0.Table, Object?>> get allTables =>
      allSchemaEntities.whereType<i0.TableInfo<i0.Table, Object?>>();
  @override
  List<i0.DatabaseSchemaEntity> get allSchemaEntities => [
    extensionSchema,
    sources,
    sourceMounts,
    excludedFolders,
    tracks,
    trackDetails,
    i2.sourceMountsRoot,
    i2.excludedFoldersSource,
    i3.tracksPresentTitle,
    i3.tracksStatus,
    i3.tracksAddedAt,
    i3.tracksAlbumKey,
    i3.tracksSongKey,
    i3.tracksRelPath,
    i3.tracksLanguage,
  ];
  @override
  i0.StreamQueryUpdateRules get streamUpdateRules =>
      const i0.StreamQueryUpdateRules([
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'sources',
            limitUpdateKind: i0.UpdateKind.delete,
          ),
          result: [i0.TableUpdate('source_mounts', kind: i0.UpdateKind.delete)],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'sources',
            limitUpdateKind: i0.UpdateKind.delete,
          ),
          result: [
            i0.TableUpdate('excluded_folders', kind: i0.UpdateKind.delete),
          ],
        ),
      ]);
}

class $AppDatabaseManager {
  final $AppDatabase _db;
  $AppDatabaseManager(this._db);
  i1.$$ExtensionSchemaTableTableManager get extensionSchema =>
      i1.$$ExtensionSchemaTableTableManager(_db, _db.extensionSchema);
  i2.$$SourcesTableTableManager get sources =>
      i2.$$SourcesTableTableManager(_db, _db.sources);
  i2.$$SourceMountsTableTableManager get sourceMounts =>
      i2.$$SourceMountsTableTableManager(_db, _db.sourceMounts);
  i2.$$ExcludedFoldersTableTableManager get excludedFolders =>
      i2.$$ExcludedFoldersTableTableManager(_db, _db.excludedFolders);
  i3.$$TracksTableTableManager get tracks =>
      i3.$$TracksTableTableManager(_db, _db.tracks);
  i3.$$TrackDetailsTableTableManager get trackDetails =>
      i3.$$TrackDetailsTableTableManager(_db, _db.trackDetails);
}
