// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:kanaru/src/database/tables/library_collection_tables.drift.dart'
    as i1;
import 'package:kanaru/src/database/tables/library_collection_tables.dart'
    as i2;
import 'package:drift/src/runtime/query_builder/query_builder.dart' as i3;
import 'package:kanaru/src/database/tables/library_source_tables.drift.dart'
    as i4;
import 'package:drift/internal/modular.dart' as i5;
import 'package:kanaru/src/database/tables/library_track_tables.drift.dart'
    as i6;

typedef $$PlaylistsTableCreateCompanionBuilder =
    i1.PlaylistsCompanion Function({
      i0.Value<int> id,
      required String uid,
      required String name,
      i0.Value<String?> nameKey,
      i0.Value<String?> kind,
      i0.Value<String> description,
      i0.Value<int?> originSourceId,
      i0.Value<String?> originLocator,
      i0.Value<String?> originRevision,
      required int createdAt,
      required int updatedAt,
      i0.Value<int?> deletedAt,
    });
typedef $$PlaylistsTableUpdateCompanionBuilder =
    i1.PlaylistsCompanion Function({
      i0.Value<int> id,
      i0.Value<String> uid,
      i0.Value<String> name,
      i0.Value<String?> nameKey,
      i0.Value<String?> kind,
      i0.Value<String> description,
      i0.Value<int?> originSourceId,
      i0.Value<String?> originLocator,
      i0.Value<String?> originRevision,
      i0.Value<int> createdAt,
      i0.Value<int> updatedAt,
      i0.Value<int?> deletedAt,
    });

final class $$PlaylistsTableReferences
    extends
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$PlaylistsTable,
          i1.Playlist
        > {
  $$PlaylistsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static i4.$SourcesTable _originSourceIdTable(i0.GeneratedDatabase db) =>
      i5.ReadDatabaseContainer(db)
          .resultSet<i4.$SourcesTable>('sources')
          .createAlias('playlists__origin_source_id__sources__id');

  i4.$$SourcesTableProcessedTableManager? get originSourceId {
    final $_column = $_itemColumn<int>('origin_source_id');
    if ($_column == null) return null;
    final manager = i4
        .$$SourcesTableTableManager(
          $_db,
          i5.ReadDatabaseContainer($_db).resultSet<i4.$SourcesTable>('sources'),
        )
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_originSourceIdTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static i0.MultiTypedResultKey<
    i1.$PlaylistEntriesTable,
    List<i1.PlaylistEntry>
  >
  _playlistEntriesRefsTable(i0.GeneratedDatabase db) =>
      i0.MultiTypedResultKey.fromTable(
        i5.ReadDatabaseContainer(db)
            .resultSet<i1.$PlaylistEntriesTable>('playlist_entries'),
        aliasName: 'playlists__id__playlist_entries__playlist_id',
      );

  i1.$$PlaylistEntriesTableProcessedTableManager get playlistEntriesRefs {
    final manager = i1
        .$$PlaylistEntriesTableTableManager(
          $_db,
          i5.ReadDatabaseContainer($_db)
              .resultSet<i1.$PlaylistEntriesTable>('playlist_entries'),
        )
        .filter((f) => f.playlistId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _playlistEntriesRefsTable($_db),
    );
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlaylistsTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$PlaylistsTable> {
  $$PlaylistsTableFilterComposer({
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

  i0.ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get nameKey => $composableBuilder(
    column: $table.nameKey,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get originLocator => $composableBuilder(
    column: $table.originLocator,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get originRevision => $composableBuilder(
    column: $table.originRevision,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
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

  i4.$$SourcesTableFilterComposer get originSourceId {
    final i4.$$SourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.originSourceId,
      referencedTable: i5.ReadDatabaseContainer($db)
          .resultSet<i4.$SourcesTable>('sources'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i4.$$SourcesTableFilterComposer(
            $db: $db,
            $table: i5.ReadDatabaseContainer($db)
                .resultSet<i4.$SourcesTable>('sources'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i0.Expression<bool> playlistEntriesRefs(
    i0.Expression<bool> Function(i1.$$PlaylistEntriesTableFilterComposer f) f,
  ) {
    final i1.$$PlaylistEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i5.ReadDatabaseContainer($db)
          .resultSet<i1.$PlaylistEntriesTable>('playlist_entries'),
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i1.$$PlaylistEntriesTableFilterComposer(
            $db: $db,
            $table: i5.ReadDatabaseContainer($db)
                .resultSet<i1.$PlaylistEntriesTable>('playlist_entries'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlaylistsTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$PlaylistsTable> {
  $$PlaylistsTableOrderingComposer({
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

  i0.ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get nameKey => $composableBuilder(
    column: $table.nameKey,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get originLocator => $composableBuilder(
    column: $table.originLocator,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get originRevision => $composableBuilder(
    column: $table.originRevision,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
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

  i4.$$SourcesTableOrderingComposer get originSourceId {
    final i4.$$SourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.originSourceId,
      referencedTable: i5.ReadDatabaseContainer($db)
          .resultSet<i4.$SourcesTable>('sources'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i4.$$SourcesTableOrderingComposer(
            $db: $db,
            $table: i5.ReadDatabaseContainer($db)
                .resultSet<i4.$SourcesTable>('sources'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistsTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$PlaylistsTable> {
  $$PlaylistsTableAnnotationComposer({
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

  i0.GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  i0.GeneratedColumn<String> get nameKey =>
      $composableBuilder(column: $table.nameKey, builder: (column) => column);

  i0.GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  i0.GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get originLocator => $composableBuilder(
    column: $table.originLocator,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get originRevision => $composableBuilder(
    column: $table.originRevision,
    builder: (column) => column,
  );

  i0.GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  i0.GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  i0.GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  i4.$$SourcesTableAnnotationComposer get originSourceId {
    final i4.$$SourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.originSourceId,
      referencedTable: i5.ReadDatabaseContainer($db)
          .resultSet<i4.$SourcesTable>('sources'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i4.$$SourcesTableAnnotationComposer(
            $db: $db,
            $table: i5.ReadDatabaseContainer($db)
                .resultSet<i4.$SourcesTable>('sources'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i0.Expression<T> playlistEntriesRefs<T extends Object>(
    i0.Expression<T> Function(i1.$$PlaylistEntriesTableAnnotationComposer a) f,
  ) {
    final i1.$$PlaylistEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: i5.ReadDatabaseContainer($db)
              .resultSet<i1.$PlaylistEntriesTable>('playlist_entries'),
          getReferencedColumn: (t) => t.playlistId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => i1.$$PlaylistEntriesTableAnnotationComposer(
                $db: $db,
                $table: i5.ReadDatabaseContainer($db)
                    .resultSet<i1.$PlaylistEntriesTable>('playlist_entries'),
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$PlaylistsTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$PlaylistsTable,
          i1.Playlist,
          i1.$$PlaylistsTableFilterComposer,
          i1.$$PlaylistsTableOrderingComposer,
          i1.$$PlaylistsTableAnnotationComposer,
          $$PlaylistsTableCreateCompanionBuilder,
          $$PlaylistsTableUpdateCompanionBuilder,
          (i1.Playlist, i1.$$PlaylistsTableReferences),
          i1.Playlist,
          i0.PrefetchHooks Function({
            bool originSourceId,
            bool playlistEntriesRefs,
          })
        > {
  $$PlaylistsTableTableManager(
    i0.GeneratedDatabase db,
    i1.$PlaylistsTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$PlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$PlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$PlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                i0.Value<String> uid = const i0.Value.absent(),
                i0.Value<String> name = const i0.Value.absent(),
                i0.Value<String?> nameKey = const i0.Value.absent(),
                i0.Value<String?> kind = const i0.Value.absent(),
                i0.Value<String> description = const i0.Value.absent(),
                i0.Value<int?> originSourceId = const i0.Value.absent(),
                i0.Value<String?> originLocator = const i0.Value.absent(),
                i0.Value<String?> originRevision = const i0.Value.absent(),
                i0.Value<int> createdAt = const i0.Value.absent(),
                i0.Value<int> updatedAt = const i0.Value.absent(),
                i0.Value<int?> deletedAt = const i0.Value.absent(),
              }) => i1.PlaylistsCompanion(
                id: id,
                uid: uid,
                name: name,
                nameKey: nameKey,
                kind: kind,
                description: description,
                originSourceId: originSourceId,
                originLocator: originLocator,
                originRevision: originRevision,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                required String uid,
                required String name,
                i0.Value<String?> nameKey = const i0.Value.absent(),
                i0.Value<String?> kind = const i0.Value.absent(),
                i0.Value<String> description = const i0.Value.absent(),
                i0.Value<int?> originSourceId = const i0.Value.absent(),
                i0.Value<String?> originLocator = const i0.Value.absent(),
                i0.Value<String?> originRevision = const i0.Value.absent(),
                required int createdAt,
                required int updatedAt,
                i0.Value<int?> deletedAt = const i0.Value.absent(),
              }) => i1.PlaylistsCompanion.insert(
                id: id,
                uid: uid,
                name: name,
                nameKey: nameKey,
                kind: kind,
                description: description,
                originSourceId: originSourceId,
                originLocator: originLocator,
                originRevision: originRevision,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<i1.$PlaylistsTable, i1.Playlist>(table),
                  i1.$$PlaylistsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({originSourceId = false, playlistEntriesRefs = false}) {
                return i0.PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (playlistEntriesRefs)
                      i5.ReadDatabaseContainer(
                        db,
                      ).resultSet<i1.$PlaylistEntriesTable>('playlist_entries'),
                  ],
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
                        if (originSourceId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.originSourceId,
                            referencedTable: i1.$$PlaylistsTableReferences
                                ._originSourceIdTable(db),
                            referencedColumn: i1.$$PlaylistsTableReferences
                                ._originSourceIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (playlistEntriesRefs)
                        await i0.$_getPrefetchedDataByColumns<
                          i1.Playlist,
                          i1.$PlaylistsTable,
                          i1.PlaylistEntry,
                          i1.$PlaylistEntriesTable
                        >(
                          currentTable: table,
                          referencedTable: i1.$$PlaylistsTableReferences
                              ._playlistEntriesRefsTable(db),
                          managerFromTypedResult: (p0) => i1
                              .$$PlaylistsTableReferences(db, table, p0)
                              .playlistEntriesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'playlist_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PlaylistsTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$PlaylistsTable,
      i1.Playlist,
      i1.$$PlaylistsTableFilterComposer,
      i1.$$PlaylistsTableOrderingComposer,
      i1.$$PlaylistsTableAnnotationComposer,
      $$PlaylistsTableCreateCompanionBuilder,
      $$PlaylistsTableUpdateCompanionBuilder,
      (i1.Playlist, i1.$$PlaylistsTableReferences),
      i1.Playlist,
      i0.PrefetchHooks Function({bool originSourceId, bool playlistEntriesRefs})
    >;
typedef $$PlaylistEntriesTableCreateCompanionBuilder =
    i1.PlaylistEntriesCompanion Function({
      i0.Value<int> id,
      required String uid,
      required int playlistId,
      required int trackId,
      required String sortKey,
      required int addedAt,
      required int updatedAt,
      i0.Value<int?> deletedAt,
    });
typedef $$PlaylistEntriesTableUpdateCompanionBuilder =
    i1.PlaylistEntriesCompanion Function({
      i0.Value<int> id,
      i0.Value<String> uid,
      i0.Value<int> playlistId,
      i0.Value<int> trackId,
      i0.Value<String> sortKey,
      i0.Value<int> addedAt,
      i0.Value<int> updatedAt,
      i0.Value<int?> deletedAt,
    });

final class $$PlaylistEntriesTableReferences
    extends
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$PlaylistEntriesTable,
          i1.PlaylistEntry
        > {
  $$PlaylistEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static i1.$PlaylistsTable _playlistIdTable(i0.GeneratedDatabase db) =>
      i5.ReadDatabaseContainer(db)
          .resultSet<i1.$PlaylistsTable>('playlists')
          .createAlias('playlist_entries__playlist_id__playlists__id');

  i1.$$PlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<int>('playlist_id')!;

    final manager = i1
        .$$PlaylistsTableTableManager(
          $_db,
          i5.ReadDatabaseContainer($_db)
              .resultSet<i1.$PlaylistsTable>('playlists'),
        )
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static i6.$TracksTable _trackIdTable(i0.GeneratedDatabase db) =>
      i5.ReadDatabaseContainer(db)
          .resultSet<i6.$TracksTable>('tracks')
          .createAlias('playlist_entries__track_id__tracks__id');

  i6.$$TracksTableProcessedTableManager get trackId {
    final $_column = $_itemColumn<int>('track_id')!;

    final manager = i6
        .$$TracksTableTableManager(
          $_db,
          i5.ReadDatabaseContainer($_db).resultSet<i6.$TracksTable>('tracks'),
        )
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlaylistEntriesTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$PlaylistEntriesTable> {
  $$PlaylistEntriesTableFilterComposer({
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

  i0.ColumnFilters<String> get sortKey => $composableBuilder(
    column: $table.sortKey,
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

  i1.$$PlaylistsTableFilterComposer get playlistId {
    final i1.$$PlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: i5.ReadDatabaseContainer($db)
          .resultSet<i1.$PlaylistsTable>('playlists'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i1.$$PlaylistsTableFilterComposer(
            $db: $db,
            $table: i5.ReadDatabaseContainer($db)
                .resultSet<i1.$PlaylistsTable>('playlists'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i6.$$TracksTableFilterComposer get trackId {
    final i6.$$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: i5.ReadDatabaseContainer($db)
          .resultSet<i6.$TracksTable>('tracks'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i6.$$TracksTableFilterComposer(
            $db: $db,
            $table: i5.ReadDatabaseContainer($db)
                .resultSet<i6.$TracksTable>('tracks'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistEntriesTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$PlaylistEntriesTable> {
  $$PlaylistEntriesTableOrderingComposer({
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

  i0.ColumnOrderings<String> get sortKey => $composableBuilder(
    column: $table.sortKey,
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

  i1.$$PlaylistsTableOrderingComposer get playlistId {
    final i1.$$PlaylistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: i5.ReadDatabaseContainer($db)
          .resultSet<i1.$PlaylistsTable>('playlists'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i1.$$PlaylistsTableOrderingComposer(
            $db: $db,
            $table: i5.ReadDatabaseContainer($db)
                .resultSet<i1.$PlaylistsTable>('playlists'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i6.$$TracksTableOrderingComposer get trackId {
    final i6.$$TracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: i5.ReadDatabaseContainer($db)
          .resultSet<i6.$TracksTable>('tracks'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i6.$$TracksTableOrderingComposer(
            $db: $db,
            $table: i5.ReadDatabaseContainer($db)
                .resultSet<i6.$TracksTable>('tracks'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistEntriesTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$PlaylistEntriesTable> {
  $$PlaylistEntriesTableAnnotationComposer({
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

  i0.GeneratedColumn<String> get sortKey =>
      $composableBuilder(column: $table.sortKey, builder: (column) => column);

  i0.GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  i0.GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  i0.GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  i1.$$PlaylistsTableAnnotationComposer get playlistId {
    final i1.$$PlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: i5.ReadDatabaseContainer($db)
          .resultSet<i1.$PlaylistsTable>('playlists'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i1.$$PlaylistsTableAnnotationComposer(
            $db: $db,
            $table: i5.ReadDatabaseContainer($db)
                .resultSet<i1.$PlaylistsTable>('playlists'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i6.$$TracksTableAnnotationComposer get trackId {
    final i6.$$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: i5.ReadDatabaseContainer($db)
          .resultSet<i6.$TracksTable>('tracks'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i6.$$TracksTableAnnotationComposer(
            $db: $db,
            $table: i5.ReadDatabaseContainer($db)
                .resultSet<i6.$TracksTable>('tracks'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistEntriesTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$PlaylistEntriesTable,
          i1.PlaylistEntry,
          i1.$$PlaylistEntriesTableFilterComposer,
          i1.$$PlaylistEntriesTableOrderingComposer,
          i1.$$PlaylistEntriesTableAnnotationComposer,
          $$PlaylistEntriesTableCreateCompanionBuilder,
          $$PlaylistEntriesTableUpdateCompanionBuilder,
          (i1.PlaylistEntry, i1.$$PlaylistEntriesTableReferences),
          i1.PlaylistEntry,
          i0.PrefetchHooks Function({bool playlistId, bool trackId})
        > {
  $$PlaylistEntriesTableTableManager(
    i0.GeneratedDatabase db,
    i1.$PlaylistEntriesTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$PlaylistEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$PlaylistEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => i1
              .$$PlaylistEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                i0.Value<String> uid = const i0.Value.absent(),
                i0.Value<int> playlistId = const i0.Value.absent(),
                i0.Value<int> trackId = const i0.Value.absent(),
                i0.Value<String> sortKey = const i0.Value.absent(),
                i0.Value<int> addedAt = const i0.Value.absent(),
                i0.Value<int> updatedAt = const i0.Value.absent(),
                i0.Value<int?> deletedAt = const i0.Value.absent(),
              }) => i1.PlaylistEntriesCompanion(
                id: id,
                uid: uid,
                playlistId: playlistId,
                trackId: trackId,
                sortKey: sortKey,
                addedAt: addedAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                required String uid,
                required int playlistId,
                required int trackId,
                required String sortKey,
                required int addedAt,
                required int updatedAt,
                i0.Value<int?> deletedAt = const i0.Value.absent(),
              }) => i1.PlaylistEntriesCompanion.insert(
                id: id,
                uid: uid,
                playlistId: playlistId,
                trackId: trackId,
                sortKey: sortKey,
                addedAt: addedAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<i1.$PlaylistEntriesTable, i1.PlaylistEntry>(
                    table,
                  ),
                  i1.$$PlaylistEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistId = false, trackId = false}) {
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
                    if (playlistId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.playlistId,
                        referencedTable: i1.$$PlaylistEntriesTableReferences
                            ._playlistIdTable(db),
                        referencedColumn: i1.$$PlaylistEntriesTableReferences
                            ._playlistIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (trackId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.trackId,
                        referencedTable: i1.$$PlaylistEntriesTableReferences
                            ._trackIdTable(db),
                        referencedColumn: i1.$$PlaylistEntriesTableReferences
                            ._trackIdTable(db)
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

typedef $$PlaylistEntriesTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$PlaylistEntriesTable,
      i1.PlaylistEntry,
      i1.$$PlaylistEntriesTableFilterComposer,
      i1.$$PlaylistEntriesTableOrderingComposer,
      i1.$$PlaylistEntriesTableAnnotationComposer,
      $$PlaylistEntriesTableCreateCompanionBuilder,
      $$PlaylistEntriesTableUpdateCompanionBuilder,
      (i1.PlaylistEntry, i1.$$PlaylistEntriesTableReferences),
      i1.PlaylistEntry,
      i0.PrefetchHooks Function({bool playlistId, bool trackId})
    >;
typedef $$SavedItemsTableCreateCompanionBuilder =
    i1.SavedItemsCompanion Function({
      i0.Value<int> id,
      required String uid,
      required String kind,
      required int sourceId,
      required String remoteId,
      required String snapshotJson,
      required int savedAt,
      required int updatedAt,
      i0.Value<int?> deletedAt,
    });
typedef $$SavedItemsTableUpdateCompanionBuilder =
    i1.SavedItemsCompanion Function({
      i0.Value<int> id,
      i0.Value<String> uid,
      i0.Value<String> kind,
      i0.Value<int> sourceId,
      i0.Value<String> remoteId,
      i0.Value<String> snapshotJson,
      i0.Value<int> savedAt,
      i0.Value<int> updatedAt,
      i0.Value<int?> deletedAt,
    });

final class $$SavedItemsTableReferences
    extends
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$SavedItemsTable,
          i1.SavedItem
        > {
  $$SavedItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static i4.$SourcesTable _sourceIdTable(i0.GeneratedDatabase db) =>
      i5.ReadDatabaseContainer(db)
          .resultSet<i4.$SourcesTable>('sources')
          .createAlias('saved_items__source_id__sources__id');

  i4.$$SourcesTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<int>('source_id')!;

    final manager = i4
        .$$SourcesTableTableManager(
          $_db,
          i5.ReadDatabaseContainer($_db).resultSet<i4.$SourcesTable>('sources'),
        )
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SavedItemsTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$SavedItemsTable> {
  $$SavedItemsTableFilterComposer({
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

  i0.ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get snapshotJson => $composableBuilder(
    column: $table.snapshotJson,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get savedAt => $composableBuilder(
    column: $table.savedAt,
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

  i4.$$SourcesTableFilterComposer get sourceId {
    final i4.$$SourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: i5.ReadDatabaseContainer($db)
          .resultSet<i4.$SourcesTable>('sources'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i4.$$SourcesTableFilterComposer(
            $db: $db,
            $table: i5.ReadDatabaseContainer($db)
                .resultSet<i4.$SourcesTable>('sources'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SavedItemsTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$SavedItemsTable> {
  $$SavedItemsTableOrderingComposer({
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

  i0.ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get snapshotJson => $composableBuilder(
    column: $table.snapshotJson,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get savedAt => $composableBuilder(
    column: $table.savedAt,
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

  i4.$$SourcesTableOrderingComposer get sourceId {
    final i4.$$SourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: i5.ReadDatabaseContainer($db)
          .resultSet<i4.$SourcesTable>('sources'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i4.$$SourcesTableOrderingComposer(
            $db: $db,
            $table: i5.ReadDatabaseContainer($db)
                .resultSet<i4.$SourcesTable>('sources'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SavedItemsTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$SavedItemsTable> {
  $$SavedItemsTableAnnotationComposer({
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

  i0.GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  i0.GeneratedColumn<String> get snapshotJson => $composableBuilder(
    column: $table.snapshotJson,
    builder: (column) => column,
  );

  i0.GeneratedColumn<int> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);

  i0.GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  i0.GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  i4.$$SourcesTableAnnotationComposer get sourceId {
    final i4.$$SourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: i5.ReadDatabaseContainer($db)
          .resultSet<i4.$SourcesTable>('sources'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i4.$$SourcesTableAnnotationComposer(
            $db: $db,
            $table: i5.ReadDatabaseContainer($db)
                .resultSet<i4.$SourcesTable>('sources'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SavedItemsTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$SavedItemsTable,
          i1.SavedItem,
          i1.$$SavedItemsTableFilterComposer,
          i1.$$SavedItemsTableOrderingComposer,
          i1.$$SavedItemsTableAnnotationComposer,
          $$SavedItemsTableCreateCompanionBuilder,
          $$SavedItemsTableUpdateCompanionBuilder,
          (i1.SavedItem, i1.$$SavedItemsTableReferences),
          i1.SavedItem,
          i0.PrefetchHooks Function({bool sourceId})
        > {
  $$SavedItemsTableTableManager(
    i0.GeneratedDatabase db,
    i1.$SavedItemsTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$SavedItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$SavedItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$SavedItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                i0.Value<String> uid = const i0.Value.absent(),
                i0.Value<String> kind = const i0.Value.absent(),
                i0.Value<int> sourceId = const i0.Value.absent(),
                i0.Value<String> remoteId = const i0.Value.absent(),
                i0.Value<String> snapshotJson = const i0.Value.absent(),
                i0.Value<int> savedAt = const i0.Value.absent(),
                i0.Value<int> updatedAt = const i0.Value.absent(),
                i0.Value<int?> deletedAt = const i0.Value.absent(),
              }) => i1.SavedItemsCompanion(
                id: id,
                uid: uid,
                kind: kind,
                sourceId: sourceId,
                remoteId: remoteId,
                snapshotJson: snapshotJson,
                savedAt: savedAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                required String uid,
                required String kind,
                required int sourceId,
                required String remoteId,
                required String snapshotJson,
                required int savedAt,
                required int updatedAt,
                i0.Value<int?> deletedAt = const i0.Value.absent(),
              }) => i1.SavedItemsCompanion.insert(
                id: id,
                uid: uid,
                kind: kind,
                sourceId: sourceId,
                remoteId: remoteId,
                snapshotJson: snapshotJson,
                savedAt: savedAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<i1.$SavedItemsTable, i1.SavedItem>(table),
                  i1.$$SavedItemsTableReferences(db, table, e),
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
                        referencedTable: i1.$$SavedItemsTableReferences
                            ._sourceIdTable(db),
                        referencedColumn: i1.$$SavedItemsTableReferences
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

typedef $$SavedItemsTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$SavedItemsTable,
      i1.SavedItem,
      i1.$$SavedItemsTableFilterComposer,
      i1.$$SavedItemsTableOrderingComposer,
      i1.$$SavedItemsTableAnnotationComposer,
      $$SavedItemsTableCreateCompanionBuilder,
      $$SavedItemsTableUpdateCompanionBuilder,
      (i1.SavedItem, i1.$$SavedItemsTableReferences),
      i1.SavedItem,
      i0.PrefetchHooks Function({bool sourceId})
    >;
i0.Index get playlistsFavoritesUnique => i0.Index(
  'playlists_favorites_unique',
  'CREATE UNIQUE INDEX playlists_favorites_unique ON playlists (kind) WHERE kind = \'favorites\' AND deleted_at IS NULL',
);

class $PlaylistsTable extends i2.Playlists
    with i0.TableInfo<$PlaylistsTable, i1.Playlist> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistsTable(this.attachedDatabase, [this._alias]);
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
  static const i0.VerificationMeta _nameKeyMeta = const i0.VerificationMeta(
    'nameKey',
  );
  @override
  late final i0.GeneratedColumn<String> nameKey = i0.GeneratedColumn<String>(
    'name_key',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _kindMeta = const i0.VerificationMeta(
    'kind',
  );
  @override
  late final i0.GeneratedColumn<String> kind = i0.GeneratedColumn<String>(
    'kind',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _descriptionMeta = const i0.VerificationMeta(
    'description',
  );
  @override
  late final i0.GeneratedColumn<String> description =
      i0.GeneratedColumn<String>(
        'description',
        aliasedName,
        false,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const i3.Constant(''),
      );
  static const i0.VerificationMeta _originSourceIdMeta =
      const i0.VerificationMeta('originSourceId');
  @override
  late final i0.GeneratedColumn<int> originSourceId = i0.GeneratedColumn<int>(
    'origin_source_id',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
      'REFERENCES sources (id) ON DELETE RESTRICT',
    ),
  );
  static const i0.VerificationMeta _originLocatorMeta =
      const i0.VerificationMeta('originLocator');
  @override
  late final i0.GeneratedColumn<String> originLocator =
      i0.GeneratedColumn<String>(
        'origin_locator',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const i0.VerificationMeta _originRevisionMeta =
      const i0.VerificationMeta('originRevision');
  @override
  late final i0.GeneratedColumn<String> originRevision =
      i0.GeneratedColumn<String>(
        'origin_revision',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const i0.VerificationMeta _createdAtMeta = const i0.VerificationMeta(
    'createdAt',
  );
  @override
  late final i0.GeneratedColumn<int> createdAt = i0.GeneratedColumn<int>(
    'created_at',
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
    name,
    nameKey,
    kind,
    description,
    originSourceId,
    originLocator,
    originRevision,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlists';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.Playlist> instance, {
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
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('name_key')) {
      context.handle(
        _nameKeyMeta,
        nameKey.isAcceptableOrUnknown(data['name_key']!, _nameKeyMeta),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('origin_source_id')) {
      context.handle(
        _originSourceIdMeta,
        originSourceId.isAcceptableOrUnknown(
          data['origin_source_id']!,
          _originSourceIdMeta,
        ),
      );
    }
    if (data.containsKey('origin_locator')) {
      context.handle(
        _originLocatorMeta,
        originLocator.isAcceptableOrUnknown(
          data['origin_locator']!,
          _originLocatorMeta,
        ),
      );
    }
    if (data.containsKey('origin_revision')) {
      context.handle(
        _originRevisionMeta,
        originRevision.isAcceptableOrUnknown(
          data['origin_revision']!,
          _originRevisionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
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
  i1.Playlist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.Playlist(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      name: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      nameKey: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}name_key'],
      ),
      kind: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}kind'],
      ),
      description: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      originSourceId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}origin_source_id'],
      ),
      originLocator: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}origin_locator'],
      ),
      originRevision: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}origin_revision'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}created_at'],
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
  $PlaylistsTable createAlias(String alias) {
    return $PlaylistsTable(attachedDatabase, alias);
  }
}

class Playlist extends i0.DataClass implements i0.Insertable<i1.Playlist> {
  final int id;

  /// `favorites` for Favorites, a ULID otherwise.
  final String uid;
  final String name;

  /// Mood playlists: lower case, collapsed spaces, NFC, accents kept. Mood
  /// rows must always set it: NULLs are distinct, so a NULL would bypass
  /// `playlists_mood_name_unique`.
  final String? nameKey;

  /// A [PlaylistKind] value; null = normal or imported.
  final String? kind;
  final String description;

  /// Source of an imported playlist.
  final int? originSourceId;
  final String? originLocator;

  /// Revision at the last import.
  final String? originRevision;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  const Playlist({
    required this.id,
    required this.uid,
    required this.name,
    this.nameKey,
    this.kind,
    required this.description,
    this.originSourceId,
    this.originLocator,
    this.originRevision,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id);
    map['uid'] = i0.Variable<String>(uid);
    map['name'] = i0.Variable<String>(name);
    if (!nullToAbsent || nameKey != null) {
      map['name_key'] = i0.Variable<String>(nameKey);
    }
    if (!nullToAbsent || kind != null) {
      map['kind'] = i0.Variable<String>(kind);
    }
    map['description'] = i0.Variable<String>(description);
    if (!nullToAbsent || originSourceId != null) {
      map['origin_source_id'] = i0.Variable<int>(originSourceId);
    }
    if (!nullToAbsent || originLocator != null) {
      map['origin_locator'] = i0.Variable<String>(originLocator);
    }
    if (!nullToAbsent || originRevision != null) {
      map['origin_revision'] = i0.Variable<String>(originRevision);
    }
    map['created_at'] = i0.Variable<int>(createdAt);
    map['updated_at'] = i0.Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = i0.Variable<int>(deletedAt);
    }
    return map;
  }

  i1.PlaylistsCompanion toCompanion(bool nullToAbsent) {
    return i1.PlaylistsCompanion(
      id: i0.Value(id),
      uid: i0.Value(uid),
      name: i0.Value(name),
      nameKey: nameKey == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(nameKey),
      kind: kind == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(kind),
      description: i0.Value(description),
      originSourceId: originSourceId == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(originSourceId),
      originLocator: originLocator == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(originLocator),
      originRevision: originRevision == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(originRevision),
      createdAt: i0.Value(createdAt),
      updatedAt: i0.Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(deletedAt),
    );
  }

  factory Playlist.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return Playlist(
      id: serializer.fromJson<int>(json['id']),
      uid: serializer.fromJson<String>(json['uid']),
      name: serializer.fromJson<String>(json['name']),
      nameKey: serializer.fromJson<String?>(json['nameKey']),
      kind: serializer.fromJson<String?>(json['kind']),
      description: serializer.fromJson<String>(json['description']),
      originSourceId: serializer.fromJson<int?>(json['originSourceId']),
      originLocator: serializer.fromJson<String?>(json['originLocator']),
      originRevision: serializer.fromJson<String?>(json['originRevision']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
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
      'name': serializer.toJson<String>(name),
      'nameKey': serializer.toJson<String?>(nameKey),
      'kind': serializer.toJson<String?>(kind),
      'description': serializer.toJson<String>(description),
      'originSourceId': serializer.toJson<int?>(originSourceId),
      'originLocator': serializer.toJson<String?>(originLocator),
      'originRevision': serializer.toJson<String?>(originRevision),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  i1.Playlist copyWith({
    int? id,
    String? uid,
    String? name,
    i0.Value<String?> nameKey = const i0.Value.absent(),
    i0.Value<String?> kind = const i0.Value.absent(),
    String? description,
    i0.Value<int?> originSourceId = const i0.Value.absent(),
    i0.Value<String?> originLocator = const i0.Value.absent(),
    i0.Value<String?> originRevision = const i0.Value.absent(),
    int? createdAt,
    int? updatedAt,
    i0.Value<int?> deletedAt = const i0.Value.absent(),
  }) => i1.Playlist(
    id: id ?? this.id,
    uid: uid ?? this.uid,
    name: name ?? this.name,
    nameKey: nameKey.present ? nameKey.value : this.nameKey,
    kind: kind.present ? kind.value : this.kind,
    description: description ?? this.description,
    originSourceId: originSourceId.present
        ? originSourceId.value
        : this.originSourceId,
    originLocator: originLocator.present
        ? originLocator.value
        : this.originLocator,
    originRevision: originRevision.present
        ? originRevision.value
        : this.originRevision,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Playlist copyWithCompanion(i1.PlaylistsCompanion data) {
    return Playlist(
      id: data.id.present ? data.id.value : this.id,
      uid: data.uid.present ? data.uid.value : this.uid,
      name: data.name.present ? data.name.value : this.name,
      nameKey: data.nameKey.present ? data.nameKey.value : this.nameKey,
      kind: data.kind.present ? data.kind.value : this.kind,
      description: data.description.present
          ? data.description.value
          : this.description,
      originSourceId: data.originSourceId.present
          ? data.originSourceId.value
          : this.originSourceId,
      originLocator: data.originLocator.present
          ? data.originLocator.value
          : this.originLocator,
      originRevision: data.originRevision.present
          ? data.originRevision.value
          : this.originRevision,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Playlist(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('nameKey: $nameKey, ')
          ..write('kind: $kind, ')
          ..write('description: $description, ')
          ..write('originSourceId: $originSourceId, ')
          ..write('originLocator: $originLocator, ')
          ..write('originRevision: $originRevision, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uid,
    name,
    nameKey,
    kind,
    description,
    originSourceId,
    originLocator,
    originRevision,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.Playlist &&
          other.id == this.id &&
          other.uid == this.uid &&
          other.name == this.name &&
          other.nameKey == this.nameKey &&
          other.kind == this.kind &&
          other.description == this.description &&
          other.originSourceId == this.originSourceId &&
          other.originLocator == this.originLocator &&
          other.originRevision == this.originRevision &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class PlaylistsCompanion extends i0.UpdateCompanion<i1.Playlist> {
  final i0.Value<int> id;
  final i0.Value<String> uid;
  final i0.Value<String> name;
  final i0.Value<String?> nameKey;
  final i0.Value<String?> kind;
  final i0.Value<String> description;
  final i0.Value<int?> originSourceId;
  final i0.Value<String?> originLocator;
  final i0.Value<String?> originRevision;
  final i0.Value<int> createdAt;
  final i0.Value<int> updatedAt;
  final i0.Value<int?> deletedAt;
  const PlaylistsCompanion({
    this.id = const i0.Value.absent(),
    this.uid = const i0.Value.absent(),
    this.name = const i0.Value.absent(),
    this.nameKey = const i0.Value.absent(),
    this.kind = const i0.Value.absent(),
    this.description = const i0.Value.absent(),
    this.originSourceId = const i0.Value.absent(),
    this.originLocator = const i0.Value.absent(),
    this.originRevision = const i0.Value.absent(),
    this.createdAt = const i0.Value.absent(),
    this.updatedAt = const i0.Value.absent(),
    this.deletedAt = const i0.Value.absent(),
  });
  PlaylistsCompanion.insert({
    this.id = const i0.Value.absent(),
    required String uid,
    required String name,
    this.nameKey = const i0.Value.absent(),
    this.kind = const i0.Value.absent(),
    this.description = const i0.Value.absent(),
    this.originSourceId = const i0.Value.absent(),
    this.originLocator = const i0.Value.absent(),
    this.originRevision = const i0.Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const i0.Value.absent(),
  }) : uid = i0.Value(uid),
       name = i0.Value(name),
       createdAt = i0.Value(createdAt),
       updatedAt = i0.Value(updatedAt);
  static i0.Insertable<i1.Playlist> custom({
    i0.Expression<int>? id,
    i0.Expression<String>? uid,
    i0.Expression<String>? name,
    i0.Expression<String>? nameKey,
    i0.Expression<String>? kind,
    i0.Expression<String>? description,
    i0.Expression<int>? originSourceId,
    i0.Expression<String>? originLocator,
    i0.Expression<String>? originRevision,
    i0.Expression<int>? createdAt,
    i0.Expression<int>? updatedAt,
    i0.Expression<int>? deletedAt,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (uid != null) 'uid': uid,
      if (name != null) 'name': name,
      if (nameKey != null) 'name_key': nameKey,
      if (kind != null) 'kind': kind,
      if (description != null) 'description': description,
      if (originSourceId != null) 'origin_source_id': originSourceId,
      if (originLocator != null) 'origin_locator': originLocator,
      if (originRevision != null) 'origin_revision': originRevision,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  i1.PlaylistsCompanion copyWith({
    i0.Value<int>? id,
    i0.Value<String>? uid,
    i0.Value<String>? name,
    i0.Value<String?>? nameKey,
    i0.Value<String?>? kind,
    i0.Value<String>? description,
    i0.Value<int?>? originSourceId,
    i0.Value<String?>? originLocator,
    i0.Value<String?>? originRevision,
    i0.Value<int>? createdAt,
    i0.Value<int>? updatedAt,
    i0.Value<int?>? deletedAt,
  }) {
    return i1.PlaylistsCompanion(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      nameKey: nameKey ?? this.nameKey,
      kind: kind ?? this.kind,
      description: description ?? this.description,
      originSourceId: originSourceId ?? this.originSourceId,
      originLocator: originLocator ?? this.originLocator,
      originRevision: originRevision ?? this.originRevision,
      createdAt: createdAt ?? this.createdAt,
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
    if (name.present) {
      map['name'] = i0.Variable<String>(name.value);
    }
    if (nameKey.present) {
      map['name_key'] = i0.Variable<String>(nameKey.value);
    }
    if (kind.present) {
      map['kind'] = i0.Variable<String>(kind.value);
    }
    if (description.present) {
      map['description'] = i0.Variable<String>(description.value);
    }
    if (originSourceId.present) {
      map['origin_source_id'] = i0.Variable<int>(originSourceId.value);
    }
    if (originLocator.present) {
      map['origin_locator'] = i0.Variable<String>(originLocator.value);
    }
    if (originRevision.present) {
      map['origin_revision'] = i0.Variable<String>(originRevision.value);
    }
    if (createdAt.present) {
      map['created_at'] = i0.Variable<int>(createdAt.value);
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
    return (StringBuffer('PlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('name: $name, ')
          ..write('nameKey: $nameKey, ')
          ..write('kind: $kind, ')
          ..write('description: $description, ')
          ..write('originSourceId: $originSourceId, ')
          ..write('originLocator: $originLocator, ')
          ..write('originRevision: $originRevision, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

i0.Index get playlistsMoodNameUnique => i0.Index(
  'playlists_mood_name_unique',
  'CREATE UNIQUE INDEX playlists_mood_name_unique ON playlists (name_key) WHERE kind = \'mood\' AND deleted_at IS NULL',
);
i0.Index get playlistsOriginUnique => i0.Index(
  'playlists_origin_unique',
  'CREATE UNIQUE INDEX playlists_origin_unique ON playlists (origin_source_id, origin_locator) WHERE origin_source_id IS NOT NULL AND deleted_at IS NULL',
);
i0.Index get playlistsOriginSource => i0.Index(
  'playlists_origin_source',
  'CREATE INDEX playlists_origin_source ON playlists (origin_source_id)',
);
i0.Index get playlistEntriesOrder => i0.Index(
  'playlist_entries_order',
  'CREATE INDEX playlist_entries_order ON playlist_entries (playlist_id, deleted_at, sort_key, uid, track_id)',
);

class $PlaylistEntriesTable extends i2.PlaylistEntries
    with i0.TableInfo<$PlaylistEntriesTable, i1.PlaylistEntry> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistEntriesTable(this.attachedDatabase, [this._alias]);
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
  static const i0.VerificationMeta _playlistIdMeta = const i0.VerificationMeta(
    'playlistId',
  );
  @override
  late final i0.GeneratedColumn<int> playlistId = i0.GeneratedColumn<int>(
    'playlist_id',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
      'REFERENCES playlists (id) ON DELETE CASCADE',
    ),
  );
  static const i0.VerificationMeta _trackIdMeta = const i0.VerificationMeta(
    'trackId',
  );
  @override
  late final i0.GeneratedColumn<int> trackId = i0.GeneratedColumn<int>(
    'track_id',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
      'REFERENCES tracks (id) ON DELETE RESTRICT',
    ),
  );
  static const i0.VerificationMeta _sortKeyMeta = const i0.VerificationMeta(
    'sortKey',
  );
  @override
  late final i0.GeneratedColumn<String> sortKey = i0.GeneratedColumn<String>(
    'sort_key',
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
    playlistId,
    trackId,
    sortKey,
    addedAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlist_entries';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.PlaylistEntry> instance, {
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
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('sort_key')) {
      context.handle(
        _sortKeyMeta,
        sortKey.isAcceptableOrUnknown(data['sort_key']!, _sortKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_sortKeyMeta);
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
  i1.PlaylistEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.PlaylistEntry(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      playlistId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}playlist_id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      )!,
      sortKey: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}sort_key'],
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
  $PlaylistEntriesTable createAlias(String alias) {
    return $PlaylistEntriesTable(attachedDatabase, alias);
  }
}

class PlaylistEntry extends i0.DataClass
    implements i0.Insertable<i1.PlaylistEntry> {
  final int id;
  final String uid;
  final int playlistId;
  final int trackId;

  /// Fractional key in base62; SQLite compares text in binary order, the
  /// same as Dart's `String.compareTo` for these ASCII keys.
  final String sortKey;
  final int addedAt;
  final int updatedAt;
  final int? deletedAt;
  const PlaylistEntry({
    required this.id,
    required this.uid,
    required this.playlistId,
    required this.trackId,
    required this.sortKey,
    required this.addedAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id);
    map['uid'] = i0.Variable<String>(uid);
    map['playlist_id'] = i0.Variable<int>(playlistId);
    map['track_id'] = i0.Variable<int>(trackId);
    map['sort_key'] = i0.Variable<String>(sortKey);
    map['added_at'] = i0.Variable<int>(addedAt);
    map['updated_at'] = i0.Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = i0.Variable<int>(deletedAt);
    }
    return map;
  }

  i1.PlaylistEntriesCompanion toCompanion(bool nullToAbsent) {
    return i1.PlaylistEntriesCompanion(
      id: i0.Value(id),
      uid: i0.Value(uid),
      playlistId: i0.Value(playlistId),
      trackId: i0.Value(trackId),
      sortKey: i0.Value(sortKey),
      addedAt: i0.Value(addedAt),
      updatedAt: i0.Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(deletedAt),
    );
  }

  factory PlaylistEntry.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return PlaylistEntry(
      id: serializer.fromJson<int>(json['id']),
      uid: serializer.fromJson<String>(json['uid']),
      playlistId: serializer.fromJson<int>(json['playlistId']),
      trackId: serializer.fromJson<int>(json['trackId']),
      sortKey: serializer.fromJson<String>(json['sortKey']),
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
      'playlistId': serializer.toJson<int>(playlistId),
      'trackId': serializer.toJson<int>(trackId),
      'sortKey': serializer.toJson<String>(sortKey),
      'addedAt': serializer.toJson<int>(addedAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  i1.PlaylistEntry copyWith({
    int? id,
    String? uid,
    int? playlistId,
    int? trackId,
    String? sortKey,
    int? addedAt,
    int? updatedAt,
    i0.Value<int?> deletedAt = const i0.Value.absent(),
  }) => i1.PlaylistEntry(
    id: id ?? this.id,
    uid: uid ?? this.uid,
    playlistId: playlistId ?? this.playlistId,
    trackId: trackId ?? this.trackId,
    sortKey: sortKey ?? this.sortKey,
    addedAt: addedAt ?? this.addedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  PlaylistEntry copyWithCompanion(i1.PlaylistEntriesCompanion data) {
    return PlaylistEntry(
      id: data.id.present ? data.id.value : this.id,
      uid: data.uid.present ? data.uid.value : this.uid,
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      sortKey: data.sortKey.present ? data.sortKey.value : this.sortKey,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistEntry(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('playlistId: $playlistId, ')
          ..write('trackId: $trackId, ')
          ..write('sortKey: $sortKey, ')
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
    playlistId,
    trackId,
    sortKey,
    addedAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.PlaylistEntry &&
          other.id == this.id &&
          other.uid == this.uid &&
          other.playlistId == this.playlistId &&
          other.trackId == this.trackId &&
          other.sortKey == this.sortKey &&
          other.addedAt == this.addedAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class PlaylistEntriesCompanion extends i0.UpdateCompanion<i1.PlaylistEntry> {
  final i0.Value<int> id;
  final i0.Value<String> uid;
  final i0.Value<int> playlistId;
  final i0.Value<int> trackId;
  final i0.Value<String> sortKey;
  final i0.Value<int> addedAt;
  final i0.Value<int> updatedAt;
  final i0.Value<int?> deletedAt;
  const PlaylistEntriesCompanion({
    this.id = const i0.Value.absent(),
    this.uid = const i0.Value.absent(),
    this.playlistId = const i0.Value.absent(),
    this.trackId = const i0.Value.absent(),
    this.sortKey = const i0.Value.absent(),
    this.addedAt = const i0.Value.absent(),
    this.updatedAt = const i0.Value.absent(),
    this.deletedAt = const i0.Value.absent(),
  });
  PlaylistEntriesCompanion.insert({
    this.id = const i0.Value.absent(),
    required String uid,
    required int playlistId,
    required int trackId,
    required String sortKey,
    required int addedAt,
    required int updatedAt,
    this.deletedAt = const i0.Value.absent(),
  }) : uid = i0.Value(uid),
       playlistId = i0.Value(playlistId),
       trackId = i0.Value(trackId),
       sortKey = i0.Value(sortKey),
       addedAt = i0.Value(addedAt),
       updatedAt = i0.Value(updatedAt);
  static i0.Insertable<i1.PlaylistEntry> custom({
    i0.Expression<int>? id,
    i0.Expression<String>? uid,
    i0.Expression<int>? playlistId,
    i0.Expression<int>? trackId,
    i0.Expression<String>? sortKey,
    i0.Expression<int>? addedAt,
    i0.Expression<int>? updatedAt,
    i0.Expression<int>? deletedAt,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (uid != null) 'uid': uid,
      if (playlistId != null) 'playlist_id': playlistId,
      if (trackId != null) 'track_id': trackId,
      if (sortKey != null) 'sort_key': sortKey,
      if (addedAt != null) 'added_at': addedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  i1.PlaylistEntriesCompanion copyWith({
    i0.Value<int>? id,
    i0.Value<String>? uid,
    i0.Value<int>? playlistId,
    i0.Value<int>? trackId,
    i0.Value<String>? sortKey,
    i0.Value<int>? addedAt,
    i0.Value<int>? updatedAt,
    i0.Value<int?>? deletedAt,
  }) {
    return i1.PlaylistEntriesCompanion(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      playlistId: playlistId ?? this.playlistId,
      trackId: trackId ?? this.trackId,
      sortKey: sortKey ?? this.sortKey,
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
    if (playlistId.present) {
      map['playlist_id'] = i0.Variable<int>(playlistId.value);
    }
    if (trackId.present) {
      map['track_id'] = i0.Variable<int>(trackId.value);
    }
    if (sortKey.present) {
      map['sort_key'] = i0.Variable<String>(sortKey.value);
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
    return (StringBuffer('PlaylistEntriesCompanion(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('playlistId: $playlistId, ')
          ..write('trackId: $trackId, ')
          ..write('sortKey: $sortKey, ')
          ..write('addedAt: $addedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

i0.Index get playlistEntriesTrack => i0.Index(
  'playlist_entries_track',
  'CREATE INDEX playlist_entries_track ON playlist_entries (track_id, deleted_at, playlist_id)',
);
i0.Index get savedItemsLookup => i0.Index(
  'saved_items_lookup',
  'CREATE INDEX saved_items_lookup ON saved_items (source_id, kind, remote_id)',
);

class $SavedItemsTable extends i2.SavedItems
    with i0.TableInfo<$SavedItemsTable, i1.SavedItem> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedItemsTable(this.attachedDatabase, [this._alias]);
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
      'REFERENCES sources (id) ON DELETE RESTRICT',
    ),
  );
  static const i0.VerificationMeta _remoteIdMeta = const i0.VerificationMeta(
    'remoteId',
  );
  @override
  late final i0.GeneratedColumn<String> remoteId = i0.GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _snapshotJsonMeta =
      const i0.VerificationMeta('snapshotJson');
  @override
  late final i0.GeneratedColumn<String> snapshotJson =
      i0.GeneratedColumn<String>(
        'snapshot_json',
        aliasedName,
        false,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const i0.VerificationMeta _savedAtMeta = const i0.VerificationMeta(
    'savedAt',
  );
  @override
  late final i0.GeneratedColumn<int> savedAt = i0.GeneratedColumn<int>(
    'saved_at',
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
    sourceId,
    remoteId,
    snapshotJson,
    savedAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_items';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.SavedItem> instance, {
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
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_remoteIdMeta);
    }
    if (data.containsKey('snapshot_json')) {
      context.handle(
        _snapshotJsonMeta,
        snapshotJson.isAcceptableOrUnknown(
          data['snapshot_json']!,
          _snapshotJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_snapshotJsonMeta);
    }
    if (data.containsKey('saved_at')) {
      context.handle(
        _savedAtMeta,
        savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_savedAtMeta);
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
  i1.SavedItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.SavedItem(
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
      sourceId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      )!,
      snapshotJson: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}snapshot_json'],
      )!,
      savedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}saved_at'],
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
  $SavedItemsTable createAlias(String alias) {
    return $SavedItemsTable(attachedDatabase, alias);
  }
}

class SavedItem extends i0.DataClass implements i0.Insertable<i1.SavedItem> {
  final int id;
  final String uid;

  /// A [SavedItemKind] value.
  final String kind;
  final int sourceId;

  /// Identifier on the source.
  final String remoteId;

  /// Last seen remote data.
  final String snapshotJson;
  final int savedAt;
  final int updatedAt;
  final int? deletedAt;
  const SavedItem({
    required this.id,
    required this.uid,
    required this.kind,
    required this.sourceId,
    required this.remoteId,
    required this.snapshotJson,
    required this.savedAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id);
    map['uid'] = i0.Variable<String>(uid);
    map['kind'] = i0.Variable<String>(kind);
    map['source_id'] = i0.Variable<int>(sourceId);
    map['remote_id'] = i0.Variable<String>(remoteId);
    map['snapshot_json'] = i0.Variable<String>(snapshotJson);
    map['saved_at'] = i0.Variable<int>(savedAt);
    map['updated_at'] = i0.Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = i0.Variable<int>(deletedAt);
    }
    return map;
  }

  i1.SavedItemsCompanion toCompanion(bool nullToAbsent) {
    return i1.SavedItemsCompanion(
      id: i0.Value(id),
      uid: i0.Value(uid),
      kind: i0.Value(kind),
      sourceId: i0.Value(sourceId),
      remoteId: i0.Value(remoteId),
      snapshotJson: i0.Value(snapshotJson),
      savedAt: i0.Value(savedAt),
      updatedAt: i0.Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(deletedAt),
    );
  }

  factory SavedItem.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return SavedItem(
      id: serializer.fromJson<int>(json['id']),
      uid: serializer.fromJson<String>(json['uid']),
      kind: serializer.fromJson<String>(json['kind']),
      sourceId: serializer.fromJson<int>(json['sourceId']),
      remoteId: serializer.fromJson<String>(json['remoteId']),
      snapshotJson: serializer.fromJson<String>(json['snapshotJson']),
      savedAt: serializer.fromJson<int>(json['savedAt']),
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
      'sourceId': serializer.toJson<int>(sourceId),
      'remoteId': serializer.toJson<String>(remoteId),
      'snapshotJson': serializer.toJson<String>(snapshotJson),
      'savedAt': serializer.toJson<int>(savedAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  i1.SavedItem copyWith({
    int? id,
    String? uid,
    String? kind,
    int? sourceId,
    String? remoteId,
    String? snapshotJson,
    int? savedAt,
    int? updatedAt,
    i0.Value<int?> deletedAt = const i0.Value.absent(),
  }) => i1.SavedItem(
    id: id ?? this.id,
    uid: uid ?? this.uid,
    kind: kind ?? this.kind,
    sourceId: sourceId ?? this.sourceId,
    remoteId: remoteId ?? this.remoteId,
    snapshotJson: snapshotJson ?? this.snapshotJson,
    savedAt: savedAt ?? this.savedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  SavedItem copyWithCompanion(i1.SavedItemsCompanion data) {
    return SavedItem(
      id: data.id.present ? data.id.value : this.id,
      uid: data.uid.present ? data.uid.value : this.uid,
      kind: data.kind.present ? data.kind.value : this.kind,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      snapshotJson: data.snapshotJson.present
          ? data.snapshotJson.value
          : this.snapshotJson,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedItem(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('kind: $kind, ')
          ..write('sourceId: $sourceId, ')
          ..write('remoteId: $remoteId, ')
          ..write('snapshotJson: $snapshotJson, ')
          ..write('savedAt: $savedAt, ')
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
    sourceId,
    remoteId,
    snapshotJson,
    savedAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.SavedItem &&
          other.id == this.id &&
          other.uid == this.uid &&
          other.kind == this.kind &&
          other.sourceId == this.sourceId &&
          other.remoteId == this.remoteId &&
          other.snapshotJson == this.snapshotJson &&
          other.savedAt == this.savedAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class SavedItemsCompanion extends i0.UpdateCompanion<i1.SavedItem> {
  final i0.Value<int> id;
  final i0.Value<String> uid;
  final i0.Value<String> kind;
  final i0.Value<int> sourceId;
  final i0.Value<String> remoteId;
  final i0.Value<String> snapshotJson;
  final i0.Value<int> savedAt;
  final i0.Value<int> updatedAt;
  final i0.Value<int?> deletedAt;
  const SavedItemsCompanion({
    this.id = const i0.Value.absent(),
    this.uid = const i0.Value.absent(),
    this.kind = const i0.Value.absent(),
    this.sourceId = const i0.Value.absent(),
    this.remoteId = const i0.Value.absent(),
    this.snapshotJson = const i0.Value.absent(),
    this.savedAt = const i0.Value.absent(),
    this.updatedAt = const i0.Value.absent(),
    this.deletedAt = const i0.Value.absent(),
  });
  SavedItemsCompanion.insert({
    this.id = const i0.Value.absent(),
    required String uid,
    required String kind,
    required int sourceId,
    required String remoteId,
    required String snapshotJson,
    required int savedAt,
    required int updatedAt,
    this.deletedAt = const i0.Value.absent(),
  }) : uid = i0.Value(uid),
       kind = i0.Value(kind),
       sourceId = i0.Value(sourceId),
       remoteId = i0.Value(remoteId),
       snapshotJson = i0.Value(snapshotJson),
       savedAt = i0.Value(savedAt),
       updatedAt = i0.Value(updatedAt);
  static i0.Insertable<i1.SavedItem> custom({
    i0.Expression<int>? id,
    i0.Expression<String>? uid,
    i0.Expression<String>? kind,
    i0.Expression<int>? sourceId,
    i0.Expression<String>? remoteId,
    i0.Expression<String>? snapshotJson,
    i0.Expression<int>? savedAt,
    i0.Expression<int>? updatedAt,
    i0.Expression<int>? deletedAt,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (uid != null) 'uid': uid,
      if (kind != null) 'kind': kind,
      if (sourceId != null) 'source_id': sourceId,
      if (remoteId != null) 'remote_id': remoteId,
      if (snapshotJson != null) 'snapshot_json': snapshotJson,
      if (savedAt != null) 'saved_at': savedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  i1.SavedItemsCompanion copyWith({
    i0.Value<int>? id,
    i0.Value<String>? uid,
    i0.Value<String>? kind,
    i0.Value<int>? sourceId,
    i0.Value<String>? remoteId,
    i0.Value<String>? snapshotJson,
    i0.Value<int>? savedAt,
    i0.Value<int>? updatedAt,
    i0.Value<int?>? deletedAt,
  }) {
    return i1.SavedItemsCompanion(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      kind: kind ?? this.kind,
      sourceId: sourceId ?? this.sourceId,
      remoteId: remoteId ?? this.remoteId,
      snapshotJson: snapshotJson ?? this.snapshotJson,
      savedAt: savedAt ?? this.savedAt,
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
    if (sourceId.present) {
      map['source_id'] = i0.Variable<int>(sourceId.value);
    }
    if (remoteId.present) {
      map['remote_id'] = i0.Variable<String>(remoteId.value);
    }
    if (snapshotJson.present) {
      map['snapshot_json'] = i0.Variable<String>(snapshotJson.value);
    }
    if (savedAt.present) {
      map['saved_at'] = i0.Variable<int>(savedAt.value);
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
    return (StringBuffer('SavedItemsCompanion(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('kind: $kind, ')
          ..write('sourceId: $sourceId, ')
          ..write('remoteId: $remoteId, ')
          ..write('snapshotJson: $snapshotJson, ')
          ..write('savedAt: $savedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}
