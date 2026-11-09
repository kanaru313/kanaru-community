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
  /// Same value as `tracks.cover_key`.
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
