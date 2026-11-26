// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:kanaru/src/database/tables/ai_tables.drift.dart' as i1;
import 'package:kanaru/src/database/tables/ai_tables.dart' as i2;
import 'package:drift/src/runtime/query_builder/query_builder.dart' as i3;
import 'package:drift/internal/modular.dart' as i4;

typedef $$AiConversationsTableCreateCompanionBuilder =
    i1.AiConversationsCompanion Function({
      i0.Value<int> id,
      required String title,
      i0.Value<bool> titleAuto,
      i0.Value<String?> installId,
      i0.Value<int?> installGeneration,
      i0.Value<String?> model,
      required String permission,
      required int createdAt,
      required int updatedAt,
      required int lastMessageAt,
    });
typedef $$AiConversationsTableUpdateCompanionBuilder =
    i1.AiConversationsCompanion Function({
      i0.Value<int> id,
      i0.Value<String> title,
      i0.Value<bool> titleAuto,
      i0.Value<String?> installId,
      i0.Value<int?> installGeneration,
      i0.Value<String?> model,
      i0.Value<String> permission,
      i0.Value<int> createdAt,
      i0.Value<int> updatedAt,
      i0.Value<int> lastMessageAt,
    });

final class $$AiConversationsTableReferences
    extends
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$AiConversationsTable,
          i1.AiConversationRow
        > {
  $$AiConversationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static i0.MultiTypedResultKey<i1.$AiMessagesTable, List<i1.AiMessageRow>>
  _aiMessagesRefsTable(i0.GeneratedDatabase db) =>
      i0.MultiTypedResultKey.fromTable(
        i4.ReadDatabaseContainer(db)
            .resultSet<i1.$AiMessagesTable>('ai_messages'),
        aliasName: 'ai_conversations__id__ai_messages__conversation_id',
      );

  i1.$$AiMessagesTableProcessedTableManager get aiMessagesRefs {
    final manager = i1
        .$$AiMessagesTableTableManager(
          $_db,
          i4.ReadDatabaseContainer($_db)
              .resultSet<i1.$AiMessagesTable>('ai_messages'),
        )
        .filter((f) => f.conversationId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_aiMessagesRefsTable($_db));
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AiConversationsTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$AiConversationsTable> {
  $$AiConversationsTableFilterComposer({
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

  i0.ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<bool> get titleAuto => $composableBuilder(
    column: $table.titleAuto,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get installGeneration => $composableBuilder(
    column: $table.installGeneration,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get permission => $composableBuilder(
    column: $table.permission,
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

  i0.ColumnFilters<int> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.Expression<bool> aiMessagesRefs(
    i0.Expression<bool> Function(i1.$$AiMessagesTableFilterComposer f) f,
  ) {
    final i1.$$AiMessagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i4.ReadDatabaseContainer($db)
          .resultSet<i1.$AiMessagesTable>('ai_messages'),
      getReferencedColumn: (t) => t.conversationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i1.$$AiMessagesTableFilterComposer(
            $db: $db,
            $table: i4.ReadDatabaseContainer($db)
                .resultSet<i1.$AiMessagesTable>('ai_messages'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AiConversationsTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$AiConversationsTable> {
  $$AiConversationsTableOrderingComposer({
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

  i0.ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<bool> get titleAuto => $composableBuilder(
    column: $table.titleAuto,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get installGeneration => $composableBuilder(
    column: $table.installGeneration,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get permission => $composableBuilder(
    column: $table.permission,
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

  i0.ColumnOrderings<int> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $$AiConversationsTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$AiConversationsTable> {
  $$AiConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  i0.GeneratedColumn<bool> get titleAuto =>
      $composableBuilder(column: $table.titleAuto, builder: (column) => column);

  i0.GeneratedColumn<String> get installId =>
      $composableBuilder(column: $table.installId, builder: (column) => column);

  i0.GeneratedColumn<int> get installGeneration => $composableBuilder(
    column: $table.installGeneration,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  i0.GeneratedColumn<String> get permission => $composableBuilder(
    column: $table.permission,
    builder: (column) => column,
  );

  i0.GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  i0.GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  i0.GeneratedColumn<int> get lastMessageAt => $composableBuilder(
    column: $table.lastMessageAt,
    builder: (column) => column,
  );

  i0.Expression<T> aiMessagesRefs<T extends Object>(
    i0.Expression<T> Function(i1.$$AiMessagesTableAnnotationComposer a) f,
  ) {
    final i1.$$AiMessagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i4.ReadDatabaseContainer($db)
          .resultSet<i1.$AiMessagesTable>('ai_messages'),
      getReferencedColumn: (t) => t.conversationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i1.$$AiMessagesTableAnnotationComposer(
            $db: $db,
            $table: i4.ReadDatabaseContainer($db)
                .resultSet<i1.$AiMessagesTable>('ai_messages'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AiConversationsTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$AiConversationsTable,
          i1.AiConversationRow,
          i1.$$AiConversationsTableFilterComposer,
          i1.$$AiConversationsTableOrderingComposer,
          i1.$$AiConversationsTableAnnotationComposer,
          $$AiConversationsTableCreateCompanionBuilder,
          $$AiConversationsTableUpdateCompanionBuilder,
          (i1.AiConversationRow, i1.$$AiConversationsTableReferences),
          i1.AiConversationRow,
          i0.PrefetchHooks Function({bool aiMessagesRefs})
        > {
  $$AiConversationsTableTableManager(
    i0.GeneratedDatabase db,
    i1.$AiConversationsTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$AiConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$AiConversationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => i1
              .$$AiConversationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                i0.Value<String> title = const i0.Value.absent(),
                i0.Value<bool> titleAuto = const i0.Value.absent(),
                i0.Value<String?> installId = const i0.Value.absent(),
                i0.Value<int?> installGeneration = const i0.Value.absent(),
                i0.Value<String?> model = const i0.Value.absent(),
                i0.Value<String> permission = const i0.Value.absent(),
                i0.Value<int> createdAt = const i0.Value.absent(),
                i0.Value<int> updatedAt = const i0.Value.absent(),
                i0.Value<int> lastMessageAt = const i0.Value.absent(),
              }) => i1.AiConversationsCompanion(
                id: id,
                title: title,
                titleAuto: titleAuto,
                installId: installId,
                installGeneration: installGeneration,
                model: model,
                permission: permission,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastMessageAt: lastMessageAt,
              ),
          createCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                required String title,
                i0.Value<bool> titleAuto = const i0.Value.absent(),
                i0.Value<String?> installId = const i0.Value.absent(),
                i0.Value<int?> installGeneration = const i0.Value.absent(),
                i0.Value<String?> model = const i0.Value.absent(),
                required String permission,
                required int createdAt,
                required int updatedAt,
                required int lastMessageAt,
              }) => i1.AiConversationsCompanion.insert(
                id: id,
                title: title,
                titleAuto: titleAuto,
                installId: installId,
                installGeneration: installGeneration,
                model: model,
                permission: permission,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastMessageAt: lastMessageAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<i1.$AiConversationsTable, i1.AiConversationRow>(
                    table,
                  ),
                  i1.$$AiConversationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({aiMessagesRefs = false}) {
            return i0.PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (aiMessagesRefs)
                  i4.ReadDatabaseContainer(db)
                      .resultSet<i1.$AiMessagesTable>('ai_messages'),
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (aiMessagesRefs)
                    await i0.$_getPrefetchedDataByColumns<
                      i1.AiConversationRow,
                      i1.$AiConversationsTable,
                      i1.AiMessageRow,
                      i1.$AiMessagesTable
                    >(
                      currentTable: table,
                      referencedTable: i1.$$AiConversationsTableReferences
                          ._aiMessagesRefsTable(db),
                      managerFromTypedResult: (p0) => i1
                          .$$AiConversationsTableReferences(db, table, p0)
                          .aiMessagesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'conversation_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AiConversationsTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$AiConversationsTable,
      i1.AiConversationRow,
      i1.$$AiConversationsTableFilterComposer,
      i1.$$AiConversationsTableOrderingComposer,
      i1.$$AiConversationsTableAnnotationComposer,
      $$AiConversationsTableCreateCompanionBuilder,
      $$AiConversationsTableUpdateCompanionBuilder,
      (i1.AiConversationRow, i1.$$AiConversationsTableReferences),
      i1.AiConversationRow,
      i0.PrefetchHooks Function({bool aiMessagesRefs})
    >;
typedef $$AiMessagesTableCreateCompanionBuilder =
    i1.AiMessagesCompanion Function({
      i0.Value<int> id,
      required int conversationId,
      required int seq,
      required String role,
      required String partsJson,
      i0.Value<String?> liveText,
      i0.Value<String?> providerJson,
      i0.Value<String?> installId,
      i0.Value<int?> pluginVersion,
      i0.Value<int?> installGeneration,
      i0.Value<String?> model,
      required String state,
      i0.Value<String?> errorJson,
      i0.Value<String?> usageJson,
      required int createdAt,
    });
typedef $$AiMessagesTableUpdateCompanionBuilder =
    i1.AiMessagesCompanion Function({
      i0.Value<int> id,
      i0.Value<int> conversationId,
      i0.Value<int> seq,
      i0.Value<String> role,
      i0.Value<String> partsJson,
      i0.Value<String?> liveText,
      i0.Value<String?> providerJson,
      i0.Value<String?> installId,
      i0.Value<int?> pluginVersion,
      i0.Value<int?> installGeneration,
      i0.Value<String?> model,
      i0.Value<String> state,
      i0.Value<String?> errorJson,
      i0.Value<String?> usageJson,
      i0.Value<int> createdAt,
    });

final class $$AiMessagesTableReferences
    extends
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$AiMessagesTable,
          i1.AiMessageRow
        > {
  $$AiMessagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static i1.$AiConversationsTable _conversationIdTable(
    i0.GeneratedDatabase db,
  ) =>
      i4.ReadDatabaseContainer(db)
          .resultSet<i1.$AiConversationsTable>('ai_conversations')
          .createAlias('ai_messages__conversation_id__ai_conversations__id');

  i1.$$AiConversationsTableProcessedTableManager get conversationId {
    final $_column = $_itemColumn<int>('conversation_id')!;

    final manager = i1
        .$$AiConversationsTableTableManager(
          $_db,
          i4.ReadDatabaseContainer($_db)
              .resultSet<i1.$AiConversationsTable>('ai_conversations'),
        )
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_conversationIdTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AiMessagesTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$AiMessagesTable> {
  $$AiMessagesTableFilterComposer({
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

  i0.ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get partsJson => $composableBuilder(
    column: $table.partsJson,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get liveText => $composableBuilder(
    column: $table.liveText,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get providerJson => $composableBuilder(
    column: $table.providerJson,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get pluginVersion => $composableBuilder(
    column: $table.pluginVersion,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get installGeneration => $composableBuilder(
    column: $table.installGeneration,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get errorJson => $composableBuilder(
    column: $table.errorJson,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get usageJson => $composableBuilder(
    column: $table.usageJson,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i1.$$AiConversationsTableFilterComposer get conversationId {
    final i1.$$AiConversationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: i4.ReadDatabaseContainer($db)
          .resultSet<i1.$AiConversationsTable>('ai_conversations'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i1.$$AiConversationsTableFilterComposer(
            $db: $db,
            $table: i4.ReadDatabaseContainer($db)
                .resultSet<i1.$AiConversationsTable>('ai_conversations'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AiMessagesTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$AiMessagesTable> {
  $$AiMessagesTableOrderingComposer({
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

  i0.ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get partsJson => $composableBuilder(
    column: $table.partsJson,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get liveText => $composableBuilder(
    column: $table.liveText,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get providerJson => $composableBuilder(
    column: $table.providerJson,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get pluginVersion => $composableBuilder(
    column: $table.pluginVersion,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get installGeneration => $composableBuilder(
    column: $table.installGeneration,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get errorJson => $composableBuilder(
    column: $table.errorJson,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get usageJson => $composableBuilder(
    column: $table.usageJson,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i1.$$AiConversationsTableOrderingComposer get conversationId {
    final i1.$$AiConversationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.conversationId,
      referencedTable: i4.ReadDatabaseContainer($db)
          .resultSet<i1.$AiConversationsTable>('ai_conversations'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i1.$$AiConversationsTableOrderingComposer(
            $db: $db,
            $table: i4.ReadDatabaseContainer($db)
                .resultSet<i1.$AiConversationsTable>('ai_conversations'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AiMessagesTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$AiMessagesTable> {
  $$AiMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  i0.GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  i0.GeneratedColumn<String> get partsJson =>
      $composableBuilder(column: $table.partsJson, builder: (column) => column);

  i0.GeneratedColumn<String> get liveText =>
      $composableBuilder(column: $table.liveText, builder: (column) => column);

  i0.GeneratedColumn<String> get providerJson => $composableBuilder(
    column: $table.providerJson,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get installId =>
      $composableBuilder(column: $table.installId, builder: (column) => column);

  i0.GeneratedColumn<int> get pluginVersion => $composableBuilder(
    column: $table.pluginVersion,
    builder: (column) => column,
  );

  i0.GeneratedColumn<int> get installGeneration => $composableBuilder(
    column: $table.installGeneration,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  i0.GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  i0.GeneratedColumn<String> get errorJson =>
      $composableBuilder(column: $table.errorJson, builder: (column) => column);

  i0.GeneratedColumn<String> get usageJson =>
      $composableBuilder(column: $table.usageJson, builder: (column) => column);

  i0.GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  i1.$$AiConversationsTableAnnotationComposer get conversationId {
    final i1.$$AiConversationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.conversationId,
          referencedTable: i4.ReadDatabaseContainer($db)
              .resultSet<i1.$AiConversationsTable>('ai_conversations'),
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => i1.$$AiConversationsTableAnnotationComposer(
                $db: $db,
                $table: i4.ReadDatabaseContainer($db)
                    .resultSet<i1.$AiConversationsTable>('ai_conversations'),
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$AiMessagesTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$AiMessagesTable,
          i1.AiMessageRow,
          i1.$$AiMessagesTableFilterComposer,
          i1.$$AiMessagesTableOrderingComposer,
          i1.$$AiMessagesTableAnnotationComposer,
          $$AiMessagesTableCreateCompanionBuilder,
          $$AiMessagesTableUpdateCompanionBuilder,
          (i1.AiMessageRow, i1.$$AiMessagesTableReferences),
          i1.AiMessageRow,
          i0.PrefetchHooks Function({bool conversationId})
        > {
  $$AiMessagesTableTableManager(
    i0.GeneratedDatabase db,
    i1.$AiMessagesTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$AiMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$AiMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$AiMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                i0.Value<int> conversationId = const i0.Value.absent(),
                i0.Value<int> seq = const i0.Value.absent(),
                i0.Value<String> role = const i0.Value.absent(),
                i0.Value<String> partsJson = const i0.Value.absent(),
                i0.Value<String?> liveText = const i0.Value.absent(),
                i0.Value<String?> providerJson = const i0.Value.absent(),
                i0.Value<String?> installId = const i0.Value.absent(),
                i0.Value<int?> pluginVersion = const i0.Value.absent(),
                i0.Value<int?> installGeneration = const i0.Value.absent(),
                i0.Value<String?> model = const i0.Value.absent(),
                i0.Value<String> state = const i0.Value.absent(),
                i0.Value<String?> errorJson = const i0.Value.absent(),
                i0.Value<String?> usageJson = const i0.Value.absent(),
                i0.Value<int> createdAt = const i0.Value.absent(),
              }) => i1.AiMessagesCompanion(
                id: id,
                conversationId: conversationId,
                seq: seq,
                role: role,
                partsJson: partsJson,
                liveText: liveText,
                providerJson: providerJson,
                installId: installId,
                pluginVersion: pluginVersion,
                installGeneration: installGeneration,
                model: model,
                state: state,
                errorJson: errorJson,
                usageJson: usageJson,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                required int conversationId,
                required int seq,
                required String role,
                required String partsJson,
                i0.Value<String?> liveText = const i0.Value.absent(),
                i0.Value<String?> providerJson = const i0.Value.absent(),
                i0.Value<String?> installId = const i0.Value.absent(),
                i0.Value<int?> pluginVersion = const i0.Value.absent(),
                i0.Value<int?> installGeneration = const i0.Value.absent(),
                i0.Value<String?> model = const i0.Value.absent(),
                required String state,
                i0.Value<String?> errorJson = const i0.Value.absent(),
                i0.Value<String?> usageJson = const i0.Value.absent(),
                required int createdAt,
              }) => i1.AiMessagesCompanion.insert(
                id: id,
                conversationId: conversationId,
                seq: seq,
                role: role,
                partsJson: partsJson,
                liveText: liveText,
                providerJson: providerJson,
                installId: installId,
                pluginVersion: pluginVersion,
                installGeneration: installGeneration,
                model: model,
                state: state,
                errorJson: errorJson,
                usageJson: usageJson,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<i1.$AiMessagesTable, i1.AiMessageRow>(table),
                  i1.$$AiMessagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({conversationId = false}) {
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
                    if (conversationId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.conversationId,
                        referencedTable: i1.$$AiMessagesTableReferences
                            ._conversationIdTable(db),
                        referencedColumn: i1.$$AiMessagesTableReferences
                            ._conversationIdTable(db)
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

typedef $$AiMessagesTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$AiMessagesTable,
      i1.AiMessageRow,
      i1.$$AiMessagesTableFilterComposer,
      i1.$$AiMessagesTableOrderingComposer,
      i1.$$AiMessagesTableAnnotationComposer,
      $$AiMessagesTableCreateCompanionBuilder,
      $$AiMessagesTableUpdateCompanionBuilder,
      (i1.AiMessageRow, i1.$$AiMessagesTableReferences),
      i1.AiMessageRow,
      i0.PrefetchHooks Function({bool conversationId})
    >;
i0.Index get aiConversationsLastMessage => i0.Index(
  'ai_conversations_last_message',
  'CREATE INDEX ai_conversations_last_message ON ai_conversations (last_message_at)',
);

class $AiConversationsTable extends i2.AiConversations
    with i0.TableInfo<$AiConversationsTable, i1.AiConversationRow> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiConversationsTable(this.attachedDatabase, [this._alias]);
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
  static const i0.VerificationMeta _titleMeta = const i0.VerificationMeta(
    'title',
  );
  @override
  late final i0.GeneratedColumn<String> title = i0.GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _titleAutoMeta = const i0.VerificationMeta(
    'titleAuto',
  );
  @override
  late final i0.GeneratedColumn<bool> titleAuto = i0.GeneratedColumn<bool>(
    'title_auto',
    aliasedName,
    false,
    type: i0.DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
      'CHECK ("title_auto" IN (0, 1))',
    ),
    defaultValue: const i3.Constant(true),
  );
  static const i0.VerificationMeta _installIdMeta = const i0.VerificationMeta(
    'installId',
  );
  @override
  late final i0.GeneratedColumn<String> installId = i0.GeneratedColumn<String>(
    'install_id',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _installGenerationMeta =
      const i0.VerificationMeta('installGeneration');
  @override
  late final i0.GeneratedColumn<int> installGeneration =
      i0.GeneratedColumn<int>(
        'install_generation',
        aliasedName,
        true,
        type: i0.DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const i0.VerificationMeta _modelMeta = const i0.VerificationMeta(
    'model',
  );
  @override
  late final i0.GeneratedColumn<String> model = i0.GeneratedColumn<String>(
    'model',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _permissionMeta = const i0.VerificationMeta(
    'permission',
  );
  @override
  late final i0.GeneratedColumn<String> permission = i0.GeneratedColumn<String>(
    'permission',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const i0.VerificationMeta _lastMessageAtMeta =
      const i0.VerificationMeta('lastMessageAt');
  @override
  late final i0.GeneratedColumn<int> lastMessageAt = i0.GeneratedColumn<int>(
    'last_message_at',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<i0.GeneratedColumn> get $columns => [
    id,
    title,
    titleAuto,
    installId,
    installGeneration,
    model,
    permission,
    createdAt,
    updatedAt,
    lastMessageAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_conversations';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.AiConversationRow> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('title_auto')) {
      context.handle(
        _titleAutoMeta,
        titleAuto.isAcceptableOrUnknown(data['title_auto']!, _titleAutoMeta),
      );
    }
    if (data.containsKey('install_id')) {
      context.handle(
        _installIdMeta,
        installId.isAcceptableOrUnknown(data['install_id']!, _installIdMeta),
      );
    }
    if (data.containsKey('install_generation')) {
      context.handle(
        _installGenerationMeta,
        installGeneration.isAcceptableOrUnknown(
          data['install_generation']!,
          _installGenerationMeta,
        ),
      );
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('permission')) {
      context.handle(
        _permissionMeta,
        permission.isAcceptableOrUnknown(data['permission']!, _permissionMeta),
      );
    } else if (isInserting) {
      context.missing(_permissionMeta);
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
    if (data.containsKey('last_message_at')) {
      context.handle(
        _lastMessageAtMeta,
        lastMessageAt.isAcceptableOrUnknown(
          data['last_message_at']!,
          _lastMessageAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastMessageAtMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i1.AiConversationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.AiConversationRow(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      titleAuto: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.bool,
        data['${effectivePrefix}title_auto'],
      )!,
      installId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}install_id'],
      ),
      installGeneration: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}install_generation'],
      ),
      model: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}model'],
      ),
      permission: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}permission'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      lastMessageAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}last_message_at'],
      )!,
    );
  }

  @override
  $AiConversationsTable createAlias(String alias) {
    return $AiConversationsTable(attachedDatabase, alias);
  }
}

class AiConversationRow extends i0.DataClass
    implements i0.Insertable<i1.AiConversationRow> {
  final int id;
  final String title;

  /// True while the title was made by the app and may be replaced by a
  /// generated one; false once the user renamed the chat.
  final bool titleAuto;
  final String? installId;
  final int? installGeneration;
  final String? model;

  /// One of [AiPermissionValues.values].
  final String permission;
  final int createdAt;
  final int updatedAt;
  final int lastMessageAt;
  const AiConversationRow({
    required this.id,
    required this.title,
    required this.titleAuto,
    this.installId,
    this.installGeneration,
    this.model,
    required this.permission,
    required this.createdAt,
    required this.updatedAt,
    required this.lastMessageAt,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id);
    map['title'] = i0.Variable<String>(title);
    map['title_auto'] = i0.Variable<bool>(titleAuto);
    if (!nullToAbsent || installId != null) {
      map['install_id'] = i0.Variable<String>(installId);
    }
    if (!nullToAbsent || installGeneration != null) {
      map['install_generation'] = i0.Variable<int>(installGeneration);
    }
    if (!nullToAbsent || model != null) {
      map['model'] = i0.Variable<String>(model);
    }
    map['permission'] = i0.Variable<String>(permission);
    map['created_at'] = i0.Variable<int>(createdAt);
    map['updated_at'] = i0.Variable<int>(updatedAt);
    map['last_message_at'] = i0.Variable<int>(lastMessageAt);
    return map;
  }

  i1.AiConversationsCompanion toCompanion(bool nullToAbsent) {
    return i1.AiConversationsCompanion(
      id: i0.Value(id),
      title: i0.Value(title),
      titleAuto: i0.Value(titleAuto),
      installId: installId == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(installId),
      installGeneration: installGeneration == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(installGeneration),
      model: model == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(model),
      permission: i0.Value(permission),
      createdAt: i0.Value(createdAt),
      updatedAt: i0.Value(updatedAt),
      lastMessageAt: i0.Value(lastMessageAt),
    );
  }

  factory AiConversationRow.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return AiConversationRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      titleAuto: serializer.fromJson<bool>(json['titleAuto']),
      installId: serializer.fromJson<String?>(json['installId']),
      installGeneration: serializer.fromJson<int?>(json['installGeneration']),
      model: serializer.fromJson<String?>(json['model']),
      permission: serializer.fromJson<String>(json['permission']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      lastMessageAt: serializer.fromJson<int>(json['lastMessageAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'titleAuto': serializer.toJson<bool>(titleAuto),
      'installId': serializer.toJson<String?>(installId),
      'installGeneration': serializer.toJson<int?>(installGeneration),
      'model': serializer.toJson<String?>(model),
      'permission': serializer.toJson<String>(permission),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'lastMessageAt': serializer.toJson<int>(lastMessageAt),
    };
  }

  i1.AiConversationRow copyWith({
    int? id,
    String? title,
    bool? titleAuto,
    i0.Value<String?> installId = const i0.Value.absent(),
    i0.Value<int?> installGeneration = const i0.Value.absent(),
    i0.Value<String?> model = const i0.Value.absent(),
    String? permission,
    int? createdAt,
    int? updatedAt,
    int? lastMessageAt,
  }) => i1.AiConversationRow(
    id: id ?? this.id,
    title: title ?? this.title,
    titleAuto: titleAuto ?? this.titleAuto,
    installId: installId.present ? installId.value : this.installId,
    installGeneration: installGeneration.present
        ? installGeneration.value
        : this.installGeneration,
    model: model.present ? model.value : this.model,
    permission: permission ?? this.permission,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastMessageAt: lastMessageAt ?? this.lastMessageAt,
  );
  AiConversationRow copyWithCompanion(i1.AiConversationsCompanion data) {
    return AiConversationRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      titleAuto: data.titleAuto.present ? data.titleAuto.value : this.titleAuto,
      installId: data.installId.present ? data.installId.value : this.installId,
      installGeneration: data.installGeneration.present
          ? data.installGeneration.value
          : this.installGeneration,
      model: data.model.present ? data.model.value : this.model,
      permission: data.permission.present
          ? data.permission.value
          : this.permission,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastMessageAt: data.lastMessageAt.present
          ? data.lastMessageAt.value
          : this.lastMessageAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiConversationRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('titleAuto: $titleAuto, ')
          ..write('installId: $installId, ')
          ..write('installGeneration: $installGeneration, ')
          ..write('model: $model, ')
          ..write('permission: $permission, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastMessageAt: $lastMessageAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    titleAuto,
    installId,
    installGeneration,
    model,
    permission,
    createdAt,
    updatedAt,
    lastMessageAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.AiConversationRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.titleAuto == this.titleAuto &&
          other.installId == this.installId &&
          other.installGeneration == this.installGeneration &&
          other.model == this.model &&
          other.permission == this.permission &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastMessageAt == this.lastMessageAt);
}

class AiConversationsCompanion
    extends i0.UpdateCompanion<i1.AiConversationRow> {
  final i0.Value<int> id;
  final i0.Value<String> title;
  final i0.Value<bool> titleAuto;
  final i0.Value<String?> installId;
  final i0.Value<int?> installGeneration;
  final i0.Value<String?> model;
  final i0.Value<String> permission;
  final i0.Value<int> createdAt;
  final i0.Value<int> updatedAt;
  final i0.Value<int> lastMessageAt;
  const AiConversationsCompanion({
    this.id = const i0.Value.absent(),
    this.title = const i0.Value.absent(),
    this.titleAuto = const i0.Value.absent(),
    this.installId = const i0.Value.absent(),
    this.installGeneration = const i0.Value.absent(),
    this.model = const i0.Value.absent(),
    this.permission = const i0.Value.absent(),
    this.createdAt = const i0.Value.absent(),
    this.updatedAt = const i0.Value.absent(),
    this.lastMessageAt = const i0.Value.absent(),
  });
  AiConversationsCompanion.insert({
    this.id = const i0.Value.absent(),
    required String title,
    this.titleAuto = const i0.Value.absent(),
    this.installId = const i0.Value.absent(),
    this.installGeneration = const i0.Value.absent(),
    this.model = const i0.Value.absent(),
    required String permission,
    required int createdAt,
    required int updatedAt,
    required int lastMessageAt,
  }) : title = i0.Value(title),
       permission = i0.Value(permission),
       createdAt = i0.Value(createdAt),
       updatedAt = i0.Value(updatedAt),
       lastMessageAt = i0.Value(lastMessageAt);
  static i0.Insertable<i1.AiConversationRow> custom({
    i0.Expression<int>? id,
    i0.Expression<String>? title,
    i0.Expression<bool>? titleAuto,
    i0.Expression<String>? installId,
    i0.Expression<int>? installGeneration,
    i0.Expression<String>? model,
    i0.Expression<String>? permission,
    i0.Expression<int>? createdAt,
    i0.Expression<int>? updatedAt,
    i0.Expression<int>? lastMessageAt,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (titleAuto != null) 'title_auto': titleAuto,
      if (installId != null) 'install_id': installId,
      if (installGeneration != null) 'install_generation': installGeneration,
      if (model != null) 'model': model,
      if (permission != null) 'permission': permission,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastMessageAt != null) 'last_message_at': lastMessageAt,
    });
  }

  i1.AiConversationsCompanion copyWith({
    i0.Value<int>? id,
    i0.Value<String>? title,
    i0.Value<bool>? titleAuto,
    i0.Value<String?>? installId,
    i0.Value<int?>? installGeneration,
    i0.Value<String?>? model,
    i0.Value<String>? permission,
    i0.Value<int>? createdAt,
    i0.Value<int>? updatedAt,
    i0.Value<int>? lastMessageAt,
  }) {
    return i1.AiConversationsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      titleAuto: titleAuto ?? this.titleAuto,
      installId: installId ?? this.installId,
      installGeneration: installGeneration ?? this.installGeneration,
      model: model ?? this.model,
      permission: permission ?? this.permission,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = i0.Variable<String>(title.value);
    }
    if (titleAuto.present) {
      map['title_auto'] = i0.Variable<bool>(titleAuto.value);
    }
    if (installId.present) {
      map['install_id'] = i0.Variable<String>(installId.value);
    }
    if (installGeneration.present) {
      map['install_generation'] = i0.Variable<int>(installGeneration.value);
    }
    if (model.present) {
      map['model'] = i0.Variable<String>(model.value);
    }
    if (permission.present) {
      map['permission'] = i0.Variable<String>(permission.value);
    }
    if (createdAt.present) {
      map['created_at'] = i0.Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = i0.Variable<int>(updatedAt.value);
    }
    if (lastMessageAt.present) {
      map['last_message_at'] = i0.Variable<int>(lastMessageAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiConversationsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('titleAuto: $titleAuto, ')
          ..write('installId: $installId, ')
          ..write('installGeneration: $installGeneration, ')
          ..write('model: $model, ')
          ..write('permission: $permission, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastMessageAt: $lastMessageAt')
          ..write(')'))
        .toString();
  }
}

i0.Index get aiMessagesConversationSeq => i0.Index(
  'ai_messages_conversation_seq',
  'CREATE UNIQUE INDEX ai_messages_conversation_seq ON ai_messages (conversation_id, seq)',
);

class $AiMessagesTable extends i2.AiMessages
    with i0.TableInfo<$AiMessagesTable, i1.AiMessageRow> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiMessagesTable(this.attachedDatabase, [this._alias]);
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
  static const i0.VerificationMeta _conversationIdMeta =
      const i0.VerificationMeta('conversationId');
  @override
  late final i0.GeneratedColumn<int> conversationId = i0.GeneratedColumn<int>(
    'conversation_id',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
      'REFERENCES ai_conversations (id) ON DELETE CASCADE',
    ),
  );
  static const i0.VerificationMeta _seqMeta = const i0.VerificationMeta('seq');
  @override
  late final i0.GeneratedColumn<int> seq = i0.GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _roleMeta = const i0.VerificationMeta(
    'role',
  );
  @override
  late final i0.GeneratedColumn<String> role = i0.GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _partsJsonMeta = const i0.VerificationMeta(
    'partsJson',
  );
  @override
  late final i0.GeneratedColumn<String> partsJson = i0.GeneratedColumn<String>(
    'parts_json',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _liveTextMeta = const i0.VerificationMeta(
    'liveText',
  );
  @override
  late final i0.GeneratedColumn<String> liveText = i0.GeneratedColumn<String>(
    'live_text',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _providerJsonMeta =
      const i0.VerificationMeta('providerJson');
  @override
  late final i0.GeneratedColumn<String> providerJson =
      i0.GeneratedColumn<String>(
        'provider_json',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const i0.VerificationMeta _installIdMeta = const i0.VerificationMeta(
    'installId',
  );
  @override
  late final i0.GeneratedColumn<String> installId = i0.GeneratedColumn<String>(
    'install_id',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _pluginVersionMeta =
      const i0.VerificationMeta('pluginVersion');
  @override
  late final i0.GeneratedColumn<int> pluginVersion = i0.GeneratedColumn<int>(
    'plugin_version',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _installGenerationMeta =
      const i0.VerificationMeta('installGeneration');
  @override
  late final i0.GeneratedColumn<int> installGeneration =
      i0.GeneratedColumn<int>(
        'install_generation',
        aliasedName,
        true,
        type: i0.DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const i0.VerificationMeta _modelMeta = const i0.VerificationMeta(
    'model',
  );
  @override
  late final i0.GeneratedColumn<String> model = i0.GeneratedColumn<String>(
    'model',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _stateMeta = const i0.VerificationMeta(
    'state',
  );
  @override
  late final i0.GeneratedColumn<String> state = i0.GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _errorJsonMeta = const i0.VerificationMeta(
    'errorJson',
  );
  @override
  late final i0.GeneratedColumn<String> errorJson = i0.GeneratedColumn<String>(
    'error_json',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _usageJsonMeta = const i0.VerificationMeta(
    'usageJson',
  );
  @override
  late final i0.GeneratedColumn<String> usageJson = i0.GeneratedColumn<String>(
    'usage_json',
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
  @override
  List<i0.GeneratedColumn> get $columns => [
    id,
    conversationId,
    seq,
    role,
    partsJson,
    liveText,
    providerJson,
    installId,
    pluginVersion,
    installGeneration,
    model,
    state,
    errorJson,
    usageJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_messages';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.AiMessageRow> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('parts_json')) {
      context.handle(
        _partsJsonMeta,
        partsJson.isAcceptableOrUnknown(data['parts_json']!, _partsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_partsJsonMeta);
    }
    if (data.containsKey('live_text')) {
      context.handle(
        _liveTextMeta,
        liveText.isAcceptableOrUnknown(data['live_text']!, _liveTextMeta),
      );
    }
    if (data.containsKey('provider_json')) {
      context.handle(
        _providerJsonMeta,
        providerJson.isAcceptableOrUnknown(
          data['provider_json']!,
          _providerJsonMeta,
        ),
      );
    }
    if (data.containsKey('install_id')) {
      context.handle(
        _installIdMeta,
        installId.isAcceptableOrUnknown(data['install_id']!, _installIdMeta),
      );
    }
    if (data.containsKey('plugin_version')) {
      context.handle(
        _pluginVersionMeta,
        pluginVersion.isAcceptableOrUnknown(
          data['plugin_version']!,
          _pluginVersionMeta,
        ),
      );
    }
    if (data.containsKey('install_generation')) {
      context.handle(
        _installGenerationMeta,
        installGeneration.isAcceptableOrUnknown(
          data['install_generation']!,
          _installGenerationMeta,
        ),
      );
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('error_json')) {
      context.handle(
        _errorJsonMeta,
        errorJson.isAcceptableOrUnknown(data['error_json']!, _errorJsonMeta),
      );
    }
    if (data.containsKey('usage_json')) {
      context.handle(
        _usageJsonMeta,
        usageJson.isAcceptableOrUnknown(data['usage_json']!, _usageJsonMeta),
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
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i1.AiMessageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.AiMessageRow(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}conversation_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      role: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      partsJson: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}parts_json'],
      )!,
      liveText: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}live_text'],
      ),
      providerJson: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}provider_json'],
      ),
      installId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}install_id'],
      ),
      pluginVersion: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}plugin_version'],
      ),
      installGeneration: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}install_generation'],
      ),
      model: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}model'],
      ),
      state: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      errorJson: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}error_json'],
      ),
      usageJson: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}usage_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AiMessagesTable createAlias(String alias) {
    return $AiMessagesTable(attachedDatabase, alias);
  }
}

class AiMessageRow extends i0.DataClass
    implements i0.Insertable<i1.AiMessageRow> {
  final int id;
  final int conversationId;
  final int seq;

  /// One of [AiMessageRoleValues.values].
  final String role;
  final String partsJson;

  /// Text streamed so far, flushed on its own so a flush does not rewrite
  /// [partsJson].
  final String? liveText;

  /// Provider-specific data kept for the whole conversation.
  final String? providerJson;
  final String? installId;
  final int? pluginVersion;
  final int? installGeneration;
  final String? model;

  /// One of [AiMessageStateValues.values].
  final String state;
  final String? errorJson;
  final String? usageJson;
  final int createdAt;
  const AiMessageRow({
    required this.id,
    required this.conversationId,
    required this.seq,
    required this.role,
    required this.partsJson,
    this.liveText,
    this.providerJson,
    this.installId,
    this.pluginVersion,
    this.installGeneration,
    this.model,
    required this.state,
    this.errorJson,
    this.usageJson,
    required this.createdAt,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id);
    map['conversation_id'] = i0.Variable<int>(conversationId);
    map['seq'] = i0.Variable<int>(seq);
    map['role'] = i0.Variable<String>(role);
    map['parts_json'] = i0.Variable<String>(partsJson);
    if (!nullToAbsent || liveText != null) {
      map['live_text'] = i0.Variable<String>(liveText);
    }
    if (!nullToAbsent || providerJson != null) {
      map['provider_json'] = i0.Variable<String>(providerJson);
    }
    if (!nullToAbsent || installId != null) {
      map['install_id'] = i0.Variable<String>(installId);
    }
    if (!nullToAbsent || pluginVersion != null) {
      map['plugin_version'] = i0.Variable<int>(pluginVersion);
    }
    if (!nullToAbsent || installGeneration != null) {
      map['install_generation'] = i0.Variable<int>(installGeneration);
    }
    if (!nullToAbsent || model != null) {
      map['model'] = i0.Variable<String>(model);
    }
    map['state'] = i0.Variable<String>(state);
    if (!nullToAbsent || errorJson != null) {
      map['error_json'] = i0.Variable<String>(errorJson);
    }
    if (!nullToAbsent || usageJson != null) {
      map['usage_json'] = i0.Variable<String>(usageJson);
    }
    map['created_at'] = i0.Variable<int>(createdAt);
    return map;
  }

  i1.AiMessagesCompanion toCompanion(bool nullToAbsent) {
    return i1.AiMessagesCompanion(
      id: i0.Value(id),
      conversationId: i0.Value(conversationId),
      seq: i0.Value(seq),
      role: i0.Value(role),
      partsJson: i0.Value(partsJson),
      liveText: liveText == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(liveText),
      providerJson: providerJson == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(providerJson),
      installId: installId == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(installId),
      pluginVersion: pluginVersion == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(pluginVersion),
      installGeneration: installGeneration == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(installGeneration),
      model: model == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(model),
      state: i0.Value(state),
      errorJson: errorJson == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(errorJson),
      usageJson: usageJson == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(usageJson),
      createdAt: i0.Value(createdAt),
    );
  }

  factory AiMessageRow.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return AiMessageRow(
      id: serializer.fromJson<int>(json['id']),
      conversationId: serializer.fromJson<int>(json['conversationId']),
      seq: serializer.fromJson<int>(json['seq']),
      role: serializer.fromJson<String>(json['role']),
      partsJson: serializer.fromJson<String>(json['partsJson']),
      liveText: serializer.fromJson<String?>(json['liveText']),
      providerJson: serializer.fromJson<String?>(json['providerJson']),
      installId: serializer.fromJson<String?>(json['installId']),
      pluginVersion: serializer.fromJson<int?>(json['pluginVersion']),
      installGeneration: serializer.fromJson<int?>(json['installGeneration']),
      model: serializer.fromJson<String?>(json['model']),
      state: serializer.fromJson<String>(json['state']),
      errorJson: serializer.fromJson<String?>(json['errorJson']),
      usageJson: serializer.fromJson<String?>(json['usageJson']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'conversationId': serializer.toJson<int>(conversationId),
      'seq': serializer.toJson<int>(seq),
      'role': serializer.toJson<String>(role),
      'partsJson': serializer.toJson<String>(partsJson),
      'liveText': serializer.toJson<String?>(liveText),
      'providerJson': serializer.toJson<String?>(providerJson),
      'installId': serializer.toJson<String?>(installId),
      'pluginVersion': serializer.toJson<int?>(pluginVersion),
      'installGeneration': serializer.toJson<int?>(installGeneration),
      'model': serializer.toJson<String?>(model),
      'state': serializer.toJson<String>(state),
      'errorJson': serializer.toJson<String?>(errorJson),
      'usageJson': serializer.toJson<String?>(usageJson),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  i1.AiMessageRow copyWith({
    int? id,
    int? conversationId,
    int? seq,
    String? role,
    String? partsJson,
    i0.Value<String?> liveText = const i0.Value.absent(),
    i0.Value<String?> providerJson = const i0.Value.absent(),
    i0.Value<String?> installId = const i0.Value.absent(),
    i0.Value<int?> pluginVersion = const i0.Value.absent(),
    i0.Value<int?> installGeneration = const i0.Value.absent(),
    i0.Value<String?> model = const i0.Value.absent(),
    String? state,
    i0.Value<String?> errorJson = const i0.Value.absent(),
    i0.Value<String?> usageJson = const i0.Value.absent(),
    int? createdAt,
  }) => i1.AiMessageRow(
    id: id ?? this.id,
    conversationId: conversationId ?? this.conversationId,
    seq: seq ?? this.seq,
    role: role ?? this.role,
    partsJson: partsJson ?? this.partsJson,
    liveText: liveText.present ? liveText.value : this.liveText,
    providerJson: providerJson.present ? providerJson.value : this.providerJson,
    installId: installId.present ? installId.value : this.installId,
    pluginVersion: pluginVersion.present
        ? pluginVersion.value
        : this.pluginVersion,
    installGeneration: installGeneration.present
        ? installGeneration.value
        : this.installGeneration,
    model: model.present ? model.value : this.model,
    state: state ?? this.state,
    errorJson: errorJson.present ? errorJson.value : this.errorJson,
    usageJson: usageJson.present ? usageJson.value : this.usageJson,
    createdAt: createdAt ?? this.createdAt,
  );
  AiMessageRow copyWithCompanion(i1.AiMessagesCompanion data) {
    return AiMessageRow(
      id: data.id.present ? data.id.value : this.id,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      seq: data.seq.present ? data.seq.value : this.seq,
      role: data.role.present ? data.role.value : this.role,
      partsJson: data.partsJson.present ? data.partsJson.value : this.partsJson,
      liveText: data.liveText.present ? data.liveText.value : this.liveText,
      providerJson: data.providerJson.present
          ? data.providerJson.value
          : this.providerJson,
      installId: data.installId.present ? data.installId.value : this.installId,
      pluginVersion: data.pluginVersion.present
          ? data.pluginVersion.value
          : this.pluginVersion,
      installGeneration: data.installGeneration.present
          ? data.installGeneration.value
          : this.installGeneration,
      model: data.model.present ? data.model.value : this.model,
      state: data.state.present ? data.state.value : this.state,
      errorJson: data.errorJson.present ? data.errorJson.value : this.errorJson,
      usageJson: data.usageJson.present ? data.usageJson.value : this.usageJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiMessageRow(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('seq: $seq, ')
          ..write('role: $role, ')
          ..write('partsJson: $partsJson, ')
          ..write('liveText: $liveText, ')
          ..write('providerJson: $providerJson, ')
          ..write('installId: $installId, ')
          ..write('pluginVersion: $pluginVersion, ')
          ..write('installGeneration: $installGeneration, ')
          ..write('model: $model, ')
          ..write('state: $state, ')
          ..write('errorJson: $errorJson, ')
          ..write('usageJson: $usageJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    conversationId,
    seq,
    role,
    partsJson,
    liveText,
    providerJson,
    installId,
    pluginVersion,
    installGeneration,
    model,
    state,
    errorJson,
    usageJson,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.AiMessageRow &&
          other.id == this.id &&
          other.conversationId == this.conversationId &&
          other.seq == this.seq &&
          other.role == this.role &&
          other.partsJson == this.partsJson &&
          other.liveText == this.liveText &&
          other.providerJson == this.providerJson &&
          other.installId == this.installId &&
          other.pluginVersion == this.pluginVersion &&
          other.installGeneration == this.installGeneration &&
          other.model == this.model &&
          other.state == this.state &&
          other.errorJson == this.errorJson &&
          other.usageJson == this.usageJson &&
          other.createdAt == this.createdAt);
}

class AiMessagesCompanion extends i0.UpdateCompanion<i1.AiMessageRow> {
  final i0.Value<int> id;
  final i0.Value<int> conversationId;
  final i0.Value<int> seq;
  final i0.Value<String> role;
  final i0.Value<String> partsJson;
  final i0.Value<String?> liveText;
  final i0.Value<String?> providerJson;
  final i0.Value<String?> installId;
  final i0.Value<int?> pluginVersion;
  final i0.Value<int?> installGeneration;
  final i0.Value<String?> model;
  final i0.Value<String> state;
  final i0.Value<String?> errorJson;
  final i0.Value<String?> usageJson;
  final i0.Value<int> createdAt;
  const AiMessagesCompanion({
    this.id = const i0.Value.absent(),
    this.conversationId = const i0.Value.absent(),
    this.seq = const i0.Value.absent(),
    this.role = const i0.Value.absent(),
    this.partsJson = const i0.Value.absent(),
    this.liveText = const i0.Value.absent(),
    this.providerJson = const i0.Value.absent(),
    this.installId = const i0.Value.absent(),
    this.pluginVersion = const i0.Value.absent(),
    this.installGeneration = const i0.Value.absent(),
    this.model = const i0.Value.absent(),
    this.state = const i0.Value.absent(),
    this.errorJson = const i0.Value.absent(),
    this.usageJson = const i0.Value.absent(),
    this.createdAt = const i0.Value.absent(),
  });
  AiMessagesCompanion.insert({
    this.id = const i0.Value.absent(),
    required int conversationId,
    required int seq,
    required String role,
    required String partsJson,
    this.liveText = const i0.Value.absent(),
    this.providerJson = const i0.Value.absent(),
    this.installId = const i0.Value.absent(),
    this.pluginVersion = const i0.Value.absent(),
    this.installGeneration = const i0.Value.absent(),
    this.model = const i0.Value.absent(),
    required String state,
    this.errorJson = const i0.Value.absent(),
    this.usageJson = const i0.Value.absent(),
    required int createdAt,
  }) : conversationId = i0.Value(conversationId),
       seq = i0.Value(seq),
       role = i0.Value(role),
       partsJson = i0.Value(partsJson),
       state = i0.Value(state),
       createdAt = i0.Value(createdAt);
  static i0.Insertable<i1.AiMessageRow> custom({
    i0.Expression<int>? id,
    i0.Expression<int>? conversationId,
    i0.Expression<int>? seq,
    i0.Expression<String>? role,
    i0.Expression<String>? partsJson,
    i0.Expression<String>? liveText,
    i0.Expression<String>? providerJson,
    i0.Expression<String>? installId,
    i0.Expression<int>? pluginVersion,
    i0.Expression<int>? installGeneration,
    i0.Expression<String>? model,
    i0.Expression<String>? state,
    i0.Expression<String>? errorJson,
    i0.Expression<String>? usageJson,
    i0.Expression<int>? createdAt,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (conversationId != null) 'conversation_id': conversationId,
      if (seq != null) 'seq': seq,
      if (role != null) 'role': role,
      if (partsJson != null) 'parts_json': partsJson,
      if (liveText != null) 'live_text': liveText,
      if (providerJson != null) 'provider_json': providerJson,
      if (installId != null) 'install_id': installId,
      if (pluginVersion != null) 'plugin_version': pluginVersion,
      if (installGeneration != null) 'install_generation': installGeneration,
      if (model != null) 'model': model,
      if (state != null) 'state': state,
      if (errorJson != null) 'error_json': errorJson,
      if (usageJson != null) 'usage_json': usageJson,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  i1.AiMessagesCompanion copyWith({
    i0.Value<int>? id,
    i0.Value<int>? conversationId,
    i0.Value<int>? seq,
    i0.Value<String>? role,
    i0.Value<String>? partsJson,
    i0.Value<String?>? liveText,
    i0.Value<String?>? providerJson,
    i0.Value<String?>? installId,
    i0.Value<int?>? pluginVersion,
    i0.Value<int?>? installGeneration,
    i0.Value<String?>? model,
    i0.Value<String>? state,
    i0.Value<String?>? errorJson,
    i0.Value<String?>? usageJson,
    i0.Value<int>? createdAt,
  }) {
    return i1.AiMessagesCompanion(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      seq: seq ?? this.seq,
      role: role ?? this.role,
      partsJson: partsJson ?? this.partsJson,
      liveText: liveText ?? this.liveText,
      providerJson: providerJson ?? this.providerJson,
      installId: installId ?? this.installId,
      pluginVersion: pluginVersion ?? this.pluginVersion,
      installGeneration: installGeneration ?? this.installGeneration,
      model: model ?? this.model,
      state: state ?? this.state,
      errorJson: errorJson ?? this.errorJson,
      usageJson: usageJson ?? this.usageJson,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<int>(id.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = i0.Variable<int>(conversationId.value);
    }
    if (seq.present) {
      map['seq'] = i0.Variable<int>(seq.value);
    }
    if (role.present) {
      map['role'] = i0.Variable<String>(role.value);
    }
    if (partsJson.present) {
      map['parts_json'] = i0.Variable<String>(partsJson.value);
    }
    if (liveText.present) {
      map['live_text'] = i0.Variable<String>(liveText.value);
    }
    if (providerJson.present) {
      map['provider_json'] = i0.Variable<String>(providerJson.value);
    }
    if (installId.present) {
      map['install_id'] = i0.Variable<String>(installId.value);
    }
    if (pluginVersion.present) {
      map['plugin_version'] = i0.Variable<int>(pluginVersion.value);
    }
    if (installGeneration.present) {
      map['install_generation'] = i0.Variable<int>(installGeneration.value);
    }
    if (model.present) {
      map['model'] = i0.Variable<String>(model.value);
    }
    if (state.present) {
      map['state'] = i0.Variable<String>(state.value);
    }
    if (errorJson.present) {
      map['error_json'] = i0.Variable<String>(errorJson.value);
    }
    if (usageJson.present) {
      map['usage_json'] = i0.Variable<String>(usageJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = i0.Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiMessagesCompanion(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('seq: $seq, ')
          ..write('role: $role, ')
          ..write('partsJson: $partsJson, ')
          ..write('liveText: $liveText, ')
          ..write('providerJson: $providerJson, ')
          ..write('installId: $installId, ')
          ..write('pluginVersion: $pluginVersion, ')
          ..write('installGeneration: $installGeneration, ')
          ..write('model: $model, ')
          ..write('state: $state, ')
          ..write('errorJson: $errorJson, ')
          ..write('usageJson: $usageJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}
