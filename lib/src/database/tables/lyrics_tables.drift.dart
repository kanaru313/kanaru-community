// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:kanaru/src/database/tables/lyrics_tables.drift.dart' as i1;
import 'package:kanaru/src/database/tables/lyrics_tables.dart' as i2;
import 'package:kanaru/src/database/tables/library_track_tables.drift.dart'
    as i3;
import 'package:drift/internal/modular.dart' as i4;

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

  static i3.$TracksTable _trackIdTable(i0.GeneratedDatabase db) =>
      i4.ReadDatabaseContainer(db)
          .resultSet<i3.$TracksTable>('tracks')
          .createAlias('track_lyrics_choices__track_id__tracks__id');

  i3.$$TracksTableProcessedTableManager get trackId {
    final $_column = $_itemColumn<int>('track_id')!;

    final manager = i3
        .$$TracksTableTableManager(
          $_db,
          i4.ReadDatabaseContainer($_db).resultSet<i3.$TracksTable>('tracks'),
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

  i3.$$TracksTableFilterComposer get trackId {
    final i3.$$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: i4.ReadDatabaseContainer($db)
          .resultSet<i3.$TracksTable>('tracks'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i3.$$TracksTableFilterComposer(
            $db: $db,
            $table: i4.ReadDatabaseContainer($db)
                .resultSet<i3.$TracksTable>('tracks'),
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

  i3.$$TracksTableOrderingComposer get trackId {
    final i3.$$TracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: i4.ReadDatabaseContainer($db)
          .resultSet<i3.$TracksTable>('tracks'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i3.$$TracksTableOrderingComposer(
            $db: $db,
            $table: i4.ReadDatabaseContainer($db)
                .resultSet<i3.$TracksTable>('tracks'),
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

  i3.$$TracksTableAnnotationComposer get trackId {
    final i3.$$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: i4.ReadDatabaseContainer($db)
          .resultSet<i3.$TracksTable>('tracks'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i3.$$TracksTableAnnotationComposer(
            $db: $db,
            $table: i4.ReadDatabaseContainer($db)
                .resultSet<i3.$TracksTable>('tracks'),
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

  /// `off` only for now (see [LyricsChoiceMode]).
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
