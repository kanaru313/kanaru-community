// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:kanaru/src/database/tables/lyrics_translation_tables.drift.dart'
    as i1;
import 'package:kanaru/src/database/tables/lyrics_translation_tables.dart'
    as i2;
import 'package:drift/src/runtime/query_builder/query_builder.dart' as i3;
import 'package:kanaru/src/database/tables/library_track_tables.drift.dart'
    as i4;
import 'package:drift/internal/modular.dart' as i5;

typedef $$LyricsTranslationsTableCreateCompanionBuilder =
    i1.LyricsTranslationsCompanion Function({
      required String contentHash,
      required String installId,
      required String targetLang,
      i0.Value<String?> sourceLang,
      required String linesJson,
      required String settingsJson,
      i0.Value<bool> complete,
      required int createdAt,
      i0.Value<int> rowid,
    });
typedef $$LyricsTranslationsTableUpdateCompanionBuilder =
    i1.LyricsTranslationsCompanion Function({
      i0.Value<String> contentHash,
      i0.Value<String> installId,
      i0.Value<String> targetLang,
      i0.Value<String?> sourceLang,
      i0.Value<String> linesJson,
      i0.Value<String> settingsJson,
      i0.Value<bool> complete,
      i0.Value<int> createdAt,
      i0.Value<int> rowid,
    });

class $$LyricsTranslationsTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$LyricsTranslationsTable> {
  $$LyricsTranslationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get targetLang => $composableBuilder(
    column: $table.targetLang,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get sourceLang => $composableBuilder(
    column: $table.sourceLang,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get linesJson => $composableBuilder(
    column: $table.linesJson,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get settingsJson => $composableBuilder(
    column: $table.settingsJson,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<bool> get complete => $composableBuilder(
    column: $table.complete,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => i0.ColumnFilters(column),
  );
}

class $$LyricsTranslationsTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$LyricsTranslationsTable> {
  $$LyricsTranslationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get targetLang => $composableBuilder(
    column: $table.targetLang,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get sourceLang => $composableBuilder(
    column: $table.sourceLang,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get linesJson => $composableBuilder(
    column: $table.linesJson,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get settingsJson => $composableBuilder(
    column: $table.settingsJson,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<bool> get complete => $composableBuilder(
    column: $table.complete,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $$LyricsTranslationsTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$LyricsTranslationsTable> {
  $$LyricsTranslationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get installId =>
      $composableBuilder(column: $table.installId, builder: (column) => column);

  i0.GeneratedColumn<String> get targetLang => $composableBuilder(
    column: $table.targetLang,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get sourceLang => $composableBuilder(
    column: $table.sourceLang,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get linesJson =>
      $composableBuilder(column: $table.linesJson, builder: (column) => column);

  i0.GeneratedColumn<String> get settingsJson => $composableBuilder(
    column: $table.settingsJson,
    builder: (column) => column,
  );

  i0.GeneratedColumn<bool> get complete =>
      $composableBuilder(column: $table.complete, builder: (column) => column);

  i0.GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LyricsTranslationsTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$LyricsTranslationsTable,
          i1.LyricsTranslationRow,
          i1.$$LyricsTranslationsTableFilterComposer,
          i1.$$LyricsTranslationsTableOrderingComposer,
          i1.$$LyricsTranslationsTableAnnotationComposer,
          $$LyricsTranslationsTableCreateCompanionBuilder,
          $$LyricsTranslationsTableUpdateCompanionBuilder,
          (
            i1.LyricsTranslationRow,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i1.$LyricsTranslationsTable,
              i1.LyricsTranslationRow
            >,
          ),
          i1.LyricsTranslationRow,
          i0.PrefetchHooks Function()
        > {
  $$LyricsTranslationsTableTableManager(
    i0.GeneratedDatabase db,
    i1.$LyricsTranslationsTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => i1
              .$$LyricsTranslationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$LyricsTranslationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              i1.$$LyricsTranslationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                i0.Value<String> contentHash = const i0.Value.absent(),
                i0.Value<String> installId = const i0.Value.absent(),
                i0.Value<String> targetLang = const i0.Value.absent(),
                i0.Value<String?> sourceLang = const i0.Value.absent(),
                i0.Value<String> linesJson = const i0.Value.absent(),
                i0.Value<String> settingsJson = const i0.Value.absent(),
                i0.Value<bool> complete = const i0.Value.absent(),
                i0.Value<int> createdAt = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.LyricsTranslationsCompanion(
                contentHash: contentHash,
                installId: installId,
                targetLang: targetLang,
                sourceLang: sourceLang,
                linesJson: linesJson,
                settingsJson: settingsJson,
                complete: complete,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String contentHash,
                required String installId,
                required String targetLang,
                i0.Value<String?> sourceLang = const i0.Value.absent(),
                required String linesJson,
                required String settingsJson,
                i0.Value<bool> complete = const i0.Value.absent(),
                required int createdAt,
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.LyricsTranslationsCompanion.insert(
                contentHash: contentHash,
                installId: installId,
                targetLang: targetLang,
                sourceLang: sourceLang,
                linesJson: linesJson,
                settingsJson: settingsJson,
                complete: complete,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    i1.$LyricsTranslationsTable,
                    i1.LyricsTranslationRow
                  >(table),
                  i0.BaseReferences<
                    i0.GeneratedDatabase,
                    i1.$LyricsTranslationsTable,
                    i1.LyricsTranslationRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LyricsTranslationsTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$LyricsTranslationsTable,
      i1.LyricsTranslationRow,
      i1.$$LyricsTranslationsTableFilterComposer,
      i1.$$LyricsTranslationsTableOrderingComposer,
      i1.$$LyricsTranslationsTableAnnotationComposer,
      $$LyricsTranslationsTableCreateCompanionBuilder,
      $$LyricsTranslationsTableUpdateCompanionBuilder,
      (
        i1.LyricsTranslationRow,
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$LyricsTranslationsTable,
          i1.LyricsTranslationRow
        >,
      ),
      i1.LyricsTranslationRow,
      i0.PrefetchHooks Function()
    >;
typedef $$TrackTranslationPrefsTableCreateCompanionBuilder =
    i1.TrackTranslationPrefsCompanion Function({
      i0.Value<int> trackId,
      i0.Value<String?> targetLang,
      required int updatedAt,
    });
typedef $$TrackTranslationPrefsTableUpdateCompanionBuilder =
    i1.TrackTranslationPrefsCompanion Function({
      i0.Value<int> trackId,
      i0.Value<String?> targetLang,
      i0.Value<int> updatedAt,
    });

final class $$TrackTranslationPrefsTableReferences
    extends
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$TrackTranslationPrefsTable,
          i1.TrackTranslationPref
        > {
  $$TrackTranslationPrefsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static i4.$TracksTable _trackIdTable(i0.GeneratedDatabase db) =>
      i5.ReadDatabaseContainer(db)
          .resultSet<i4.$TracksTable>('tracks')
          .createAlias('track_translation_prefs__track_id__tracks__id');

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

class $$TrackTranslationPrefsTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$TrackTranslationPrefsTable> {
  $$TrackTranslationPrefsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get targetLang => $composableBuilder(
    column: $table.targetLang,
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

class $$TrackTranslationPrefsTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$TrackTranslationPrefsTable> {
  $$TrackTranslationPrefsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get targetLang => $composableBuilder(
    column: $table.targetLang,
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

class $$TrackTranslationPrefsTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$TrackTranslationPrefsTable> {
  $$TrackTranslationPrefsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get targetLang => $composableBuilder(
    column: $table.targetLang,
    builder: (column) => column,
  );

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

class $$TrackTranslationPrefsTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$TrackTranslationPrefsTable,
          i1.TrackTranslationPref,
          i1.$$TrackTranslationPrefsTableFilterComposer,
          i1.$$TrackTranslationPrefsTableOrderingComposer,
          i1.$$TrackTranslationPrefsTableAnnotationComposer,
          $$TrackTranslationPrefsTableCreateCompanionBuilder,
          $$TrackTranslationPrefsTableUpdateCompanionBuilder,
          (i1.TrackTranslationPref, i1.$$TrackTranslationPrefsTableReferences),
          i1.TrackTranslationPref,
          i0.PrefetchHooks Function({bool trackId})
        > {
  $$TrackTranslationPrefsTableTableManager(
    i0.GeneratedDatabase db,
    i1.$TrackTranslationPrefsTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$TrackTranslationPrefsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              i1.$$TrackTranslationPrefsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              i1.$$TrackTranslationPrefsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                i0.Value<int> trackId = const i0.Value.absent(),
                i0.Value<String?> targetLang = const i0.Value.absent(),
                i0.Value<int> updatedAt = const i0.Value.absent(),
              }) => i1.TrackTranslationPrefsCompanion(
                trackId: trackId,
                targetLang: targetLang,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                i0.Value<int> trackId = const i0.Value.absent(),
                i0.Value<String?> targetLang = const i0.Value.absent(),
                required int updatedAt,
              }) => i1.TrackTranslationPrefsCompanion.insert(
                trackId: trackId,
                targetLang: targetLang,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    i1.$TrackTranslationPrefsTable,
                    i1.TrackTranslationPref
                  >(table),
                  i1.$$TrackTranslationPrefsTableReferences(db, table, e),
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
                        referencedTable: i1
                            .$$TrackTranslationPrefsTableReferences
                            ._trackIdTable(db),
                        referencedColumn: i1
                            .$$TrackTranslationPrefsTableReferences
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

typedef $$TrackTranslationPrefsTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$TrackTranslationPrefsTable,
      i1.TrackTranslationPref,
      i1.$$TrackTranslationPrefsTableFilterComposer,
      i1.$$TrackTranslationPrefsTableOrderingComposer,
      i1.$$TrackTranslationPrefsTableAnnotationComposer,
      $$TrackTranslationPrefsTableCreateCompanionBuilder,
      $$TrackTranslationPrefsTableUpdateCompanionBuilder,
      (i1.TrackTranslationPref, i1.$$TrackTranslationPrefsTableReferences),
      i1.TrackTranslationPref,
      i0.PrefetchHooks Function({bool trackId})
    >;
i0.Index get lyricsTranslationsLookup => i0.Index(
  'lyrics_translations_lookup',
  'CREATE INDEX lyrics_translations_lookup ON lyrics_translations (content_hash, target_lang, created_at)',
);

class $LyricsTranslationsTable extends i2.LyricsTranslations
    with i0.TableInfo<$LyricsTranslationsTable, i1.LyricsTranslationRow> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LyricsTranslationsTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _contentHashMeta = const i0.VerificationMeta(
    'contentHash',
  );
  @override
  late final i0.GeneratedColumn<String> contentHash =
      i0.GeneratedColumn<String>(
        'content_hash',
        aliasedName,
        false,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: true,
      );
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
  static const i0.VerificationMeta _targetLangMeta = const i0.VerificationMeta(
    'targetLang',
  );
  @override
  late final i0.GeneratedColumn<String> targetLang = i0.GeneratedColumn<String>(
    'target_lang',
    aliasedName,
    false,
    check: () => i3.ComparableExpr(targetLang.length).isBetweenValues(2, 7),
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _sourceLangMeta = const i0.VerificationMeta(
    'sourceLang',
  );
  @override
  late final i0.GeneratedColumn<String> sourceLang = i0.GeneratedColumn<String>(
    'source_lang',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _linesJsonMeta = const i0.VerificationMeta(
    'linesJson',
  );
  @override
  late final i0.GeneratedColumn<String> linesJson = i0.GeneratedColumn<String>(
    'lines_json',
    aliasedName,
    false,
    check: () =>
        i3.ComparableExpr(linesJson.length)
            .isSmallerOrEqualValue(i2.TranslationLimits.maxLinesJsonLength),
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _settingsJsonMeta =
      const i0.VerificationMeta('settingsJson');
  @override
  late final i0.GeneratedColumn<String> settingsJson =
      i0.GeneratedColumn<String>(
        'settings_json',
        aliasedName,
        false,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const i0.VerificationMeta _completeMeta = const i0.VerificationMeta(
    'complete',
  );
  @override
  late final i0.GeneratedColumn<bool> complete = i0.GeneratedColumn<bool>(
    'complete',
    aliasedName,
    false,
    type: i0.DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
      'CHECK ("complete" IN (0, 1))',
    ),
    defaultValue: const i3.Constant(false),
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
    contentHash,
    installId,
    targetLang,
    sourceLang,
    linesJson,
    settingsJson,
    complete,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lyrics_translations';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.LyricsTranslationRow> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentHashMeta);
    }
    if (data.containsKey('install_id')) {
      context.handle(
        _installIdMeta,
        installId.isAcceptableOrUnknown(data['install_id']!, _installIdMeta),
      );
    } else if (isInserting) {
      context.missing(_installIdMeta);
    }
    if (data.containsKey('target_lang')) {
      context.handle(
        _targetLangMeta,
        targetLang.isAcceptableOrUnknown(data['target_lang']!, _targetLangMeta),
      );
    } else if (isInserting) {
      context.missing(_targetLangMeta);
    }
    if (data.containsKey('source_lang')) {
      context.handle(
        _sourceLangMeta,
        sourceLang.isAcceptableOrUnknown(data['source_lang']!, _sourceLangMeta),
      );
    }
    if (data.containsKey('lines_json')) {
      context.handle(
        _linesJsonMeta,
        linesJson.isAcceptableOrUnknown(data['lines_json']!, _linesJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_linesJsonMeta);
    }
    if (data.containsKey('settings_json')) {
      context.handle(
        _settingsJsonMeta,
        settingsJson.isAcceptableOrUnknown(
          data['settings_json']!,
          _settingsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_settingsJsonMeta);
    }
    if (data.containsKey('complete')) {
      context.handle(
        _completeMeta,
        complete.isAcceptableOrUnknown(data['complete']!, _completeMeta),
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
  Set<i0.GeneratedColumn> get $primaryKey => {
    contentHash,
    installId,
    targetLang,
  };
  @override
  i1.LyricsTranslationRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.LyricsTranslationRow(
      contentHash: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      )!,
      installId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}install_id'],
      )!,
      targetLang: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}target_lang'],
      )!,
      sourceLang: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}source_lang'],
      ),
      linesJson: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}lines_json'],
      )!,
      settingsJson: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}settings_json'],
      )!,
      complete: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.bool,
        data['${effectivePrefix}complete'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LyricsTranslationsTable createAlias(String alias) {
    return $LyricsTranslationsTable(attachedDatabase, alias);
  }
}

class LyricsTranslationRow extends i0.DataClass
    implements i0.Insertable<i1.LyricsTranslationRow> {
  final String contentHash;

  /// The translate plugin's install id (no foreign key).
  final String installId;
  final String targetLang;

  /// Dominant source language the plugin saw; null when unknown.
  final String? sourceLang;

  /// JSON object: source line to translated line.
  final String linesJson;

  /// JSON `{pluginVersion, model, style, instructionHash}` of the run.
  final String settingsJson;

  /// False while chunks are still arriving; only a complete row is reused.
  final bool complete;
  final int createdAt;
  const LyricsTranslationRow({
    required this.contentHash,
    required this.installId,
    required this.targetLang,
    this.sourceLang,
    required this.linesJson,
    required this.settingsJson,
    required this.complete,
    required this.createdAt,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['content_hash'] = i0.Variable<String>(contentHash);
    map['install_id'] = i0.Variable<String>(installId);
    map['target_lang'] = i0.Variable<String>(targetLang);
    if (!nullToAbsent || sourceLang != null) {
      map['source_lang'] = i0.Variable<String>(sourceLang);
    }
    map['lines_json'] = i0.Variable<String>(linesJson);
    map['settings_json'] = i0.Variable<String>(settingsJson);
    map['complete'] = i0.Variable<bool>(complete);
    map['created_at'] = i0.Variable<int>(createdAt);
    return map;
  }

  i1.LyricsTranslationsCompanion toCompanion(bool nullToAbsent) {
    return i1.LyricsTranslationsCompanion(
      contentHash: i0.Value(contentHash),
      installId: i0.Value(installId),
      targetLang: i0.Value(targetLang),
      sourceLang: sourceLang == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(sourceLang),
      linesJson: i0.Value(linesJson),
      settingsJson: i0.Value(settingsJson),
      complete: i0.Value(complete),
      createdAt: i0.Value(createdAt),
    );
  }

  factory LyricsTranslationRow.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return LyricsTranslationRow(
      contentHash: serializer.fromJson<String>(json['contentHash']),
      installId: serializer.fromJson<String>(json['installId']),
      targetLang: serializer.fromJson<String>(json['targetLang']),
      sourceLang: serializer.fromJson<String?>(json['sourceLang']),
      linesJson: serializer.fromJson<String>(json['linesJson']),
      settingsJson: serializer.fromJson<String>(json['settingsJson']),
      complete: serializer.fromJson<bool>(json['complete']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'contentHash': serializer.toJson<String>(contentHash),
      'installId': serializer.toJson<String>(installId),
      'targetLang': serializer.toJson<String>(targetLang),
      'sourceLang': serializer.toJson<String?>(sourceLang),
      'linesJson': serializer.toJson<String>(linesJson),
      'settingsJson': serializer.toJson<String>(settingsJson),
      'complete': serializer.toJson<bool>(complete),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  i1.LyricsTranslationRow copyWith({
    String? contentHash,
    String? installId,
    String? targetLang,
    i0.Value<String?> sourceLang = const i0.Value.absent(),
    String? linesJson,
    String? settingsJson,
    bool? complete,
    int? createdAt,
  }) => i1.LyricsTranslationRow(
    contentHash: contentHash ?? this.contentHash,
    installId: installId ?? this.installId,
    targetLang: targetLang ?? this.targetLang,
    sourceLang: sourceLang.present ? sourceLang.value : this.sourceLang,
    linesJson: linesJson ?? this.linesJson,
    settingsJson: settingsJson ?? this.settingsJson,
    complete: complete ?? this.complete,
    createdAt: createdAt ?? this.createdAt,
  );
  LyricsTranslationRow copyWithCompanion(i1.LyricsTranslationsCompanion data) {
    return LyricsTranslationRow(
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      installId: data.installId.present ? data.installId.value : this.installId,
      targetLang: data.targetLang.present
          ? data.targetLang.value
          : this.targetLang,
      sourceLang: data.sourceLang.present
          ? data.sourceLang.value
          : this.sourceLang,
      linesJson: data.linesJson.present ? data.linesJson.value : this.linesJson,
      settingsJson: data.settingsJson.present
          ? data.settingsJson.value
          : this.settingsJson,
      complete: data.complete.present ? data.complete.value : this.complete,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LyricsTranslationRow(')
          ..write('contentHash: $contentHash, ')
          ..write('installId: $installId, ')
          ..write('targetLang: $targetLang, ')
          ..write('sourceLang: $sourceLang, ')
          ..write('linesJson: $linesJson, ')
          ..write('settingsJson: $settingsJson, ')
          ..write('complete: $complete, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    contentHash,
    installId,
    targetLang,
    sourceLang,
    linesJson,
    settingsJson,
    complete,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.LyricsTranslationRow &&
          other.contentHash == this.contentHash &&
          other.installId == this.installId &&
          other.targetLang == this.targetLang &&
          other.sourceLang == this.sourceLang &&
          other.linesJson == this.linesJson &&
          other.settingsJson == this.settingsJson &&
          other.complete == this.complete &&
          other.createdAt == this.createdAt);
}

class LyricsTranslationsCompanion
    extends i0.UpdateCompanion<i1.LyricsTranslationRow> {
  final i0.Value<String> contentHash;
  final i0.Value<String> installId;
  final i0.Value<String> targetLang;
  final i0.Value<String?> sourceLang;
  final i0.Value<String> linesJson;
  final i0.Value<String> settingsJson;
  final i0.Value<bool> complete;
  final i0.Value<int> createdAt;
  final i0.Value<int> rowid;
  const LyricsTranslationsCompanion({
    this.contentHash = const i0.Value.absent(),
    this.installId = const i0.Value.absent(),
    this.targetLang = const i0.Value.absent(),
    this.sourceLang = const i0.Value.absent(),
    this.linesJson = const i0.Value.absent(),
    this.settingsJson = const i0.Value.absent(),
    this.complete = const i0.Value.absent(),
    this.createdAt = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  LyricsTranslationsCompanion.insert({
    required String contentHash,
    required String installId,
    required String targetLang,
    this.sourceLang = const i0.Value.absent(),
    required String linesJson,
    required String settingsJson,
    this.complete = const i0.Value.absent(),
    required int createdAt,
    this.rowid = const i0.Value.absent(),
  }) : contentHash = i0.Value(contentHash),
       installId = i0.Value(installId),
       targetLang = i0.Value(targetLang),
       linesJson = i0.Value(linesJson),
       settingsJson = i0.Value(settingsJson),
       createdAt = i0.Value(createdAt);
  static i0.Insertable<i1.LyricsTranslationRow> custom({
    i0.Expression<String>? contentHash,
    i0.Expression<String>? installId,
    i0.Expression<String>? targetLang,
    i0.Expression<String>? sourceLang,
    i0.Expression<String>? linesJson,
    i0.Expression<String>? settingsJson,
    i0.Expression<bool>? complete,
    i0.Expression<int>? createdAt,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (contentHash != null) 'content_hash': contentHash,
      if (installId != null) 'install_id': installId,
      if (targetLang != null) 'target_lang': targetLang,
      if (sourceLang != null) 'source_lang': sourceLang,
      if (linesJson != null) 'lines_json': linesJson,
      if (settingsJson != null) 'settings_json': settingsJson,
      if (complete != null) 'complete': complete,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i1.LyricsTranslationsCompanion copyWith({
    i0.Value<String>? contentHash,
    i0.Value<String>? installId,
    i0.Value<String>? targetLang,
    i0.Value<String?>? sourceLang,
    i0.Value<String>? linesJson,
    i0.Value<String>? settingsJson,
    i0.Value<bool>? complete,
    i0.Value<int>? createdAt,
    i0.Value<int>? rowid,
  }) {
    return i1.LyricsTranslationsCompanion(
      contentHash: contentHash ?? this.contentHash,
      installId: installId ?? this.installId,
      targetLang: targetLang ?? this.targetLang,
      sourceLang: sourceLang ?? this.sourceLang,
      linesJson: linesJson ?? this.linesJson,
      settingsJson: settingsJson ?? this.settingsJson,
      complete: complete ?? this.complete,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (contentHash.present) {
      map['content_hash'] = i0.Variable<String>(contentHash.value);
    }
    if (installId.present) {
      map['install_id'] = i0.Variable<String>(installId.value);
    }
    if (targetLang.present) {
      map['target_lang'] = i0.Variable<String>(targetLang.value);
    }
    if (sourceLang.present) {
      map['source_lang'] = i0.Variable<String>(sourceLang.value);
    }
    if (linesJson.present) {
      map['lines_json'] = i0.Variable<String>(linesJson.value);
    }
    if (settingsJson.present) {
      map['settings_json'] = i0.Variable<String>(settingsJson.value);
    }
    if (complete.present) {
      map['complete'] = i0.Variable<bool>(complete.value);
    }
    if (createdAt.present) {
      map['created_at'] = i0.Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LyricsTranslationsCompanion(')
          ..write('contentHash: $contentHash, ')
          ..write('installId: $installId, ')
          ..write('targetLang: $targetLang, ')
          ..write('sourceLang: $sourceLang, ')
          ..write('linesJson: $linesJson, ')
          ..write('settingsJson: $settingsJson, ')
          ..write('complete: $complete, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TrackTranslationPrefsTable extends i2.TrackTranslationPrefs
    with i0.TableInfo<$TrackTranslationPrefsTable, i1.TrackTranslationPref> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackTranslationPrefsTable(this.attachedDatabase, [this._alias]);
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
  static const i0.VerificationMeta _targetLangMeta = const i0.VerificationMeta(
    'targetLang',
  );
  @override
  late final i0.GeneratedColumn<String> targetLang = i0.GeneratedColumn<String>(
    'target_lang',
    aliasedName,
    true,
    check: () => i3.ComparableExpr(targetLang.length).isBetweenValues(2, 7),
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
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
  List<i0.GeneratedColumn> get $columns => [trackId, targetLang, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'track_translation_prefs';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.TrackTranslationPref> instance, {
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
    if (data.containsKey('target_lang')) {
      context.handle(
        _targetLangMeta,
        targetLang.isAcceptableOrUnknown(data['target_lang']!, _targetLangMeta),
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
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {trackId};
  @override
  i1.TrackTranslationPref map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.TrackTranslationPref(
      trackId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      )!,
      targetLang: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}target_lang'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TrackTranslationPrefsTable createAlias(String alias) {
    return $TrackTranslationPrefsTable(attachedDatabase, alias);
  }
}

class TrackTranslationPref extends i0.DataClass
    implements i0.Insertable<i1.TrackTranslationPref> {
  final int trackId;

  /// Shape check only (see [LyricsTranslations.targetLang]); never null in
  /// practice: "no choice" deletes the row.
  final String? targetLang;
  final int updatedAt;
  const TrackTranslationPref({
    required this.trackId,
    this.targetLang,
    required this.updatedAt,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['track_id'] = i0.Variable<int>(trackId);
    if (!nullToAbsent || targetLang != null) {
      map['target_lang'] = i0.Variable<String>(targetLang);
    }
    map['updated_at'] = i0.Variable<int>(updatedAt);
    return map;
  }

  i1.TrackTranslationPrefsCompanion toCompanion(bool nullToAbsent) {
    return i1.TrackTranslationPrefsCompanion(
      trackId: i0.Value(trackId),
      targetLang: targetLang == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(targetLang),
      updatedAt: i0.Value(updatedAt),
    );
  }

  factory TrackTranslationPref.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return TrackTranslationPref(
      trackId: serializer.fromJson<int>(json['trackId']),
      targetLang: serializer.fromJson<String?>(json['targetLang']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trackId': serializer.toJson<int>(trackId),
      'targetLang': serializer.toJson<String?>(targetLang),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  i1.TrackTranslationPref copyWith({
    int? trackId,
    i0.Value<String?> targetLang = const i0.Value.absent(),
    int? updatedAt,
  }) => i1.TrackTranslationPref(
    trackId: trackId ?? this.trackId,
    targetLang: targetLang.present ? targetLang.value : this.targetLang,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TrackTranslationPref copyWithCompanion(
    i1.TrackTranslationPrefsCompanion data,
  ) {
    return TrackTranslationPref(
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      targetLang: data.targetLang.present
          ? data.targetLang.value
          : this.targetLang,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackTranslationPref(')
          ..write('trackId: $trackId, ')
          ..write('targetLang: $targetLang, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(trackId, targetLang, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.TrackTranslationPref &&
          other.trackId == this.trackId &&
          other.targetLang == this.targetLang &&
          other.updatedAt == this.updatedAt);
}

class TrackTranslationPrefsCompanion
    extends i0.UpdateCompanion<i1.TrackTranslationPref> {
  final i0.Value<int> trackId;
  final i0.Value<String?> targetLang;
  final i0.Value<int> updatedAt;
  const TrackTranslationPrefsCompanion({
    this.trackId = const i0.Value.absent(),
    this.targetLang = const i0.Value.absent(),
    this.updatedAt = const i0.Value.absent(),
  });
  TrackTranslationPrefsCompanion.insert({
    this.trackId = const i0.Value.absent(),
    this.targetLang = const i0.Value.absent(),
    required int updatedAt,
  }) : updatedAt = i0.Value(updatedAt);
  static i0.Insertable<i1.TrackTranslationPref> custom({
    i0.Expression<int>? trackId,
    i0.Expression<String>? targetLang,
    i0.Expression<int>? updatedAt,
  }) {
    return i0.RawValuesInsertable({
      if (trackId != null) 'track_id': trackId,
      if (targetLang != null) 'target_lang': targetLang,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  i1.TrackTranslationPrefsCompanion copyWith({
    i0.Value<int>? trackId,
    i0.Value<String?>? targetLang,
    i0.Value<int>? updatedAt,
  }) {
    return i1.TrackTranslationPrefsCompanion(
      trackId: trackId ?? this.trackId,
      targetLang: targetLang ?? this.targetLang,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (trackId.present) {
      map['track_id'] = i0.Variable<int>(trackId.value);
    }
    if (targetLang.present) {
      map['target_lang'] = i0.Variable<String>(targetLang.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = i0.Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackTranslationPrefsCompanion(')
          ..write('trackId: $trackId, ')
          ..write('targetLang: $targetLang, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}
