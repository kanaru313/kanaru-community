// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:kanaru/src/database/tables/library_cover_tables.drift.dart'
    as i1;
import 'package:kanaru/src/database/tables/library_cover_tables.dart' as i2;

typedef $$CoverColorsTableCreateCompanionBuilder =
    i1.CoverColorsCompanion Function({
      required String coverKey,
      required int seed,
      required String colors,
      required int version,
      required int updatedAt,
      i0.Value<int> rowid,
    });
typedef $$CoverColorsTableUpdateCompanionBuilder =
    i1.CoverColorsCompanion Function({
      i0.Value<String> coverKey,
      i0.Value<int> seed,
      i0.Value<String> colors,
      i0.Value<int> version,
      i0.Value<int> updatedAt,
      i0.Value<int> rowid,
    });

class $$CoverColorsTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$CoverColorsTable> {
  $$CoverColorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get coverKey => $composableBuilder(
    column: $table.coverKey,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get seed => $composableBuilder(
    column: $table.seed,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get colors => $composableBuilder(
    column: $table.colors,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => i0.ColumnFilters(column),
  );
}

class $$CoverColorsTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$CoverColorsTable> {
  $$CoverColorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get coverKey => $composableBuilder(
    column: $table.coverKey,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get seed => $composableBuilder(
    column: $table.seed,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get colors => $composableBuilder(
    column: $table.colors,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $$CoverColorsTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$CoverColorsTable> {
  $$CoverColorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get coverKey =>
      $composableBuilder(column: $table.coverKey, builder: (column) => column);

  i0.GeneratedColumn<int> get seed =>
      $composableBuilder(column: $table.seed, builder: (column) => column);

  i0.GeneratedColumn<String> get colors =>
      $composableBuilder(column: $table.colors, builder: (column) => column);

  i0.GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  i0.GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CoverColorsTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$CoverColorsTable,
          i1.CoverColorsRow,
          i1.$$CoverColorsTableFilterComposer,
          i1.$$CoverColorsTableOrderingComposer,
          i1.$$CoverColorsTableAnnotationComposer,
          $$CoverColorsTableCreateCompanionBuilder,
          $$CoverColorsTableUpdateCompanionBuilder,
          (
            i1.CoverColorsRow,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i1.$CoverColorsTable,
              i1.CoverColorsRow
            >,
          ),
          i1.CoverColorsRow,
          i0.PrefetchHooks Function()
        > {
  $$CoverColorsTableTableManager(
    i0.GeneratedDatabase db,
    i1.$CoverColorsTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$CoverColorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$CoverColorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$CoverColorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> coverKey = const i0.Value.absent(),
                i0.Value<int> seed = const i0.Value.absent(),
                i0.Value<String> colors = const i0.Value.absent(),
                i0.Value<int> version = const i0.Value.absent(),
                i0.Value<int> updatedAt = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.CoverColorsCompanion(
                coverKey: coverKey,
                seed: seed,
                colors: colors,
                version: version,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String coverKey,
                required int seed,
                required String colors,
                required int version,
                required int updatedAt,
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.CoverColorsCompanion.insert(
                coverKey: coverKey,
                seed: seed,
                colors: colors,
                version: version,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<i1.$CoverColorsTable, i1.CoverColorsRow>(table),
                  i0.BaseReferences<
                    i0.GeneratedDatabase,
                    i1.$CoverColorsTable,
                    i1.CoverColorsRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CoverColorsTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$CoverColorsTable,
      i1.CoverColorsRow,
      i1.$$CoverColorsTableFilterComposer,
      i1.$$CoverColorsTableOrderingComposer,
      i1.$$CoverColorsTableAnnotationComposer,
      $$CoverColorsTableCreateCompanionBuilder,
      $$CoverColorsTableUpdateCompanionBuilder,
      (
        i1.CoverColorsRow,
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$CoverColorsTable,
          i1.CoverColorsRow
        >,
      ),
      i1.CoverColorsRow,
      i0.PrefetchHooks Function()
    >;
typedef $$CustomCoversTableCreateCompanionBuilder =
    i1.CustomCoversCompanion Function({
      required String kind,
      required String itemKey,
      required String coverKey,
      required int updatedAt,
      i0.Value<int> rowid,
    });
typedef $$CustomCoversTableUpdateCompanionBuilder =
    i1.CustomCoversCompanion Function({
      i0.Value<String> kind,
      i0.Value<String> itemKey,
      i0.Value<String> coverKey,
      i0.Value<int> updatedAt,
      i0.Value<int> rowid,
    });

class $$CustomCoversTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$CustomCoversTable> {
  $$CustomCoversTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get itemKey => $composableBuilder(
    column: $table.itemKey,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get coverKey => $composableBuilder(
    column: $table.coverKey,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => i0.ColumnFilters(column),
  );
}

class $$CustomCoversTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$CustomCoversTable> {
  $$CustomCoversTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get itemKey => $composableBuilder(
    column: $table.itemKey,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get coverKey => $composableBuilder(
    column: $table.coverKey,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $$CustomCoversTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$CustomCoversTable> {
  $$CustomCoversTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  i0.GeneratedColumn<String> get itemKey =>
      $composableBuilder(column: $table.itemKey, builder: (column) => column);

  i0.GeneratedColumn<String> get coverKey =>
      $composableBuilder(column: $table.coverKey, builder: (column) => column);

  i0.GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CustomCoversTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$CustomCoversTable,
          i1.CustomCoverRow,
          i1.$$CustomCoversTableFilterComposer,
          i1.$$CustomCoversTableOrderingComposer,
          i1.$$CustomCoversTableAnnotationComposer,
          $$CustomCoversTableCreateCompanionBuilder,
          $$CustomCoversTableUpdateCompanionBuilder,
          (
            i1.CustomCoverRow,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i1.$CustomCoversTable,
              i1.CustomCoverRow
            >,
          ),
          i1.CustomCoverRow,
          i0.PrefetchHooks Function()
        > {
  $$CustomCoversTableTableManager(
    i0.GeneratedDatabase db,
    i1.$CustomCoversTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$CustomCoversTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$CustomCoversTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$CustomCoversTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> kind = const i0.Value.absent(),
                i0.Value<String> itemKey = const i0.Value.absent(),
                i0.Value<String> coverKey = const i0.Value.absent(),
                i0.Value<int> updatedAt = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.CustomCoversCompanion(
                kind: kind,
                itemKey: itemKey,
                coverKey: coverKey,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String kind,
                required String itemKey,
                required String coverKey,
                required int updatedAt,
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.CustomCoversCompanion.insert(
                kind: kind,
                itemKey: itemKey,
                coverKey: coverKey,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<i1.$CustomCoversTable, i1.CustomCoverRow>(table),
                  i0.BaseReferences<
                    i0.GeneratedDatabase,
                    i1.$CustomCoversTable,
                    i1.CustomCoverRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomCoversTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$CustomCoversTable,
      i1.CustomCoverRow,
      i1.$$CustomCoversTableFilterComposer,
      i1.$$CustomCoversTableOrderingComposer,
      i1.$$CustomCoversTableAnnotationComposer,
      $$CustomCoversTableCreateCompanionBuilder,
      $$CustomCoversTableUpdateCompanionBuilder,
      (
        i1.CustomCoverRow,
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$CustomCoversTable,
          i1.CustomCoverRow
        >,
      ),
      i1.CustomCoverRow,
      i0.PrefetchHooks Function()
    >;

class $CoverColorsTable extends i2.CoverColors
    with i0.TableInfo<$CoverColorsTable, i1.CoverColorsRow> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoverColorsTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _coverKeyMeta = const i0.VerificationMeta(
    'coverKey',
  );
  @override
  late final i0.GeneratedColumn<String> coverKey = i0.GeneratedColumn<String>(
    'cover_key',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _seedMeta = const i0.VerificationMeta(
    'seed',
  );
  @override
  late final i0.GeneratedColumn<int> seed = i0.GeneratedColumn<int>(
    'seed',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _colorsMeta = const i0.VerificationMeta(
    'colors',
  );
  @override
  late final i0.GeneratedColumn<String> colors = i0.GeneratedColumn<String>(
    'colors',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
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
    coverKey,
    seed,
    colors,
    version,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cover_colors';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.CoverColorsRow> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cover_key')) {
      context.handle(
        _coverKeyMeta,
        coverKey.isAcceptableOrUnknown(data['cover_key']!, _coverKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_coverKeyMeta);
    }
    if (data.containsKey('seed')) {
      context.handle(
        _seedMeta,
        seed.isAcceptableOrUnknown(data['seed']!, _seedMeta),
      );
    } else if (isInserting) {
      context.missing(_seedMeta);
    }
    if (data.containsKey('colors')) {
      context.handle(
        _colorsMeta,
        colors.isAcceptableOrUnknown(data['colors']!, _colorsMeta),
      );
    } else if (isInserting) {
      context.missing(_colorsMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
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
  Set<i0.GeneratedColumn> get $primaryKey => {coverKey};
  @override
  i1.CoverColorsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.CoverColorsRow(
      coverKey: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}cover_key'],
      )!,
      seed: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}seed'],
      )!,
      colors: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}colors'],
      )!,
      version: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CoverColorsTable createAlias(String alias) {
    return $CoverColorsTable(attachedDatabase, alias);
  }
}

class CoverColorsRow extends i0.DataClass
    implements i0.Insertable<i1.CoverColorsRow> {
  /// Same value as `tracks.cover_key` or `custom_covers.cover_key`.
  final String coverKey;

  /// ARGB seed colour (input of `ColorScheme.fromSeed`).
  final int seed;

  /// JSON array of ARGB ints, most dominant first.
  final String colors;

  /// Version of the algorithm that produced the row.
  final int version;
  final int updatedAt;
  const CoverColorsRow({
    required this.coverKey,
    required this.seed,
    required this.colors,
    required this.version,
    required this.updatedAt,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['cover_key'] = i0.Variable<String>(coverKey);
    map['seed'] = i0.Variable<int>(seed);
    map['colors'] = i0.Variable<String>(colors);
    map['version'] = i0.Variable<int>(version);
    map['updated_at'] = i0.Variable<int>(updatedAt);
    return map;
  }

  i1.CoverColorsCompanion toCompanion(bool nullToAbsent) {
    return i1.CoverColorsCompanion(
      coverKey: i0.Value(coverKey),
      seed: i0.Value(seed),
      colors: i0.Value(colors),
      version: i0.Value(version),
      updatedAt: i0.Value(updatedAt),
    );
  }

  factory CoverColorsRow.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return CoverColorsRow(
      coverKey: serializer.fromJson<String>(json['coverKey']),
      seed: serializer.fromJson<int>(json['seed']),
      colors: serializer.fromJson<String>(json['colors']),
      version: serializer.fromJson<int>(json['version']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'coverKey': serializer.toJson<String>(coverKey),
      'seed': serializer.toJson<int>(seed),
      'colors': serializer.toJson<String>(colors),
      'version': serializer.toJson<int>(version),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  i1.CoverColorsRow copyWith({
    String? coverKey,
    int? seed,
    String? colors,
    int? version,
    int? updatedAt,
  }) => i1.CoverColorsRow(
    coverKey: coverKey ?? this.coverKey,
    seed: seed ?? this.seed,
    colors: colors ?? this.colors,
    version: version ?? this.version,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CoverColorsRow copyWithCompanion(i1.CoverColorsCompanion data) {
    return CoverColorsRow(
      coverKey: data.coverKey.present ? data.coverKey.value : this.coverKey,
      seed: data.seed.present ? data.seed.value : this.seed,
      colors: data.colors.present ? data.colors.value : this.colors,
      version: data.version.present ? data.version.value : this.version,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CoverColorsRow(')
          ..write('coverKey: $coverKey, ')
          ..write('seed: $seed, ')
          ..write('colors: $colors, ')
          ..write('version: $version, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(coverKey, seed, colors, version, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.CoverColorsRow &&
          other.coverKey == this.coverKey &&
          other.seed == this.seed &&
          other.colors == this.colors &&
          other.version == this.version &&
          other.updatedAt == this.updatedAt);
}

class CoverColorsCompanion extends i0.UpdateCompanion<i1.CoverColorsRow> {
  final i0.Value<String> coverKey;
  final i0.Value<int> seed;
  final i0.Value<String> colors;
  final i0.Value<int> version;
  final i0.Value<int> updatedAt;
  final i0.Value<int> rowid;
  const CoverColorsCompanion({
    this.coverKey = const i0.Value.absent(),
    this.seed = const i0.Value.absent(),
    this.colors = const i0.Value.absent(),
    this.version = const i0.Value.absent(),
    this.updatedAt = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  CoverColorsCompanion.insert({
    required String coverKey,
    required int seed,
    required String colors,
    required int version,
    required int updatedAt,
    this.rowid = const i0.Value.absent(),
  }) : coverKey = i0.Value(coverKey),
       seed = i0.Value(seed),
       colors = i0.Value(colors),
       version = i0.Value(version),
       updatedAt = i0.Value(updatedAt);
  static i0.Insertable<i1.CoverColorsRow> custom({
    i0.Expression<String>? coverKey,
    i0.Expression<int>? seed,
    i0.Expression<String>? colors,
    i0.Expression<int>? version,
    i0.Expression<int>? updatedAt,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (coverKey != null) 'cover_key': coverKey,
      if (seed != null) 'seed': seed,
      if (colors != null) 'colors': colors,
      if (version != null) 'version': version,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i1.CoverColorsCompanion copyWith({
    i0.Value<String>? coverKey,
    i0.Value<int>? seed,
    i0.Value<String>? colors,
    i0.Value<int>? version,
    i0.Value<int>? updatedAt,
    i0.Value<int>? rowid,
  }) {
    return i1.CoverColorsCompanion(
      coverKey: coverKey ?? this.coverKey,
      seed: seed ?? this.seed,
      colors: colors ?? this.colors,
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (coverKey.present) {
      map['cover_key'] = i0.Variable<String>(coverKey.value);
    }
    if (seed.present) {
      map['seed'] = i0.Variable<int>(seed.value);
    }
    if (colors.present) {
      map['colors'] = i0.Variable<String>(colors.value);
    }
    if (version.present) {
      map['version'] = i0.Variable<int>(version.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = i0.Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoverColorsCompanion(')
          ..write('coverKey: $coverKey, ')
          ..write('seed: $seed, ')
          ..write('colors: $colors, ')
          ..write('version: $version, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

i0.Index get customCoversCoverKey => i0.Index(
  'custom_covers_cover_key',
  'CREATE INDEX custom_covers_cover_key ON custom_covers (cover_key)',
);

class $CustomCoversTable extends i2.CustomCovers
    with i0.TableInfo<$CustomCoversTable, i1.CustomCoverRow> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomCoversTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _kindMeta = const i0.VerificationMeta(
    'kind',
  );
  @override
  late final i0.GeneratedColumn<String> kind = i0.GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    check: () => kind.isIn(i2.CustomCoverKinds.values),
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _itemKeyMeta = const i0.VerificationMeta(
    'itemKey',
  );
  @override
  late final i0.GeneratedColumn<String> itemKey = i0.GeneratedColumn<String>(
    'item_key',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _coverKeyMeta = const i0.VerificationMeta(
    'coverKey',
  );
  @override
  late final i0.GeneratedColumn<String> coverKey = i0.GeneratedColumn<String>(
    'cover_key',
    aliasedName,
    false,
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
  List<i0.GeneratedColumn> get $columns => [kind, itemKey, coverKey, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_covers';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.CustomCoverRow> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('item_key')) {
      context.handle(
        _itemKeyMeta,
        itemKey.isAcceptableOrUnknown(data['item_key']!, _itemKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_itemKeyMeta);
    }
    if (data.containsKey('cover_key')) {
      context.handle(
        _coverKeyMeta,
        coverKey.isAcceptableOrUnknown(data['cover_key']!, _coverKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_coverKeyMeta);
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
  Set<i0.GeneratedColumn> get $primaryKey => {kind, itemKey};
  @override
  i1.CustomCoverRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.CustomCoverRow(
      kind: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      itemKey: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}item_key'],
      )!,
      coverKey: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}cover_key'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CustomCoversTable createAlias(String alias) {
    return $CustomCoversTable(attachedDatabase, alias);
  }
}

class CustomCoverRow extends i0.DataClass
    implements i0.Insertable<i1.CustomCoverRow> {
  final String kind;

  /// Playlist uid, or the encoded `AlbumKey` / `ArtistKey`.
  final String itemKey;

  /// Key of the processed cover: `<2 hex>/<32 hex>` (blake3 of the image
  /// bytes, made by the Rust import; same form as `tracks.cover_key`).
  final String coverKey;
  final int updatedAt;
  const CustomCoverRow({
    required this.kind,
    required this.itemKey,
    required this.coverKey,
    required this.updatedAt,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['kind'] = i0.Variable<String>(kind);
    map['item_key'] = i0.Variable<String>(itemKey);
    map['cover_key'] = i0.Variable<String>(coverKey);
    map['updated_at'] = i0.Variable<int>(updatedAt);
    return map;
  }

  i1.CustomCoversCompanion toCompanion(bool nullToAbsent) {
    return i1.CustomCoversCompanion(
      kind: i0.Value(kind),
      itemKey: i0.Value(itemKey),
      coverKey: i0.Value(coverKey),
      updatedAt: i0.Value(updatedAt),
    );
  }

  factory CustomCoverRow.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return CustomCoverRow(
      kind: serializer.fromJson<String>(json['kind']),
      itemKey: serializer.fromJson<String>(json['itemKey']),
      coverKey: serializer.fromJson<String>(json['coverKey']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kind': serializer.toJson<String>(kind),
      'itemKey': serializer.toJson<String>(itemKey),
      'coverKey': serializer.toJson<String>(coverKey),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  i1.CustomCoverRow copyWith({
    String? kind,
    String? itemKey,
    String? coverKey,
    int? updatedAt,
  }) => i1.CustomCoverRow(
    kind: kind ?? this.kind,
    itemKey: itemKey ?? this.itemKey,
    coverKey: coverKey ?? this.coverKey,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CustomCoverRow copyWithCompanion(i1.CustomCoversCompanion data) {
    return CustomCoverRow(
      kind: data.kind.present ? data.kind.value : this.kind,
      itemKey: data.itemKey.present ? data.itemKey.value : this.itemKey,
      coverKey: data.coverKey.present ? data.coverKey.value : this.coverKey,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomCoverRow(')
          ..write('kind: $kind, ')
          ..write('itemKey: $itemKey, ')
          ..write('coverKey: $coverKey, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(kind, itemKey, coverKey, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.CustomCoverRow &&
          other.kind == this.kind &&
          other.itemKey == this.itemKey &&
          other.coverKey == this.coverKey &&
          other.updatedAt == this.updatedAt);
}

class CustomCoversCompanion extends i0.UpdateCompanion<i1.CustomCoverRow> {
  final i0.Value<String> kind;
  final i0.Value<String> itemKey;
  final i0.Value<String> coverKey;
  final i0.Value<int> updatedAt;
  final i0.Value<int> rowid;
  const CustomCoversCompanion({
    this.kind = const i0.Value.absent(),
    this.itemKey = const i0.Value.absent(),
    this.coverKey = const i0.Value.absent(),
    this.updatedAt = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  CustomCoversCompanion.insert({
    required String kind,
    required String itemKey,
    required String coverKey,
    required int updatedAt,
    this.rowid = const i0.Value.absent(),
  }) : kind = i0.Value(kind),
       itemKey = i0.Value(itemKey),
       coverKey = i0.Value(coverKey),
       updatedAt = i0.Value(updatedAt);
  static i0.Insertable<i1.CustomCoverRow> custom({
    i0.Expression<String>? kind,
    i0.Expression<String>? itemKey,
    i0.Expression<String>? coverKey,
    i0.Expression<int>? updatedAt,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (kind != null) 'kind': kind,
      if (itemKey != null) 'item_key': itemKey,
      if (coverKey != null) 'cover_key': coverKey,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i1.CustomCoversCompanion copyWith({
    i0.Value<String>? kind,
    i0.Value<String>? itemKey,
    i0.Value<String>? coverKey,
    i0.Value<int>? updatedAt,
    i0.Value<int>? rowid,
  }) {
    return i1.CustomCoversCompanion(
      kind: kind ?? this.kind,
      itemKey: itemKey ?? this.itemKey,
      coverKey: coverKey ?? this.coverKey,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (kind.present) {
      map['kind'] = i0.Variable<String>(kind.value);
    }
    if (itemKey.present) {
      map['item_key'] = i0.Variable<String>(itemKey.value);
    }
    if (coverKey.present) {
      map['cover_key'] = i0.Variable<String>(coverKey.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = i0.Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomCoversCompanion(')
          ..write('kind: $kind, ')
          ..write('itemKey: $itemKey, ')
          ..write('coverKey: $coverKey, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}
