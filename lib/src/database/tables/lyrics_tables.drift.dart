// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:kanaru/src/database/tables/lyrics_tables.drift.dart' as i1;
import 'package:kanaru/src/database/tables/lyrics_tables.dart' as i2;
import 'package:drift/src/runtime/query_builder/query_builder.dart' as i3;
import 'package:kanaru/src/database/tables/library_track_tables.drift.dart'
    as i4;
import 'package:drift/internal/modular.dart' as i5;

typedef $$TrackLyricsChoicesTableCreateCompanionBuilder =
    i1.TrackLyricsChoicesCompanion Function({
      i0.Value<int> trackId,
      required String mode,
      required int updatedAt,
    });
typedef $$TrackLyricsChoicesTableUpdateCompanionBuilder =
    i1.TrackLyricsChoicesCompanion Function({
      i0.Value<int> trackId,
      i0.Value<String> mode,
      i0.Value<int> updatedAt,
    });

final class $$TrackLyricsChoicesTableReferences
    extends
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$TrackLyricsChoicesTable,
          i1.TrackLyricsChoice
        > {
  $$TrackLyricsChoicesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static i4.$TracksTable _trackIdTable(i0.GeneratedDatabase db) =>
      i5.ReadDatabaseContainer(db)
          .resultSet<i4.$TracksTable>('tracks')
          .createAlias('track_lyrics_choices__track_id__tracks__id');

  i4.$$TracksTableProcessedTableManager get trackId {
    final $_column = $_itemColumn<int>('track_id')!;

    final manager = i4
        .$$TracksTableTableManager(
          $_db,
          i5.ReadDatabaseContainer($_db).resultSet<i4.$TracksTable>('tracks'),
        )
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TrackLyricsChoicesTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$TrackLyricsChoicesTable> {
  $$TrackLyricsChoicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i4.$$TracksTableFilterComposer get trackId {
    final i4.$$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: i5.ReadDatabaseContainer($db)
          .resultSet<i4.$TracksTable>('tracks'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i4.$$TracksTableFilterComposer(
            $db: $db,
            $table: i5.ReadDatabaseContainer($db)
                .resultSet<i4.$TracksTable>('tracks'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackLyricsChoicesTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$TrackLyricsChoicesTable> {
  $$TrackLyricsChoicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i4.$$TracksTableOrderingComposer get trackId {
    final i4.$$TracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: i5.ReadDatabaseContainer($db)
          .resultSet<i4.$TracksTable>('tracks'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i4.$$TracksTableOrderingComposer(
            $db: $db,
            $table: i5.ReadDatabaseContainer($db)
                .resultSet<i4.$TracksTable>('tracks'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackLyricsChoicesTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$TrackLyricsChoicesTable> {
  $$TrackLyricsChoicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  i0.GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  i4.$$TracksTableAnnotationComposer get trackId {
    final i4.$$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: i5.ReadDatabaseContainer($db)
          .resultSet<i4.$TracksTable>('tracks'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i4.$$TracksTableAnnotationComposer(
            $db: $db,
            $table: i5.ReadDatabaseContainer($db)
                .resultSet<i4.$TracksTable>('tracks'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackLyricsChoicesTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$TrackLyricsChoicesTable,
          i1.TrackLyricsChoice,
          i1.$$TrackLyricsChoicesTableFilterComposer,
          i1.$$TrackLyricsChoicesTableOrderingComposer,
          i1.$$TrackLyricsChoicesTableAnnotationComposer,
          $$TrackLyricsChoicesTableCreateCompanionBuilder,
          $$TrackLyricsChoicesTableUpdateCompanionBuilder,
          (i1.TrackLyricsChoice, i1.$$TrackLyricsChoicesTableReferences),
          i1.TrackLyricsChoice,
          i0.PrefetchHooks Function({bool trackId})
        > {
  $$TrackLyricsChoicesTableTableManager(
    i0.GeneratedDatabase db,
    i1.$TrackLyricsChoicesTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => i1
              .$$TrackLyricsChoicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$TrackLyricsChoicesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              i1.$$TrackLyricsChoicesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                i0.Value<int> trackId = const i0.Value.absent(),
                i0.Value<String> mode = const i0.Value.absent(),
                i0.Value<int> updatedAt = const i0.Value.absent(),
              }) => i1.TrackLyricsChoicesCompanion(
                trackId: trackId,
                mode: mode,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                i0.Value<int> trackId = const i0.Value.absent(),
                required String mode,
                required int updatedAt,
              }) => i1.TrackLyricsChoicesCompanion.insert(
                trackId: trackId,
                mode: mode,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    i1.$TrackLyricsChoicesTable,
                    i1.TrackLyricsChoice
                  >(table),
                  i1.$$TrackLyricsChoicesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({trackId = false}) {
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
                    if (trackId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.trackId,
                        referencedTable: i1.$$TrackLyricsChoicesTableReferences
                            ._trackIdTable(db),
                        referencedColumn: i1.$$TrackLyricsChoicesTableReferences
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

typedef $$TrackLyricsChoicesTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$TrackLyricsChoicesTable,
      i1.TrackLyricsChoice,
      i1.$$TrackLyricsChoicesTableFilterComposer,
      i1.$$TrackLyricsChoicesTableOrderingComposer,
      i1.$$TrackLyricsChoicesTableAnnotationComposer,
      $$TrackLyricsChoicesTableCreateCompanionBuilder,
      $$TrackLyricsChoicesTableUpdateCompanionBuilder,
      (i1.TrackLyricsChoice, i1.$$TrackLyricsChoicesTableReferences),
      i1.TrackLyricsChoice,
      i0.PrefetchHooks Function({bool trackId})
    >;
typedef $$LyricsPinsTableCreateCompanionBuilder =
    i1.LyricsPinsCompanion Function({
      i0.Value<int> trackId,
      required String uid,
      required String providerId,
      required String providerName,
      required String remoteId,
      i0.Value<String?> syncedText,
      i0.Value<String?> plainText,
      i0.Value<bool> instrumental,
      i0.Value<int?> remoteDurationMs,
      required int pinnedAt,
      required int updatedAt,
    });
typedef $$LyricsPinsTableUpdateCompanionBuilder =
    i1.LyricsPinsCompanion Function({
      i0.Value<int> trackId,
      i0.Value<String> uid,
      i0.Value<String> providerId,
      i0.Value<String> providerName,
      i0.Value<String> remoteId,
      i0.Value<String?> syncedText,
      i0.Value<String?> plainText,
      i0.Value<bool> instrumental,
      i0.Value<int?> remoteDurationMs,
      i0.Value<int> pinnedAt,
      i0.Value<int> updatedAt,
    });

final class $$LyricsPinsTableReferences
    extends
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$LyricsPinsTable,
          i1.LyricsPinRow
        > {
  $$LyricsPinsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static i4.$TracksTable _trackIdTable(i0.GeneratedDatabase db) =>
      i5.ReadDatabaseContainer(db)
          .resultSet<i4.$TracksTable>('tracks')
          .createAlias('lyrics_pins__track_id__tracks__id');

  i4.$$TracksTableProcessedTableManager get trackId {
    final $_column = $_itemColumn<int>('track_id')!;

    final manager = i4
        .$$TracksTableTableManager(
          $_db,
          i5.ReadDatabaseContainer($_db).resultSet<i4.$TracksTable>('tracks'),
        )
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LyricsPinsTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$LyricsPinsTable> {
  $$LyricsPinsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get providerName => $composableBuilder(
    column: $table.providerName,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get syncedText => $composableBuilder(
    column: $table.syncedText,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get plainText => $composableBuilder(
    column: $table.plainText,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<bool> get instrumental => $composableBuilder(
    column: $table.instrumental,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get remoteDurationMs => $composableBuilder(
    column: $table.remoteDurationMs,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get pinnedAt => $composableBuilder(
    column: $table.pinnedAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i4.$$TracksTableFilterComposer get trackId {
    final i4.$$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: i5.ReadDatabaseContainer($db)
          .resultSet<i4.$TracksTable>('tracks'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i4.$$TracksTableFilterComposer(
            $db: $db,
            $table: i5.ReadDatabaseContainer($db)
                .resultSet<i4.$TracksTable>('tracks'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LyricsPinsTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$LyricsPinsTable> {
  $$LyricsPinsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get providerName => $composableBuilder(
    column: $table.providerName,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get syncedText => $composableBuilder(
    column: $table.syncedText,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get plainText => $composableBuilder(
    column: $table.plainText,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<bool> get instrumental => $composableBuilder(
    column: $table.instrumental,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get remoteDurationMs => $composableBuilder(
    column: $table.remoteDurationMs,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get pinnedAt => $composableBuilder(
    column: $table.pinnedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i4.$$TracksTableOrderingComposer get trackId {
    final i4.$$TracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: i5.ReadDatabaseContainer($db)
          .resultSet<i4.$TracksTable>('tracks'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i4.$$TracksTableOrderingComposer(
            $db: $db,
            $table: i5.ReadDatabaseContainer($db)
                .resultSet<i4.$TracksTable>('tracks'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LyricsPinsTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$LyricsPinsTable> {
  $$LyricsPinsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  i0.GeneratedColumn<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get providerName => $composableBuilder(
    column: $table.providerName,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  i0.GeneratedColumn<String> get syncedText => $composableBuilder(
    column: $table.syncedText,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get plainText =>
      $composableBuilder(column: $table.plainText, builder: (column) => column);

  i0.GeneratedColumn<bool> get instrumental => $composableBuilder(
    column: $table.instrumental,
    builder: (column) => column,
  );

  i0.GeneratedColumn<int> get remoteDurationMs => $composableBuilder(
    column: $table.remoteDurationMs,
    builder: (column) => column,
  );

  i0.GeneratedColumn<int> get pinnedAt =>
      $composableBuilder(column: $table.pinnedAt, builder: (column) => column);

  i0.GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  i4.$$TracksTableAnnotationComposer get trackId {
    final i4.$$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: i5.ReadDatabaseContainer($db)
          .resultSet<i4.$TracksTable>('tracks'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i4.$$TracksTableAnnotationComposer(
            $db: $db,
            $table: i5.ReadDatabaseContainer($db)
                .resultSet<i4.$TracksTable>('tracks'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LyricsPinsTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$LyricsPinsTable,
          i1.LyricsPinRow,
          i1.$$LyricsPinsTableFilterComposer,
          i1.$$LyricsPinsTableOrderingComposer,
          i1.$$LyricsPinsTableAnnotationComposer,
          $$LyricsPinsTableCreateCompanionBuilder,
          $$LyricsPinsTableUpdateCompanionBuilder,
          (i1.LyricsPinRow, i1.$$LyricsPinsTableReferences),
          i1.LyricsPinRow,
          i0.PrefetchHooks Function({bool trackId})
        > {
  $$LyricsPinsTableTableManager(
    i0.GeneratedDatabase db,
    i1.$LyricsPinsTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$LyricsPinsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$LyricsPinsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$LyricsPinsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<int> trackId = const i0.Value.absent(),
                i0.Value<String> uid = const i0.Value.absent(),
                i0.Value<String> providerId = const i0.Value.absent(),
                i0.Value<String> providerName = const i0.Value.absent(),
                i0.Value<String> remoteId = const i0.Value.absent(),
                i0.Value<String?> syncedText = const i0.Value.absent(),
                i0.Value<String?> plainText = const i0.Value.absent(),
                i0.Value<bool> instrumental = const i0.Value.absent(),
                i0.Value<int?> remoteDurationMs = const i0.Value.absent(),
                i0.Value<int> pinnedAt = const i0.Value.absent(),
                i0.Value<int> updatedAt = const i0.Value.absent(),
              }) => i1.LyricsPinsCompanion(
                trackId: trackId,
                uid: uid,
                providerId: providerId,
                providerName: providerName,
                remoteId: remoteId,
                syncedText: syncedText,
                plainText: plainText,
                instrumental: instrumental,
                remoteDurationMs: remoteDurationMs,
                pinnedAt: pinnedAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                i0.Value<int> trackId = const i0.Value.absent(),
                required String uid,
                required String providerId,
                required String providerName,
                required String remoteId,
                i0.Value<String?> syncedText = const i0.Value.absent(),
                i0.Value<String?> plainText = const i0.Value.absent(),
                i0.Value<bool> instrumental = const i0.Value.absent(),
                i0.Value<int?> remoteDurationMs = const i0.Value.absent(),
                required int pinnedAt,
                required int updatedAt,
              }) => i1.LyricsPinsCompanion.insert(
                trackId: trackId,
                uid: uid,
                providerId: providerId,
                providerName: providerName,
                remoteId: remoteId,
                syncedText: syncedText,
                plainText: plainText,
                instrumental: instrumental,
                remoteDurationMs: remoteDurationMs,
                pinnedAt: pinnedAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<i1.$LyricsPinsTable, i1.LyricsPinRow>(table),
                  i1.$$LyricsPinsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({trackId = false}) {
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
                    if (trackId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.trackId,
                        referencedTable: i1.$$LyricsPinsTableReferences
                            ._trackIdTable(db),
                        referencedColumn: i1.$$LyricsPinsTableReferences
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

typedef $$LyricsPinsTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$LyricsPinsTable,
      i1.LyricsPinRow,
      i1.$$LyricsPinsTableFilterComposer,
      i1.$$LyricsPinsTableOrderingComposer,
      i1.$$LyricsPinsTableAnnotationComposer,
      $$LyricsPinsTableCreateCompanionBuilder,
      $$LyricsPinsTableUpdateCompanionBuilder,
      (i1.LyricsPinRow, i1.$$LyricsPinsTableReferences),
      i1.LyricsPinRow,
      i0.PrefetchHooks Function({bool trackId})
    >;
typedef $$LyricsRejectsTableCreateCompanionBuilder =
    i1.LyricsRejectsCompanion Function({
      required int trackId,
      required String providerId,
      required String remoteId,
      i0.Value<String?> contentHash,
      required int rejectedAt,
      i0.Value<int> rowid,
    });
typedef $$LyricsRejectsTableUpdateCompanionBuilder =
    i1.LyricsRejectsCompanion Function({
      i0.Value<int> trackId,
      i0.Value<String> providerId,
      i0.Value<String> remoteId,
      i0.Value<String?> contentHash,
      i0.Value<int> rejectedAt,
      i0.Value<int> rowid,
    });

final class $$LyricsRejectsTableReferences
    extends
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$LyricsRejectsTable,
          i1.LyricsRejectRow
        > {
  $$LyricsRejectsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static i4.$TracksTable _trackIdTable(i0.GeneratedDatabase db) =>
      i5.ReadDatabaseContainer(db)
          .resultSet<i4.$TracksTable>('tracks')
          .createAlias('lyrics_rejects__track_id__tracks__id');

  i4.$$TracksTableProcessedTableManager get trackId {
    final $_column = $_itemColumn<int>('track_id')!;

    final manager = i4
        .$$TracksTableTableManager(
          $_db,
          i5.ReadDatabaseContainer($_db).resultSet<i4.$TracksTable>('tracks'),
        )
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LyricsRejectsTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$LyricsRejectsTable> {
  $$LyricsRejectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get rejectedAt => $composableBuilder(
    column: $table.rejectedAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i4.$$TracksTableFilterComposer get trackId {
    final i4.$$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: i5.ReadDatabaseContainer($db)
          .resultSet<i4.$TracksTable>('tracks'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i4.$$TracksTableFilterComposer(
            $db: $db,
            $table: i5.ReadDatabaseContainer($db)
                .resultSet<i4.$TracksTable>('tracks'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LyricsRejectsTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$LyricsRejectsTable> {
  $$LyricsRejectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get rejectedAt => $composableBuilder(
    column: $table.rejectedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i4.$$TracksTableOrderingComposer get trackId {
    final i4.$$TracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: i5.ReadDatabaseContainer($db)
          .resultSet<i4.$TracksTable>('tracks'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i4.$$TracksTableOrderingComposer(
            $db: $db,
            $table: i5.ReadDatabaseContainer($db)
                .resultSet<i4.$TracksTable>('tracks'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LyricsRejectsTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$LyricsRejectsTable> {
  $$LyricsRejectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  i0.GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  i0.GeneratedColumn<int> get rejectedAt => $composableBuilder(
    column: $table.rejectedAt,
    builder: (column) => column,
  );

  i4.$$TracksTableAnnotationComposer get trackId {
    final i4.$$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: i5.ReadDatabaseContainer($db)
          .resultSet<i4.$TracksTable>('tracks'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i4.$$TracksTableAnnotationComposer(
            $db: $db,
            $table: i5.ReadDatabaseContainer($db)
                .resultSet<i4.$TracksTable>('tracks'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LyricsRejectsTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$LyricsRejectsTable,
          i1.LyricsRejectRow,
          i1.$$LyricsRejectsTableFilterComposer,
          i1.$$LyricsRejectsTableOrderingComposer,
          i1.$$LyricsRejectsTableAnnotationComposer,
          $$LyricsRejectsTableCreateCompanionBuilder,
          $$LyricsRejectsTableUpdateCompanionBuilder,
          (i1.LyricsRejectRow, i1.$$LyricsRejectsTableReferences),
          i1.LyricsRejectRow,
          i0.PrefetchHooks Function({bool trackId})
        > {
  $$LyricsRejectsTableTableManager(
    i0.GeneratedDatabase db,
    i1.$LyricsRejectsTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$LyricsRejectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$LyricsRejectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$LyricsRejectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<int> trackId = const i0.Value.absent(),
                i0.Value<String> providerId = const i0.Value.absent(),
                i0.Value<String> remoteId = const i0.Value.absent(),
                i0.Value<String?> contentHash = const i0.Value.absent(),
                i0.Value<int> rejectedAt = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.LyricsRejectsCompanion(
                trackId: trackId,
                providerId: providerId,
                remoteId: remoteId,
                contentHash: contentHash,
                rejectedAt: rejectedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int trackId,
                required String providerId,
                required String remoteId,
                i0.Value<String?> contentHash = const i0.Value.absent(),
                required int rejectedAt,
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.LyricsRejectsCompanion.insert(
                trackId: trackId,
                providerId: providerId,
                remoteId: remoteId,
                contentHash: contentHash,
                rejectedAt: rejectedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<i1.$LyricsRejectsTable, i1.LyricsRejectRow>(
                    table,
                  ),
                  i1.$$LyricsRejectsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({trackId = false}) {
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
                    if (trackId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.trackId,
                        referencedTable: i1.$$LyricsRejectsTableReferences
                            ._trackIdTable(db),
                        referencedColumn: i1.$$LyricsRejectsTableReferences
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

typedef $$LyricsRejectsTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$LyricsRejectsTable,
      i1.LyricsRejectRow,
      i1.$$LyricsRejectsTableFilterComposer,
      i1.$$LyricsRejectsTableOrderingComposer,
      i1.$$LyricsRejectsTableAnnotationComposer,
      $$LyricsRejectsTableCreateCompanionBuilder,
      $$LyricsRejectsTableUpdateCompanionBuilder,
      (i1.LyricsRejectRow, i1.$$LyricsRejectsTableReferences),
      i1.LyricsRejectRow,
      i0.PrefetchHooks Function({bool trackId})
    >;
typedef $$OnlineLyricsTableCreateCompanionBuilder =
    i1.OnlineLyricsCompanion Function({
      required String cacheKey,
      required String providerId,
      required String status,
      i0.Value<String?> remoteId,
      i0.Value<String?> syncedText,
      i0.Value<String?> plainText,
      i0.Value<bool> instrumental,
      i0.Value<int?> remoteDurationMs,
      required int fetchedAt,
      i0.Value<int> rowid,
    });
typedef $$OnlineLyricsTableUpdateCompanionBuilder =
    i1.OnlineLyricsCompanion Function({
      i0.Value<String> cacheKey,
      i0.Value<String> providerId,
      i0.Value<String> status,
      i0.Value<String?> remoteId,
      i0.Value<String?> syncedText,
      i0.Value<String?> plainText,
      i0.Value<bool> instrumental,
      i0.Value<int?> remoteDurationMs,
      i0.Value<int> fetchedAt,
      i0.Value<int> rowid,
    });

class $$OnlineLyricsTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$OnlineLyricsTable> {
  $$OnlineLyricsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get syncedText => $composableBuilder(
    column: $table.syncedText,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get plainText => $composableBuilder(
    column: $table.plainText,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<bool> get instrumental => $composableBuilder(
    column: $table.instrumental,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get remoteDurationMs => $composableBuilder(
    column: $table.remoteDurationMs,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => i0.ColumnFilters(column),
  );
}

class $$OnlineLyricsTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$OnlineLyricsTable> {
  $$OnlineLyricsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get syncedText => $composableBuilder(
    column: $table.syncedText,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get plainText => $composableBuilder(
    column: $table.plainText,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<bool> get instrumental => $composableBuilder(
    column: $table.instrumental,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get remoteDurationMs => $composableBuilder(
    column: $table.remoteDurationMs,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $$OnlineLyricsTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$OnlineLyricsTable> {
  $$OnlineLyricsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  i0.GeneratedColumn<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  i0.GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  i0.GeneratedColumn<String> get syncedText => $composableBuilder(
    column: $table.syncedText,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get plainText =>
      $composableBuilder(column: $table.plainText, builder: (column) => column);

  i0.GeneratedColumn<bool> get instrumental => $composableBuilder(
    column: $table.instrumental,
    builder: (column) => column,
  );

  i0.GeneratedColumn<int> get remoteDurationMs => $composableBuilder(
    column: $table.remoteDurationMs,
    builder: (column) => column,
  );

  i0.GeneratedColumn<int> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$OnlineLyricsTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$OnlineLyricsTable,
          i1.OnlineLyricsRow,
          i1.$$OnlineLyricsTableFilterComposer,
          i1.$$OnlineLyricsTableOrderingComposer,
          i1.$$OnlineLyricsTableAnnotationComposer,
          $$OnlineLyricsTableCreateCompanionBuilder,
          $$OnlineLyricsTableUpdateCompanionBuilder,
          (
            i1.OnlineLyricsRow,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i1.$OnlineLyricsTable,
              i1.OnlineLyricsRow
            >,
          ),
          i1.OnlineLyricsRow,
          i0.PrefetchHooks Function()
        > {
  $$OnlineLyricsTableTableManager(
    i0.GeneratedDatabase db,
    i1.$OnlineLyricsTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$OnlineLyricsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$OnlineLyricsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$OnlineLyricsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> cacheKey = const i0.Value.absent(),
                i0.Value<String> providerId = const i0.Value.absent(),
                i0.Value<String> status = const i0.Value.absent(),
                i0.Value<String?> remoteId = const i0.Value.absent(),
                i0.Value<String?> syncedText = const i0.Value.absent(),
                i0.Value<String?> plainText = const i0.Value.absent(),
                i0.Value<bool> instrumental = const i0.Value.absent(),
                i0.Value<int?> remoteDurationMs = const i0.Value.absent(),
                i0.Value<int> fetchedAt = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.OnlineLyricsCompanion(
                cacheKey: cacheKey,
                providerId: providerId,
                status: status,
                remoteId: remoteId,
                syncedText: syncedText,
                plainText: plainText,
                instrumental: instrumental,
                remoteDurationMs: remoteDurationMs,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cacheKey,
                required String providerId,
                required String status,
                i0.Value<String?> remoteId = const i0.Value.absent(),
                i0.Value<String?> syncedText = const i0.Value.absent(),
                i0.Value<String?> plainText = const i0.Value.absent(),
                i0.Value<bool> instrumental = const i0.Value.absent(),
                i0.Value<int?> remoteDurationMs = const i0.Value.absent(),
                required int fetchedAt,
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.OnlineLyricsCompanion.insert(
                cacheKey: cacheKey,
                providerId: providerId,
                status: status,
                remoteId: remoteId,
                syncedText: syncedText,
                plainText: plainText,
                instrumental: instrumental,
                remoteDurationMs: remoteDurationMs,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<i1.$OnlineLyricsTable, i1.OnlineLyricsRow>(table),
                  i0.BaseReferences<
                    i0.GeneratedDatabase,
                    i1.$OnlineLyricsTable,
                    i1.OnlineLyricsRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OnlineLyricsTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$OnlineLyricsTable,
      i1.OnlineLyricsRow,
      i1.$$OnlineLyricsTableFilterComposer,
      i1.$$OnlineLyricsTableOrderingComposer,
      i1.$$OnlineLyricsTableAnnotationComposer,
      $$OnlineLyricsTableCreateCompanionBuilder,
      $$OnlineLyricsTableUpdateCompanionBuilder,
      (
        i1.OnlineLyricsRow,
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$OnlineLyricsTable,
          i1.OnlineLyricsRow
        >,
      ),
      i1.OnlineLyricsRow,
      i0.PrefetchHooks Function()
    >;

class $TrackLyricsChoicesTable extends i2.TrackLyricsChoices
    with i0.TableInfo<$TrackLyricsChoicesTable, i1.TrackLyricsChoice> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackLyricsChoicesTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _trackIdMeta = const i0.VerificationMeta(
    'trackId',
  );
  @override
  late final i0.GeneratedColumn<int> trackId = i0.GeneratedColumn<int>(
    'track_id',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
      'REFERENCES tracks (id) ON DELETE RESTRICT',
    ),
  );
  static const i0.VerificationMeta _modeMeta = const i0.VerificationMeta(
    'mode',
  );
  @override
  late final i0.GeneratedColumn<String> mode = i0.GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    check: () => mode.isIn(i2.LyricsChoiceMode.values),
    type: i0.DriftSqlType.string,
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
  @override
  List<i0.GeneratedColumn> get $columns => [trackId, mode, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'track_lyrics_choices';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.TrackLyricsChoice> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {trackId};
  @override
  i1.TrackLyricsChoice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.TrackLyricsChoice(
      trackId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TrackLyricsChoicesTable createAlias(String alias) {
    return $TrackLyricsChoicesTable(attachedDatabase, alias);
  }
}

class TrackLyricsChoice extends i0.DataClass
    implements i0.Insertable<i1.TrackLyricsChoice> {
  final int trackId;

  /// `off` or `file` (see [LyricsChoiceMode]).
  final String mode;
  final int updatedAt;
  const TrackLyricsChoice({
    required this.trackId,
    required this.mode,
    required this.updatedAt,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['track_id'] = i0.Variable<int>(trackId);
    map['mode'] = i0.Variable<String>(mode);
    map['updated_at'] = i0.Variable<int>(updatedAt);
    return map;
  }

  i1.TrackLyricsChoicesCompanion toCompanion(bool nullToAbsent) {
    return i1.TrackLyricsChoicesCompanion(
      trackId: i0.Value(trackId),
      mode: i0.Value(mode),
      updatedAt: i0.Value(updatedAt),
    );
  }

  factory TrackLyricsChoice.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return TrackLyricsChoice(
      trackId: serializer.fromJson<int>(json['trackId']),
      mode: serializer.fromJson<String>(json['mode']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trackId': serializer.toJson<int>(trackId),
      'mode': serializer.toJson<String>(mode),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  i1.TrackLyricsChoice copyWith({int? trackId, String? mode, int? updatedAt}) =>
      i1.TrackLyricsChoice(
        trackId: trackId ?? this.trackId,
        mode: mode ?? this.mode,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  TrackLyricsChoice copyWithCompanion(i1.TrackLyricsChoicesCompanion data) {
    return TrackLyricsChoice(
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      mode: data.mode.present ? data.mode.value : this.mode,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackLyricsChoice(')
          ..write('trackId: $trackId, ')
          ..write('mode: $mode, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(trackId, mode, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.TrackLyricsChoice &&
          other.trackId == this.trackId &&
          other.mode == this.mode &&
          other.updatedAt == this.updatedAt);
}

class TrackLyricsChoicesCompanion
    extends i0.UpdateCompanion<i1.TrackLyricsChoice> {
  final i0.Value<int> trackId;
  final i0.Value<String> mode;
  final i0.Value<int> updatedAt;
  const TrackLyricsChoicesCompanion({
    this.trackId = const i0.Value.absent(),
    this.mode = const i0.Value.absent(),
    this.updatedAt = const i0.Value.absent(),
  });
  TrackLyricsChoicesCompanion.insert({
    this.trackId = const i0.Value.absent(),
    required String mode,
    required int updatedAt,
  }) : mode = i0.Value(mode),
       updatedAt = i0.Value(updatedAt);
  static i0.Insertable<i1.TrackLyricsChoice> custom({
    i0.Expression<int>? trackId,
    i0.Expression<String>? mode,
    i0.Expression<int>? updatedAt,
  }) {
    return i0.RawValuesInsertable({
      if (trackId != null) 'track_id': trackId,
      if (mode != null) 'mode': mode,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  i1.TrackLyricsChoicesCompanion copyWith({
    i0.Value<int>? trackId,
    i0.Value<String>? mode,
    i0.Value<int>? updatedAt,
  }) {
    return i1.TrackLyricsChoicesCompanion(
      trackId: trackId ?? this.trackId,
      mode: mode ?? this.mode,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (trackId.present) {
      map['track_id'] = i0.Variable<int>(trackId.value);
    }
    if (mode.present) {
      map['mode'] = i0.Variable<String>(mode.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = i0.Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackLyricsChoicesCompanion(')
          ..write('trackId: $trackId, ')
          ..write('mode: $mode, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LyricsPinsTable extends i2.LyricsPins
    with i0.TableInfo<$LyricsPinsTable, i1.LyricsPinRow> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LyricsPinsTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _trackIdMeta = const i0.VerificationMeta(
    'trackId',
  );
  @override
  late final i0.GeneratedColumn<int> trackId = i0.GeneratedColumn<int>(
    'track_id',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
      'REFERENCES tracks (id) ON DELETE RESTRICT',
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
  static const i0.VerificationMeta _providerIdMeta = const i0.VerificationMeta(
    'providerId',
  );
  @override
  late final i0.GeneratedColumn<String> providerId = i0.GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _providerNameMeta =
      const i0.VerificationMeta('providerName');
  @override
  late final i0.GeneratedColumn<String> providerName =
      i0.GeneratedColumn<String>(
        'provider_name',
        aliasedName,
        false,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: true,
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
  static const i0.VerificationMeta _syncedTextMeta = const i0.VerificationMeta(
    'syncedText',
  );
  @override
  late final i0.GeneratedColumn<String> syncedText = i0.GeneratedColumn<String>(
    'synced_text',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _plainTextMeta = const i0.VerificationMeta(
    'plainText',
  );
  @override
  late final i0.GeneratedColumn<String> plainText = i0.GeneratedColumn<String>(
    'plain_text',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _instrumentalMeta =
      const i0.VerificationMeta('instrumental');
  @override
  late final i0.GeneratedColumn<bool> instrumental = i0.GeneratedColumn<bool>(
    'instrumental',
    aliasedName,
    false,
    type: i0.DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
      'CHECK ("instrumental" IN (0, 1))',
    ),
    defaultValue: const i3.Constant(false),
  );
  static const i0.VerificationMeta _remoteDurationMsMeta =
      const i0.VerificationMeta('remoteDurationMs');
  @override
  late final i0.GeneratedColumn<int> remoteDurationMs = i0.GeneratedColumn<int>(
    'remote_duration_ms',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _pinnedAtMeta = const i0.VerificationMeta(
    'pinnedAt',
  );
  @override
  late final i0.GeneratedColumn<int> pinnedAt = i0.GeneratedColumn<int>(
    'pinned_at',
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
  @override
  List<i0.GeneratedColumn> get $columns => [
    trackId,
    uid,
    providerId,
    providerName,
    remoteId,
    syncedText,
    plainText,
    instrumental,
    remoteDurationMs,
    pinnedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lyrics_pins';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.LyricsPinRow> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    }
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('provider_name')) {
      context.handle(
        _providerNameMeta,
        providerName.isAcceptableOrUnknown(
          data['provider_name']!,
          _providerNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_providerNameMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_remoteIdMeta);
    }
    if (data.containsKey('synced_text')) {
      context.handle(
        _syncedTextMeta,
        syncedText.isAcceptableOrUnknown(data['synced_text']!, _syncedTextMeta),
      );
    }
    if (data.containsKey('plain_text')) {
      context.handle(
        _plainTextMeta,
        plainText.isAcceptableOrUnknown(data['plain_text']!, _plainTextMeta),
      );
    }
    if (data.containsKey('instrumental')) {
      context.handle(
        _instrumentalMeta,
        instrumental.isAcceptableOrUnknown(
          data['instrumental']!,
          _instrumentalMeta,
        ),
      );
    }
    if (data.containsKey('remote_duration_ms')) {
      context.handle(
        _remoteDurationMsMeta,
        remoteDurationMs.isAcceptableOrUnknown(
          data['remote_duration_ms']!,
          _remoteDurationMsMeta,
        ),
      );
    }
    if (data.containsKey('pinned_at')) {
      context.handle(
        _pinnedAtMeta,
        pinnedAt.isAcceptableOrUnknown(data['pinned_at']!, _pinnedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_pinnedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {trackId};
  @override
  i1.LyricsPinRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.LyricsPinRow(
      trackId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      providerName: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}provider_name'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      )!,
      syncedText: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}synced_text'],
      ),
      plainText: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}plain_text'],
      ),
      instrumental: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.bool,
        data['${effectivePrefix}instrumental'],
      )!,
      remoteDurationMs: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}remote_duration_ms'],
      ),
      pinnedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}pinned_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LyricsPinsTable createAlias(String alias) {
    return $LyricsPinsTable(attachedDatabase, alias);
  }
}

class LyricsPinRow extends i0.DataClass
    implements i0.Insertable<i1.LyricsPinRow> {
  final int trackId;

  /// `pin:` + hash(track uid).
  final String uid;
  final String providerId;

  /// The plugin's name when the copy was kept, shown after the plugin is gone.
  final String providerName;
  final String remoteId;

  /// At most 1 MiB each; a copy holds at least one of the two or is
  /// instrumental.
  final String? syncedText;
  final String? plainText;
  final bool instrumental;
  final int? remoteDurationMs;
  final int pinnedAt;
  final int updatedAt;
  const LyricsPinRow({
    required this.trackId,
    required this.uid,
    required this.providerId,
    required this.providerName,
    required this.remoteId,
    this.syncedText,
    this.plainText,
    required this.instrumental,
    this.remoteDurationMs,
    required this.pinnedAt,
    required this.updatedAt,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['track_id'] = i0.Variable<int>(trackId);
    map['uid'] = i0.Variable<String>(uid);
    map['provider_id'] = i0.Variable<String>(providerId);
    map['provider_name'] = i0.Variable<String>(providerName);
    map['remote_id'] = i0.Variable<String>(remoteId);
    if (!nullToAbsent || syncedText != null) {
      map['synced_text'] = i0.Variable<String>(syncedText);
    }
    if (!nullToAbsent || plainText != null) {
      map['plain_text'] = i0.Variable<String>(plainText);
    }
    map['instrumental'] = i0.Variable<bool>(instrumental);
    if (!nullToAbsent || remoteDurationMs != null) {
      map['remote_duration_ms'] = i0.Variable<int>(remoteDurationMs);
    }
    map['pinned_at'] = i0.Variable<int>(pinnedAt);
    map['updated_at'] = i0.Variable<int>(updatedAt);
    return map;
  }

  i1.LyricsPinsCompanion toCompanion(bool nullToAbsent) {
    return i1.LyricsPinsCompanion(
      trackId: i0.Value(trackId),
      uid: i0.Value(uid),
      providerId: i0.Value(providerId),
      providerName: i0.Value(providerName),
      remoteId: i0.Value(remoteId),
      syncedText: syncedText == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(syncedText),
      plainText: plainText == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(plainText),
      instrumental: i0.Value(instrumental),
      remoteDurationMs: remoteDurationMs == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(remoteDurationMs),
      pinnedAt: i0.Value(pinnedAt),
      updatedAt: i0.Value(updatedAt),
    );
  }

  factory LyricsPinRow.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return LyricsPinRow(
      trackId: serializer.fromJson<int>(json['trackId']),
      uid: serializer.fromJson<String>(json['uid']),
      providerId: serializer.fromJson<String>(json['providerId']),
      providerName: serializer.fromJson<String>(json['providerName']),
      remoteId: serializer.fromJson<String>(json['remoteId']),
      syncedText: serializer.fromJson<String?>(json['syncedText']),
      plainText: serializer.fromJson<String?>(json['plainText']),
      instrumental: serializer.fromJson<bool>(json['instrumental']),
      remoteDurationMs: serializer.fromJson<int?>(json['remoteDurationMs']),
      pinnedAt: serializer.fromJson<int>(json['pinnedAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trackId': serializer.toJson<int>(trackId),
      'uid': serializer.toJson<String>(uid),
      'providerId': serializer.toJson<String>(providerId),
      'providerName': serializer.toJson<String>(providerName),
      'remoteId': serializer.toJson<String>(remoteId),
      'syncedText': serializer.toJson<String?>(syncedText),
      'plainText': serializer.toJson<String?>(plainText),
      'instrumental': serializer.toJson<bool>(instrumental),
      'remoteDurationMs': serializer.toJson<int?>(remoteDurationMs),
      'pinnedAt': serializer.toJson<int>(pinnedAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  i1.LyricsPinRow copyWith({
    int? trackId,
    String? uid,
    String? providerId,
    String? providerName,
    String? remoteId,
    i0.Value<String?> syncedText = const i0.Value.absent(),
    i0.Value<String?> plainText = const i0.Value.absent(),
    bool? instrumental,
    i0.Value<int?> remoteDurationMs = const i0.Value.absent(),
    int? pinnedAt,
    int? updatedAt,
  }) => i1.LyricsPinRow(
    trackId: trackId ?? this.trackId,
    uid: uid ?? this.uid,
    providerId: providerId ?? this.providerId,
    providerName: providerName ?? this.providerName,
    remoteId: remoteId ?? this.remoteId,
    syncedText: syncedText.present ? syncedText.value : this.syncedText,
    plainText: plainText.present ? plainText.value : this.plainText,
    instrumental: instrumental ?? this.instrumental,
    remoteDurationMs: remoteDurationMs.present
        ? remoteDurationMs.value
        : this.remoteDurationMs,
    pinnedAt: pinnedAt ?? this.pinnedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LyricsPinRow copyWithCompanion(i1.LyricsPinsCompanion data) {
    return LyricsPinRow(
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      uid: data.uid.present ? data.uid.value : this.uid,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      providerName: data.providerName.present
          ? data.providerName.value
          : this.providerName,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      syncedText: data.syncedText.present
          ? data.syncedText.value
          : this.syncedText,
      plainText: data.plainText.present ? data.plainText.value : this.plainText,
      instrumental: data.instrumental.present
          ? data.instrumental.value
          : this.instrumental,
      remoteDurationMs: data.remoteDurationMs.present
          ? data.remoteDurationMs.value
          : this.remoteDurationMs,
      pinnedAt: data.pinnedAt.present ? data.pinnedAt.value : this.pinnedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LyricsPinRow(')
          ..write('trackId: $trackId, ')
          ..write('uid: $uid, ')
          ..write('providerId: $providerId, ')
          ..write('providerName: $providerName, ')
          ..write('remoteId: $remoteId, ')
          ..write('syncedText: $syncedText, ')
          ..write('plainText: $plainText, ')
          ..write('instrumental: $instrumental, ')
          ..write('remoteDurationMs: $remoteDurationMs, ')
          ..write('pinnedAt: $pinnedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    trackId,
    uid,
    providerId,
    providerName,
    remoteId,
    syncedText,
    plainText,
    instrumental,
    remoteDurationMs,
    pinnedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.LyricsPinRow &&
          other.trackId == this.trackId &&
          other.uid == this.uid &&
          other.providerId == this.providerId &&
          other.providerName == this.providerName &&
          other.remoteId == this.remoteId &&
          other.syncedText == this.syncedText &&
          other.plainText == this.plainText &&
          other.instrumental == this.instrumental &&
          other.remoteDurationMs == this.remoteDurationMs &&
          other.pinnedAt == this.pinnedAt &&
          other.updatedAt == this.updatedAt);
}

class LyricsPinsCompanion extends i0.UpdateCompanion<i1.LyricsPinRow> {
  final i0.Value<int> trackId;
  final i0.Value<String> uid;
  final i0.Value<String> providerId;
  final i0.Value<String> providerName;
  final i0.Value<String> remoteId;
  final i0.Value<String?> syncedText;
  final i0.Value<String?> plainText;
  final i0.Value<bool> instrumental;
  final i0.Value<int?> remoteDurationMs;
  final i0.Value<int> pinnedAt;
  final i0.Value<int> updatedAt;
  const LyricsPinsCompanion({
    this.trackId = const i0.Value.absent(),
    this.uid = const i0.Value.absent(),
    this.providerId = const i0.Value.absent(),
    this.providerName = const i0.Value.absent(),
    this.remoteId = const i0.Value.absent(),
    this.syncedText = const i0.Value.absent(),
    this.plainText = const i0.Value.absent(),
    this.instrumental = const i0.Value.absent(),
    this.remoteDurationMs = const i0.Value.absent(),
    this.pinnedAt = const i0.Value.absent(),
    this.updatedAt = const i0.Value.absent(),
  });
  LyricsPinsCompanion.insert({
    this.trackId = const i0.Value.absent(),
    required String uid,
    required String providerId,
    required String providerName,
    required String remoteId,
    this.syncedText = const i0.Value.absent(),
    this.plainText = const i0.Value.absent(),
    this.instrumental = const i0.Value.absent(),
    this.remoteDurationMs = const i0.Value.absent(),
    required int pinnedAt,
    required int updatedAt,
  }) : uid = i0.Value(uid),
       providerId = i0.Value(providerId),
       providerName = i0.Value(providerName),
       remoteId = i0.Value(remoteId),
       pinnedAt = i0.Value(pinnedAt),
       updatedAt = i0.Value(updatedAt);
  static i0.Insertable<i1.LyricsPinRow> custom({
    i0.Expression<int>? trackId,
    i0.Expression<String>? uid,
    i0.Expression<String>? providerId,
    i0.Expression<String>? providerName,
    i0.Expression<String>? remoteId,
    i0.Expression<String>? syncedText,
    i0.Expression<String>? plainText,
    i0.Expression<bool>? instrumental,
    i0.Expression<int>? remoteDurationMs,
    i0.Expression<int>? pinnedAt,
    i0.Expression<int>? updatedAt,
  }) {
    return i0.RawValuesInsertable({
      if (trackId != null) 'track_id': trackId,
      if (uid != null) 'uid': uid,
      if (providerId != null) 'provider_id': providerId,
      if (providerName != null) 'provider_name': providerName,
      if (remoteId != null) 'remote_id': remoteId,
      if (syncedText != null) 'synced_text': syncedText,
      if (plainText != null) 'plain_text': plainText,
      if (instrumental != null) 'instrumental': instrumental,
      if (remoteDurationMs != null) 'remote_duration_ms': remoteDurationMs,
      if (pinnedAt != null) 'pinned_at': pinnedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  i1.LyricsPinsCompanion copyWith({
    i0.Value<int>? trackId,
    i0.Value<String>? uid,
    i0.Value<String>? providerId,
    i0.Value<String>? providerName,
    i0.Value<String>? remoteId,
    i0.Value<String?>? syncedText,
    i0.Value<String?>? plainText,
    i0.Value<bool>? instrumental,
    i0.Value<int?>? remoteDurationMs,
    i0.Value<int>? pinnedAt,
    i0.Value<int>? updatedAt,
  }) {
    return i1.LyricsPinsCompanion(
      trackId: trackId ?? this.trackId,
      uid: uid ?? this.uid,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      remoteId: remoteId ?? this.remoteId,
      syncedText: syncedText ?? this.syncedText,
      plainText: plainText ?? this.plainText,
      instrumental: instrumental ?? this.instrumental,
      remoteDurationMs: remoteDurationMs ?? this.remoteDurationMs,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (trackId.present) {
      map['track_id'] = i0.Variable<int>(trackId.value);
    }
    if (uid.present) {
      map['uid'] = i0.Variable<String>(uid.value);
    }
    if (providerId.present) {
      map['provider_id'] = i0.Variable<String>(providerId.value);
    }
    if (providerName.present) {
      map['provider_name'] = i0.Variable<String>(providerName.value);
    }
    if (remoteId.present) {
      map['remote_id'] = i0.Variable<String>(remoteId.value);
    }
    if (syncedText.present) {
      map['synced_text'] = i0.Variable<String>(syncedText.value);
    }
    if (plainText.present) {
      map['plain_text'] = i0.Variable<String>(plainText.value);
    }
    if (instrumental.present) {
      map['instrumental'] = i0.Variable<bool>(instrumental.value);
    }
    if (remoteDurationMs.present) {
      map['remote_duration_ms'] = i0.Variable<int>(remoteDurationMs.value);
    }
    if (pinnedAt.present) {
      map['pinned_at'] = i0.Variable<int>(pinnedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = i0.Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LyricsPinsCompanion(')
          ..write('trackId: $trackId, ')
          ..write('uid: $uid, ')
          ..write('providerId: $providerId, ')
          ..write('providerName: $providerName, ')
          ..write('remoteId: $remoteId, ')
          ..write('syncedText: $syncedText, ')
          ..write('plainText: $plainText, ')
          ..write('instrumental: $instrumental, ')
          ..write('remoteDurationMs: $remoteDurationMs, ')
          ..write('pinnedAt: $pinnedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LyricsRejectsTable extends i2.LyricsRejects
    with i0.TableInfo<$LyricsRejectsTable, i1.LyricsRejectRow> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LyricsRejectsTable(this.attachedDatabase, [this._alias]);
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
  static const i0.VerificationMeta _providerIdMeta = const i0.VerificationMeta(
    'providerId',
  );
  @override
  late final i0.GeneratedColumn<String> providerId = i0.GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const i0.VerificationMeta _contentHashMeta = const i0.VerificationMeta(
    'contentHash',
  );
  @override
  late final i0.GeneratedColumn<String> contentHash =
      i0.GeneratedColumn<String>(
        'content_hash',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const i0.VerificationMeta _rejectedAtMeta = const i0.VerificationMeta(
    'rejectedAt',
  );
  @override
  late final i0.GeneratedColumn<int> rejectedAt = i0.GeneratedColumn<int>(
    'rejected_at',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<i0.GeneratedColumn> get $columns => [
    trackId,
    providerId,
    remoteId,
    contentHash,
    rejectedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lyrics_rejects';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.LyricsRejectRow> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_remoteIdMeta);
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    }
    if (data.containsKey('rejected_at')) {
      context.handle(
        _rejectedAtMeta,
        rejectedAt.isAcceptableOrUnknown(data['rejected_at']!, _rejectedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_rejectedAtMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {trackId, providerId, remoteId};
  @override
  i1.LyricsRejectRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.LyricsRejectRow(
      trackId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      )!,
      contentHash: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      ),
      rejectedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}rejected_at'],
      )!,
    );
  }

  @override
  $LyricsRejectsTable createAlias(String alias) {
    return $LyricsRejectsTable(attachedDatabase, alias);
  }
}

class LyricsRejectRow extends i0.DataClass
    implements i0.Insertable<i1.LyricsRejectRow> {
  final int trackId;
  final String providerId;
  final String remoteId;

  /// Hash of the refused text, so a duplicate of it under another id is
  /// refused too; null for an instrumental or text-less result.
  final String? contentHash;
  final int rejectedAt;
  const LyricsRejectRow({
    required this.trackId,
    required this.providerId,
    required this.remoteId,
    this.contentHash,
    required this.rejectedAt,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['track_id'] = i0.Variable<int>(trackId);
    map['provider_id'] = i0.Variable<String>(providerId);
    map['remote_id'] = i0.Variable<String>(remoteId);
    if (!nullToAbsent || contentHash != null) {
      map['content_hash'] = i0.Variable<String>(contentHash);
    }
    map['rejected_at'] = i0.Variable<int>(rejectedAt);
    return map;
  }

  i1.LyricsRejectsCompanion toCompanion(bool nullToAbsent) {
    return i1.LyricsRejectsCompanion(
      trackId: i0.Value(trackId),
      providerId: i0.Value(providerId),
      remoteId: i0.Value(remoteId),
      contentHash: contentHash == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(contentHash),
      rejectedAt: i0.Value(rejectedAt),
    );
  }

  factory LyricsRejectRow.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return LyricsRejectRow(
      trackId: serializer.fromJson<int>(json['trackId']),
      providerId: serializer.fromJson<String>(json['providerId']),
      remoteId: serializer.fromJson<String>(json['remoteId']),
      contentHash: serializer.fromJson<String?>(json['contentHash']),
      rejectedAt: serializer.fromJson<int>(json['rejectedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trackId': serializer.toJson<int>(trackId),
      'providerId': serializer.toJson<String>(providerId),
      'remoteId': serializer.toJson<String>(remoteId),
      'contentHash': serializer.toJson<String?>(contentHash),
      'rejectedAt': serializer.toJson<int>(rejectedAt),
    };
  }

  i1.LyricsRejectRow copyWith({
    int? trackId,
    String? providerId,
    String? remoteId,
    i0.Value<String?> contentHash = const i0.Value.absent(),
    int? rejectedAt,
  }) => i1.LyricsRejectRow(
    trackId: trackId ?? this.trackId,
    providerId: providerId ?? this.providerId,
    remoteId: remoteId ?? this.remoteId,
    contentHash: contentHash.present ? contentHash.value : this.contentHash,
    rejectedAt: rejectedAt ?? this.rejectedAt,
  );
  LyricsRejectRow copyWithCompanion(i1.LyricsRejectsCompanion data) {
    return LyricsRejectRow(
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      rejectedAt: data.rejectedAt.present
          ? data.rejectedAt.value
          : this.rejectedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LyricsRejectRow(')
          ..write('trackId: $trackId, ')
          ..write('providerId: $providerId, ')
          ..write('remoteId: $remoteId, ')
          ..write('contentHash: $contentHash, ')
          ..write('rejectedAt: $rejectedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(trackId, providerId, remoteId, contentHash, rejectedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.LyricsRejectRow &&
          other.trackId == this.trackId &&
          other.providerId == this.providerId &&
          other.remoteId == this.remoteId &&
          other.contentHash == this.contentHash &&
          other.rejectedAt == this.rejectedAt);
}

class LyricsRejectsCompanion extends i0.UpdateCompanion<i1.LyricsRejectRow> {
  final i0.Value<int> trackId;
  final i0.Value<String> providerId;
  final i0.Value<String> remoteId;
  final i0.Value<String?> contentHash;
  final i0.Value<int> rejectedAt;
  final i0.Value<int> rowid;
  const LyricsRejectsCompanion({
    this.trackId = const i0.Value.absent(),
    this.providerId = const i0.Value.absent(),
    this.remoteId = const i0.Value.absent(),
    this.contentHash = const i0.Value.absent(),
    this.rejectedAt = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  LyricsRejectsCompanion.insert({
    required int trackId,
    required String providerId,
    required String remoteId,
    this.contentHash = const i0.Value.absent(),
    required int rejectedAt,
    this.rowid = const i0.Value.absent(),
  }) : trackId = i0.Value(trackId),
       providerId = i0.Value(providerId),
       remoteId = i0.Value(remoteId),
       rejectedAt = i0.Value(rejectedAt);
  static i0.Insertable<i1.LyricsRejectRow> custom({
    i0.Expression<int>? trackId,
    i0.Expression<String>? providerId,
    i0.Expression<String>? remoteId,
    i0.Expression<String>? contentHash,
    i0.Expression<int>? rejectedAt,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (trackId != null) 'track_id': trackId,
      if (providerId != null) 'provider_id': providerId,
      if (remoteId != null) 'remote_id': remoteId,
      if (contentHash != null) 'content_hash': contentHash,
      if (rejectedAt != null) 'rejected_at': rejectedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i1.LyricsRejectsCompanion copyWith({
    i0.Value<int>? trackId,
    i0.Value<String>? providerId,
    i0.Value<String>? remoteId,
    i0.Value<String?>? contentHash,
    i0.Value<int>? rejectedAt,
    i0.Value<int>? rowid,
  }) {
    return i1.LyricsRejectsCompanion(
      trackId: trackId ?? this.trackId,
      providerId: providerId ?? this.providerId,
      remoteId: remoteId ?? this.remoteId,
      contentHash: contentHash ?? this.contentHash,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (trackId.present) {
      map['track_id'] = i0.Variable<int>(trackId.value);
    }
    if (providerId.present) {
      map['provider_id'] = i0.Variable<String>(providerId.value);
    }
    if (remoteId.present) {
      map['remote_id'] = i0.Variable<String>(remoteId.value);
    }
    if (contentHash.present) {
      map['content_hash'] = i0.Variable<String>(contentHash.value);
    }
    if (rejectedAt.present) {
      map['rejected_at'] = i0.Variable<int>(rejectedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LyricsRejectsCompanion(')
          ..write('trackId: $trackId, ')
          ..write('providerId: $providerId, ')
          ..write('remoteId: $remoteId, ')
          ..write('contentHash: $contentHash, ')
          ..write('rejectedAt: $rejectedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OnlineLyricsTable extends i2.OnlineLyrics
    with i0.TableInfo<$OnlineLyricsTable, i1.OnlineLyricsRow> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OnlineLyricsTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _cacheKeyMeta = const i0.VerificationMeta(
    'cacheKey',
  );
  @override
  late final i0.GeneratedColumn<String> cacheKey = i0.GeneratedColumn<String>(
    'cache_key',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _providerIdMeta = const i0.VerificationMeta(
    'providerId',
  );
  @override
  late final i0.GeneratedColumn<String> providerId = i0.GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _statusMeta = const i0.VerificationMeta(
    'status',
  );
  @override
  late final i0.GeneratedColumn<String> status = i0.GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    check: () => status.isIn(i2.OnlineLyricsStatus.values),
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _remoteIdMeta = const i0.VerificationMeta(
    'remoteId',
  );
  @override
  late final i0.GeneratedColumn<String> remoteId = i0.GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _syncedTextMeta = const i0.VerificationMeta(
    'syncedText',
  );
  @override
  late final i0.GeneratedColumn<String> syncedText = i0.GeneratedColumn<String>(
    'synced_text',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _plainTextMeta = const i0.VerificationMeta(
    'plainText',
  );
  @override
  late final i0.GeneratedColumn<String> plainText = i0.GeneratedColumn<String>(
    'plain_text',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _instrumentalMeta =
      const i0.VerificationMeta('instrumental');
  @override
  late final i0.GeneratedColumn<bool> instrumental = i0.GeneratedColumn<bool>(
    'instrumental',
    aliasedName,
    false,
    type: i0.DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
      'CHECK ("instrumental" IN (0, 1))',
    ),
    defaultValue: const i3.Constant(false),
  );
  static const i0.VerificationMeta _remoteDurationMsMeta =
      const i0.VerificationMeta('remoteDurationMs');
  @override
  late final i0.GeneratedColumn<int> remoteDurationMs = i0.GeneratedColumn<int>(
    'remote_duration_ms',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _fetchedAtMeta = const i0.VerificationMeta(
    'fetchedAt',
  );
  @override
  late final i0.GeneratedColumn<int> fetchedAt = i0.GeneratedColumn<int>(
    'fetched_at',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<i0.GeneratedColumn> get $columns => [
    cacheKey,
    providerId,
    status,
    remoteId,
    syncedText,
    plainText,
    instrumental,
    remoteDurationMs,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'online_lyrics';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.OnlineLyricsRow> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('synced_text')) {
      context.handle(
        _syncedTextMeta,
        syncedText.isAcceptableOrUnknown(data['synced_text']!, _syncedTextMeta),
      );
    }
    if (data.containsKey('plain_text')) {
      context.handle(
        _plainTextMeta,
        plainText.isAcceptableOrUnknown(data['plain_text']!, _plainTextMeta),
      );
    }
    if (data.containsKey('instrumental')) {
      context.handle(
        _instrumentalMeta,
        instrumental.isAcceptableOrUnknown(
          data['instrumental']!,
          _instrumentalMeta,
        ),
      );
    }
    if (data.containsKey('remote_duration_ms')) {
      context.handle(
        _remoteDurationMsMeta,
        remoteDurationMs.isAcceptableOrUnknown(
          data['remote_duration_ms']!,
          _remoteDurationMsMeta,
        ),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {cacheKey, providerId};
  @override
  i1.OnlineLyricsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.OnlineLyricsRow(
      cacheKey: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      syncedText: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}synced_text'],
      ),
      plainText: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}plain_text'],
      ),
      instrumental: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.bool,
        data['${effectivePrefix}instrumental'],
      )!,
      remoteDurationMs: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}remote_duration_ms'],
      ),
      fetchedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $OnlineLyricsTable createAlias(String alias) {
    return $OnlineLyricsTable(attachedDatabase, alias);
  }
}

class OnlineLyricsRow extends i0.DataClass
    implements i0.Insertable<i1.OnlineLyricsRow> {
  final String cacheKey;
  final String providerId;
  final String status;

  /// Null for `not_found`.
  final String? remoteId;
  final String? syncedText;
  final String? plainText;
  final bool instrumental;
  final int? remoteDurationMs;
  final int fetchedAt;
  const OnlineLyricsRow({
    required this.cacheKey,
    required this.providerId,
    required this.status,
    this.remoteId,
    this.syncedText,
    this.plainText,
    required this.instrumental,
    this.remoteDurationMs,
    required this.fetchedAt,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['cache_key'] = i0.Variable<String>(cacheKey);
    map['provider_id'] = i0.Variable<String>(providerId);
    map['status'] = i0.Variable<String>(status);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = i0.Variable<String>(remoteId);
    }
    if (!nullToAbsent || syncedText != null) {
      map['synced_text'] = i0.Variable<String>(syncedText);
    }
    if (!nullToAbsent || plainText != null) {
      map['plain_text'] = i0.Variable<String>(plainText);
    }
    map['instrumental'] = i0.Variable<bool>(instrumental);
    if (!nullToAbsent || remoteDurationMs != null) {
      map['remote_duration_ms'] = i0.Variable<int>(remoteDurationMs);
    }
    map['fetched_at'] = i0.Variable<int>(fetchedAt);
    return map;
  }

  i1.OnlineLyricsCompanion toCompanion(bool nullToAbsent) {
    return i1.OnlineLyricsCompanion(
      cacheKey: i0.Value(cacheKey),
      providerId: i0.Value(providerId),
      status: i0.Value(status),
      remoteId: remoteId == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(remoteId),
      syncedText: syncedText == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(syncedText),
      plainText: plainText == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(plainText),
      instrumental: i0.Value(instrumental),
      remoteDurationMs: remoteDurationMs == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(remoteDurationMs),
      fetchedAt: i0.Value(fetchedAt),
    );
  }

  factory OnlineLyricsRow.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return OnlineLyricsRow(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      providerId: serializer.fromJson<String>(json['providerId']),
      status: serializer.fromJson<String>(json['status']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      syncedText: serializer.fromJson<String?>(json['syncedText']),
      plainText: serializer.fromJson<String?>(json['plainText']),
      instrumental: serializer.fromJson<bool>(json['instrumental']),
      remoteDurationMs: serializer.fromJson<int?>(json['remoteDurationMs']),
      fetchedAt: serializer.fromJson<int>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'providerId': serializer.toJson<String>(providerId),
      'status': serializer.toJson<String>(status),
      'remoteId': serializer.toJson<String?>(remoteId),
      'syncedText': serializer.toJson<String?>(syncedText),
      'plainText': serializer.toJson<String?>(plainText),
      'instrumental': serializer.toJson<bool>(instrumental),
      'remoteDurationMs': serializer.toJson<int?>(remoteDurationMs),
      'fetchedAt': serializer.toJson<int>(fetchedAt),
    };
  }

  i1.OnlineLyricsRow copyWith({
    String? cacheKey,
    String? providerId,
    String? status,
    i0.Value<String?> remoteId = const i0.Value.absent(),
    i0.Value<String?> syncedText = const i0.Value.absent(),
    i0.Value<String?> plainText = const i0.Value.absent(),
    bool? instrumental,
    i0.Value<int?> remoteDurationMs = const i0.Value.absent(),
    int? fetchedAt,
  }) => i1.OnlineLyricsRow(
    cacheKey: cacheKey ?? this.cacheKey,
    providerId: providerId ?? this.providerId,
    status: status ?? this.status,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    syncedText: syncedText.present ? syncedText.value : this.syncedText,
    plainText: plainText.present ? plainText.value : this.plainText,
    instrumental: instrumental ?? this.instrumental,
    remoteDurationMs: remoteDurationMs.present
        ? remoteDurationMs.value
        : this.remoteDurationMs,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  OnlineLyricsRow copyWithCompanion(i1.OnlineLyricsCompanion data) {
    return OnlineLyricsRow(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      status: data.status.present ? data.status.value : this.status,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      syncedText: data.syncedText.present
          ? data.syncedText.value
          : this.syncedText,
      plainText: data.plainText.present ? data.plainText.value : this.plainText,
      instrumental: data.instrumental.present
          ? data.instrumental.value
          : this.instrumental,
      remoteDurationMs: data.remoteDurationMs.present
          ? data.remoteDurationMs.value
          : this.remoteDurationMs,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OnlineLyricsRow(')
          ..write('cacheKey: $cacheKey, ')
          ..write('providerId: $providerId, ')
          ..write('status: $status, ')
          ..write('remoteId: $remoteId, ')
          ..write('syncedText: $syncedText, ')
          ..write('plainText: $plainText, ')
          ..write('instrumental: $instrumental, ')
          ..write('remoteDurationMs: $remoteDurationMs, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    cacheKey,
    providerId,
    status,
    remoteId,
    syncedText,
    plainText,
    instrumental,
    remoteDurationMs,
    fetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.OnlineLyricsRow &&
          other.cacheKey == this.cacheKey &&
          other.providerId == this.providerId &&
          other.status == this.status &&
          other.remoteId == this.remoteId &&
          other.syncedText == this.syncedText &&
          other.plainText == this.plainText &&
          other.instrumental == this.instrumental &&
          other.remoteDurationMs == this.remoteDurationMs &&
          other.fetchedAt == this.fetchedAt);
}

class OnlineLyricsCompanion extends i0.UpdateCompanion<i1.OnlineLyricsRow> {
  final i0.Value<String> cacheKey;
  final i0.Value<String> providerId;
  final i0.Value<String> status;
  final i0.Value<String?> remoteId;
  final i0.Value<String?> syncedText;
  final i0.Value<String?> plainText;
  final i0.Value<bool> instrumental;
  final i0.Value<int?> remoteDurationMs;
  final i0.Value<int> fetchedAt;
  final i0.Value<int> rowid;
  const OnlineLyricsCompanion({
    this.cacheKey = const i0.Value.absent(),
    this.providerId = const i0.Value.absent(),
    this.status = const i0.Value.absent(),
    this.remoteId = const i0.Value.absent(),
    this.syncedText = const i0.Value.absent(),
    this.plainText = const i0.Value.absent(),
    this.instrumental = const i0.Value.absent(),
    this.remoteDurationMs = const i0.Value.absent(),
    this.fetchedAt = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  OnlineLyricsCompanion.insert({
    required String cacheKey,
    required String providerId,
    required String status,
    this.remoteId = const i0.Value.absent(),
    this.syncedText = const i0.Value.absent(),
    this.plainText = const i0.Value.absent(),
    this.instrumental = const i0.Value.absent(),
    this.remoteDurationMs = const i0.Value.absent(),
    required int fetchedAt,
    this.rowid = const i0.Value.absent(),
  }) : cacheKey = i0.Value(cacheKey),
       providerId = i0.Value(providerId),
       status = i0.Value(status),
       fetchedAt = i0.Value(fetchedAt);
  static i0.Insertable<i1.OnlineLyricsRow> custom({
    i0.Expression<String>? cacheKey,
    i0.Expression<String>? providerId,
    i0.Expression<String>? status,
    i0.Expression<String>? remoteId,
    i0.Expression<String>? syncedText,
    i0.Expression<String>? plainText,
    i0.Expression<bool>? instrumental,
    i0.Expression<int>? remoteDurationMs,
    i0.Expression<int>? fetchedAt,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (providerId != null) 'provider_id': providerId,
      if (status != null) 'status': status,
      if (remoteId != null) 'remote_id': remoteId,
      if (syncedText != null) 'synced_text': syncedText,
      if (plainText != null) 'plain_text': plainText,
      if (instrumental != null) 'instrumental': instrumental,
      if (remoteDurationMs != null) 'remote_duration_ms': remoteDurationMs,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i1.OnlineLyricsCompanion copyWith({
    i0.Value<String>? cacheKey,
    i0.Value<String>? providerId,
    i0.Value<String>? status,
    i0.Value<String?>? remoteId,
    i0.Value<String?>? syncedText,
    i0.Value<String?>? plainText,
    i0.Value<bool>? instrumental,
    i0.Value<int?>? remoteDurationMs,
    i0.Value<int>? fetchedAt,
    i0.Value<int>? rowid,
  }) {
    return i1.OnlineLyricsCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      providerId: providerId ?? this.providerId,
      status: status ?? this.status,
      remoteId: remoteId ?? this.remoteId,
      syncedText: syncedText ?? this.syncedText,
      plainText: plainText ?? this.plainText,
      instrumental: instrumental ?? this.instrumental,
      remoteDurationMs: remoteDurationMs ?? this.remoteDurationMs,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = i0.Variable<String>(cacheKey.value);
    }
    if (providerId.present) {
      map['provider_id'] = i0.Variable<String>(providerId.value);
    }
    if (status.present) {
      map['status'] = i0.Variable<String>(status.value);
    }
    if (remoteId.present) {
      map['remote_id'] = i0.Variable<String>(remoteId.value);
    }
    if (syncedText.present) {
      map['synced_text'] = i0.Variable<String>(syncedText.value);
    }
    if (plainText.present) {
      map['plain_text'] = i0.Variable<String>(plainText.value);
    }
    if (instrumental.present) {
      map['instrumental'] = i0.Variable<bool>(instrumental.value);
    }
    if (remoteDurationMs.present) {
      map['remote_duration_ms'] = i0.Variable<int>(remoteDurationMs.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = i0.Variable<int>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OnlineLyricsCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('providerId: $providerId, ')
          ..write('status: $status, ')
          ..write('remoteId: $remoteId, ')
          ..write('syncedText: $syncedText, ')
          ..write('plainText: $plainText, ')
          ..write('instrumental: $instrumental, ')
          ..write('remoteDurationMs: $remoteDurationMs, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}
