// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:kanaru/src/database/tables/playback_stats.drift.dart' as i1;
import 'package:drift/internal/modular.dart' as i2;

typedef $PlayStatsCtlCreateCompanionBuilder =
    i1.PlayStatsCtlCompanion Function({i0.Value<int> id, i0.Value<int> bulk});
typedef $PlayStatsCtlUpdateCompanionBuilder =
    i1.PlayStatsCtlCompanion Function({i0.Value<int> id, i0.Value<int> bulk});

class $PlayStatsCtlFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.PlayStatsCtl> {
  $PlayStatsCtlFilterComposer({
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

  i0.ColumnFilters<int> get bulk => $composableBuilder(
    column: $table.bulk,
    builder: (column) => i0.ColumnFilters(column),
  );
}

class $PlayStatsCtlOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.PlayStatsCtl> {
  $PlayStatsCtlOrderingComposer({
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

  i0.ColumnOrderings<int> get bulk => $composableBuilder(
    column: $table.bulk,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $PlayStatsCtlAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.PlayStatsCtl> {
  $PlayStatsCtlAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<int> get bulk =>
      $composableBuilder(column: $table.bulk, builder: (column) => column);
}

class $PlayStatsCtlTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.PlayStatsCtl,
          i1.PlayStatsCtlData,
          i1.$PlayStatsCtlFilterComposer,
          i1.$PlayStatsCtlOrderingComposer,
          i1.$PlayStatsCtlAnnotationComposer,
          $PlayStatsCtlCreateCompanionBuilder,
          $PlayStatsCtlUpdateCompanionBuilder,
          (
            i1.PlayStatsCtlData,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i1.PlayStatsCtl,
              i1.PlayStatsCtlData
            >,
          ),
          i1.PlayStatsCtlData,
          i0.PrefetchHooks Function()
        > {
  $PlayStatsCtlTableManager(i0.GeneratedDatabase db, i1.PlayStatsCtl table)
    : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$PlayStatsCtlFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$PlayStatsCtlOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$PlayStatsCtlAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            i0.Value<int> id = const i0.Value.absent(),
            i0.Value<int> bulk = const i0.Value.absent(),
          }) => i1.PlayStatsCtlCompanion(id: id, bulk: bulk),
          createCompanionCallback: ({
            i0.Value<int> id = const i0.Value.absent(),
            i0.Value<int> bulk = const i0.Value.absent(),
          }) => i1.PlayStatsCtlCompanion.insert(id: id, bulk: bulk),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<i1.PlayStatsCtl, i1.PlayStatsCtlData>(table),
                  i0.BaseReferences<
                    i0.GeneratedDatabase,
                    i1.PlayStatsCtl,
                    i1.PlayStatsCtlData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $PlayStatsCtlProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.PlayStatsCtl,
      i1.PlayStatsCtlData,
      i1.$PlayStatsCtlFilterComposer,
      i1.$PlayStatsCtlOrderingComposer,
      i1.$PlayStatsCtlAnnotationComposer,
      $PlayStatsCtlCreateCompanionBuilder,
      $PlayStatsCtlUpdateCompanionBuilder,
      (
        i1.PlayStatsCtlData,
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.PlayStatsCtl,
          i1.PlayStatsCtlData
        >,
      ),
      i1.PlayStatsCtlData,
      i0.PrefetchHooks Function()
    >;

class PlayStatsCtl extends i0.Table
    with i0.TableInfo<PlayStatsCtl, i1.PlayStatsCtlData> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  PlayStatsCtl(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _idMeta = const i0.VerificationMeta('id');
  late final i0.GeneratedColumn<int> id = i0.GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (id = 1)',
  );
  static const i0.VerificationMeta _bulkMeta = const i0.VerificationMeta(
    'bulk',
  );
  late final i0.GeneratedColumn<int> bulk = i0.GeneratedColumn<int>(
    'bulk',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (bulk IN (0, 1))',
    defaultValue: const i0.CustomExpression('0'),
  );
  @override
  List<i0.GeneratedColumn> get $columns => [id, bulk];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'play_stats_ctl';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.PlayStatsCtlData> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('bulk')) {
      context.handle(
        _bulkMeta,
        bulk.isAcceptableOrUnknown(data['bulk']!, _bulkMeta),
      );
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  i1.PlayStatsCtlData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.PlayStatsCtlData(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      bulk: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}bulk'],
      )!,
    );
  }

  @override
  PlayStatsCtl createAlias(String alias) {
    return PlayStatsCtl(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class PlayStatsCtlData extends i0.DataClass
    implements i0.Insertable<i1.PlayStatsCtlData> {
  final int id;
  final int bulk;
  const PlayStatsCtlData({required this.id, required this.bulk});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id);
    map['bulk'] = i0.Variable<int>(bulk);
    return map;
  }

  i1.PlayStatsCtlCompanion toCompanion(bool nullToAbsent) {
    return i1.PlayStatsCtlCompanion(id: i0.Value(id), bulk: i0.Value(bulk));
  }

  factory PlayStatsCtlData.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return PlayStatsCtlData(
      id: serializer.fromJson<int>(json['id']),
      bulk: serializer.fromJson<int>(json['bulk']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bulk': serializer.toJson<int>(bulk),
    };
  }

  i1.PlayStatsCtlData copyWith({int? id, int? bulk}) =>
      i1.PlayStatsCtlData(id: id ?? this.id, bulk: bulk ?? this.bulk);
  PlayStatsCtlData copyWithCompanion(i1.PlayStatsCtlCompanion data) {
    return PlayStatsCtlData(
      id: data.id.present ? data.id.value : this.id,
      bulk: data.bulk.present ? data.bulk.value : this.bulk,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayStatsCtlData(')
          ..write('id: $id, ')
          ..write('bulk: $bulk')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, bulk);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.PlayStatsCtlData &&
          other.id == this.id &&
          other.bulk == this.bulk);
}

class PlayStatsCtlCompanion extends i0.UpdateCompanion<i1.PlayStatsCtlData> {
  final i0.Value<int> id;
  final i0.Value<int> bulk;
  const PlayStatsCtlCompanion({
    this.id = const i0.Value.absent(),
    this.bulk = const i0.Value.absent(),
  });
  PlayStatsCtlCompanion.insert({
    this.id = const i0.Value.absent(),
    this.bulk = const i0.Value.absent(),
  });
  static i0.Insertable<i1.PlayStatsCtlData> custom({
    i0.Expression<int>? id,
    i0.Expression<int>? bulk,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (bulk != null) 'bulk': bulk,
    });
  }

  i1.PlayStatsCtlCompanion copyWith({i0.Value<int>? id, i0.Value<int>? bulk}) {
    return i1.PlayStatsCtlCompanion(id: id ?? this.id, bulk: bulk ?? this.bulk);
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<int>(id.value);
    }
    if (bulk.present) {
      map['bulk'] = i0.Variable<int>(bulk.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayStatsCtlCompanion(')
          ..write('id: $id, ')
          ..write('bulk: $bulk')
          ..write(')'))
        .toString();
  }
}

i0.OnCreateQuery get $drift0 =>
    i0.OnCreateQuery('INSERT INTO play_stats_ctl (id, bulk) VALUES (1, 0)');
i0.Trigger get playLogStatsInsert => i0.Trigger(
  'CREATE TRIGGER play_log_stats_insert AFTER INSERT ON play_log WHEN (SELECT bulk FROM play_stats_ctl WHERE id = 1) = 0 BEGIN INSERT INTO play_stats (track_id, play_count, skip_count, first_played_at, last_played_at) SELECT new.track_id, new.skipped = 0, new.skipped = 1, CASE WHEN new.skipped = 0 THEN new.played_at END, CASE WHEN new.skipped = 0 THEN new.played_at END WHERE new.deleted_at IS NULL ON CONFLICT (track_id) DO UPDATE SET play_count = play_count + excluded.play_count, skip_count = skip_count + excluded.skip_count, first_played_at = min(coalesce(first_played_at, excluded.first_played_at), coalesce(excluded.first_played_at, first_played_at)), last_played_at = max(coalesce(last_played_at, excluded.last_played_at), coalesce(excluded.last_played_at, last_played_at));END',
  'play_log_stats_insert',
);
i0.Trigger get playLogStatsUpdate => i0.Trigger(
  'CREATE TRIGGER play_log_stats_update AFTER UPDATE OF track_id, played_at, skipped, deleted_at ON play_log WHEN (SELECT bulk FROM play_stats_ctl WHERE id = 1) = 0 AND(old.track_id IS NOT new.track_id OR old.played_at IS NOT new.played_at OR old.skipped IS NOT new.skipped OR old.deleted_at IS NOT new.deleted_at)BEGIN UPDATE play_stats SET play_count = play_count -(old.skipped = 0), skip_count = skip_count -(old.skipped = 1), first_played_at = CASE WHEN old.skipped = 0 AND old.played_at <= first_played_at THEN (SELECT played_at FROM play_log WHERE track_id = old.track_id AND deleted_at IS NULL AND skipped = 0 ORDER BY played_at LIMIT 1) ELSE first_played_at END, last_played_at = CASE WHEN old.skipped = 0 AND old.played_at >= last_played_at THEN (SELECT played_at FROM play_log WHERE track_id = old.track_id AND deleted_at IS NULL AND skipped = 0 ORDER BY played_at DESC LIMIT 1) ELSE last_played_at END WHERE track_id = old.track_id AND old.deleted_at IS NULL;DELETE FROM play_stats WHERE track_id = old.track_id AND play_count <= 0 AND skip_count <= 0;INSERT INTO play_stats (track_id, play_count, skip_count, first_played_at, last_played_at) SELECT new.track_id, new.skipped = 0, new.skipped = 1, CASE WHEN new.skipped = 0 THEN new.played_at END, CASE WHEN new.skipped = 0 THEN new.played_at END WHERE new.deleted_at IS NULL ON CONFLICT (track_id) DO UPDATE SET play_count = play_count + excluded.play_count, skip_count = skip_count + excluded.skip_count, first_played_at = min(coalesce(first_played_at, excluded.first_played_at), coalesce(excluded.first_played_at, first_played_at)), last_played_at = max(coalesce(last_played_at, excluded.last_played_at), coalesce(excluded.last_played_at, last_played_at));END',
  'play_log_stats_update',
);
i0.Trigger get playLogStatsDelete => i0.Trigger(
  'CREATE TRIGGER play_log_stats_delete AFTER DELETE ON play_log WHEN (SELECT bulk FROM play_stats_ctl WHERE id = 1) = 0 BEGIN UPDATE play_stats SET play_count = play_count -(old.skipped = 0), skip_count = skip_count -(old.skipped = 1), first_played_at = CASE WHEN old.skipped = 0 AND old.played_at <= first_played_at THEN (SELECT played_at FROM play_log WHERE track_id = old.track_id AND deleted_at IS NULL AND skipped = 0 ORDER BY played_at LIMIT 1) ELSE first_played_at END, last_played_at = CASE WHEN old.skipped = 0 AND old.played_at >= last_played_at THEN (SELECT played_at FROM play_log WHERE track_id = old.track_id AND deleted_at IS NULL AND skipped = 0 ORDER BY played_at DESC LIMIT 1) ELSE last_played_at END WHERE track_id = old.track_id AND old.deleted_at IS NULL;DELETE FROM play_stats WHERE track_id = old.track_id AND play_count <= 0 AND skip_count <= 0;END',
  'play_log_stats_delete',
);

class PlaybackStatsDrift extends i2.ModularAccessor {
  PlaybackStatsDrift(i0.GeneratedDatabase db) : super(db);
  i1.PlayStatsCtl get playStatsCtl =>
      i2.ReadDatabaseContainer(attachedDatabase)
          .resultSet<i1.PlayStatsCtl>('play_stats_ctl');
}
