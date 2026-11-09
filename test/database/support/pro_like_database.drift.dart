// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:kanaru/src/database/tables/library_source_tables.drift.dart'
    as i1;
import 'package:kanaru/src/database/tables/library_track_tables.drift.dart'
    as i2;

import 'pro_like_database.drift.dart' as i3;
import 'pro_like_database.dart' as i4;

import 'package:drift/internal/modular.dart' as i5;

typedef $$ProLikeNotesTableCreateCompanionBuilder =
    i3.ProLikeNotesCompanion Function({
      i0.Value<int> id,
      required int trackId,
      required String body,
    });
typedef $$ProLikeNotesTableUpdateCompanionBuilder =
    i3.ProLikeNotesCompanion Function({
      i0.Value<int> id,
      i0.Value<int> trackId,
      i0.Value<String> body,
    });

final class $$ProLikeNotesTableReferences
    extends
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i3.$ProLikeNotesTable,
          i3.ProLikeNote
        > {
  $$ProLikeNotesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static i2.$TracksTable _trackIdTable(i0.GeneratedDatabase db) =>
      i5.ReadDatabaseContainer(db)
          .resultSet<i2.$TracksTable>('tracks')
          .createAlias('pro_like_notes__track_id__tracks__id');

  i2.$$TracksTableProcessedTableManager get trackId {
    final $_column = $_itemColumn<int>('track_id')!;

    final manager = i2
        .$$TracksTableTableManager(
          $_db,
          i5.ReadDatabaseContainer($_db).resultSet<i2.$TracksTable>('tracks'),
        )
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProLikeNotesTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i3.$ProLikeNotesTable> {
  $$ProLikeNotesTableFilterComposer({
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

  i0.ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => i0.ColumnFilters(column),
  );

  i2.$$TracksTableFilterComposer get trackId {
    final i2.$$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: i5.ReadDatabaseContainer($db)
          .resultSet<i2.$TracksTable>('tracks'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$$TracksTableFilterComposer(
            $db: $db,
            $table: i5.ReadDatabaseContainer($db)
                .resultSet<i2.$TracksTable>('tracks'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProLikeNotesTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i3.$ProLikeNotesTable> {
  $$ProLikeNotesTableOrderingComposer({
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

  i0.ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i2.$$TracksTableOrderingComposer get trackId {
    final i2.$$TracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: i5.ReadDatabaseContainer($db)
          .resultSet<i2.$TracksTable>('tracks'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$$TracksTableOrderingComposer(
            $db: $db,
            $table: i5.ReadDatabaseContainer($db)
                .resultSet<i2.$TracksTable>('tracks'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProLikeNotesTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i3.$ProLikeNotesTable> {
  $$ProLikeNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  i2.$$TracksTableAnnotationComposer get trackId {
    final i2.$$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: i5.ReadDatabaseContainer($db)
          .resultSet<i2.$TracksTable>('tracks'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i2.$$TracksTableAnnotationComposer(
            $db: $db,
            $table: i5.ReadDatabaseContainer($db)
                .resultSet<i2.$TracksTable>('tracks'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProLikeNotesTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i3.$ProLikeNotesTable,
          i3.ProLikeNote,
          i3.$$ProLikeNotesTableFilterComposer,
          i3.$$ProLikeNotesTableOrderingComposer,
          i3.$$ProLikeNotesTableAnnotationComposer,
          $$ProLikeNotesTableCreateCompanionBuilder,
          $$ProLikeNotesTableUpdateCompanionBuilder,
          (i3.ProLikeNote, i3.$$ProLikeNotesTableReferences),
          i3.ProLikeNote,
          i0.PrefetchHooks Function({bool trackId})
        > {
  $$ProLikeNotesTableTableManager(
    i0.GeneratedDatabase db,
    i3.$ProLikeNotesTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i3.$$ProLikeNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i3.$$ProLikeNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i3.$$ProLikeNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            i0.Value<int> id = const i0.Value.absent(),
            i0.Value<int> trackId = const i0.Value.absent(),
            i0.Value<String> body = const i0.Value.absent(),
          }) => i3.ProLikeNotesCompanion(id: id, trackId: trackId, body: body),
          createCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                required int trackId,
                required String body,
              }) => i3.ProLikeNotesCompanion.insert(
                id: id,
                trackId: trackId,
                body: body,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<i3.$ProLikeNotesTable, i3.ProLikeNote>(table),
                  i3.$$ProLikeNotesTableReferences(db, table, e),
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
                        referencedTable: i3.$$ProLikeNotesTableReferences
                            ._trackIdTable(db),
                        referencedColumn: i3.$$ProLikeNotesTableReferences
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

typedef $$ProLikeNotesTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i3.$ProLikeNotesTable,
      i3.ProLikeNote,
      i3.$$ProLikeNotesTableFilterComposer,
      i3.$$ProLikeNotesTableOrderingComposer,
      i3.$$ProLikeNotesTableAnnotationComposer,
      $$ProLikeNotesTableCreateCompanionBuilder,
      $$ProLikeNotesTableUpdateCompanionBuilder,
      (i3.ProLikeNote, i3.$$ProLikeNotesTableReferences),
      i3.ProLikeNote,
      i0.PrefetchHooks Function({bool trackId})
    >;

abstract class $ProLikeDatabase extends i0.GeneratedDatabase {
  $ProLikeDatabase(i0.QueryExecutor e) : super(e);
  $ProLikeDatabaseManager get managers => $ProLikeDatabaseManager(this);
  late final i1.$SourcesTable sources = i1.$SourcesTable(this);
  late final i2.$TracksTable tracks = i2.$TracksTable(this);
  late final i3.$ProLikeNotesTable proLikeNotes = i3.$ProLikeNotesTable(this);
  @override
  Iterable<i0.TableInfo<i0.Table, Object?>> get allTables =>
      allSchemaEntities.whereType<i0.TableInfo<i0.Table, Object?>>();
  @override
  List<i0.DatabaseSchemaEntity> get allSchemaEntities => [
    sources,
    tracks,
    proLikeNotes,
    i2.tracksPresentTitle,
    i2.tracksStatus,
    i2.tracksAddedAt,
    i2.tracksAlbumKey,
    i2.tracksSongKey,
    i2.tracksRelPath,
    i2.tracksLanguage,
    i2.tracksTagsVersion,
    i2.tracksKeysVersion,
    i2.tracksCoverVersion,
    i2.tracksGenreKey,
  ];
}

class $ProLikeDatabaseManager {
  final $ProLikeDatabase _db;
  $ProLikeDatabaseManager(this._db);
  i1.$$SourcesTableTableManager get sources =>
      i1.$$SourcesTableTableManager(_db, _db.sources);
  i2.$$TracksTableTableManager get tracks =>
      i2.$$TracksTableTableManager(_db, _db.tracks);
  i3.$$ProLikeNotesTableTableManager get proLikeNotes =>
      i3.$$ProLikeNotesTableTableManager(_db, _db.proLikeNotes);
}

class $ProLikeNotesTable extends i4.ProLikeNotes
    with i0.TableInfo<$ProLikeNotesTable, i3.ProLikeNote> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProLikeNotesTable(this.attachedDatabase, [this._alias]);
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
  static const i0.VerificationMeta _bodyMeta = const i0.VerificationMeta(
    'body',
  );
  @override
  late final i0.GeneratedColumn<String> body = i0.GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<i0.GeneratedColumn> get $columns => [id, trackId, body];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pro_like_notes';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i3.ProLikeNote> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i3.ProLikeNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i3.ProLikeNote(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      )!,
      body: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
    );
  }

  @override
  $ProLikeNotesTable createAlias(String alias) {
    return $ProLikeNotesTable(attachedDatabase, alias);
  }
}

class ProLikeNote extends i0.DataClass
    implements i0.Insertable<i3.ProLikeNote> {
  final int id;
  final int trackId;
  final String body;
  const ProLikeNote({
    required this.id,
    required this.trackId,
    required this.body,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id);
    map['track_id'] = i0.Variable<int>(trackId);
    map['body'] = i0.Variable<String>(body);
    return map;
  }

  i3.ProLikeNotesCompanion toCompanion(bool nullToAbsent) {
    return i3.ProLikeNotesCompanion(
      id: i0.Value(id),
      trackId: i0.Value(trackId),
      body: i0.Value(body),
    );
  }

  factory ProLikeNote.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return ProLikeNote(
      id: serializer.fromJson<int>(json['id']),
      trackId: serializer.fromJson<int>(json['trackId']),
      body: serializer.fromJson<String>(json['body']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trackId': serializer.toJson<int>(trackId),
      'body': serializer.toJson<String>(body),
    };
  }

  i3.ProLikeNote copyWith({int? id, int? trackId, String? body}) =>
      i3.ProLikeNote(
        id: id ?? this.id,
        trackId: trackId ?? this.trackId,
        body: body ?? this.body,
      );
  ProLikeNote copyWithCompanion(i3.ProLikeNotesCompanion data) {
    return ProLikeNote(
      id: data.id.present ? data.id.value : this.id,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      body: data.body.present ? data.body.value : this.body,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProLikeNote(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('body: $body')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, trackId, body);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i3.ProLikeNote &&
          other.id == this.id &&
          other.trackId == this.trackId &&
          other.body == this.body);
}

class ProLikeNotesCompanion extends i0.UpdateCompanion<i3.ProLikeNote> {
  final i0.Value<int> id;
  final i0.Value<int> trackId;
  final i0.Value<String> body;
  const ProLikeNotesCompanion({
    this.id = const i0.Value.absent(),
    this.trackId = const i0.Value.absent(),
    this.body = const i0.Value.absent(),
  });
  ProLikeNotesCompanion.insert({
    this.id = const i0.Value.absent(),
    required int trackId,
    required String body,
  }) : trackId = i0.Value(trackId),
       body = i0.Value(body);
  static i0.Insertable<i3.ProLikeNote> custom({
    i0.Expression<int>? id,
    i0.Expression<int>? trackId,
    i0.Expression<String>? body,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (trackId != null) 'track_id': trackId,
      if (body != null) 'body': body,
    });
  }

  i3.ProLikeNotesCompanion copyWith({
    i0.Value<int>? id,
    i0.Value<int>? trackId,
    i0.Value<String>? body,
  }) {
    return i3.ProLikeNotesCompanion(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      body: body ?? this.body,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<int>(id.value);
    }
    if (trackId.present) {
      map['track_id'] = i0.Variable<int>(trackId.value);
    }
    if (body.present) {
      map['body'] = i0.Variable<String>(body.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProLikeNotesCompanion(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('body: $body')
          ..write(')'))
        .toString();
  }
}
