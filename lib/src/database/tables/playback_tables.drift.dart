// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:kanaru/src/database/tables/playback_tables.drift.dart' as i1;
import 'package:kanaru/src/database/tables/playback_tables.dart' as i2;
import 'package:drift/src/runtime/query_builder/query_builder.dart' as i3;
import 'package:kanaru/src/database/tables/library_track_tables.drift.dart'
    as i4;
import 'package:drift/internal/modular.dart' as i5;

typedef $$PlayLogTableCreateCompanionBuilder = i1.PlayLogCompanion Function({
  i0.Value<int> id,
  required String uid,
  required int trackId,
  required int playedAt,
  i0.Value<int?> listenedMs,
  required String deviceId,
  i0.Value<String?> contextKind,
  i0.Value<String?> contextRef,
  i0.Value<bool> skipped,
  required int updatedAt,
  i0.Value<int?> deletedAt,
});
typedef $$PlayLogTableUpdateCompanionBuilder = i1.PlayLogCompanion Function({
  i0.Value<int> id,
  i0.Value<String> uid,
  i0.Value<int> trackId,
  i0.Value<int> playedAt,
  i0.Value<int?> listenedMs,
  i0.Value<String> deviceId,
  i0.Value<String?> contextKind,
  i0.Value<String?> contextRef,
  i0.Value<bool> skipped,
  i0.Value<int> updatedAt,
  i0.Value<int?> deletedAt,
});

final class $$PlayLogTableReferences
    extends i0.BaseReferences<i0.GeneratedDatabase, i1.$PlayLogTable, i1.Play> {
  $$PlayLogTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static i4.$TracksTable _trackIdTable(i0.GeneratedDatabase db) =>
      i5.ReadDatabaseContainer(db)
          .resultSet<i4.$TracksTable>('tracks')
          .createAlias('play_log__track_id__tracks__id');

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

class $$PlayLogTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$PlayLogTable> {
  $$PlayLogTableFilterComposer({
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

  i0.ColumnFilters<int> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get listenedMs => $composableBuilder(
    column: $table.listenedMs,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get contextKind => $composableBuilder(
    column: $table.contextKind,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get contextRef => $composableBuilder(
    column: $table.contextRef,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<bool> get skipped => $composableBuilder(
    column: $table.skipped,
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

class $$PlayLogTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$PlayLogTable> {
  $$PlayLogTableOrderingComposer({
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

  i0.ColumnOrderings<int> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get listenedMs => $composableBuilder(
    column: $table.listenedMs,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get contextKind => $composableBuilder(
    column: $table.contextKind,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get contextRef => $composableBuilder(
    column: $table.contextRef,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<bool> get skipped => $composableBuilder(
    column: $table.skipped,
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

class $$PlayLogTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$PlayLogTable> {
  $$PlayLogTableAnnotationComposer({
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

  i0.GeneratedColumn<int> get playedAt =>
      $composableBuilder(column: $table.playedAt, builder: (column) => column);

  i0.GeneratedColumn<int> get listenedMs => $composableBuilder(
    column: $table.listenedMs,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  i0.GeneratedColumn<String> get contextKind => $composableBuilder(
    column: $table.contextKind,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get contextRef => $composableBuilder(
    column: $table.contextRef,
    builder: (column) => column,
  );

  i0.GeneratedColumn<bool> get skipped =>
      $composableBuilder(column: $table.skipped, builder: (column) => column);

  i0.GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  i0.GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

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

class $$PlayLogTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$PlayLogTable,
          i1.Play,
          i1.$$PlayLogTableFilterComposer,
          i1.$$PlayLogTableOrderingComposer,
          i1.$$PlayLogTableAnnotationComposer,
          $$PlayLogTableCreateCompanionBuilder,
          $$PlayLogTableUpdateCompanionBuilder,
          (i1.Play, i1.$$PlayLogTableReferences),
          i1.Play,
          i0.PrefetchHooks Function({bool trackId})
        > {
  $$PlayLogTableTableManager(i0.GeneratedDatabase db, i1.$PlayLogTable table)
    : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$PlayLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$PlayLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$PlayLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                i0.Value<String> uid = const i0.Value.absent(),
                i0.Value<int> trackId = const i0.Value.absent(),
                i0.Value<int> playedAt = const i0.Value.absent(),
                i0.Value<int?> listenedMs = const i0.Value.absent(),
                i0.Value<String> deviceId = const i0.Value.absent(),
                i0.Value<String?> contextKind = const i0.Value.absent(),
                i0.Value<String?> contextRef = const i0.Value.absent(),
                i0.Value<bool> skipped = const i0.Value.absent(),
                i0.Value<int> updatedAt = const i0.Value.absent(),
                i0.Value<int?> deletedAt = const i0.Value.absent(),
              }) => i1.PlayLogCompanion(
                id: id,
                uid: uid,
                trackId: trackId,
                playedAt: playedAt,
                listenedMs: listenedMs,
                deviceId: deviceId,
                contextKind: contextKind,
                contextRef: contextRef,
                skipped: skipped,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                required String uid,
                required int trackId,
                required int playedAt,
                i0.Value<int?> listenedMs = const i0.Value.absent(),
                required String deviceId,
                i0.Value<String?> contextKind = const i0.Value.absent(),
                i0.Value<String?> contextRef = const i0.Value.absent(),
                i0.Value<bool> skipped = const i0.Value.absent(),
                required int updatedAt,
                i0.Value<int?> deletedAt = const i0.Value.absent(),
              }) => i1.PlayLogCompanion.insert(
                id: id,
                uid: uid,
                trackId: trackId,
                playedAt: playedAt,
                listenedMs: listenedMs,
                deviceId: deviceId,
                contextKind: contextKind,
                contextRef: contextRef,
                skipped: skipped,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<i1.$PlayLogTable, i1.Play>(table),
                  i1.$$PlayLogTableReferences(db, table, e),
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
                        referencedTable: i1.$$PlayLogTableReferences
                            ._trackIdTable(db),
                        referencedColumn: i1.$$PlayLogTableReferences
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

typedef $$PlayLogTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$PlayLogTable,
      i1.Play,
      i1.$$PlayLogTableFilterComposer,
      i1.$$PlayLogTableOrderingComposer,
      i1.$$PlayLogTableAnnotationComposer,
      $$PlayLogTableCreateCompanionBuilder,
      $$PlayLogTableUpdateCompanionBuilder,
      (i1.Play, i1.$$PlayLogTableReferences),
      i1.Play,
      i0.PrefetchHooks Function({bool trackId})
    >;
typedef $$PlayStatsTableCreateCompanionBuilder =
    i1.PlayStatsCompanion Function({
      i0.Value<int> trackId,
      required int playCount,
      i0.Value<int> skipCount,
      i0.Value<int?> firstPlayedAt,
      i0.Value<int?> lastPlayedAt,
    });
typedef $$PlayStatsTableUpdateCompanionBuilder =
    i1.PlayStatsCompanion Function({
      i0.Value<int> trackId,
      i0.Value<int> playCount,
      i0.Value<int> skipCount,
      i0.Value<int?> firstPlayedAt,
      i0.Value<int?> lastPlayedAt,
    });

final class $$PlayStatsTableReferences
    extends
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$PlayStatsTable,
          i1.PlayStat
        > {
  $$PlayStatsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static i4.$TracksTable _trackIdTable(i0.GeneratedDatabase db) =>
      i5.ReadDatabaseContainer(db)
          .resultSet<i4.$TracksTable>('tracks')
          .createAlias('play_stats__track_id__tracks__id');

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

class $$PlayStatsTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$PlayStatsTable> {
  $$PlayStatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<int> get playCount => $composableBuilder(
    column: $table.playCount,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get skipCount => $composableBuilder(
    column: $table.skipCount,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get firstPlayedAt => $composableBuilder(
    column: $table.firstPlayedAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
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

class $$PlayStatsTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$PlayStatsTable> {
  $$PlayStatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<int> get playCount => $composableBuilder(
    column: $table.playCount,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get skipCount => $composableBuilder(
    column: $table.skipCount,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get firstPlayedAt => $composableBuilder(
    column: $table.firstPlayedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
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

class $$PlayStatsTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$PlayStatsTable> {
  $$PlayStatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<int> get playCount =>
      $composableBuilder(column: $table.playCount, builder: (column) => column);

  i0.GeneratedColumn<int> get skipCount =>
      $composableBuilder(column: $table.skipCount, builder: (column) => column);

  i0.GeneratedColumn<int> get firstPlayedAt => $composableBuilder(
    column: $table.firstPlayedAt,
    builder: (column) => column,
  );

  i0.GeneratedColumn<int> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
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

class $$PlayStatsTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$PlayStatsTable,
          i1.PlayStat,
          i1.$$PlayStatsTableFilterComposer,
          i1.$$PlayStatsTableOrderingComposer,
          i1.$$PlayStatsTableAnnotationComposer,
          $$PlayStatsTableCreateCompanionBuilder,
          $$PlayStatsTableUpdateCompanionBuilder,
          (i1.PlayStat, i1.$$PlayStatsTableReferences),
          i1.PlayStat,
          i0.PrefetchHooks Function({bool trackId})
        > {
  $$PlayStatsTableTableManager(
    i0.GeneratedDatabase db,
    i1.$PlayStatsTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$PlayStatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$PlayStatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$PlayStatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<int> trackId = const i0.Value.absent(),
                i0.Value<int> playCount = const i0.Value.absent(),
                i0.Value<int> skipCount = const i0.Value.absent(),
                i0.Value<int?> firstPlayedAt = const i0.Value.absent(),
                i0.Value<int?> lastPlayedAt = const i0.Value.absent(),
              }) => i1.PlayStatsCompanion(
                trackId: trackId,
                playCount: playCount,
                skipCount: skipCount,
                firstPlayedAt: firstPlayedAt,
                lastPlayedAt: lastPlayedAt,
              ),
          createCompanionCallback:
              ({
                i0.Value<int> trackId = const i0.Value.absent(),
                required int playCount,
                i0.Value<int> skipCount = const i0.Value.absent(),
                i0.Value<int?> firstPlayedAt = const i0.Value.absent(),
                i0.Value<int?> lastPlayedAt = const i0.Value.absent(),
              }) => i1.PlayStatsCompanion.insert(
                trackId: trackId,
                playCount: playCount,
                skipCount: skipCount,
                firstPlayedAt: firstPlayedAt,
                lastPlayedAt: lastPlayedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<i1.$PlayStatsTable, i1.PlayStat>(table),
                  i1.$$PlayStatsTableReferences(db, table, e),
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
                        referencedTable: i1.$$PlayStatsTableReferences
                            ._trackIdTable(db),
                        referencedColumn: i1.$$PlayStatsTableReferences
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

typedef $$PlayStatsTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$PlayStatsTable,
      i1.PlayStat,
      i1.$$PlayStatsTableFilterComposer,
      i1.$$PlayStatsTableOrderingComposer,
      i1.$$PlayStatsTableAnnotationComposer,
      $$PlayStatsTableCreateCompanionBuilder,
      $$PlayStatsTableUpdateCompanionBuilder,
      (i1.PlayStat, i1.$$PlayStatsTableReferences),
      i1.PlayStat,
      i0.PrefetchHooks Function({bool trackId})
    >;
i0.Index get playLogTrackPlayed => i0.Index(
  'play_log_track_played',
  'CREATE INDEX play_log_track_played ON play_log (track_id, deleted_at, played_at, skipped)',
);

class $PlayLogTable extends i2.PlayLog
    with i0.TableInfo<$PlayLogTable, i1.Play> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayLogTable(this.attachedDatabase, [this._alias]);
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
  static const i0.VerificationMeta _playedAtMeta = const i0.VerificationMeta(
    'playedAt',
  );
  @override
  late final i0.GeneratedColumn<int> playedAt = i0.GeneratedColumn<int>(
    'played_at',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _listenedMsMeta = const i0.VerificationMeta(
    'listenedMs',
  );
  @override
  late final i0.GeneratedColumn<int> listenedMs = i0.GeneratedColumn<int>(
    'listened_ms',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _deviceIdMeta = const i0.VerificationMeta(
    'deviceId',
  );
  @override
  late final i0.GeneratedColumn<String> deviceId = i0.GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _contextKindMeta = const i0.VerificationMeta(
    'contextKind',
  );
  @override
  late final i0.GeneratedColumn<String> contextKind =
      i0.GeneratedColumn<String>(
        'context_kind',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const i0.VerificationMeta _contextRefMeta = const i0.VerificationMeta(
    'contextRef',
  );
  @override
  late final i0.GeneratedColumn<String> contextRef = i0.GeneratedColumn<String>(
    'context_ref',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _skippedMeta = const i0.VerificationMeta(
    'skipped',
  );
  @override
  late final i0.GeneratedColumn<bool> skipped = i0.GeneratedColumn<bool>(
    'skipped',
    aliasedName,
    false,
    type: i0.DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
      'CHECK ("skipped" IN (0, 1))',
    ),
    defaultValue: const i3.Constant(false),
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
    trackId,
    playedAt,
    listenedMs,
    deviceId,
    contextKind,
    contextRef,
    skipped,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'play_log';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.Play> instance, {
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
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('played_at')) {
      context.handle(
        _playedAtMeta,
        playedAt.isAcceptableOrUnknown(data['played_at']!, _playedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_playedAtMeta);
    }
    if (data.containsKey('listened_ms')) {
      context.handle(
        _listenedMsMeta,
        listenedMs.isAcceptableOrUnknown(data['listened_ms']!, _listenedMsMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('context_kind')) {
      context.handle(
        _contextKindMeta,
        contextKind.isAcceptableOrUnknown(
          data['context_kind']!,
          _contextKindMeta,
        ),
      );
    }
    if (data.containsKey('context_ref')) {
      context.handle(
        _contextRefMeta,
        contextRef.isAcceptableOrUnknown(data['context_ref']!, _contextRefMeta),
      );
    }
    if (data.containsKey('skipped')) {
      context.handle(
        _skippedMeta,
        skipped.isAcceptableOrUnknown(data['skipped']!, _skippedMeta),
      );
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
  i1.Play map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.Play(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      )!,
      playedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}played_at'],
      )!,
      listenedMs: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}listened_ms'],
      ),
      deviceId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      contextKind: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}context_kind'],
      ),
      contextRef: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}context_ref'],
      ),
      skipped: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.bool,
        data['${effectivePrefix}skipped'],
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
  $PlayLogTable createAlias(String alias) {
    return $PlayLogTable(attachedDatabase, alias);
  }
}

class Play extends i0.DataClass implements i0.Insertable<i1.Play> {
  final int id;

  /// ULID.
  final String uid;
  final int trackId;
  final int playedAt;
  final int? listenedMs;

  /// Device that played; read from a file outside the database.
  final String deviceId;

  /// Where playback started (open text): album, artist, playlist, search...
  final String? contextKind;

  /// Context identifier: playlist uid, album key...
  final String? contextRef;

  /// True = skipped early; such a play does not count as played.
  final bool skipped;
  final int updatedAt;

  /// Tombstone for sync. Clearing history uses a hard delete.
  final int? deletedAt;
  const Play({
    required this.id,
    required this.uid,
    required this.trackId,
    required this.playedAt,
    this.listenedMs,
    required this.deviceId,
    this.contextKind,
    this.contextRef,
    required this.skipped,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id);
    map['uid'] = i0.Variable<String>(uid);
    map['track_id'] = i0.Variable<int>(trackId);
    map['played_at'] = i0.Variable<int>(playedAt);
    if (!nullToAbsent || listenedMs != null) {
      map['listened_ms'] = i0.Variable<int>(listenedMs);
    }
    map['device_id'] = i0.Variable<String>(deviceId);
    if (!nullToAbsent || contextKind != null) {
      map['context_kind'] = i0.Variable<String>(contextKind);
    }
    if (!nullToAbsent || contextRef != null) {
      map['context_ref'] = i0.Variable<String>(contextRef);
    }
    map['skipped'] = i0.Variable<bool>(skipped);
    map['updated_at'] = i0.Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = i0.Variable<int>(deletedAt);
    }
    return map;
  }

  i1.PlayLogCompanion toCompanion(bool nullToAbsent) {
    return i1.PlayLogCompanion(
      id: i0.Value(id),
      uid: i0.Value(uid),
      trackId: i0.Value(trackId),
      playedAt: i0.Value(playedAt),
      listenedMs: listenedMs == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(listenedMs),
      deviceId: i0.Value(deviceId),
      contextKind: contextKind == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(contextKind),
      contextRef: contextRef == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(contextRef),
      skipped: i0.Value(skipped),
      updatedAt: i0.Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(deletedAt),
    );
  }

  factory Play.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return Play(
      id: serializer.fromJson<int>(json['id']),
      uid: serializer.fromJson<String>(json['uid']),
      trackId: serializer.fromJson<int>(json['trackId']),
      playedAt: serializer.fromJson<int>(json['playedAt']),
      listenedMs: serializer.fromJson<int?>(json['listenedMs']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      contextKind: serializer.fromJson<String?>(json['contextKind']),
      contextRef: serializer.fromJson<String?>(json['contextRef']),
      skipped: serializer.fromJson<bool>(json['skipped']),
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
      'trackId': serializer.toJson<int>(trackId),
      'playedAt': serializer.toJson<int>(playedAt),
      'listenedMs': serializer.toJson<int?>(listenedMs),
      'deviceId': serializer.toJson<String>(deviceId),
      'contextKind': serializer.toJson<String?>(contextKind),
      'contextRef': serializer.toJson<String?>(contextRef),
      'skipped': serializer.toJson<bool>(skipped),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  i1.Play copyWith({
    int? id,
    String? uid,
    int? trackId,
    int? playedAt,
    i0.Value<int?> listenedMs = const i0.Value.absent(),
    String? deviceId,
    i0.Value<String?> contextKind = const i0.Value.absent(),
    i0.Value<String?> contextRef = const i0.Value.absent(),
    bool? skipped,
    int? updatedAt,
    i0.Value<int?> deletedAt = const i0.Value.absent(),
  }) => i1.Play(
    id: id ?? this.id,
    uid: uid ?? this.uid,
    trackId: trackId ?? this.trackId,
    playedAt: playedAt ?? this.playedAt,
    listenedMs: listenedMs.present ? listenedMs.value : this.listenedMs,
    deviceId: deviceId ?? this.deviceId,
    contextKind: contextKind.present ? contextKind.value : this.contextKind,
    contextRef: contextRef.present ? contextRef.value : this.contextRef,
    skipped: skipped ?? this.skipped,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Play copyWithCompanion(i1.PlayLogCompanion data) {
    return Play(
      id: data.id.present ? data.id.value : this.id,
      uid: data.uid.present ? data.uid.value : this.uid,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      playedAt: data.playedAt.present ? data.playedAt.value : this.playedAt,
      listenedMs: data.listenedMs.present
          ? data.listenedMs.value
          : this.listenedMs,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      contextKind: data.contextKind.present
          ? data.contextKind.value
          : this.contextKind,
      contextRef: data.contextRef.present
          ? data.contextRef.value
          : this.contextRef,
      skipped: data.skipped.present ? data.skipped.value : this.skipped,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Play(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('trackId: $trackId, ')
          ..write('playedAt: $playedAt, ')
          ..write('listenedMs: $listenedMs, ')
          ..write('deviceId: $deviceId, ')
          ..write('contextKind: $contextKind, ')
          ..write('contextRef: $contextRef, ')
          ..write('skipped: $skipped, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uid,
    trackId,
    playedAt,
    listenedMs,
    deviceId,
    contextKind,
    contextRef,
    skipped,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.Play &&
          other.id == this.id &&
          other.uid == this.uid &&
          other.trackId == this.trackId &&
          other.playedAt == this.playedAt &&
          other.listenedMs == this.listenedMs &&
          other.deviceId == this.deviceId &&
          other.contextKind == this.contextKind &&
          other.contextRef == this.contextRef &&
          other.skipped == this.skipped &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class PlayLogCompanion extends i0.UpdateCompanion<i1.Play> {
  final i0.Value<int> id;
  final i0.Value<String> uid;
  final i0.Value<int> trackId;
  final i0.Value<int> playedAt;
  final i0.Value<int?> listenedMs;
  final i0.Value<String> deviceId;
  final i0.Value<String?> contextKind;
  final i0.Value<String?> contextRef;
  final i0.Value<bool> skipped;
  final i0.Value<int> updatedAt;
  final i0.Value<int?> deletedAt;
  const PlayLogCompanion({
    this.id = const i0.Value.absent(),
    this.uid = const i0.Value.absent(),
    this.trackId = const i0.Value.absent(),
    this.playedAt = const i0.Value.absent(),
    this.listenedMs = const i0.Value.absent(),
    this.deviceId = const i0.Value.absent(),
    this.contextKind = const i0.Value.absent(),
    this.contextRef = const i0.Value.absent(),
    this.skipped = const i0.Value.absent(),
    this.updatedAt = const i0.Value.absent(),
    this.deletedAt = const i0.Value.absent(),
  });
  PlayLogCompanion.insert({
    this.id = const i0.Value.absent(),
    required String uid,
    required int trackId,
    required int playedAt,
    this.listenedMs = const i0.Value.absent(),
    required String deviceId,
    this.contextKind = const i0.Value.absent(),
    this.contextRef = const i0.Value.absent(),
    this.skipped = const i0.Value.absent(),
    required int updatedAt,
    this.deletedAt = const i0.Value.absent(),
  }) : uid = i0.Value(uid),
       trackId = i0.Value(trackId),
       playedAt = i0.Value(playedAt),
       deviceId = i0.Value(deviceId),
       updatedAt = i0.Value(updatedAt);
  static i0.Insertable<i1.Play> custom({
    i0.Expression<int>? id,
    i0.Expression<String>? uid,
    i0.Expression<int>? trackId,
    i0.Expression<int>? playedAt,
    i0.Expression<int>? listenedMs,
    i0.Expression<String>? deviceId,
    i0.Expression<String>? contextKind,
    i0.Expression<String>? contextRef,
    i0.Expression<bool>? skipped,
    i0.Expression<int>? updatedAt,
    i0.Expression<int>? deletedAt,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (uid != null) 'uid': uid,
      if (trackId != null) 'track_id': trackId,
      if (playedAt != null) 'played_at': playedAt,
      if (listenedMs != null) 'listened_ms': listenedMs,
      if (deviceId != null) 'device_id': deviceId,
      if (contextKind != null) 'context_kind': contextKind,
      if (contextRef != null) 'context_ref': contextRef,
      if (skipped != null) 'skipped': skipped,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  i1.PlayLogCompanion copyWith({
    i0.Value<int>? id,
    i0.Value<String>? uid,
    i0.Value<int>? trackId,
    i0.Value<int>? playedAt,
    i0.Value<int?>? listenedMs,
    i0.Value<String>? deviceId,
    i0.Value<String?>? contextKind,
    i0.Value<String?>? contextRef,
    i0.Value<bool>? skipped,
    i0.Value<int>? updatedAt,
    i0.Value<int?>? deletedAt,
  }) {
    return i1.PlayLogCompanion(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      trackId: trackId ?? this.trackId,
      playedAt: playedAt ?? this.playedAt,
      listenedMs: listenedMs ?? this.listenedMs,
      deviceId: deviceId ?? this.deviceId,
      contextKind: contextKind ?? this.contextKind,
      contextRef: contextRef ?? this.contextRef,
      skipped: skipped ?? this.skipped,
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
    if (trackId.present) {
      map['track_id'] = i0.Variable<int>(trackId.value);
    }
    if (playedAt.present) {
      map['played_at'] = i0.Variable<int>(playedAt.value);
    }
    if (listenedMs.present) {
      map['listened_ms'] = i0.Variable<int>(listenedMs.value);
    }
    if (deviceId.present) {
      map['device_id'] = i0.Variable<String>(deviceId.value);
    }
    if (contextKind.present) {
      map['context_kind'] = i0.Variable<String>(contextKind.value);
    }
    if (contextRef.present) {
      map['context_ref'] = i0.Variable<String>(contextRef.value);
    }
    if (skipped.present) {
      map['skipped'] = i0.Variable<bool>(skipped.value);
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
    return (StringBuffer('PlayLogCompanion(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('trackId: $trackId, ')
          ..write('playedAt: $playedAt, ')
          ..write('listenedMs: $listenedMs, ')
          ..write('deviceId: $deviceId, ')
          ..write('contextKind: $contextKind, ')
          ..write('contextRef: $contextRef, ')
          ..write('skipped: $skipped, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

i0.Index get playLogPlayedAt => i0.Index(
  'play_log_played_at',
  'CREATE INDEX play_log_played_at ON play_log (played_at, track_id, skipped, deleted_at) WHERE deleted_at IS NULL',
);
i0.Index get playStatsLast => i0.Index(
  'play_stats_last',
  'CREATE INDEX play_stats_last ON play_stats (last_played_at) WHERE last_played_at IS NOT NULL',
);

class $PlayStatsTable extends i2.PlayStats
    with i0.TableInfo<$PlayStatsTable, i1.PlayStat> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayStatsTable(this.attachedDatabase, [this._alias]);
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
  static const i0.VerificationMeta _playCountMeta = const i0.VerificationMeta(
    'playCount',
  );
  @override
  late final i0.GeneratedColumn<int> playCount = i0.GeneratedColumn<int>(
    'play_count',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _skipCountMeta = const i0.VerificationMeta(
    'skipCount',
  );
  @override
  late final i0.GeneratedColumn<int> skipCount = i0.GeneratedColumn<int>(
    'skip_count',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const i3.Constant(0),
  );
  static const i0.VerificationMeta _firstPlayedAtMeta =
      const i0.VerificationMeta('firstPlayedAt');
  @override
  late final i0.GeneratedColumn<int> firstPlayedAt = i0.GeneratedColumn<int>(
    'first_played_at',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _lastPlayedAtMeta =
      const i0.VerificationMeta('lastPlayedAt');
  @override
  late final i0.GeneratedColumn<int> lastPlayedAt = i0.GeneratedColumn<int>(
    'last_played_at',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<i0.GeneratedColumn> get $columns => [
    trackId,
    playCount,
    skipCount,
    firstPlayedAt,
    lastPlayedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'play_stats';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.PlayStat> instance, {
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
    if (data.containsKey('play_count')) {
      context.handle(
        _playCountMeta,
        playCount.isAcceptableOrUnknown(data['play_count']!, _playCountMeta),
      );
    } else if (isInserting) {
      context.missing(_playCountMeta);
    }
    if (data.containsKey('skip_count')) {
      context.handle(
        _skipCountMeta,
        skipCount.isAcceptableOrUnknown(data['skip_count']!, _skipCountMeta),
      );
    }
    if (data.containsKey('first_played_at')) {
      context.handle(
        _firstPlayedAtMeta,
        firstPlayedAt.isAcceptableOrUnknown(
          data['first_played_at']!,
          _firstPlayedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_played_at')) {
      context.handle(
        _lastPlayedAtMeta,
        lastPlayedAt.isAcceptableOrUnknown(
          data['last_played_at']!,
          _lastPlayedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {trackId};
  @override
  i1.PlayStat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.PlayStat(
      trackId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      )!,
      playCount: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}play_count'],
      )!,
      skipCount: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}skip_count'],
      )!,
      firstPlayedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}first_played_at'],
      ),
      lastPlayedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}last_played_at'],
      ),
    );
  }

  @override
  $PlayStatsTable createAlias(String alias) {
    return $PlayStatsTable(attachedDatabase, alias);
  }
}

class PlayStat extends i0.DataClass implements i0.Insertable<i1.PlayStat> {
  final int trackId;

  /// Live plays with `skipped = 0`.
  final int playCount;

  /// Live plays with `skipped = 1`.
  final int skipCount;

  /// Earliest non-skipped play.
  final int? firstPlayedAt;

  /// Latest non-skipped play; NULL while the track was only skipped.
  final int? lastPlayedAt;
  const PlayStat({
    required this.trackId,
    required this.playCount,
    required this.skipCount,
    this.firstPlayedAt,
    this.lastPlayedAt,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['track_id'] = i0.Variable<int>(trackId);
    map['play_count'] = i0.Variable<int>(playCount);
    map['skip_count'] = i0.Variable<int>(skipCount);
    if (!nullToAbsent || firstPlayedAt != null) {
      map['first_played_at'] = i0.Variable<int>(firstPlayedAt);
    }
    if (!nullToAbsent || lastPlayedAt != null) {
      map['last_played_at'] = i0.Variable<int>(lastPlayedAt);
    }
    return map;
  }

  i1.PlayStatsCompanion toCompanion(bool nullToAbsent) {
    return i1.PlayStatsCompanion(
      trackId: i0.Value(trackId),
      playCount: i0.Value(playCount),
      skipCount: i0.Value(skipCount),
      firstPlayedAt: firstPlayedAt == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(firstPlayedAt),
      lastPlayedAt: lastPlayedAt == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(lastPlayedAt),
    );
  }

  factory PlayStat.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return PlayStat(
      trackId: serializer.fromJson<int>(json['trackId']),
      playCount: serializer.fromJson<int>(json['playCount']),
      skipCount: serializer.fromJson<int>(json['skipCount']),
      firstPlayedAt: serializer.fromJson<int?>(json['firstPlayedAt']),
      lastPlayedAt: serializer.fromJson<int?>(json['lastPlayedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trackId': serializer.toJson<int>(trackId),
      'playCount': serializer.toJson<int>(playCount),
      'skipCount': serializer.toJson<int>(skipCount),
      'firstPlayedAt': serializer.toJson<int?>(firstPlayedAt),
      'lastPlayedAt': serializer.toJson<int?>(lastPlayedAt),
    };
  }

  i1.PlayStat copyWith({
    int? trackId,
    int? playCount,
    int? skipCount,
    i0.Value<int?> firstPlayedAt = const i0.Value.absent(),
    i0.Value<int?> lastPlayedAt = const i0.Value.absent(),
  }) => i1.PlayStat(
    trackId: trackId ?? this.trackId,
    playCount: playCount ?? this.playCount,
    skipCount: skipCount ?? this.skipCount,
    firstPlayedAt: firstPlayedAt.present
        ? firstPlayedAt.value
        : this.firstPlayedAt,
    lastPlayedAt: lastPlayedAt.present ? lastPlayedAt.value : this.lastPlayedAt,
  );
  PlayStat copyWithCompanion(i1.PlayStatsCompanion data) {
    return PlayStat(
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      playCount: data.playCount.present ? data.playCount.value : this.playCount,
      skipCount: data.skipCount.present ? data.skipCount.value : this.skipCount,
      firstPlayedAt: data.firstPlayedAt.present
          ? data.firstPlayedAt.value
          : this.firstPlayedAt,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayStat(')
          ..write('trackId: $trackId, ')
          ..write('playCount: $playCount, ')
          ..write('skipCount: $skipCount, ')
          ..write('firstPlayedAt: $firstPlayedAt, ')
          ..write('lastPlayedAt: $lastPlayedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(trackId, playCount, skipCount, firstPlayedAt, lastPlayedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.PlayStat &&
          other.trackId == this.trackId &&
          other.playCount == this.playCount &&
          other.skipCount == this.skipCount &&
          other.firstPlayedAt == this.firstPlayedAt &&
          other.lastPlayedAt == this.lastPlayedAt);
}

class PlayStatsCompanion extends i0.UpdateCompanion<i1.PlayStat> {
  final i0.Value<int> trackId;
  final i0.Value<int> playCount;
  final i0.Value<int> skipCount;
  final i0.Value<int?> firstPlayedAt;
  final i0.Value<int?> lastPlayedAt;
  const PlayStatsCompanion({
    this.trackId = const i0.Value.absent(),
    this.playCount = const i0.Value.absent(),
    this.skipCount = const i0.Value.absent(),
    this.firstPlayedAt = const i0.Value.absent(),
    this.lastPlayedAt = const i0.Value.absent(),
  });
  PlayStatsCompanion.insert({
    this.trackId = const i0.Value.absent(),
    required int playCount,
    this.skipCount = const i0.Value.absent(),
    this.firstPlayedAt = const i0.Value.absent(),
    this.lastPlayedAt = const i0.Value.absent(),
  }) : playCount = i0.Value(playCount);
  static i0.Insertable<i1.PlayStat> custom({
    i0.Expression<int>? trackId,
    i0.Expression<int>? playCount,
    i0.Expression<int>? skipCount,
    i0.Expression<int>? firstPlayedAt,
    i0.Expression<int>? lastPlayedAt,
  }) {
    return i0.RawValuesInsertable({
      if (trackId != null) 'track_id': trackId,
      if (playCount != null) 'play_count': playCount,
      if (skipCount != null) 'skip_count': skipCount,
      if (firstPlayedAt != null) 'first_played_at': firstPlayedAt,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
    });
  }

  i1.PlayStatsCompanion copyWith({
    i0.Value<int>? trackId,
    i0.Value<int>? playCount,
    i0.Value<int>? skipCount,
    i0.Value<int?>? firstPlayedAt,
    i0.Value<int?>? lastPlayedAt,
  }) {
    return i1.PlayStatsCompanion(
      trackId: trackId ?? this.trackId,
      playCount: playCount ?? this.playCount,
      skipCount: skipCount ?? this.skipCount,
      firstPlayedAt: firstPlayedAt ?? this.firstPlayedAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (trackId.present) {
      map['track_id'] = i0.Variable<int>(trackId.value);
    }
    if (playCount.present) {
      map['play_count'] = i0.Variable<int>(playCount.value);
    }
    if (skipCount.present) {
      map['skip_count'] = i0.Variable<int>(skipCount.value);
    }
    if (firstPlayedAt.present) {
      map['first_played_at'] = i0.Variable<int>(firstPlayedAt.value);
    }
    if (lastPlayedAt.present) {
      map['last_played_at'] = i0.Variable<int>(lastPlayedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayStatsCompanion(')
          ..write('trackId: $trackId, ')
          ..write('playCount: $playCount, ')
          ..write('skipCount: $skipCount, ')
          ..write('firstPlayedAt: $firstPlayedAt, ')
          ..write('lastPlayedAt: $lastPlayedAt')
          ..write(')'))
        .toString();
  }
}
