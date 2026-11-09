// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:kanaru/src/database/tables/library_source_tables.drift.dart'
    as i1;
import 'package:kanaru/src/database/tables/library_source_tables.dart' as i2;
import 'package:drift/src/runtime/query_builder/query_builder.dart' as i3;
import 'package:drift/internal/modular.dart' as i4;

typedef $$SourcesTableCreateCompanionBuilder = i1.SourcesCompanion Function({
  i0.Value<int> id,
  required String uid,
  required String kind,
  required String name,
  i0.Value<String?> account,
  i0.Value<String?> root,
  i0.Value<String> configJson,
  i0.Value<String?> credentialRef,
  required int addedAt,
  required int updatedAt,
  i0.Value<int?> deletedAt,
});
typedef $$SourcesTableUpdateCompanionBuilder = i1.SourcesCompanion Function({
  i0.Value<int> id,
  i0.Value<String> uid,
  i0.Value<String> kind,
  i0.Value<String> name,
  i0.Value<String?> account,
  i0.Value<String?> root,
  i0.Value<String> configJson,
  i0.Value<String?> credentialRef,
  i0.Value<int> addedAt,
  i0.Value<int> updatedAt,
  i0.Value<int?> deletedAt,
});

final class $$SourcesTableReferences
    extends
        i0.BaseReferences<i0.GeneratedDatabase, i1.$SourcesTable, i1.Source> {
  $$SourcesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static i0.MultiTypedResultKey<i1.$SourceMountsTable, List<i1.SourceMount>>
  _sourceMountsRefsTable(i0.GeneratedDatabase db) =>
      i0.MultiTypedResultKey.fromTable(
        i4.ReadDatabaseContainer(db)
            .resultSet<i1.$SourceMountsTable>('source_mounts'),
        aliasName: 'sources__id__source_mounts__source_id',
      );

  i1.$$SourceMountsTableProcessedTableManager get sourceMountsRefs {
    final manager = i1
        .$$SourceMountsTableTableManager(
          $_db,
          i4.ReadDatabaseContainer($_db)
              .resultSet<i1.$SourceMountsTable>('source_mounts'),
        )
        .filter((f) => f.sourceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sourceMountsRefsTable($_db));
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static i0.MultiTypedResultKey<
    i1.$ExcludedFoldersTable,
    List<i1.ExcludedFolder>
  >
  _excludedFoldersRefsTable(i0.GeneratedDatabase db) =>
      i0.MultiTypedResultKey.fromTable(
        i4.ReadDatabaseContainer(db)
            .resultSet<i1.$ExcludedFoldersTable>('excluded_folders'),
        aliasName: 'sources__id__excluded_folders__source_id',
      );

  i1.$$ExcludedFoldersTableProcessedTableManager get excludedFoldersRefs {
    final manager = i1
        .$$ExcludedFoldersTableTableManager(
          $_db,
          i4.ReadDatabaseContainer($_db)
              .resultSet<i1.$ExcludedFoldersTable>('excluded_folders'),
        )
        .filter((f) => f.sourceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _excludedFoldersRefsTable($_db),
    );
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SourcesTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$SourcesTable> {
  $$SourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get account => $composableBuilder(
    column: $table.account,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get root => $composableBuilder(
    column: $table.root,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get credentialRef => $composableBuilder(
    column: $table.credentialRef,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.Expression<bool> sourceMountsRefs(
    i0.Expression<bool> Function(i1.$$SourceMountsTableFilterComposer f) f,
  ) {
    final i1.$$SourceMountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i4.ReadDatabaseContainer($db)
          .resultSet<i1.$SourceMountsTable>('source_mounts'),
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i1.$$SourceMountsTableFilterComposer(
            $db: $db,
            $table: i4.ReadDatabaseContainer($db)
                .resultSet<i1.$SourceMountsTable>('source_mounts'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  i0.Expression<bool> excludedFoldersRefs(
    i0.Expression<bool> Function(i1.$$ExcludedFoldersTableFilterComposer f) f,
  ) {
    final i1.$$ExcludedFoldersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i4.ReadDatabaseContainer($db)
          .resultSet<i1.$ExcludedFoldersTable>('excluded_folders'),
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i1.$$ExcludedFoldersTableFilterComposer(
            $db: $db,
            $table: i4.ReadDatabaseContainer($db)
                .resultSet<i1.$ExcludedFoldersTable>('excluded_folders'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SourcesTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$SourcesTable> {
  $$SourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get account => $composableBuilder(
    column: $table.account,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get root => $composableBuilder(
    column: $table.root,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get credentialRef => $composableBuilder(
    column: $table.credentialRef,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $$SourcesTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$SourcesTable> {
  $$SourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  i0.GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  i0.GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  i0.GeneratedColumn<String> get account =>
      $composableBuilder(column: $table.account, builder: (column) => column);

  i0.GeneratedColumn<String> get root =>
      $composableBuilder(column: $table.root, builder: (column) => column);

  i0.GeneratedColumn<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get credentialRef => $composableBuilder(
    column: $table.credentialRef,
    builder: (column) => column,
  );

  i0.GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  i0.GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  i0.GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  i0.Expression<T> sourceMountsRefs<T extends Object>(
    i0.Expression<T> Function(i1.$$SourceMountsTableAnnotationComposer a) f,
  ) {
    final i1.$$SourceMountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i4.ReadDatabaseContainer($db)
          .resultSet<i1.$SourceMountsTable>('source_mounts'),
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i1.$$SourceMountsTableAnnotationComposer(
            $db: $db,
            $table: i4.ReadDatabaseContainer($db)
                .resultSet<i1.$SourceMountsTable>('source_mounts'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  i0.Expression<T> excludedFoldersRefs<T extends Object>(
    i0.Expression<T> Function(i1.$$ExcludedFoldersTableAnnotationComposer a) f,
  ) {
    final i1.$$ExcludedFoldersTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: i4.ReadDatabaseContainer($db)
              .resultSet<i1.$ExcludedFoldersTable>('excluded_folders'),
          getReferencedColumn: (t) => t.sourceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => i1.$$ExcludedFoldersTableAnnotationComposer(
                $db: $db,
                $table: i4.ReadDatabaseContainer($db)
                    .resultSet<i1.$ExcludedFoldersTable>('excluded_folders'),
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SourcesTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$SourcesTable,
          i1.Source,
          i1.$$SourcesTableFilterComposer,
          i1.$$SourcesTableOrderingComposer,
          i1.$$SourcesTableAnnotationComposer,
          $$SourcesTableCreateCompanionBuilder,
          $$SourcesTableUpdateCompanionBuilder,
          (i1.Source, i1.$$SourcesTableReferences),
          i1.Source,
          i0.PrefetchHooks Function({
            bool sourceMountsRefs,
            bool excludedFoldersRefs,
          })
        > {
  $$SourcesTableTableManager(i0.GeneratedDatabase db, i1.$SourcesTable table)
    : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$SourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$SourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$SourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                i0.Value<String> uid = const i0.Value.absent(),
                i0.Value<String> kind = const i0.Value.absent(),
                i0.Value<String> name = const i0.Value.absent(),
                i0.Value<String?> account = const i0.Value.absent(),
                i0.Value<String?> root = const i0.Value.absent(),
                i0.Value<String> configJson = const i0.Value.absent(),
                i0.Value<String?> credentialRef = const i0.Value.absent(),
                i0.Value<int> addedAt = const i0.Value.absent(),
                i0.Value<int> updatedAt = const i0.Value.absent(),
                i0.Value<int?> deletedAt = const i0.Value.absent(),
              }) => i1.SourcesCompanion(
                id: id,
                uid: uid,
                kind: kind,
                name: name,
                account: account,
                root: root,
                configJson: configJson,
                credentialRef: credentialRef,
                addedAt: addedAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                required String uid,
                required String kind,
                required String name,
                i0.Value<String?> account = const i0.Value.absent(),
                i0.Value<String?> root = const i0.Value.absent(),
                i0.Value<String> configJson = const i0.Value.absent(),
                i0.Value<String?> credentialRef = const i0.Value.absent(),
                required int addedAt,
                required int updatedAt,
                i0.Value<int?> deletedAt = const i0.Value.absent(),
              }) => i1.SourcesCompanion.insert(
                id: id,
                uid: uid,
                kind: kind,
                name: name,
                account: account,
                root: root,
                configJson: configJson,
                credentialRef: credentialRef,
                addedAt: addedAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<i1.$SourcesTable, i1.Source>(table),
                  i1.$$SourcesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({sourceMountsRefs = false, excludedFoldersRefs = false}) {
                return i0.PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (sourceMountsRefs)
                      i4.ReadDatabaseContainer(db)
                          .resultSet<i1.$SourceMountsTable>('source_mounts'),
                    if (excludedFoldersRefs)
                      i4.ReadDatabaseContainer(
                        db,
                      ).resultSet<i1.$ExcludedFoldersTable>('excluded_folders'),
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (sourceMountsRefs)
                        await i0.$_getPrefetchedDataByColumns<
                          i1.Source,
                          i1.$SourcesTable,
                          i1.SourceMount,
                          i1.$SourceMountsTable
                        >(
                          currentTable: table,
                          referencedTable: i1.$$SourcesTableReferences
                              ._sourceMountsRefsTable(db),
                          managerFromTypedResult: (p0) => i1
                              .$$SourcesTableReferences(db, table, p0)
                              .sourceMountsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'source_id',
                          typedResults: items,
                        ),
                      if (excludedFoldersRefs)
                        await i0.$_getPrefetchedDataByColumns<
                          i1.Source,
                          i1.$SourcesTable,
                          i1.ExcludedFolder,
                          i1.$ExcludedFoldersTable
                        >(
                          currentTable: table,
                          referencedTable: i1.$$SourcesTableReferences
                              ._excludedFoldersRefsTable(db),
                          managerFromTypedResult: (p0) => i1
                              .$$SourcesTableReferences(db, table, p0)
                              .excludedFoldersRefs,
                          currentColumn: 'id',
                          referencedColumn: 'source_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SourcesTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$SourcesTable,
      i1.Source,
      i1.$$SourcesTableFilterComposer,
      i1.$$SourcesTableOrderingComposer,
      i1.$$SourcesTableAnnotationComposer,
      $$SourcesTableCreateCompanionBuilder,
      $$SourcesTableUpdateCompanionBuilder,
      (i1.Source, i1.$$SourcesTableReferences),
      i1.Source,
      i0.PrefetchHooks Function({
        bool sourceMountsRefs,
        bool excludedFoldersRefs,
      })
    >;
typedef $$SourceMountsTableCreateCompanionBuilder =
    i1.SourceMountsCompanion Function({
      i0.Value<int> sourceId,
      i0.Value<String?> root,
      i0.Value<bool> enabled,
      i0.Value<String?> scanCursor,
      i0.Value<int?> lastScanAt,
      required int addedAt,
    });
typedef $$SourceMountsTableUpdateCompanionBuilder =
    i1.SourceMountsCompanion Function({
      i0.Value<int> sourceId,
      i0.Value<String?> root,
      i0.Value<bool> enabled,
      i0.Value<String?> scanCursor,
      i0.Value<int?> lastScanAt,
      i0.Value<int> addedAt,
    });

final class $$SourceMountsTableReferences
    extends
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$SourceMountsTable,
          i1.SourceMount
        > {
  $$SourceMountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static i1.$SourcesTable _sourceIdTable(i0.GeneratedDatabase db) =>
      i4.ReadDatabaseContainer(db)
          .resultSet<i1.$SourcesTable>('sources')
          .createAlias('source_mounts__source_id__sources__id');

  i1.$$SourcesTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<int>('source_id')!;

    final manager = i1
        .$$SourcesTableTableManager(
          $_db,
          i4.ReadDatabaseContainer($_db).resultSet<i1.$SourcesTable>('sources'),
        )
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SourceMountsTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$SourceMountsTable> {
  $$SourceMountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get root => $composableBuilder(
    column: $table.root,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get scanCursor => $composableBuilder(
    column: $table.scanCursor,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get lastScanAt => $composableBuilder(
    column: $table.lastScanAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i1.$$SourcesTableFilterComposer get sourceId {
    final i1.$$SourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: i4.ReadDatabaseContainer($db)
          .resultSet<i1.$SourcesTable>('sources'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i1.$$SourcesTableFilterComposer(
            $db: $db,
            $table: i4.ReadDatabaseContainer($db)
                .resultSet<i1.$SourcesTable>('sources'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SourceMountsTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$SourceMountsTable> {
  $$SourceMountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get root => $composableBuilder(
    column: $table.root,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get scanCursor => $composableBuilder(
    column: $table.scanCursor,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get lastScanAt => $composableBuilder(
    column: $table.lastScanAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i1.$$SourcesTableOrderingComposer get sourceId {
    final i1.$$SourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: i4.ReadDatabaseContainer($db)
          .resultSet<i1.$SourcesTable>('sources'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i1.$$SourcesTableOrderingComposer(
            $db: $db,
            $table: i4.ReadDatabaseContainer($db)
                .resultSet<i1.$SourcesTable>('sources'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SourceMountsTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$SourceMountsTable> {
  $$SourceMountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get root =>
      $composableBuilder(column: $table.root, builder: (column) => column);

  i0.GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  i0.GeneratedColumn<String> get scanCursor => $composableBuilder(
    column: $table.scanCursor,
    builder: (column) => column,
  );

  i0.GeneratedColumn<int> get lastScanAt => $composableBuilder(
    column: $table.lastScanAt,
    builder: (column) => column,
  );

  i0.GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  i1.$$SourcesTableAnnotationComposer get sourceId {
    final i1.$$SourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: i4.ReadDatabaseContainer($db)
          .resultSet<i1.$SourcesTable>('sources'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i1.$$SourcesTableAnnotationComposer(
            $db: $db,
            $table: i4.ReadDatabaseContainer($db)
                .resultSet<i1.$SourcesTable>('sources'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SourceMountsTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$SourceMountsTable,
          i1.SourceMount,
          i1.$$SourceMountsTableFilterComposer,
          i1.$$SourceMountsTableOrderingComposer,
          i1.$$SourceMountsTableAnnotationComposer,
          $$SourceMountsTableCreateCompanionBuilder,
          $$SourceMountsTableUpdateCompanionBuilder,
          (i1.SourceMount, i1.$$SourceMountsTableReferences),
          i1.SourceMount,
          i0.PrefetchHooks Function({bool sourceId})
        > {
  $$SourceMountsTableTableManager(
    i0.GeneratedDatabase db,
    i1.$SourceMountsTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$SourceMountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$SourceMountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$SourceMountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<int> sourceId = const i0.Value.absent(),
                i0.Value<String?> root = const i0.Value.absent(),
                i0.Value<bool> enabled = const i0.Value.absent(),
                i0.Value<String?> scanCursor = const i0.Value.absent(),
                i0.Value<int?> lastScanAt = const i0.Value.absent(),
                i0.Value<int> addedAt = const i0.Value.absent(),
              }) => i1.SourceMountsCompanion(
                sourceId: sourceId,
                root: root,
                enabled: enabled,
                scanCursor: scanCursor,
                lastScanAt: lastScanAt,
                addedAt: addedAt,
              ),
          createCompanionCallback:
              ({
                i0.Value<int> sourceId = const i0.Value.absent(),
                i0.Value<String?> root = const i0.Value.absent(),
                i0.Value<bool> enabled = const i0.Value.absent(),
                i0.Value<String?> scanCursor = const i0.Value.absent(),
                i0.Value<int?> lastScanAt = const i0.Value.absent(),
                required int addedAt,
              }) => i1.SourceMountsCompanion.insert(
                sourceId: sourceId,
                root: root,
                enabled: enabled,
                scanCursor: scanCursor,
                lastScanAt: lastScanAt,
                addedAt: addedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<i1.$SourceMountsTable, i1.SourceMount>(table),
                  i1.$$SourceMountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sourceId = false}) {
            return i0.PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends i0.TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sourceId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sourceId,
                        referencedTable: i1.$$SourceMountsTableReferences
                            ._sourceIdTable(db),
                        referencedColumn: i1.$$SourceMountsTableReferences
                            ._sourceIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SourceMountsTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$SourceMountsTable,
      i1.SourceMount,
      i1.$$SourceMountsTableFilterComposer,
      i1.$$SourceMountsTableOrderingComposer,
      i1.$$SourceMountsTableAnnotationComposer,
      $$SourceMountsTableCreateCompanionBuilder,
      $$SourceMountsTableUpdateCompanionBuilder,
      (i1.SourceMount, i1.$$SourceMountsTableReferences),
      i1.SourceMount,
      i0.PrefetchHooks Function({bool sourceId})
    >;
typedef $$ExcludedFoldersTableCreateCompanionBuilder =
    i1.ExcludedFoldersCompanion Function({
      i0.Value<int> id,
      required String uid,
      required int sourceId,
      required String folderKey,
      required String displayPath,
      required int addedAt,
      required int updatedAt,
      i0.Value<int?> deletedAt,
    });
typedef $$ExcludedFoldersTableUpdateCompanionBuilder =
    i1.ExcludedFoldersCompanion Function({
      i0.Value<int> id,
      i0.Value<String> uid,
      i0.Value<int> sourceId,
      i0.Value<String> folderKey,
      i0.Value<String> displayPath,
      i0.Value<int> addedAt,
      i0.Value<int> updatedAt,
      i0.Value<int?> deletedAt,
    });

final class $$ExcludedFoldersTableReferences
    extends
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$ExcludedFoldersTable,
          i1.ExcludedFolder
        > {
  $$ExcludedFoldersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static i1.$SourcesTable _sourceIdTable(i0.GeneratedDatabase db) =>
      i4.ReadDatabaseContainer(db)
          .resultSet<i1.$SourcesTable>('sources')
          .createAlias('excluded_folders__source_id__sources__id');

  i1.$$SourcesTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<int>('source_id')!;

    final manager = i1
        .$$SourcesTableTableManager(
          $_db,
          i4.ReadDatabaseContainer($_db).resultSet<i1.$SourcesTable>('sources'),
        )
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExcludedFoldersTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$ExcludedFoldersTable> {
  $$ExcludedFoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get folderKey => $composableBuilder(
    column: $table.folderKey,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get displayPath => $composableBuilder(
    column: $table.displayPath,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i1.$$SourcesTableFilterComposer get sourceId {
    final i1.$$SourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: i4.ReadDatabaseContainer($db)
          .resultSet<i1.$SourcesTable>('sources'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i1.$$SourcesTableFilterComposer(
            $db: $db,
            $table: i4.ReadDatabaseContainer($db)
                .resultSet<i1.$SourcesTable>('sources'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExcludedFoldersTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$ExcludedFoldersTable> {
  $$ExcludedFoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get folderKey => $composableBuilder(
    column: $table.folderKey,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get displayPath => $composableBuilder(
    column: $table.displayPath,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i1.$$SourcesTableOrderingComposer get sourceId {
    final i1.$$SourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: i4.ReadDatabaseContainer($db)
          .resultSet<i1.$SourcesTable>('sources'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i1.$$SourcesTableOrderingComposer(
            $db: $db,
            $table: i4.ReadDatabaseContainer($db)
                .resultSet<i1.$SourcesTable>('sources'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExcludedFoldersTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$ExcludedFoldersTable> {
  $$ExcludedFoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  i0.GeneratedColumn<String> get folderKey =>
      $composableBuilder(column: $table.folderKey, builder: (column) => column);

  i0.GeneratedColumn<String> get displayPath => $composableBuilder(
    column: $table.displayPath,
    builder: (column) => column,
  );

  i0.GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  i0.GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  i0.GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  i1.$$SourcesTableAnnotationComposer get sourceId {
    final i1.$$SourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: i4.ReadDatabaseContainer($db)
          .resultSet<i1.$SourcesTable>('sources'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i1.$$SourcesTableAnnotationComposer(
            $db: $db,
            $table: i4.ReadDatabaseContainer($db)
                .resultSet<i1.$SourcesTable>('sources'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExcludedFoldersTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$ExcludedFoldersTable,
          i1.ExcludedFolder,
          i1.$$ExcludedFoldersTableFilterComposer,
          i1.$$ExcludedFoldersTableOrderingComposer,
          i1.$$ExcludedFoldersTableAnnotationComposer,
          $$ExcludedFoldersTableCreateCompanionBuilder,
          $$ExcludedFoldersTableUpdateCompanionBuilder,
          (i1.ExcludedFolder, i1.$$ExcludedFoldersTableReferences),
          i1.ExcludedFolder,
          i0.PrefetchHooks Function({bool sourceId})
        > {
  $$ExcludedFoldersTableTableManager(
    i0.GeneratedDatabase db,
    i1.$ExcludedFoldersTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$ExcludedFoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$ExcludedFoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => i1
              .$$ExcludedFoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                i0.Value<String> uid = const i0.Value.absent(),
                i0.Value<int> sourceId = const i0.Value.absent(),
                i0.Value<String> folderKey = const i0.Value.absent(),
                i0.Value<String> displayPath = const i0.Value.absent(),
                i0.Value<int> addedAt = const i0.Value.absent(),
                i0.Value<int> updatedAt = const i0.Value.absent(),
                i0.Value<int?> deletedAt = const i0.Value.absent(),
              }) => i1.ExcludedFoldersCompanion(
                id: id,
                uid: uid,
                sourceId: sourceId,
                folderKey: folderKey,
                displayPath: displayPath,
                addedAt: addedAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                required String uid,
                required int sourceId,
                required String folderKey,
                required String displayPath,
                required int addedAt,
                required int updatedAt,
                i0.Value<int?> deletedAt = const i0.Value.absent(),
              }) => i1.ExcludedFoldersCompanion.insert(
                id: id,
                uid: uid,
                sourceId: sourceId,
                folderKey: folderKey,
                displayPath: displayPath,
                addedAt: addedAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<i1.$ExcludedFoldersTable, i1.ExcludedFolder>(
                    table,
                  ),
                  i1.$$ExcludedFoldersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sourceId = false}) {
            return i0.PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends i0.TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sourceId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sourceId,
                        referencedTable: i1.$$ExcludedFoldersTableReferences
                            ._sourceIdTable(db),
                        referencedColumn: i1.$$ExcludedFoldersTableReferences
                            ._sourceIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ExcludedFoldersTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$ExcludedFoldersTable,
      i1.ExcludedFolder,
      i1.$$ExcludedFoldersTableFilterComposer,
      i1.$$ExcludedFoldersTableOrderingComposer,
      i1.$$ExcludedFoldersTableAnnotationComposer,
      $$ExcludedFoldersTableCreateCompanionBuilder,
      $$ExcludedFoldersTableUpdateCompanionBuilder,
      (i1.ExcludedFolder, i1.$$ExcludedFoldersTableReferences),
      i1.ExcludedFolder,
      i0.PrefetchHooks Function({bool sourceId})
    >;

class $SourcesTable extends i2.Sources
    with i0.TableInfo<$SourcesTable, i1.Source> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SourcesTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _idMeta = const i0.VerificationMeta('id');
  @override
  late final i0.GeneratedColumn<int> id = i0.GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const i0.VerificationMeta _uidMeta = const i0.VerificationMeta('uid');
  @override
  late final i0.GeneratedColumn<String> uid = i0.GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const i0.VerificationMeta _kindMeta = const i0.VerificationMeta(
    'kind',
  );
  @override
  late final i0.GeneratedColumn<String> kind = i0.GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _nameMeta = const i0.VerificationMeta(
    'name',
  );
  @override
  late final i0.GeneratedColumn<String> name = i0.GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _accountMeta = const i0.VerificationMeta(
    'account',
  );
  @override
  late final i0.GeneratedColumn<String> account = i0.GeneratedColumn<String>(
    'account',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _rootMeta = const i0.VerificationMeta(
    'root',
  );
  @override
  late final i0.GeneratedColumn<String> root = i0.GeneratedColumn<String>(
    'root',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _configJsonMeta = const i0.VerificationMeta(
    'configJson',
  );
  @override
  late final i0.GeneratedColumn<String> configJson = i0.GeneratedColumn<String>(
    'config_json',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const i3.Constant('{}'),
  );
  static const i0.VerificationMeta _credentialRefMeta =
      const i0.VerificationMeta('credentialRef');
  @override
  late final i0.GeneratedColumn<String> credentialRef =
      i0.GeneratedColumn<String>(
        'credential_ref',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const i0.VerificationMeta _addedAtMeta = const i0.VerificationMeta(
    'addedAt',
  );
  @override
  late final i0.GeneratedColumn<int> addedAt = i0.GeneratedColumn<int>(
    'added_at',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _updatedAtMeta = const i0.VerificationMeta(
    'updatedAt',
  );
  @override
  late final i0.GeneratedColumn<int> updatedAt = i0.GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _deletedAtMeta = const i0.VerificationMeta(
    'deletedAt',
  );
  @override
  late final i0.GeneratedColumn<int> deletedAt = i0.GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<i0.GeneratedColumn> get $columns => [
    id,
    uid,
    kind,
    name,
    account,
    root,
    configJson,
    credentialRef,
    addedAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sources';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.Source> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('account')) {
      context.handle(
        _accountMeta,
        account.isAcceptableOrUnknown(data['account']!, _accountMeta),
      );
    }
    if (data.containsKey('root')) {
      context.handle(
        _rootMeta,
        root.isAcceptableOrUnknown(data['root']!, _rootMeta),
      );
    }
    if (data.containsKey('config_json')) {
      context.handle(
        _configJsonMeta,
        configJson.isAcceptableOrUnknown(data['config_json']!, _configJsonMeta),
      );
    }
    if (data.containsKey('credential_ref')) {
      context.handle(
        _credentialRefMeta,
        credentialRef.isAcceptableOrUnknown(
          data['credential_ref']!,
          _credentialRefMeta,
        ),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i1.Source map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.Source(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      name: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      account: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}account'],
      ),
      root: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}root'],
      ),
      configJson: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}config_json'],
      )!,
      credentialRef: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}credential_ref'],
      ),
      addedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}added_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $SourcesTable createAlias(String alias) {
    return $SourcesTable(attachedDatabase, alias);
  }
}

class Source extends i0.DataClass implements i0.Insertable<i1.Source> {
  final int id;
  final String uid;
  final String kind;
  final String name;

  /// Account identity, remote sources only.
  final String? account;

  /// Remote base URL, bucket, drive root or plugin install id; null = local.
  final String? root;

  /// Non-secret options only.
  final String configJson;

  /// Key in the platform secret store; secrets never go in other columns.
  final String? credentialRef;
  final int addedAt;
  final int updatedAt;
  final int? deletedAt;
  const Source({
    required this.id,
    required this.uid,
    required this.kind,
    required this.name,
    this.account,
    this.root,
    required this.configJson,
    this.credentialRef,
    required this.addedAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id);
    map['uid'] = i0.Variable<String>(uid);
    map['kind'] = i0.Variable<String>(kind);
    map['name'] = i0.Variable<String>(name);
    if (!nullToAbsent || account != null) {
      map['account'] = i0.Variable<String>(account);
    }
    if (!nullToAbsent || root != null) {
      map['root'] = i0.Variable<String>(root);
    }
    map['config_json'] = i0.Variable<String>(configJson);
    if (!nullToAbsent || credentialRef != null) {
      map['credential_ref'] = i0.Variable<String>(credentialRef);
    }
    map['added_at'] = i0.Variable<int>(addedAt);
    map['updated_at'] = i0.Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = i0.Variable<int>(deletedAt);
    }
    return map;
  }

  i1.SourcesCompanion toCompanion(bool nullToAbsent) {
    return i1.SourcesCompanion(
      id: i0.Value(id),
      uid: i0.Value(uid),
      kind: i0.Value(kind),
      name: i0.Value(name),
      account: account == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(account),
      root: root == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(root),
      configJson: i0.Value(configJson),
      credentialRef: credentialRef == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(credentialRef),
      addedAt: i0.Value(addedAt),
      updatedAt: i0.Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(deletedAt),
    );
  }

  factory Source.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return Source(
      id: serializer.fromJson<int>(json['id']),
      uid: serializer.fromJson<String>(json['uid']),
      kind: serializer.fromJson<String>(json['kind']),
      name: serializer.fromJson<String>(json['name']),
      account: serializer.fromJson<String?>(json['account']),
      root: serializer.fromJson<String?>(json['root']),
      configJson: serializer.fromJson<String>(json['configJson']),
      credentialRef: serializer.fromJson<String?>(json['credentialRef']),
      addedAt: serializer.fromJson<int>(json['addedAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uid': serializer.toJson<String>(uid),
      'kind': serializer.toJson<String>(kind),
      'name': serializer.toJson<String>(name),
      'account': serializer.toJson<String?>(account),
      'root': serializer.toJson<String?>(root),
      'configJson': serializer.toJson<String>(configJson),
      'credentialRef': serializer.toJson<String?>(credentialRef),
      'addedAt': serializer.toJson<int>(addedAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  i1.Source copyWith({
    int? id,
    String? uid,
    String? kind,
    String? name,
    i0.Value<String?> account = const i0.Value.absent(),
    i0.Value<String?> root = const i0.Value.absent(),
    String? configJson,
    i0.Value<String?> credentialRef = const i0.Value.absent(),
    int? addedAt,
    int? updatedAt,
    i0.Value<int?> deletedAt = const i0.Value.absent(),
  }) => i1.Source(
    id: id ?? this.id,
    uid: uid ?? this.uid,
    kind: kind ?? this.kind,
    name: name ?? this.name,
    account: account.present ? account.value : this.account,
    root: root.present ? root.value : this.root,
    configJson: configJson ?? this.configJson,
    credentialRef: credentialRef.present
        ? credentialRef.value
        : this.credentialRef,
    addedAt: addedAt ?? this.addedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Source copyWithCompanion(i1.SourcesCompanion data) {
    return Source(
      id: data.id.present ? data.id.value : this.id,
      uid: data.uid.present ? data.uid.value : this.uid,
      kind: data.kind.present ? data.kind.value : this.kind,
      name: data.name.present ? data.name.value : this.name,
      account: data.account.present ? data.account.value : this.account,
      root: data.root.present ? data.root.value : this.root,
      configJson: data.configJson.present
          ? data.configJson.value
          : this.configJson,
      credentialRef: data.credentialRef.present
          ? data.credentialRef.value
          : this.credentialRef,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Source(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('account: $account, ')
          ..write('root: $root, ')
          ..write('configJson: $configJson, ')
          ..write('credentialRef: $credentialRef, ')
          ..write('addedAt: $addedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uid,
    kind,
    name,
    account,
    root,
    configJson,
    credentialRef,
    addedAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.Source &&
          other.id == this.id &&
          other.uid == this.uid &&
          other.kind == this.kind &&
          other.name == this.name &&
          other.account == this.account &&
          other.root == this.root &&
          other.configJson == this.configJson &&
          other.credentialRef == this.credentialRef &&
          other.addedAt == this.addedAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class SourcesCompanion extends i0.UpdateCompanion<i1.Source> {
  final i0.Value<int> id;
  final i0.Value<String> uid;
  final i0.Value<String> kind;
  final i0.Value<String> name;
  final i0.Value<String?> account;
  final i0.Value<String?> root;
  final i0.Value<String> configJson;
  final i0.Value<String?> credentialRef;
  final i0.Value<int> addedAt;
  final i0.Value<int> updatedAt;
  final i0.Value<int?> deletedAt;
  const SourcesCompanion({
    this.id = const i0.Value.absent(),
    this.uid = const i0.Value.absent(),
    this.kind = const i0.Value.absent(),
    this.name = const i0.Value.absent(),
    this.account = const i0.Value.absent(),
    this.root = const i0.Value.absent(),
    this.configJson = const i0.Value.absent(),
    this.credentialRef = const i0.Value.absent(),
    this.addedAt = const i0.Value.absent(),
    this.updatedAt = const i0.Value.absent(),
    this.deletedAt = const i0.Value.absent(),
  });
  SourcesCompanion.insert({
    this.id = const i0.Value.absent(),
    required String uid,
    required String kind,
    required String name,
    this.account = const i0.Value.absent(),
    this.root = const i0.Value.absent(),
    this.configJson = const i0.Value.absent(),
    this.credentialRef = const i0.Value.absent(),
    required int addedAt,
    required int updatedAt,
    this.deletedAt = const i0.Value.absent(),
  }) : uid = i0.Value(uid),
       kind = i0.Value(kind),
       name = i0.Value(name),
       addedAt = i0.Value(addedAt),
       updatedAt = i0.Value(updatedAt);
  static i0.Insertable<i1.Source> custom({
    i0.Expression<int>? id,
    i0.Expression<String>? uid,
    i0.Expression<String>? kind,
    i0.Expression<String>? name,
    i0.Expression<String>? account,
    i0.Expression<String>? root,
    i0.Expression<String>? configJson,
    i0.Expression<String>? credentialRef,
    i0.Expression<int>? addedAt,
    i0.Expression<int>? updatedAt,
    i0.Expression<int>? deletedAt,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (uid != null) 'uid': uid,
      if (kind != null) 'kind': kind,
      if (name != null) 'name': name,
      if (account != null) 'account': account,
      if (root != null) 'root': root,
      if (configJson != null) 'config_json': configJson,
      if (credentialRef != null) 'credential_ref': credentialRef,
      if (addedAt != null) 'added_at': addedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  i1.SourcesCompanion copyWith({
    i0.Value<int>? id,
    i0.Value<String>? uid,
    i0.Value<String>? kind,
    i0.Value<String>? name,
    i0.Value<String?>? account,
    i0.Value<String?>? root,
    i0.Value<String>? configJson,
    i0.Value<String?>? credentialRef,
    i0.Value<int>? addedAt,
    i0.Value<int>? updatedAt,
    i0.Value<int?>? deletedAt,
  }) {
    return i1.SourcesCompanion(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      account: account ?? this.account,
      root: root ?? this.root,
      configJson: configJson ?? this.configJson,
      credentialRef: credentialRef ?? this.credentialRef,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<int>(id.value);
    }
    if (uid.present) {
      map['uid'] = i0.Variable<String>(uid.value);
    }
    if (kind.present) {
      map['kind'] = i0.Variable<String>(kind.value);
    }
    if (name.present) {
      map['name'] = i0.Variable<String>(name.value);
    }
    if (account.present) {
      map['account'] = i0.Variable<String>(account.value);
    }
    if (root.present) {
      map['root'] = i0.Variable<String>(root.value);
    }
    if (configJson.present) {
      map['config_json'] = i0.Variable<String>(configJson.value);
    }
    if (credentialRef.present) {
      map['credential_ref'] = i0.Variable<String>(credentialRef.value);
    }
    if (addedAt.present) {
      map['added_at'] = i0.Variable<int>(addedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = i0.Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = i0.Variable<int>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SourcesCompanion(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('account: $account, ')
          ..write('root: $root, ')
          ..write('configJson: $configJson, ')
          ..write('credentialRef: $credentialRef, ')
          ..write('addedAt: $addedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

i0.Index get sourceMountsRoot => i0.Index(
  'source_mounts_root',
  'CREATE UNIQUE INDEX source_mounts_root ON source_mounts (root) WHERE root IS NOT NULL',
);

class $SourceMountsTable extends i2.SourceMounts
    with i0.TableInfo<$SourceMountsTable, i1.SourceMount> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SourceMountsTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _sourceIdMeta = const i0.VerificationMeta(
    'sourceId',
  );
  @override
  late final i0.GeneratedColumn<int> sourceId = i0.GeneratedColumn<int>(
    'source_id',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
      'REFERENCES sources (id) ON DELETE CASCADE',
    ),
  );
  static const i0.VerificationMeta _rootMeta = const i0.VerificationMeta(
    'root',
  );
  @override
  late final i0.GeneratedColumn<String> root = i0.GeneratedColumn<String>(
    'root',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _enabledMeta = const i0.VerificationMeta(
    'enabled',
  );
  @override
  late final i0.GeneratedColumn<bool> enabled = i0.GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: i0.DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const i3.Constant(true),
  );
  static const i0.VerificationMeta _scanCursorMeta = const i0.VerificationMeta(
    'scanCursor',
  );
  @override
  late final i0.GeneratedColumn<String> scanCursor = i0.GeneratedColumn<String>(
    'scan_cursor',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _lastScanAtMeta = const i0.VerificationMeta(
    'lastScanAt',
  );
  @override
  late final i0.GeneratedColumn<int> lastScanAt = i0.GeneratedColumn<int>(
    'last_scan_at',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _addedAtMeta = const i0.VerificationMeta(
    'addedAt',
  );
  @override
  late final i0.GeneratedColumn<int> addedAt = i0.GeneratedColumn<int>(
    'added_at',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<i0.GeneratedColumn> get $columns => [
    sourceId,
    root,
    enabled,
    scanCursor,
    lastScanAt,
    addedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'source_mounts';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.SourceMount> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('root')) {
      context.handle(
        _rootMeta,
        root.isAcceptableOrUnknown(data['root']!, _rootMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('scan_cursor')) {
      context.handle(
        _scanCursorMeta,
        scanCursor.isAcceptableOrUnknown(data['scan_cursor']!, _scanCursorMeta),
      );
    }
    if (data.containsKey('last_scan_at')) {
      context.handle(
        _lastScanAtMeta,
        lastScanAt.isAcceptableOrUnknown(
          data['last_scan_at']!,
          _lastScanAtMeta,
        ),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {sourceId};
  @override
  i1.SourceMount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.SourceMount(
      sourceId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      )!,
      root: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}root'],
      ),
      enabled: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      scanCursor: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}scan_cursor'],
      ),
      lastScanAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}last_scan_at'],
      ),
      addedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $SourceMountsTable createAlias(String alias) {
    return $SourceMountsTable(attachedDatabase, alias);
  }
}

class SourceMount extends i0.DataClass
    implements i0.Insertable<i1.SourceMount> {
  final int sourceId;

  /// Canonical local path; null for remote sources.
  final String? root;

  /// False = disabled; its tracks are hidden.
  final bool enabled;

  /// Incremental scan token (for example a Drive changes token).
  final String? scanCursor;
  final int? lastScanAt;
  final int addedAt;
  const SourceMount({
    required this.sourceId,
    this.root,
    required this.enabled,
    this.scanCursor,
    this.lastScanAt,
    required this.addedAt,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['source_id'] = i0.Variable<int>(sourceId);
    if (!nullToAbsent || root != null) {
      map['root'] = i0.Variable<String>(root);
    }
    map['enabled'] = i0.Variable<bool>(enabled);
    if (!nullToAbsent || scanCursor != null) {
      map['scan_cursor'] = i0.Variable<String>(scanCursor);
    }
    if (!nullToAbsent || lastScanAt != null) {
      map['last_scan_at'] = i0.Variable<int>(lastScanAt);
    }
    map['added_at'] = i0.Variable<int>(addedAt);
    return map;
  }

  i1.SourceMountsCompanion toCompanion(bool nullToAbsent) {
    return i1.SourceMountsCompanion(
      sourceId: i0.Value(sourceId),
      root: root == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(root),
      enabled: i0.Value(enabled),
      scanCursor: scanCursor == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(scanCursor),
      lastScanAt: lastScanAt == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(lastScanAt),
      addedAt: i0.Value(addedAt),
    );
  }

  factory SourceMount.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return SourceMount(
      sourceId: serializer.fromJson<int>(json['sourceId']),
      root: serializer.fromJson<String?>(json['root']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      scanCursor: serializer.fromJson<String?>(json['scanCursor']),
      lastScanAt: serializer.fromJson<int?>(json['lastScanAt']),
      addedAt: serializer.fromJson<int>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceId': serializer.toJson<int>(sourceId),
      'root': serializer.toJson<String?>(root),
      'enabled': serializer.toJson<bool>(enabled),
      'scanCursor': serializer.toJson<String?>(scanCursor),
      'lastScanAt': serializer.toJson<int?>(lastScanAt),
      'addedAt': serializer.toJson<int>(addedAt),
    };
  }

  i1.SourceMount copyWith({
    int? sourceId,
    i0.Value<String?> root = const i0.Value.absent(),
    bool? enabled,
    i0.Value<String?> scanCursor = const i0.Value.absent(),
    i0.Value<int?> lastScanAt = const i0.Value.absent(),
    int? addedAt,
  }) => i1.SourceMount(
    sourceId: sourceId ?? this.sourceId,
    root: root.present ? root.value : this.root,
    enabled: enabled ?? this.enabled,
    scanCursor: scanCursor.present ? scanCursor.value : this.scanCursor,
    lastScanAt: lastScanAt.present ? lastScanAt.value : this.lastScanAt,
    addedAt: addedAt ?? this.addedAt,
  );
  SourceMount copyWithCompanion(i1.SourceMountsCompanion data) {
    return SourceMount(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      root: data.root.present ? data.root.value : this.root,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      scanCursor: data.scanCursor.present
          ? data.scanCursor.value
          : this.scanCursor,
      lastScanAt: data.lastScanAt.present
          ? data.lastScanAt.value
          : this.lastScanAt,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SourceMount(')
          ..write('sourceId: $sourceId, ')
          ..write('root: $root, ')
          ..write('enabled: $enabled, ')
          ..write('scanCursor: $scanCursor, ')
          ..write('lastScanAt: $lastScanAt, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(sourceId, root, enabled, scanCursor, lastScanAt, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.SourceMount &&
          other.sourceId == this.sourceId &&
          other.root == this.root &&
          other.enabled == this.enabled &&
          other.scanCursor == this.scanCursor &&
          other.lastScanAt == this.lastScanAt &&
          other.addedAt == this.addedAt);
}

class SourceMountsCompanion extends i0.UpdateCompanion<i1.SourceMount> {
  final i0.Value<int> sourceId;
  final i0.Value<String?> root;
  final i0.Value<bool> enabled;
  final i0.Value<String?> scanCursor;
  final i0.Value<int?> lastScanAt;
  final i0.Value<int> addedAt;
  const SourceMountsCompanion({
    this.sourceId = const i0.Value.absent(),
    this.root = const i0.Value.absent(),
    this.enabled = const i0.Value.absent(),
    this.scanCursor = const i0.Value.absent(),
    this.lastScanAt = const i0.Value.absent(),
    this.addedAt = const i0.Value.absent(),
  });
  SourceMountsCompanion.insert({
    this.sourceId = const i0.Value.absent(),
    this.root = const i0.Value.absent(),
    this.enabled = const i0.Value.absent(),
    this.scanCursor = const i0.Value.absent(),
    this.lastScanAt = const i0.Value.absent(),
    required int addedAt,
  }) : addedAt = i0.Value(addedAt);
  static i0.Insertable<i1.SourceMount> custom({
    i0.Expression<int>? sourceId,
    i0.Expression<String>? root,
    i0.Expression<bool>? enabled,
    i0.Expression<String>? scanCursor,
    i0.Expression<int>? lastScanAt,
    i0.Expression<int>? addedAt,
  }) {
    return i0.RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (root != null) 'root': root,
      if (enabled != null) 'enabled': enabled,
      if (scanCursor != null) 'scan_cursor': scanCursor,
      if (lastScanAt != null) 'last_scan_at': lastScanAt,
      if (addedAt != null) 'added_at': addedAt,
    });
  }

  i1.SourceMountsCompanion copyWith({
    i0.Value<int>? sourceId,
    i0.Value<String?>? root,
    i0.Value<bool>? enabled,
    i0.Value<String?>? scanCursor,
    i0.Value<int?>? lastScanAt,
    i0.Value<int>? addedAt,
  }) {
    return i1.SourceMountsCompanion(
      sourceId: sourceId ?? this.sourceId,
      root: root ?? this.root,
      enabled: enabled ?? this.enabled,
      scanCursor: scanCursor ?? this.scanCursor,
      lastScanAt: lastScanAt ?? this.lastScanAt,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (sourceId.present) {
      map['source_id'] = i0.Variable<int>(sourceId.value);
    }
    if (root.present) {
      map['root'] = i0.Variable<String>(root.value);
    }
    if (enabled.present) {
      map['enabled'] = i0.Variable<bool>(enabled.value);
    }
    if (scanCursor.present) {
      map['scan_cursor'] = i0.Variable<String>(scanCursor.value);
    }
    if (lastScanAt.present) {
      map['last_scan_at'] = i0.Variable<int>(lastScanAt.value);
    }
    if (addedAt.present) {
      map['added_at'] = i0.Variable<int>(addedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SourceMountsCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('root: $root, ')
          ..write('enabled: $enabled, ')
          ..write('scanCursor: $scanCursor, ')
          ..write('lastScanAt: $lastScanAt, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }
}

i0.Index get excludedFoldersSource => i0.Index(
  'excluded_folders_source',
  'CREATE INDEX excluded_folders_source ON excluded_folders (source_id, folder_key)',
);

class $ExcludedFoldersTable extends i2.ExcludedFolders
    with i0.TableInfo<$ExcludedFoldersTable, i1.ExcludedFolder> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExcludedFoldersTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _idMeta = const i0.VerificationMeta('id');
  @override
  late final i0.GeneratedColumn<int> id = i0.GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const i0.VerificationMeta _uidMeta = const i0.VerificationMeta('uid');
  @override
  late final i0.GeneratedColumn<String> uid = i0.GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const i0.VerificationMeta _sourceIdMeta = const i0.VerificationMeta(
    'sourceId',
  );
  @override
  late final i0.GeneratedColumn<int> sourceId = i0.GeneratedColumn<int>(
    'source_id',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
      'REFERENCES sources (id) ON DELETE CASCADE',
    ),
  );
  static const i0.VerificationMeta _folderKeyMeta = const i0.VerificationMeta(
    'folderKey',
  );
  @override
  late final i0.GeneratedColumn<String> folderKey = i0.GeneratedColumn<String>(
    'folder_key',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _displayPathMeta = const i0.VerificationMeta(
    'displayPath',
  );
  @override
  late final i0.GeneratedColumn<String> displayPath =
      i0.GeneratedColumn<String>(
        'display_path',
        aliasedName,
        false,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const i0.VerificationMeta _addedAtMeta = const i0.VerificationMeta(
    'addedAt',
  );
  @override
  late final i0.GeneratedColumn<int> addedAt = i0.GeneratedColumn<int>(
    'added_at',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _updatedAtMeta = const i0.VerificationMeta(
    'updatedAt',
  );
  @override
  late final i0.GeneratedColumn<int> updatedAt = i0.GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _deletedAtMeta = const i0.VerificationMeta(
    'deletedAt',
  );
  @override
  late final i0.GeneratedColumn<int> deletedAt = i0.GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<i0.GeneratedColumn> get $columns => [
    id,
    uid,
    sourceId,
    folderKey,
    displayPath,
    addedAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'excluded_folders';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.ExcludedFolder> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('folder_key')) {
      context.handle(
        _folderKeyMeta,
        folderKey.isAcceptableOrUnknown(data['folder_key']!, _folderKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_folderKeyMeta);
    }
    if (data.containsKey('display_path')) {
      context.handle(
        _displayPathMeta,
        displayPath.isAcceptableOrUnknown(
          data['display_path']!,
          _displayPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayPathMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i1.ExcludedFolder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.ExcludedFolder(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      )!,
      folderKey: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}folder_key'],
      )!,
      displayPath: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}display_path'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}added_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $ExcludedFoldersTable createAlias(String alias) {
    return $ExcludedFoldersTable(attachedDatabase, alias);
  }
}

class ExcludedFolder extends i0.DataClass
    implements i0.Insertable<i1.ExcludedFolder> {
  final int id;
  final String uid;
  final int sourceId;

  /// Relative path (path-based sources) or folder id (id-based sources).
  final String folderKey;

  /// Path shown in the UI.
  final String displayPath;
  final int addedAt;
  final int updatedAt;
  final int? deletedAt;
  const ExcludedFolder({
    required this.id,
    required this.uid,
    required this.sourceId,
    required this.folderKey,
    required this.displayPath,
    required this.addedAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id);
    map['uid'] = i0.Variable<String>(uid);
    map['source_id'] = i0.Variable<int>(sourceId);
    map['folder_key'] = i0.Variable<String>(folderKey);
    map['display_path'] = i0.Variable<String>(displayPath);
    map['added_at'] = i0.Variable<int>(addedAt);
    map['updated_at'] = i0.Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = i0.Variable<int>(deletedAt);
    }
    return map;
  }

  i1.ExcludedFoldersCompanion toCompanion(bool nullToAbsent) {
    return i1.ExcludedFoldersCompanion(
      id: i0.Value(id),
      uid: i0.Value(uid),
      sourceId: i0.Value(sourceId),
      folderKey: i0.Value(folderKey),
      displayPath: i0.Value(displayPath),
      addedAt: i0.Value(addedAt),
      updatedAt: i0.Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(deletedAt),
    );
  }

  factory ExcludedFolder.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return ExcludedFolder(
      id: serializer.fromJson<int>(json['id']),
      uid: serializer.fromJson<String>(json['uid']),
      sourceId: serializer.fromJson<int>(json['sourceId']),
      folderKey: serializer.fromJson<String>(json['folderKey']),
      displayPath: serializer.fromJson<String>(json['displayPath']),
      addedAt: serializer.fromJson<int>(json['addedAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uid': serializer.toJson<String>(uid),
      'sourceId': serializer.toJson<int>(sourceId),
      'folderKey': serializer.toJson<String>(folderKey),
      'displayPath': serializer.toJson<String>(displayPath),
      'addedAt': serializer.toJson<int>(addedAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  i1.ExcludedFolder copyWith({
    int? id,
    String? uid,
    int? sourceId,
    String? folderKey,
    String? displayPath,
    int? addedAt,
    int? updatedAt,
    i0.Value<int?> deletedAt = const i0.Value.absent(),
  }) => i1.ExcludedFolder(
    id: id ?? this.id,
    uid: uid ?? this.uid,
    sourceId: sourceId ?? this.sourceId,
    folderKey: folderKey ?? this.folderKey,
    displayPath: displayPath ?? this.displayPath,
    addedAt: addedAt ?? this.addedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  ExcludedFolder copyWithCompanion(i1.ExcludedFoldersCompanion data) {
    return ExcludedFolder(
      id: data.id.present ? data.id.value : this.id,
      uid: data.uid.present ? data.uid.value : this.uid,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      folderKey: data.folderKey.present ? data.folderKey.value : this.folderKey,
      displayPath: data.displayPath.present
          ? data.displayPath.value
          : this.displayPath,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExcludedFolder(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('sourceId: $sourceId, ')
          ..write('folderKey: $folderKey, ')
          ..write('displayPath: $displayPath, ')
          ..write('addedAt: $addedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uid,
    sourceId,
    folderKey,
    displayPath,
    addedAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.ExcludedFolder &&
          other.id == this.id &&
          other.uid == this.uid &&
          other.sourceId == this.sourceId &&
          other.folderKey == this.folderKey &&
          other.displayPath == this.displayPath &&
          other.addedAt == this.addedAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class ExcludedFoldersCompanion extends i0.UpdateCompanion<i1.ExcludedFolder> {
  final i0.Value<int> id;
  final i0.Value<String> uid;
  final i0.Value<int> sourceId;
  final i0.Value<String> folderKey;
  final i0.Value<String> displayPath;
  final i0.Value<int> addedAt;
  final i0.Value<int> updatedAt;
  final i0.Value<int?> deletedAt;
  const ExcludedFoldersCompanion({
    this.id = const i0.Value.absent(),
    this.uid = const i0.Value.absent(),
    this.sourceId = const i0.Value.absent(),
    this.folderKey = const i0.Value.absent(),
    this.displayPath = const i0.Value.absent(),
    this.addedAt = const i0.Value.absent(),
    this.updatedAt = const i0.Value.absent(),
    this.deletedAt = const i0.Value.absent(),
  });
  ExcludedFoldersCompanion.insert({
    this.id = const i0.Value.absent(),
    required String uid,
    required int sourceId,
    required String folderKey,
    required String displayPath,
    required int addedAt,
    required int updatedAt,
    this.deletedAt = const i0.Value.absent(),
  }) : uid = i0.Value(uid),
       sourceId = i0.Value(sourceId),
       folderKey = i0.Value(folderKey),
       displayPath = i0.Value(displayPath),
       addedAt = i0.Value(addedAt),
       updatedAt = i0.Value(updatedAt);
  static i0.Insertable<i1.ExcludedFolder> custom({
    i0.Expression<int>? id,
    i0.Expression<String>? uid,
    i0.Expression<int>? sourceId,
    i0.Expression<String>? folderKey,
    i0.Expression<String>? displayPath,
    i0.Expression<int>? addedAt,
    i0.Expression<int>? updatedAt,
    i0.Expression<int>? deletedAt,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (uid != null) 'uid': uid,
      if (sourceId != null) 'source_id': sourceId,
      if (folderKey != null) 'folder_key': folderKey,
      if (displayPath != null) 'display_path': displayPath,
      if (addedAt != null) 'added_at': addedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  i1.ExcludedFoldersCompanion copyWith({
    i0.Value<int>? id,
    i0.Value<String>? uid,
    i0.Value<int>? sourceId,
    i0.Value<String>? folderKey,
    i0.Value<String>? displayPath,
    i0.Value<int>? addedAt,
    i0.Value<int>? updatedAt,
    i0.Value<int?>? deletedAt,
  }) {
    return i1.ExcludedFoldersCompanion(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      sourceId: sourceId ?? this.sourceId,
      folderKey: folderKey ?? this.folderKey,
      displayPath: displayPath ?? this.displayPath,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<int>(id.value);
    }
    if (uid.present) {
      map['uid'] = i0.Variable<String>(uid.value);
    }
    if (sourceId.present) {
      map['source_id'] = i0.Variable<int>(sourceId.value);
    }
    if (folderKey.present) {
      map['folder_key'] = i0.Variable<String>(folderKey.value);
    }
    if (displayPath.present) {
      map['display_path'] = i0.Variable<String>(displayPath.value);
    }
    if (addedAt.present) {
      map['added_at'] = i0.Variable<int>(addedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = i0.Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = i0.Variable<int>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExcludedFoldersCompanion(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('sourceId: $sourceId, ')
          ..write('folderKey: $folderKey, ')
          ..write('displayPath: $displayPath, ')
          ..write('addedAt: $addedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}
