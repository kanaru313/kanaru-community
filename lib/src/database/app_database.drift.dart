// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:kanaru/src/database/tables/library_source_tables.drift.dart'
    as i1;
import 'package:kanaru/src/database/tables/library_track_tables.drift.dart'
    as i2;
import 'package:kanaru/src/database/tables/library_track_search.drift.dart'
    as i3;
import 'package:kanaru/src/database/tables/extension_tables.drift.dart' as i4;

abstract class $AppDatabase extends i0.GeneratedDatabase {
  $AppDatabase(i0.QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final i1.$SourcesTable sources = i1.$SourcesTable(this);
  late final i2.$TracksTable tracks = i2.$TracksTable(this);
  late final i3.TrackSearch trackSearch = i3.TrackSearch(this);
  late final i2.$TrackDetailsTable trackDetails = i2.$TrackDetailsTable(this);
  late final i1.$SourceMountsTable sourceMounts = i1.$SourceMountsTable(this);
  late final i1.$ExcludedFoldersTable excludedFolders = i1
      .$ExcludedFoldersTable(this);
  late final i4.$ExtensionSchemaTable extensionSchema = i4
      .$ExtensionSchemaTable(this);
  @override
  Iterable<i0.TableInfo<i0.Table, Object?>> get allTables =>
      allSchemaEntities.whereType<i0.TableInfo<i0.Table, Object?>>();
  @override
  List<i0.DatabaseSchemaEntity> get allSchemaEntities => [
    sources,
    tracks,
    trackSearch,
    i3.tracksSearchInsert,
    i3.tracksSearchDelete,
    i3.tracksSearchUpdate,
    trackDetails,
    i2.tracksPresentTitle,
    i2.tracksStatus,
    i2.tracksAddedAt,
    i2.tracksAlbumKey,
    i2.tracksSongKey,
    i2.tracksRelPath,
    i2.tracksLanguage,
    sourceMounts,
    excludedFolders,
    i1.sourceMountsRoot,
    i1.excludedFoldersSource,
    extensionSchema,
  ];
  @override
  i0.StreamQueryUpdateRules get streamUpdateRules =>
      const i0.StreamQueryUpdateRules([
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'tracks',
            limitUpdateKind: i0.UpdateKind.insert,
          ),
          result: [i0.TableUpdate('track_search', kind: i0.UpdateKind.insert)],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'tracks',
            limitUpdateKind: i0.UpdateKind.delete,
          ),
          result: [i0.TableUpdate('track_search', kind: i0.UpdateKind.insert)],
        ),
        i0.WritePropagation(
          on: i0.TableUpdateQuery.onTableName(
            'tracks',
            limitUpdateKind: i0.UpdateKind.update,
          ),
          result: [i0.TableUpdate('track_search', kind: i0.UpdateKind.insert)],
        ),
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
  i1.$$SourcesTableTableManager get sources =>
      i1.$$SourcesTableTableManager(_db, _db.sources);
  i2.$$TracksTableTableManager get tracks =>
      i2.$$TracksTableTableManager(_db, _db.tracks);
  i3.$TrackSearchTableManager get trackSearch =>
      i3.$TrackSearchTableManager(_db, _db.trackSearch);
  i2.$$TrackDetailsTableTableManager get trackDetails =>
      i2.$$TrackDetailsTableTableManager(_db, _db.trackDetails);
  i1.$$SourceMountsTableTableManager get sourceMounts =>
      i1.$$SourceMountsTableTableManager(_db, _db.sourceMounts);
  i1.$$ExcludedFoldersTableTableManager get excludedFolders =>
      i1.$$ExcludedFoldersTableTableManager(_db, _db.excludedFolders);
  i4.$$ExtensionSchemaTableTableManager get extensionSchema =>
      i4.$$ExtensionSchemaTableTableManager(_db, _db.extensionSchema);
}
