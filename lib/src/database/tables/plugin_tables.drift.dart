// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:kanaru/src/database/tables/plugin_tables.drift.dart' as i1;
import 'package:kanaru/src/database/tables/plugin_tables.dart' as i2;
import 'package:drift/src/runtime/query_builder/query_builder.dart' as i3;
import 'package:drift/internal/modular.dart' as i4;

typedef $$PluginReposTableCreateCompanionBuilder =
    i1.PluginReposCompanion Function({
      i0.Value<int> id,
      required String url,
      required String name,
      i0.Value<String?> catalogJson,
      i0.Value<int?> refreshedAt,
      i0.Value<int?> lastAttemptAt,
      i0.Value<String?> lastError,
      required int addedAt,
      required String addressClass,
    });
typedef $$PluginReposTableUpdateCompanionBuilder =
    i1.PluginReposCompanion Function({
      i0.Value<int> id,
      i0.Value<String> url,
      i0.Value<String> name,
      i0.Value<String?> catalogJson,
      i0.Value<int?> refreshedAt,
      i0.Value<int?> lastAttemptAt,
      i0.Value<String?> lastError,
      i0.Value<int> addedAt,
      i0.Value<String> addressClass,
    });

class $$PluginReposTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$PluginReposTable> {
  $$PluginReposTableFilterComposer({
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

  i0.ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get catalogJson => $composableBuilder(
    column: $table.catalogJson,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get refreshedAt => $composableBuilder(
    column: $table.refreshedAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get addressClass => $composableBuilder(
    column: $table.addressClass,
    builder: (column) => i0.ColumnFilters(column),
  );
}

class $$PluginReposTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$PluginReposTable> {
  $$PluginReposTableOrderingComposer({
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

  i0.ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get catalogJson => $composableBuilder(
    column: $table.catalogJson,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get refreshedAt => $composableBuilder(
    column: $table.refreshedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get addressClass => $composableBuilder(
    column: $table.addressClass,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $$PluginReposTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$PluginReposTable> {
  $$PluginReposTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  i0.GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  i0.GeneratedColumn<String> get catalogJson => $composableBuilder(
    column: $table.catalogJson,
    builder: (column) => column,
  );

  i0.GeneratedColumn<int> get refreshedAt => $composableBuilder(
    column: $table.refreshedAt,
    builder: (column) => column,
  );

  i0.GeneratedColumn<int> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  i0.GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  i0.GeneratedColumn<String> get addressClass => $composableBuilder(
    column: $table.addressClass,
    builder: (column) => column,
  );
}

class $$PluginReposTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$PluginReposTable,
          i1.PluginRepoRow,
          i1.$$PluginReposTableFilterComposer,
          i1.$$PluginReposTableOrderingComposer,
          i1.$$PluginReposTableAnnotationComposer,
          $$PluginReposTableCreateCompanionBuilder,
          $$PluginReposTableUpdateCompanionBuilder,
          (
            i1.PluginRepoRow,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i1.$PluginReposTable,
              i1.PluginRepoRow
            >,
          ),
          i1.PluginRepoRow,
          i0.PrefetchHooks Function()
        > {
  $$PluginReposTableTableManager(
    i0.GeneratedDatabase db,
    i1.$PluginReposTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$PluginReposTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$PluginReposTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$PluginReposTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                i0.Value<String> url = const i0.Value.absent(),
                i0.Value<String> name = const i0.Value.absent(),
                i0.Value<String?> catalogJson = const i0.Value.absent(),
                i0.Value<int?> refreshedAt = const i0.Value.absent(),
                i0.Value<int?> lastAttemptAt = const i0.Value.absent(),
                i0.Value<String?> lastError = const i0.Value.absent(),
                i0.Value<int> addedAt = const i0.Value.absent(),
                i0.Value<String> addressClass = const i0.Value.absent(),
              }) => i1.PluginReposCompanion(
                id: id,
                url: url,
                name: name,
                catalogJson: catalogJson,
                refreshedAt: refreshedAt,
                lastAttemptAt: lastAttemptAt,
                lastError: lastError,
                addedAt: addedAt,
                addressClass: addressClass,
              ),
          createCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                required String url,
                required String name,
                i0.Value<String?> catalogJson = const i0.Value.absent(),
                i0.Value<int?> refreshedAt = const i0.Value.absent(),
                i0.Value<int?> lastAttemptAt = const i0.Value.absent(),
                i0.Value<String?> lastError = const i0.Value.absent(),
                required int addedAt,
                required String addressClass,
              }) => i1.PluginReposCompanion.insert(
                id: id,
                url: url,
                name: name,
                catalogJson: catalogJson,
                refreshedAt: refreshedAt,
                lastAttemptAt: lastAttemptAt,
                lastError: lastError,
                addedAt: addedAt,
                addressClass: addressClass,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<i1.$PluginReposTable, i1.PluginRepoRow>(table),
                  i0.BaseReferences<
                    i0.GeneratedDatabase,
                    i1.$PluginReposTable,
                    i1.PluginRepoRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PluginReposTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$PluginReposTable,
      i1.PluginRepoRow,
      i1.$$PluginReposTableFilterComposer,
      i1.$$PluginReposTableOrderingComposer,
      i1.$$PluginReposTableAnnotationComposer,
      $$PluginReposTableCreateCompanionBuilder,
      $$PluginReposTableUpdateCompanionBuilder,
      (
        i1.PluginRepoRow,
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$PluginReposTable,
          i1.PluginRepoRow
        >,
      ),
      i1.PluginRepoRow,
      i0.PrefetchHooks Function()
    >;
typedef $$PluginsTableCreateCompanionBuilder = i1.PluginsCompanion Function({
  required String installId,
  required String kind,
  required String name,
  i0.Value<String?> author,
  required int version,
  required int apiVersion,
  required String manifestJson,
  i0.Value<String?> packageDir,
  required String packageSha256,
  required String origin,
  i0.Value<String?> repoUrl,
  i0.Value<String?> repoSlug,
  i0.Value<String?> originLabel,
  required String consentedHostsJson,
  required int installedAt,
  required int updatedAt,
  i0.Value<int?> removedAt,
  i0.Value<int> rowid,
});
typedef $$PluginsTableUpdateCompanionBuilder = i1.PluginsCompanion Function({
  i0.Value<String> installId,
  i0.Value<String> kind,
  i0.Value<String> name,
  i0.Value<String?> author,
  i0.Value<int> version,
  i0.Value<int> apiVersion,
  i0.Value<String> manifestJson,
  i0.Value<String?> packageDir,
  i0.Value<String> packageSha256,
  i0.Value<String> origin,
  i0.Value<String?> repoUrl,
  i0.Value<String?> repoSlug,
  i0.Value<String?> originLabel,
  i0.Value<String> consentedHostsJson,
  i0.Value<int> installedAt,
  i0.Value<int> updatedAt,
  i0.Value<int?> removedAt,
  i0.Value<int> rowid,
});

final class $$PluginsTableReferences
    extends
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$PluginsTable,
          i1.PluginRow
        > {
  $$PluginsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static i0.MultiTypedResultKey<i1.$PluginDataTable, List<i1.PluginDataRow>>
  _pluginDataRefsTable(i0.GeneratedDatabase db) =>
      i0.MultiTypedResultKey.fromTable(
        i4.ReadDatabaseContainer(db)
            .resultSet<i1.$PluginDataTable>('plugin_data'),
        aliasName: 'plugins__install_id__plugin_data__install_id',
      );

  i1.$$PluginDataTableProcessedTableManager get pluginDataRefs {
    final manager = i1
        .$$PluginDataTableTableManager(
          $_db,
          i4.ReadDatabaseContainer($_db)
              .resultSet<i1.$PluginDataTable>('plugin_data'),
        )
        .filter(
          (f) => f.installId.installId.sqlEquals(
            $_itemColumn<String>('install_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_pluginDataRefsTable($_db));
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PluginsTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$PluginsTable> {
  $$PluginsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get installId => $composableBuilder(
    column: $table.installId,
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

  i0.ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get apiVersion => $composableBuilder(
    column: $table.apiVersion,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get manifestJson => $composableBuilder(
    column: $table.manifestJson,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get packageDir => $composableBuilder(
    column: $table.packageDir,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get packageSha256 => $composableBuilder(
    column: $table.packageSha256,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get repoUrl => $composableBuilder(
    column: $table.repoUrl,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get repoSlug => $composableBuilder(
    column: $table.repoSlug,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get originLabel => $composableBuilder(
    column: $table.originLabel,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get consentedHostsJson => $composableBuilder(
    column: $table.consentedHostsJson,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get removedAt => $composableBuilder(
    column: $table.removedAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.Expression<bool> pluginDataRefs(
    i0.Expression<bool> Function(i1.$$PluginDataTableFilterComposer f) f,
  ) {
    final i1.$$PluginDataTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.installId,
      referencedTable: i4.ReadDatabaseContainer($db)
          .resultSet<i1.$PluginDataTable>('plugin_data'),
      getReferencedColumn: (t) => t.installId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i1.$$PluginDataTableFilterComposer(
            $db: $db,
            $table: i4.ReadDatabaseContainer($db)
                .resultSet<i1.$PluginDataTable>('plugin_data'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PluginsTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$PluginsTable> {
  $$PluginsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get installId => $composableBuilder(
    column: $table.installId,
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

  i0.ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get apiVersion => $composableBuilder(
    column: $table.apiVersion,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get manifestJson => $composableBuilder(
    column: $table.manifestJson,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get packageDir => $composableBuilder(
    column: $table.packageDir,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get packageSha256 => $composableBuilder(
    column: $table.packageSha256,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get repoUrl => $composableBuilder(
    column: $table.repoUrl,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get repoSlug => $composableBuilder(
    column: $table.repoSlug,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get originLabel => $composableBuilder(
    column: $table.originLabel,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get consentedHostsJson => $composableBuilder(
    column: $table.consentedHostsJson,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get removedAt => $composableBuilder(
    column: $table.removedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $$PluginsTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$PluginsTable> {
  $$PluginsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get installId =>
      $composableBuilder(column: $table.installId, builder: (column) => column);

  i0.GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  i0.GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  i0.GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  i0.GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  i0.GeneratedColumn<int> get apiVersion => $composableBuilder(
    column: $table.apiVersion,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get manifestJson => $composableBuilder(
    column: $table.manifestJson,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get packageDir => $composableBuilder(
    column: $table.packageDir,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get packageSha256 => $composableBuilder(
    column: $table.packageSha256,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  i0.GeneratedColumn<String> get repoUrl =>
      $composableBuilder(column: $table.repoUrl, builder: (column) => column);

  i0.GeneratedColumn<String> get repoSlug =>
      $composableBuilder(column: $table.repoSlug, builder: (column) => column);

  i0.GeneratedColumn<String> get originLabel => $composableBuilder(
    column: $table.originLabel,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get consentedHostsJson => $composableBuilder(
    column: $table.consentedHostsJson,
    builder: (column) => column,
  );

  i0.GeneratedColumn<int> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => column,
  );

  i0.GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  i0.GeneratedColumn<int> get removedAt =>
      $composableBuilder(column: $table.removedAt, builder: (column) => column);

  i0.Expression<T> pluginDataRefs<T extends Object>(
    i0.Expression<T> Function(i1.$$PluginDataTableAnnotationComposer a) f,
  ) {
    final i1.$$PluginDataTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.installId,
      referencedTable: i4.ReadDatabaseContainer($db)
          .resultSet<i1.$PluginDataTable>('plugin_data'),
      getReferencedColumn: (t) => t.installId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i1.$$PluginDataTableAnnotationComposer(
            $db: $db,
            $table: i4.ReadDatabaseContainer($db)
                .resultSet<i1.$PluginDataTable>('plugin_data'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PluginsTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$PluginsTable,
          i1.PluginRow,
          i1.$$PluginsTableFilterComposer,
          i1.$$PluginsTableOrderingComposer,
          i1.$$PluginsTableAnnotationComposer,
          $$PluginsTableCreateCompanionBuilder,
          $$PluginsTableUpdateCompanionBuilder,
          (i1.PluginRow, i1.$$PluginsTableReferences),
          i1.PluginRow,
          i0.PrefetchHooks Function({bool pluginDataRefs})
        > {
  $$PluginsTableTableManager(i0.GeneratedDatabase db, i1.$PluginsTable table)
    : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$PluginsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$PluginsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$PluginsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> installId = const i0.Value.absent(),
                i0.Value<String> kind = const i0.Value.absent(),
                i0.Value<String> name = const i0.Value.absent(),
                i0.Value<String?> author = const i0.Value.absent(),
                i0.Value<int> version = const i0.Value.absent(),
                i0.Value<int> apiVersion = const i0.Value.absent(),
                i0.Value<String> manifestJson = const i0.Value.absent(),
                i0.Value<String?> packageDir = const i0.Value.absent(),
                i0.Value<String> packageSha256 = const i0.Value.absent(),
                i0.Value<String> origin = const i0.Value.absent(),
                i0.Value<String?> repoUrl = const i0.Value.absent(),
                i0.Value<String?> repoSlug = const i0.Value.absent(),
                i0.Value<String?> originLabel = const i0.Value.absent(),
                i0.Value<String> consentedHostsJson = const i0.Value.absent(),
                i0.Value<int> installedAt = const i0.Value.absent(),
                i0.Value<int> updatedAt = const i0.Value.absent(),
                i0.Value<int?> removedAt = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.PluginsCompanion(
                installId: installId,
                kind: kind,
                name: name,
                author: author,
                version: version,
                apiVersion: apiVersion,
                manifestJson: manifestJson,
                packageDir: packageDir,
                packageSha256: packageSha256,
                origin: origin,
                repoUrl: repoUrl,
                repoSlug: repoSlug,
                originLabel: originLabel,
                consentedHostsJson: consentedHostsJson,
                installedAt: installedAt,
                updatedAt: updatedAt,
                removedAt: removedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String installId,
                required String kind,
                required String name,
                i0.Value<String?> author = const i0.Value.absent(),
                required int version,
                required int apiVersion,
                required String manifestJson,
                i0.Value<String?> packageDir = const i0.Value.absent(),
                required String packageSha256,
                required String origin,
                i0.Value<String?> repoUrl = const i0.Value.absent(),
                i0.Value<String?> repoSlug = const i0.Value.absent(),
                i0.Value<String?> originLabel = const i0.Value.absent(),
                required String consentedHostsJson,
                required int installedAt,
                required int updatedAt,
                i0.Value<int?> removedAt = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.PluginsCompanion.insert(
                installId: installId,
                kind: kind,
                name: name,
                author: author,
                version: version,
                apiVersion: apiVersion,
                manifestJson: manifestJson,
                packageDir: packageDir,
                packageSha256: packageSha256,
                origin: origin,
                repoUrl: repoUrl,
                repoSlug: repoSlug,
                originLabel: originLabel,
                consentedHostsJson: consentedHostsJson,
                installedAt: installedAt,
                updatedAt: updatedAt,
                removedAt: removedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<i1.$PluginsTable, i1.PluginRow>(table),
                  i1.$$PluginsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({pluginDataRefs = false}) {
            return i0.PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (pluginDataRefs)
                  i4.ReadDatabaseContainer(db)
                      .resultSet<i1.$PluginDataTable>('plugin_data'),
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (pluginDataRefs)
                    await i0.$_getPrefetchedDataByColumns<
                      i1.PluginRow,
                      i1.$PluginsTable,
                      i1.PluginDataRow,
                      i1.$PluginDataTable
                    >(
                      currentTable: table,
                      referencedTable: i1.$$PluginsTableReferences
                          ._pluginDataRefsTable(db),
                      managerFromTypedResult: (p0) => i1
                          .$$PluginsTableReferences(db, table, p0)
                          .pluginDataRefs,
                      currentColumn: 'install_id',
                      referencedColumn: 'install_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PluginsTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$PluginsTable,
      i1.PluginRow,
      i1.$$PluginsTableFilterComposer,
      i1.$$PluginsTableOrderingComposer,
      i1.$$PluginsTableAnnotationComposer,
      $$PluginsTableCreateCompanionBuilder,
      $$PluginsTableUpdateCompanionBuilder,
      (i1.PluginRow, i1.$$PluginsTableReferences),
      i1.PluginRow,
      i0.PrefetchHooks Function({bool pluginDataRefs})
    >;
typedef $$PluginDataTableCreateCompanionBuilder =
    i1.PluginDataCompanion Function({
      required String installId,
      i0.Value<String> configJson,
      i0.Value<String> customChoicesJson,
      i0.Value<int> rowid,
    });
typedef $$PluginDataTableUpdateCompanionBuilder =
    i1.PluginDataCompanion Function({
      i0.Value<String> installId,
      i0.Value<String> configJson,
      i0.Value<String> customChoicesJson,
      i0.Value<int> rowid,
    });

final class $$PluginDataTableReferences
    extends
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$PluginDataTable,
          i1.PluginDataRow
        > {
  $$PluginDataTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static i1.$PluginsTable _installIdTable(i0.GeneratedDatabase db) =>
      i4.ReadDatabaseContainer(db)
          .resultSet<i1.$PluginsTable>('plugins')
          .createAlias('plugin_data__install_id__plugins__install_id');

  i1.$$PluginsTableProcessedTableManager get installId {
    final $_column = $_itemColumn<String>('install_id')!;

    final manager = i1
        .$$PluginsTableTableManager(
          $_db,
          i4.ReadDatabaseContainer($_db).resultSet<i1.$PluginsTable>('plugins'),
        )
        .filter((f) => f.installId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_installIdTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PluginDataTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$PluginDataTable> {
  $$PluginDataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get customChoicesJson => $composableBuilder(
    column: $table.customChoicesJson,
    builder: (column) => i0.ColumnFilters(column),
  );

  i1.$$PluginsTableFilterComposer get installId {
    final i1.$$PluginsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.installId,
      referencedTable: i4.ReadDatabaseContainer($db)
          .resultSet<i1.$PluginsTable>('plugins'),
      getReferencedColumn: (t) => t.installId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i1.$$PluginsTableFilterComposer(
            $db: $db,
            $table: i4.ReadDatabaseContainer($db)
                .resultSet<i1.$PluginsTable>('plugins'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PluginDataTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$PluginDataTable> {
  $$PluginDataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get customChoicesJson => $composableBuilder(
    column: $table.customChoicesJson,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i1.$$PluginsTableOrderingComposer get installId {
    final i1.$$PluginsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.installId,
      referencedTable: i4.ReadDatabaseContainer($db)
          .resultSet<i1.$PluginsTable>('plugins'),
      getReferencedColumn: (t) => t.installId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i1.$$PluginsTableOrderingComposer(
            $db: $db,
            $table: i4.ReadDatabaseContainer($db)
                .resultSet<i1.$PluginsTable>('plugins'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PluginDataTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$PluginDataTable> {
  $$PluginDataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get customChoicesJson => $composableBuilder(
    column: $table.customChoicesJson,
    builder: (column) => column,
  );

  i1.$$PluginsTableAnnotationComposer get installId {
    final i1.$$PluginsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.installId,
      referencedTable: i4.ReadDatabaseContainer($db)
          .resultSet<i1.$PluginsTable>('plugins'),
      getReferencedColumn: (t) => t.installId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i1.$$PluginsTableAnnotationComposer(
            $db: $db,
            $table: i4.ReadDatabaseContainer($db)
                .resultSet<i1.$PluginsTable>('plugins'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PluginDataTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$PluginDataTable,
          i1.PluginDataRow,
          i1.$$PluginDataTableFilterComposer,
          i1.$$PluginDataTableOrderingComposer,
          i1.$$PluginDataTableAnnotationComposer,
          $$PluginDataTableCreateCompanionBuilder,
          $$PluginDataTableUpdateCompanionBuilder,
          (i1.PluginDataRow, i1.$$PluginDataTableReferences),
          i1.PluginDataRow,
          i0.PrefetchHooks Function({bool installId})
        > {
  $$PluginDataTableTableManager(
    i0.GeneratedDatabase db,
    i1.$PluginDataTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$PluginDataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$PluginDataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$PluginDataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> installId = const i0.Value.absent(),
                i0.Value<String> configJson = const i0.Value.absent(),
                i0.Value<String> customChoicesJson = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.PluginDataCompanion(
                installId: installId,
                configJson: configJson,
                customChoicesJson: customChoicesJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String installId,
                i0.Value<String> configJson = const i0.Value.absent(),
                i0.Value<String> customChoicesJson = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.PluginDataCompanion.insert(
                installId: installId,
                configJson: configJson,
                customChoicesJson: customChoicesJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<i1.$PluginDataTable, i1.PluginDataRow>(table),
                  i1.$$PluginDataTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({installId = false}) {
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
                    if (installId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.installId,
                        referencedTable: i1.$$PluginDataTableReferences
                            ._installIdTable(db),
                        referencedColumn: i1.$$PluginDataTableReferences
                            ._installIdTable(db)
                            .installId,
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

typedef $$PluginDataTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$PluginDataTable,
      i1.PluginDataRow,
      i1.$$PluginDataTableFilterComposer,
      i1.$$PluginDataTableOrderingComposer,
      i1.$$PluginDataTableAnnotationComposer,
      $$PluginDataTableCreateCompanionBuilder,
      $$PluginDataTableUpdateCompanionBuilder,
      (i1.PluginDataRow, i1.$$PluginDataTableReferences),
      i1.PluginDataRow,
      i0.PrefetchHooks Function({bool installId})
    >;

class $PluginReposTable extends i2.PluginRepos
    with i0.TableInfo<$PluginReposTable, i1.PluginRepoRow> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PluginReposTable(this.attachedDatabase, [this._alias]);
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
  static const i0.VerificationMeta _urlMeta = const i0.VerificationMeta('url');
  @override
  late final i0.GeneratedColumn<String> url = i0.GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways('UNIQUE'),
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
  static const i0.VerificationMeta _catalogJsonMeta = const i0.VerificationMeta(
    'catalogJson',
  );
  @override
  late final i0.GeneratedColumn<String> catalogJson =
      i0.GeneratedColumn<String>(
        'catalog_json',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const i0.VerificationMeta _refreshedAtMeta = const i0.VerificationMeta(
    'refreshedAt',
  );
  @override
  late final i0.GeneratedColumn<int> refreshedAt = i0.GeneratedColumn<int>(
    'refreshed_at',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _lastAttemptAtMeta =
      const i0.VerificationMeta('lastAttemptAt');
  @override
  late final i0.GeneratedColumn<int> lastAttemptAt = i0.GeneratedColumn<int>(
    'last_attempt_at',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _lastErrorMeta = const i0.VerificationMeta(
    'lastError',
  );
  @override
  late final i0.GeneratedColumn<String> lastError = i0.GeneratedColumn<String>(
    'last_error',
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
  static const i0.VerificationMeta _addressClassMeta =
      const i0.VerificationMeta('addressClass');
  @override
  late final i0.GeneratedColumn<String> addressClass =
      i0.GeneratedColumn<String>(
        'address_class',
        aliasedName,
        false,
        check: () => addressClass.isIn(i2.PluginAddressClassValues.values),
        type: i0.DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  List<i0.GeneratedColumn> get $columns => [
    id,
    url,
    name,
    catalogJson,
    refreshedAt,
    lastAttemptAt,
    lastError,
    addedAt,
    addressClass,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plugin_repos';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.PluginRepoRow> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('catalog_json')) {
      context.handle(
        _catalogJsonMeta,
        catalogJson.isAcceptableOrUnknown(
          data['catalog_json']!,
          _catalogJsonMeta,
        ),
      );
    }
    if (data.containsKey('refreshed_at')) {
      context.handle(
        _refreshedAtMeta,
        refreshedAt.isAcceptableOrUnknown(
          data['refreshed_at']!,
          _refreshedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
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
    if (data.containsKey('address_class')) {
      context.handle(
        _addressClassMeta,
        addressClass.isAcceptableOrUnknown(
          data['address_class']!,
          _addressClassMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_addressClassMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i1.PluginRepoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.PluginRepoRow(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      url: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      name: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      catalogJson: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}catalog_json'],
      ),
      refreshedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}refreshed_at'],
      ),
      lastAttemptAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}last_attempt_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      addedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}added_at'],
      )!,
      addressClass: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}address_class'],
      )!,
    );
  }

  @override
  $PluginReposTable createAlias(String alias) {
    return $PluginReposTable(attachedDatabase, alias);
  }
}

class PluginRepoRow extends i0.DataClass
    implements i0.Insertable<i1.PluginRepoRow> {
  final int id;

  /// The canonical address (`canonicalRepoUrl`), unique.
  final String url;
  final String name;

  /// The last good catalog (at most 1 MiB) as normalized JSON with every
  /// reference absolute (the plugin store writes the parsed catalog, not the
  /// received bytes); null before the first successful fetch. A failed
  /// refresh keeps it.
  final String? catalogJson;
  final int? refreshedAt;
  final int? lastAttemptAt;

  /// Kind of the last failure (not a message), null after a success.
  final String? lastError;
  final int addedAt;

  /// Address class of the catalog as the fetcher reported it at add or the
  /// last refresh (`public` or `local`). Package and icon fetches from this
  /// catalog are judged with it.
  final String addressClass;
  const PluginRepoRow({
    required this.id,
    required this.url,
    required this.name,
    this.catalogJson,
    this.refreshedAt,
    this.lastAttemptAt,
    this.lastError,
    required this.addedAt,
    required this.addressClass,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id);
    map['url'] = i0.Variable<String>(url);
    map['name'] = i0.Variable<String>(name);
    if (!nullToAbsent || catalogJson != null) {
      map['catalog_json'] = i0.Variable<String>(catalogJson);
    }
    if (!nullToAbsent || refreshedAt != null) {
      map['refreshed_at'] = i0.Variable<int>(refreshedAt);
    }
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = i0.Variable<int>(lastAttemptAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = i0.Variable<String>(lastError);
    }
    map['added_at'] = i0.Variable<int>(addedAt);
    map['address_class'] = i0.Variable<String>(addressClass);
    return map;
  }

  i1.PluginReposCompanion toCompanion(bool nullToAbsent) {
    return i1.PluginReposCompanion(
      id: i0.Value(id),
      url: i0.Value(url),
      name: i0.Value(name),
      catalogJson: catalogJson == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(catalogJson),
      refreshedAt: refreshedAt == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(refreshedAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(lastAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(lastError),
      addedAt: i0.Value(addedAt),
      addressClass: i0.Value(addressClass),
    );
  }

  factory PluginRepoRow.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return PluginRepoRow(
      id: serializer.fromJson<int>(json['id']),
      url: serializer.fromJson<String>(json['url']),
      name: serializer.fromJson<String>(json['name']),
      catalogJson: serializer.fromJson<String?>(json['catalogJson']),
      refreshedAt: serializer.fromJson<int?>(json['refreshedAt']),
      lastAttemptAt: serializer.fromJson<int?>(json['lastAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      addedAt: serializer.fromJson<int>(json['addedAt']),
      addressClass: serializer.fromJson<String>(json['addressClass']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'url': serializer.toJson<String>(url),
      'name': serializer.toJson<String>(name),
      'catalogJson': serializer.toJson<String?>(catalogJson),
      'refreshedAt': serializer.toJson<int?>(refreshedAt),
      'lastAttemptAt': serializer.toJson<int?>(lastAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
      'addedAt': serializer.toJson<int>(addedAt),
      'addressClass': serializer.toJson<String>(addressClass),
    };
  }

  i1.PluginRepoRow copyWith({
    int? id,
    String? url,
    String? name,
    i0.Value<String?> catalogJson = const i0.Value.absent(),
    i0.Value<int?> refreshedAt = const i0.Value.absent(),
    i0.Value<int?> lastAttemptAt = const i0.Value.absent(),
    i0.Value<String?> lastError = const i0.Value.absent(),
    int? addedAt,
    String? addressClass,
  }) => i1.PluginRepoRow(
    id: id ?? this.id,
    url: url ?? this.url,
    name: name ?? this.name,
    catalogJson: catalogJson.present ? catalogJson.value : this.catalogJson,
    refreshedAt: refreshedAt.present ? refreshedAt.value : this.refreshedAt,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    addedAt: addedAt ?? this.addedAt,
    addressClass: addressClass ?? this.addressClass,
  );
  PluginRepoRow copyWithCompanion(i1.PluginReposCompanion data) {
    return PluginRepoRow(
      id: data.id.present ? data.id.value : this.id,
      url: data.url.present ? data.url.value : this.url,
      name: data.name.present ? data.name.value : this.name,
      catalogJson: data.catalogJson.present
          ? data.catalogJson.value
          : this.catalogJson,
      refreshedAt: data.refreshedAt.present
          ? data.refreshedAt.value
          : this.refreshedAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      addressClass: data.addressClass.present
          ? data.addressClass.value
          : this.addressClass,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PluginRepoRow(')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('name: $name, ')
          ..write('catalogJson: $catalogJson, ')
          ..write('refreshedAt: $refreshedAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('addedAt: $addedAt, ')
          ..write('addressClass: $addressClass')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    url,
    name,
    catalogJson,
    refreshedAt,
    lastAttemptAt,
    lastError,
    addedAt,
    addressClass,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.PluginRepoRow &&
          other.id == this.id &&
          other.url == this.url &&
          other.name == this.name &&
          other.catalogJson == this.catalogJson &&
          other.refreshedAt == this.refreshedAt &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.lastError == this.lastError &&
          other.addedAt == this.addedAt &&
          other.addressClass == this.addressClass);
}

class PluginReposCompanion extends i0.UpdateCompanion<i1.PluginRepoRow> {
  final i0.Value<int> id;
  final i0.Value<String> url;
  final i0.Value<String> name;
  final i0.Value<String?> catalogJson;
  final i0.Value<int?> refreshedAt;
  final i0.Value<int?> lastAttemptAt;
  final i0.Value<String?> lastError;
  final i0.Value<int> addedAt;
  final i0.Value<String> addressClass;
  const PluginReposCompanion({
    this.id = const i0.Value.absent(),
    this.url = const i0.Value.absent(),
    this.name = const i0.Value.absent(),
    this.catalogJson = const i0.Value.absent(),
    this.refreshedAt = const i0.Value.absent(),
    this.lastAttemptAt = const i0.Value.absent(),
    this.lastError = const i0.Value.absent(),
    this.addedAt = const i0.Value.absent(),
    this.addressClass = const i0.Value.absent(),
  });
  PluginReposCompanion.insert({
    this.id = const i0.Value.absent(),
    required String url,
    required String name,
    this.catalogJson = const i0.Value.absent(),
    this.refreshedAt = const i0.Value.absent(),
    this.lastAttemptAt = const i0.Value.absent(),
    this.lastError = const i0.Value.absent(),
    required int addedAt,
    required String addressClass,
  }) : url = i0.Value(url),
       name = i0.Value(name),
       addedAt = i0.Value(addedAt),
       addressClass = i0.Value(addressClass);
  static i0.Insertable<i1.PluginRepoRow> custom({
    i0.Expression<int>? id,
    i0.Expression<String>? url,
    i0.Expression<String>? name,
    i0.Expression<String>? catalogJson,
    i0.Expression<int>? refreshedAt,
    i0.Expression<int>? lastAttemptAt,
    i0.Expression<String>? lastError,
    i0.Expression<int>? addedAt,
    i0.Expression<String>? addressClass,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (url != null) 'url': url,
      if (name != null) 'name': name,
      if (catalogJson != null) 'catalog_json': catalogJson,
      if (refreshedAt != null) 'refreshed_at': refreshedAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (lastError != null) 'last_error': lastError,
      if (addedAt != null) 'added_at': addedAt,
      if (addressClass != null) 'address_class': addressClass,
    });
  }

  i1.PluginReposCompanion copyWith({
    i0.Value<int>? id,
    i0.Value<String>? url,
    i0.Value<String>? name,
    i0.Value<String?>? catalogJson,
    i0.Value<int?>? refreshedAt,
    i0.Value<int?>? lastAttemptAt,
    i0.Value<String?>? lastError,
    i0.Value<int>? addedAt,
    i0.Value<String>? addressClass,
  }) {
    return i1.PluginReposCompanion(
      id: id ?? this.id,
      url: url ?? this.url,
      name: name ?? this.name,
      catalogJson: catalogJson ?? this.catalogJson,
      refreshedAt: refreshedAt ?? this.refreshedAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastError: lastError ?? this.lastError,
      addedAt: addedAt ?? this.addedAt,
      addressClass: addressClass ?? this.addressClass,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<int>(id.value);
    }
    if (url.present) {
      map['url'] = i0.Variable<String>(url.value);
    }
    if (name.present) {
      map['name'] = i0.Variable<String>(name.value);
    }
    if (catalogJson.present) {
      map['catalog_json'] = i0.Variable<String>(catalogJson.value);
    }
    if (refreshedAt.present) {
      map['refreshed_at'] = i0.Variable<int>(refreshedAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = i0.Variable<int>(lastAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = i0.Variable<String>(lastError.value);
    }
    if (addedAt.present) {
      map['added_at'] = i0.Variable<int>(addedAt.value);
    }
    if (addressClass.present) {
      map['address_class'] = i0.Variable<String>(addressClass.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PluginReposCompanion(')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('name: $name, ')
          ..write('catalogJson: $catalogJson, ')
          ..write('refreshedAt: $refreshedAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('addedAt: $addedAt, ')
          ..write('addressClass: $addressClass')
          ..write(')'))
        .toString();
  }
}

i0.Index get pluginsRepoEntry => i0.Index(
  'plugins_repo_entry',
  'CREATE UNIQUE INDEX plugins_repo_entry ON plugins (repo_url, repo_slug)',
);

class $PluginsTable extends i2.Plugins
    with i0.TableInfo<$PluginsTable, i1.PluginRow> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PluginsTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _installIdMeta = const i0.VerificationMeta(
    'installId',
  );
  @override
  late final i0.GeneratedColumn<String> installId = i0.GeneratedColumn<String>(
    'install_id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _kindMeta = const i0.VerificationMeta(
    'kind',
  );
  @override
  late final i0.GeneratedColumn<String> kind = i0.GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    check: () => kind.isIn(i2.PluginKindValues.values),
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
  static const i0.VerificationMeta _authorMeta = const i0.VerificationMeta(
    'author',
  );
  @override
  late final i0.GeneratedColumn<String> author = i0.GeneratedColumn<String>(
    'author',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _versionMeta = const i0.VerificationMeta(
    'version',
  );
  @override
  late final i0.GeneratedColumn<int> version = i0.GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _apiVersionMeta = const i0.VerificationMeta(
    'apiVersion',
  );
  @override
  late final i0.GeneratedColumn<int> apiVersion = i0.GeneratedColumn<int>(
    'api_version',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _manifestJsonMeta =
      const i0.VerificationMeta('manifestJson');
  @override
  late final i0.GeneratedColumn<String> manifestJson =
      i0.GeneratedColumn<String>(
        'manifest_json',
        aliasedName,
        false,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const i0.VerificationMeta _packageDirMeta = const i0.VerificationMeta(
    'packageDir',
  );
  @override
  late final i0.GeneratedColumn<String> packageDir = i0.GeneratedColumn<String>(
    'package_dir',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _packageSha256Meta =
      const i0.VerificationMeta('packageSha256');
  @override
  late final i0.GeneratedColumn<String> packageSha256 =
      i0.GeneratedColumn<String>(
        'package_sha256',
        aliasedName,
        false,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const i0.VerificationMeta _originMeta = const i0.VerificationMeta(
    'origin',
  );
  @override
  late final i0.GeneratedColumn<String> origin = i0.GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    check: () => origin.isIn(i2.PluginOriginValues.values),
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _repoUrlMeta = const i0.VerificationMeta(
    'repoUrl',
  );
  @override
  late final i0.GeneratedColumn<String> repoUrl = i0.GeneratedColumn<String>(
    'repo_url',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _repoSlugMeta = const i0.VerificationMeta(
    'repoSlug',
  );
  @override
  late final i0.GeneratedColumn<String> repoSlug = i0.GeneratedColumn<String>(
    'repo_slug',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _originLabelMeta = const i0.VerificationMeta(
    'originLabel',
  );
  @override
  late final i0.GeneratedColumn<String> originLabel =
      i0.GeneratedColumn<String>(
        'origin_label',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const i0.VerificationMeta _consentedHostsJsonMeta =
      const i0.VerificationMeta('consentedHostsJson');
  @override
  late final i0.GeneratedColumn<String> consentedHostsJson =
      i0.GeneratedColumn<String>(
        'consented_hosts_json',
        aliasedName,
        false,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const i0.VerificationMeta _installedAtMeta = const i0.VerificationMeta(
    'installedAt',
  );
  @override
  late final i0.GeneratedColumn<int> installedAt = i0.GeneratedColumn<int>(
    'installed_at',
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
  static const i0.VerificationMeta _removedAtMeta = const i0.VerificationMeta(
    'removedAt',
  );
  @override
  late final i0.GeneratedColumn<int> removedAt = i0.GeneratedColumn<int>(
    'removed_at',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<i0.GeneratedColumn> get $columns => [
    installId,
    kind,
    name,
    author,
    version,
    apiVersion,
    manifestJson,
    packageDir,
    packageSha256,
    origin,
    repoUrl,
    repoSlug,
    originLabel,
    consentedHostsJson,
    installedAt,
    updatedAt,
    removedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plugins';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.PluginRow> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('install_id')) {
      context.handle(
        _installIdMeta,
        installId.isAcceptableOrUnknown(data['install_id']!, _installIdMeta),
      );
    } else if (isInserting) {
      context.missing(_installIdMeta);
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
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('api_version')) {
      context.handle(
        _apiVersionMeta,
        apiVersion.isAcceptableOrUnknown(data['api_version']!, _apiVersionMeta),
      );
    } else if (isInserting) {
      context.missing(_apiVersionMeta);
    }
    if (data.containsKey('manifest_json')) {
      context.handle(
        _manifestJsonMeta,
        manifestJson.isAcceptableOrUnknown(
          data['manifest_json']!,
          _manifestJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_manifestJsonMeta);
    }
    if (data.containsKey('package_dir')) {
      context.handle(
        _packageDirMeta,
        packageDir.isAcceptableOrUnknown(data['package_dir']!, _packageDirMeta),
      );
    }
    if (data.containsKey('package_sha256')) {
      context.handle(
        _packageSha256Meta,
        packageSha256.isAcceptableOrUnknown(
          data['package_sha256']!,
          _packageSha256Meta,
        ),
      );
    } else if (isInserting) {
      context.missing(_packageSha256Meta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('repo_url')) {
      context.handle(
        _repoUrlMeta,
        repoUrl.isAcceptableOrUnknown(data['repo_url']!, _repoUrlMeta),
      );
    }
    if (data.containsKey('repo_slug')) {
      context.handle(
        _repoSlugMeta,
        repoSlug.isAcceptableOrUnknown(data['repo_slug']!, _repoSlugMeta),
      );
    }
    if (data.containsKey('origin_label')) {
      context.handle(
        _originLabelMeta,
        originLabel.isAcceptableOrUnknown(
          data['origin_label']!,
          _originLabelMeta,
        ),
      );
    }
    if (data.containsKey('consented_hosts_json')) {
      context.handle(
        _consentedHostsJsonMeta,
        consentedHostsJson.isAcceptableOrUnknown(
          data['consented_hosts_json']!,
          _consentedHostsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_consentedHostsJsonMeta);
    }
    if (data.containsKey('installed_at')) {
      context.handle(
        _installedAtMeta,
        installedAt.isAcceptableOrUnknown(
          data['installed_at']!,
          _installedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_installedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('removed_at')) {
      context.handle(
        _removedAtMeta,
        removedAt.isAcceptableOrUnknown(data['removed_at']!, _removedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {installId};
  @override
  i1.PluginRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.PluginRow(
      installId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}install_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      name: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      author: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}author'],
      ),
      version: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      apiVersion: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}api_version'],
      )!,
      manifestJson: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}manifest_json'],
      )!,
      packageDir: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}package_dir'],
      ),
      packageSha256: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}package_sha256'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      repoUrl: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}repo_url'],
      ),
      repoSlug: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}repo_slug'],
      ),
      originLabel: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}origin_label'],
      ),
      consentedHostsJson: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}consented_hosts_json'],
      )!,
      installedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}installed_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      removedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}removed_at'],
      ),
    );
  }

  @override
  $PluginsTable createAlias(String alias) {
    return $PluginsTable(attachedDatabase, alias);
  }
}

class PluginRow extends i0.DataClass implements i0.Insertable<i1.PluginRow> {
  final String installId;
  final String kind;
  final String name;
  final String? author;
  final int version;
  final int apiVersion;

  /// The original `plugin.json` text (at most 64 KiB), parsed on read; fields
  /// this app does not know survive in it.
  final String manifestJson;

  /// Folder of the package under `plugins/<install_id>/`
  /// (`v<version>-<epochMs>`). Null for a tombstone and for a row waiting for
  /// its package to be installed again.
  final String? packageDir;

  /// Lower-case hex SHA-256 of the package zip.
  final String packageSha256;
  final String origin;

  /// Set exactly for `origin = 'repo'`.
  final String? repoUrl;
  final String? repoSlug;

  /// File name (`file`) or link (`link`); null for a repository install.
  final String? originLabel;

  /// JSON array of the hosts the user agreed to at install / update. A later
  /// package needing a host outside this set needs a new review.
  final String consentedHostsJson;
  final int installedAt;

  /// Epoch ms of the last package switch or removal; strictly increases.
  final int updatedAt;

  /// Tombstone time; null while the plugin is installed.
  final int? removedAt;
  const PluginRow({
    required this.installId,
    required this.kind,
    required this.name,
    this.author,
    required this.version,
    required this.apiVersion,
    required this.manifestJson,
    this.packageDir,
    required this.packageSha256,
    required this.origin,
    this.repoUrl,
    this.repoSlug,
    this.originLabel,
    required this.consentedHostsJson,
    required this.installedAt,
    required this.updatedAt,
    this.removedAt,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['install_id'] = i0.Variable<String>(installId);
    map['kind'] = i0.Variable<String>(kind);
    map['name'] = i0.Variable<String>(name);
    if (!nullToAbsent || author != null) {
      map['author'] = i0.Variable<String>(author);
    }
    map['version'] = i0.Variable<int>(version);
    map['api_version'] = i0.Variable<int>(apiVersion);
    map['manifest_json'] = i0.Variable<String>(manifestJson);
    if (!nullToAbsent || packageDir != null) {
      map['package_dir'] = i0.Variable<String>(packageDir);
    }
    map['package_sha256'] = i0.Variable<String>(packageSha256);
    map['origin'] = i0.Variable<String>(origin);
    if (!nullToAbsent || repoUrl != null) {
      map['repo_url'] = i0.Variable<String>(repoUrl);
    }
    if (!nullToAbsent || repoSlug != null) {
      map['repo_slug'] = i0.Variable<String>(repoSlug);
    }
    if (!nullToAbsent || originLabel != null) {
      map['origin_label'] = i0.Variable<String>(originLabel);
    }
    map['consented_hosts_json'] = i0.Variable<String>(consentedHostsJson);
    map['installed_at'] = i0.Variable<int>(installedAt);
    map['updated_at'] = i0.Variable<int>(updatedAt);
    if (!nullToAbsent || removedAt != null) {
      map['removed_at'] = i0.Variable<int>(removedAt);
    }
    return map;
  }

  i1.PluginsCompanion toCompanion(bool nullToAbsent) {
    return i1.PluginsCompanion(
      installId: i0.Value(installId),
      kind: i0.Value(kind),
      name: i0.Value(name),
      author: author == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(author),
      version: i0.Value(version),
      apiVersion: i0.Value(apiVersion),
      manifestJson: i0.Value(manifestJson),
      packageDir: packageDir == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(packageDir),
      packageSha256: i0.Value(packageSha256),
      origin: i0.Value(origin),
      repoUrl: repoUrl == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(repoUrl),
      repoSlug: repoSlug == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(repoSlug),
      originLabel: originLabel == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(originLabel),
      consentedHostsJson: i0.Value(consentedHostsJson),
      installedAt: i0.Value(installedAt),
      updatedAt: i0.Value(updatedAt),
      removedAt: removedAt == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(removedAt),
    );
  }

  factory PluginRow.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return PluginRow(
      installId: serializer.fromJson<String>(json['installId']),
      kind: serializer.fromJson<String>(json['kind']),
      name: serializer.fromJson<String>(json['name']),
      author: serializer.fromJson<String?>(json['author']),
      version: serializer.fromJson<int>(json['version']),
      apiVersion: serializer.fromJson<int>(json['apiVersion']),
      manifestJson: serializer.fromJson<String>(json['manifestJson']),
      packageDir: serializer.fromJson<String?>(json['packageDir']),
      packageSha256: serializer.fromJson<String>(json['packageSha256']),
      origin: serializer.fromJson<String>(json['origin']),
      repoUrl: serializer.fromJson<String?>(json['repoUrl']),
      repoSlug: serializer.fromJson<String?>(json['repoSlug']),
      originLabel: serializer.fromJson<String?>(json['originLabel']),
      consentedHostsJson: serializer.fromJson<String>(
        json['consentedHostsJson'],
      ),
      installedAt: serializer.fromJson<int>(json['installedAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      removedAt: serializer.fromJson<int?>(json['removedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'installId': serializer.toJson<String>(installId),
      'kind': serializer.toJson<String>(kind),
      'name': serializer.toJson<String>(name),
      'author': serializer.toJson<String?>(author),
      'version': serializer.toJson<int>(version),
      'apiVersion': serializer.toJson<int>(apiVersion),
      'manifestJson': serializer.toJson<String>(manifestJson),
      'packageDir': serializer.toJson<String?>(packageDir),
      'packageSha256': serializer.toJson<String>(packageSha256),
      'origin': serializer.toJson<String>(origin),
      'repoUrl': serializer.toJson<String?>(repoUrl),
      'repoSlug': serializer.toJson<String?>(repoSlug),
      'originLabel': serializer.toJson<String?>(originLabel),
      'consentedHostsJson': serializer.toJson<String>(consentedHostsJson),
      'installedAt': serializer.toJson<int>(installedAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'removedAt': serializer.toJson<int?>(removedAt),
    };
  }

  i1.PluginRow copyWith({
    String? installId,
    String? kind,
    String? name,
    i0.Value<String?> author = const i0.Value.absent(),
    int? version,
    int? apiVersion,
    String? manifestJson,
    i0.Value<String?> packageDir = const i0.Value.absent(),
    String? packageSha256,
    String? origin,
    i0.Value<String?> repoUrl = const i0.Value.absent(),
    i0.Value<String?> repoSlug = const i0.Value.absent(),
    i0.Value<String?> originLabel = const i0.Value.absent(),
    String? consentedHostsJson,
    int? installedAt,
    int? updatedAt,
    i0.Value<int?> removedAt = const i0.Value.absent(),
  }) => i1.PluginRow(
    installId: installId ?? this.installId,
    kind: kind ?? this.kind,
    name: name ?? this.name,
    author: author.present ? author.value : this.author,
    version: version ?? this.version,
    apiVersion: apiVersion ?? this.apiVersion,
    manifestJson: manifestJson ?? this.manifestJson,
    packageDir: packageDir.present ? packageDir.value : this.packageDir,
    packageSha256: packageSha256 ?? this.packageSha256,
    origin: origin ?? this.origin,
    repoUrl: repoUrl.present ? repoUrl.value : this.repoUrl,
    repoSlug: repoSlug.present ? repoSlug.value : this.repoSlug,
    originLabel: originLabel.present ? originLabel.value : this.originLabel,
    consentedHostsJson: consentedHostsJson ?? this.consentedHostsJson,
    installedAt: installedAt ?? this.installedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    removedAt: removedAt.present ? removedAt.value : this.removedAt,
  );
  PluginRow copyWithCompanion(i1.PluginsCompanion data) {
    return PluginRow(
      installId: data.installId.present ? data.installId.value : this.installId,
      kind: data.kind.present ? data.kind.value : this.kind,
      name: data.name.present ? data.name.value : this.name,
      author: data.author.present ? data.author.value : this.author,
      version: data.version.present ? data.version.value : this.version,
      apiVersion: data.apiVersion.present
          ? data.apiVersion.value
          : this.apiVersion,
      manifestJson: data.manifestJson.present
          ? data.manifestJson.value
          : this.manifestJson,
      packageDir: data.packageDir.present
          ? data.packageDir.value
          : this.packageDir,
      packageSha256: data.packageSha256.present
          ? data.packageSha256.value
          : this.packageSha256,
      origin: data.origin.present ? data.origin.value : this.origin,
      repoUrl: data.repoUrl.present ? data.repoUrl.value : this.repoUrl,
      repoSlug: data.repoSlug.present ? data.repoSlug.value : this.repoSlug,
      originLabel: data.originLabel.present
          ? data.originLabel.value
          : this.originLabel,
      consentedHostsJson: data.consentedHostsJson.present
          ? data.consentedHostsJson.value
          : this.consentedHostsJson,
      installedAt: data.installedAt.present
          ? data.installedAt.value
          : this.installedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      removedAt: data.removedAt.present ? data.removedAt.value : this.removedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PluginRow(')
          ..write('installId: $installId, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('author: $author, ')
          ..write('version: $version, ')
          ..write('apiVersion: $apiVersion, ')
          ..write('manifestJson: $manifestJson, ')
          ..write('packageDir: $packageDir, ')
          ..write('packageSha256: $packageSha256, ')
          ..write('origin: $origin, ')
          ..write('repoUrl: $repoUrl, ')
          ..write('repoSlug: $repoSlug, ')
          ..write('originLabel: $originLabel, ')
          ..write('consentedHostsJson: $consentedHostsJson, ')
          ..write('installedAt: $installedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('removedAt: $removedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    installId,
    kind,
    name,
    author,
    version,
    apiVersion,
    manifestJson,
    packageDir,
    packageSha256,
    origin,
    repoUrl,
    repoSlug,
    originLabel,
    consentedHostsJson,
    installedAt,
    updatedAt,
    removedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.PluginRow &&
          other.installId == this.installId &&
          other.kind == this.kind &&
          other.name == this.name &&
          other.author == this.author &&
          other.version == this.version &&
          other.apiVersion == this.apiVersion &&
          other.manifestJson == this.manifestJson &&
          other.packageDir == this.packageDir &&
          other.packageSha256 == this.packageSha256 &&
          other.origin == this.origin &&
          other.repoUrl == this.repoUrl &&
          other.repoSlug == this.repoSlug &&
          other.originLabel == this.originLabel &&
          other.consentedHostsJson == this.consentedHostsJson &&
          other.installedAt == this.installedAt &&
          other.updatedAt == this.updatedAt &&
          other.removedAt == this.removedAt);
}

class PluginsCompanion extends i0.UpdateCompanion<i1.PluginRow> {
  final i0.Value<String> installId;
  final i0.Value<String> kind;
  final i0.Value<String> name;
  final i0.Value<String?> author;
  final i0.Value<int> version;
  final i0.Value<int> apiVersion;
  final i0.Value<String> manifestJson;
  final i0.Value<String?> packageDir;
  final i0.Value<String> packageSha256;
  final i0.Value<String> origin;
  final i0.Value<String?> repoUrl;
  final i0.Value<String?> repoSlug;
  final i0.Value<String?> originLabel;
  final i0.Value<String> consentedHostsJson;
  final i0.Value<int> installedAt;
  final i0.Value<int> updatedAt;
  final i0.Value<int?> removedAt;
  final i0.Value<int> rowid;
  const PluginsCompanion({
    this.installId = const i0.Value.absent(),
    this.kind = const i0.Value.absent(),
    this.name = const i0.Value.absent(),
    this.author = const i0.Value.absent(),
    this.version = const i0.Value.absent(),
    this.apiVersion = const i0.Value.absent(),
    this.manifestJson = const i0.Value.absent(),
    this.packageDir = const i0.Value.absent(),
    this.packageSha256 = const i0.Value.absent(),
    this.origin = const i0.Value.absent(),
    this.repoUrl = const i0.Value.absent(),
    this.repoSlug = const i0.Value.absent(),
    this.originLabel = const i0.Value.absent(),
    this.consentedHostsJson = const i0.Value.absent(),
    this.installedAt = const i0.Value.absent(),
    this.updatedAt = const i0.Value.absent(),
    this.removedAt = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  PluginsCompanion.insert({
    required String installId,
    required String kind,
    required String name,
    this.author = const i0.Value.absent(),
    required int version,
    required int apiVersion,
    required String manifestJson,
    this.packageDir = const i0.Value.absent(),
    required String packageSha256,
    required String origin,
    this.repoUrl = const i0.Value.absent(),
    this.repoSlug = const i0.Value.absent(),
    this.originLabel = const i0.Value.absent(),
    required String consentedHostsJson,
    required int installedAt,
    required int updatedAt,
    this.removedAt = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  }) : installId = i0.Value(installId),
       kind = i0.Value(kind),
       name = i0.Value(name),
       version = i0.Value(version),
       apiVersion = i0.Value(apiVersion),
       manifestJson = i0.Value(manifestJson),
       packageSha256 = i0.Value(packageSha256),
       origin = i0.Value(origin),
       consentedHostsJson = i0.Value(consentedHostsJson),
       installedAt = i0.Value(installedAt),
       updatedAt = i0.Value(updatedAt);
  static i0.Insertable<i1.PluginRow> custom({
    i0.Expression<String>? installId,
    i0.Expression<String>? kind,
    i0.Expression<String>? name,
    i0.Expression<String>? author,
    i0.Expression<int>? version,
    i0.Expression<int>? apiVersion,
    i0.Expression<String>? manifestJson,
    i0.Expression<String>? packageDir,
    i0.Expression<String>? packageSha256,
    i0.Expression<String>? origin,
    i0.Expression<String>? repoUrl,
    i0.Expression<String>? repoSlug,
    i0.Expression<String>? originLabel,
    i0.Expression<String>? consentedHostsJson,
    i0.Expression<int>? installedAt,
    i0.Expression<int>? updatedAt,
    i0.Expression<int>? removedAt,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (installId != null) 'install_id': installId,
      if (kind != null) 'kind': kind,
      if (name != null) 'name': name,
      if (author != null) 'author': author,
      if (version != null) 'version': version,
      if (apiVersion != null) 'api_version': apiVersion,
      if (manifestJson != null) 'manifest_json': manifestJson,
      if (packageDir != null) 'package_dir': packageDir,
      if (packageSha256 != null) 'package_sha256': packageSha256,
      if (origin != null) 'origin': origin,
      if (repoUrl != null) 'repo_url': repoUrl,
      if (repoSlug != null) 'repo_slug': repoSlug,
      if (originLabel != null) 'origin_label': originLabel,
      if (consentedHostsJson != null)
        'consented_hosts_json': consentedHostsJson,
      if (installedAt != null) 'installed_at': installedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (removedAt != null) 'removed_at': removedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i1.PluginsCompanion copyWith({
    i0.Value<String>? installId,
    i0.Value<String>? kind,
    i0.Value<String>? name,
    i0.Value<String?>? author,
    i0.Value<int>? version,
    i0.Value<int>? apiVersion,
    i0.Value<String>? manifestJson,
    i0.Value<String?>? packageDir,
    i0.Value<String>? packageSha256,
    i0.Value<String>? origin,
    i0.Value<String?>? repoUrl,
    i0.Value<String?>? repoSlug,
    i0.Value<String?>? originLabel,
    i0.Value<String>? consentedHostsJson,
    i0.Value<int>? installedAt,
    i0.Value<int>? updatedAt,
    i0.Value<int?>? removedAt,
    i0.Value<int>? rowid,
  }) {
    return i1.PluginsCompanion(
      installId: installId ?? this.installId,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      author: author ?? this.author,
      version: version ?? this.version,
      apiVersion: apiVersion ?? this.apiVersion,
      manifestJson: manifestJson ?? this.manifestJson,
      packageDir: packageDir ?? this.packageDir,
      packageSha256: packageSha256 ?? this.packageSha256,
      origin: origin ?? this.origin,
      repoUrl: repoUrl ?? this.repoUrl,
      repoSlug: repoSlug ?? this.repoSlug,
      originLabel: originLabel ?? this.originLabel,
      consentedHostsJson: consentedHostsJson ?? this.consentedHostsJson,
      installedAt: installedAt ?? this.installedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      removedAt: removedAt ?? this.removedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (installId.present) {
      map['install_id'] = i0.Variable<String>(installId.value);
    }
    if (kind.present) {
      map['kind'] = i0.Variable<String>(kind.value);
    }
    if (name.present) {
      map['name'] = i0.Variable<String>(name.value);
    }
    if (author.present) {
      map['author'] = i0.Variable<String>(author.value);
    }
    if (version.present) {
      map['version'] = i0.Variable<int>(version.value);
    }
    if (apiVersion.present) {
      map['api_version'] = i0.Variable<int>(apiVersion.value);
    }
    if (manifestJson.present) {
      map['manifest_json'] = i0.Variable<String>(manifestJson.value);
    }
    if (packageDir.present) {
      map['package_dir'] = i0.Variable<String>(packageDir.value);
    }
    if (packageSha256.present) {
      map['package_sha256'] = i0.Variable<String>(packageSha256.value);
    }
    if (origin.present) {
      map['origin'] = i0.Variable<String>(origin.value);
    }
    if (repoUrl.present) {
      map['repo_url'] = i0.Variable<String>(repoUrl.value);
    }
    if (repoSlug.present) {
      map['repo_slug'] = i0.Variable<String>(repoSlug.value);
    }
    if (originLabel.present) {
      map['origin_label'] = i0.Variable<String>(originLabel.value);
    }
    if (consentedHostsJson.present) {
      map['consented_hosts_json'] = i0.Variable<String>(
        consentedHostsJson.value,
      );
    }
    if (installedAt.present) {
      map['installed_at'] = i0.Variable<int>(installedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = i0.Variable<int>(updatedAt.value);
    }
    if (removedAt.present) {
      map['removed_at'] = i0.Variable<int>(removedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PluginsCompanion(')
          ..write('installId: $installId, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('author: $author, ')
          ..write('version: $version, ')
          ..write('apiVersion: $apiVersion, ')
          ..write('manifestJson: $manifestJson, ')
          ..write('packageDir: $packageDir, ')
          ..write('packageSha256: $packageSha256, ')
          ..write('origin: $origin, ')
          ..write('repoUrl: $repoUrl, ')
          ..write('repoSlug: $repoSlug, ')
          ..write('originLabel: $originLabel, ')
          ..write('consentedHostsJson: $consentedHostsJson, ')
          ..write('installedAt: $installedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('removedAt: $removedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PluginDataTable extends i2.PluginData
    with i0.TableInfo<$PluginDataTable, i1.PluginDataRow> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PluginDataTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _installIdMeta = const i0.VerificationMeta(
    'installId',
  );
  @override
  late final i0.GeneratedColumn<String> installId = i0.GeneratedColumn<String>(
    'install_id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
      'REFERENCES plugins (install_id) ON DELETE RESTRICT',
    ),
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
  static const i0.VerificationMeta _customChoicesJsonMeta =
      const i0.VerificationMeta('customChoicesJson');
  @override
  late final i0.GeneratedColumn<String> customChoicesJson =
      i0.GeneratedColumn<String>(
        'custom_choices_json',
        aliasedName,
        false,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const i3.Constant('{}'),
      );
  @override
  List<i0.GeneratedColumn> get $columns => [
    installId,
    configJson,
    customChoicesJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plugin_data';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.PluginDataRow> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('install_id')) {
      context.handle(
        _installIdMeta,
        installId.isAcceptableOrUnknown(data['install_id']!, _installIdMeta),
      );
    } else if (isInserting) {
      context.missing(_installIdMeta);
    }
    if (data.containsKey('config_json')) {
      context.handle(
        _configJsonMeta,
        configJson.isAcceptableOrUnknown(data['config_json']!, _configJsonMeta),
      );
    }
    if (data.containsKey('custom_choices_json')) {
      context.handle(
        _customChoicesJsonMeta,
        customChoicesJson.isAcceptableOrUnknown(
          data['custom_choices_json']!,
          _customChoicesJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {installId};
  @override
  i1.PluginDataRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.PluginDataRow(
      installId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}install_id'],
      )!,
      configJson: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}config_json'],
      )!,
      customChoicesJson: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}custom_choices_json'],
      )!,
    );
  }

  @override
  $PluginDataTable createAlias(String alias) {
    return $PluginDataTable(attachedDatabase, alias);
  }
}

class PluginDataRow extends i0.DataClass
    implements i0.Insertable<i1.PluginDataRow> {
  final String installId;

  /// JSON object, field key to value (at most 64 KiB).
  final String configJson;

  /// JSON object, field key to the list of `{value, subtitle?}` choices the
  /// user added to a `custom` select (at most 64 KiB). Never read by a script.
  final String customChoicesJson;
  const PluginDataRow({
    required this.installId,
    required this.configJson,
    required this.customChoicesJson,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['install_id'] = i0.Variable<String>(installId);
    map['config_json'] = i0.Variable<String>(configJson);
    map['custom_choices_json'] = i0.Variable<String>(customChoicesJson);
    return map;
  }

  i1.PluginDataCompanion toCompanion(bool nullToAbsent) {
    return i1.PluginDataCompanion(
      installId: i0.Value(installId),
      configJson: i0.Value(configJson),
      customChoicesJson: i0.Value(customChoicesJson),
    );
  }

  factory PluginDataRow.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return PluginDataRow(
      installId: serializer.fromJson<String>(json['installId']),
      configJson: serializer.fromJson<String>(json['configJson']),
      customChoicesJson: serializer.fromJson<String>(json['customChoicesJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'installId': serializer.toJson<String>(installId),
      'configJson': serializer.toJson<String>(configJson),
      'customChoicesJson': serializer.toJson<String>(customChoicesJson),
    };
  }

  i1.PluginDataRow copyWith({
    String? installId,
    String? configJson,
    String? customChoicesJson,
  }) => i1.PluginDataRow(
    installId: installId ?? this.installId,
    configJson: configJson ?? this.configJson,
    customChoicesJson: customChoicesJson ?? this.customChoicesJson,
  );
  PluginDataRow copyWithCompanion(i1.PluginDataCompanion data) {
    return PluginDataRow(
      installId: data.installId.present ? data.installId.value : this.installId,
      configJson: data.configJson.present
          ? data.configJson.value
          : this.configJson,
      customChoicesJson: data.customChoicesJson.present
          ? data.customChoicesJson.value
          : this.customChoicesJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PluginDataRow(')
          ..write('installId: $installId, ')
          ..write('configJson: $configJson, ')
          ..write('customChoicesJson: $customChoicesJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(installId, configJson, customChoicesJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.PluginDataRow &&
          other.installId == this.installId &&
          other.configJson == this.configJson &&
          other.customChoicesJson == this.customChoicesJson);
}

class PluginDataCompanion extends i0.UpdateCompanion<i1.PluginDataRow> {
  final i0.Value<String> installId;
  final i0.Value<String> configJson;
  final i0.Value<String> customChoicesJson;
  final i0.Value<int> rowid;
  const PluginDataCompanion({
    this.installId = const i0.Value.absent(),
    this.configJson = const i0.Value.absent(),
    this.customChoicesJson = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  PluginDataCompanion.insert({
    required String installId,
    this.configJson = const i0.Value.absent(),
    this.customChoicesJson = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  }) : installId = i0.Value(installId);
  static i0.Insertable<i1.PluginDataRow> custom({
    i0.Expression<String>? installId,
    i0.Expression<String>? configJson,
    i0.Expression<String>? customChoicesJson,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (installId != null) 'install_id': installId,
      if (configJson != null) 'config_json': configJson,
      if (customChoicesJson != null) 'custom_choices_json': customChoicesJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i1.PluginDataCompanion copyWith({
    i0.Value<String>? installId,
    i0.Value<String>? configJson,
    i0.Value<String>? customChoicesJson,
    i0.Value<int>? rowid,
  }) {
    return i1.PluginDataCompanion(
      installId: installId ?? this.installId,
      configJson: configJson ?? this.configJson,
      customChoicesJson: customChoicesJson ?? this.customChoicesJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (installId.present) {
      map['install_id'] = i0.Variable<String>(installId.value);
    }
    if (configJson.present) {
      map['config_json'] = i0.Variable<String>(configJson.value);
    }
    if (customChoicesJson.present) {
      map['custom_choices_json'] = i0.Variable<String>(customChoicesJson.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PluginDataCompanion(')
          ..write('installId: $installId, ')
          ..write('configJson: $configJson, ')
          ..write('customChoicesJson: $customChoicesJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}
