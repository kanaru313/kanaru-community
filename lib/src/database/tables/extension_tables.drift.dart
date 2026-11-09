// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:kanaru/src/database/tables/extension_tables.drift.dart' as i1;
import 'package:kanaru/src/database/tables/extension_tables.dart' as i2;

typedef $$ExtensionSchemaTableCreateCompanionBuilder =
    i1.ExtensionSchemaCompanion Function({
      required String extensionId,
      required int version,
      i0.Value<int> rowid,
    });
typedef $$ExtensionSchemaTableUpdateCompanionBuilder =
    i1.ExtensionSchemaCompanion Function({
      i0.Value<String> extensionId,
      i0.Value<int> version,
      i0.Value<int> rowid,
    });

class $$ExtensionSchemaTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$ExtensionSchemaTable> {
  $$ExtensionSchemaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get extensionId => $composableBuilder(
    column: $table.extensionId,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => i0.ColumnFilters(column),
  );
}

class $$ExtensionSchemaTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$ExtensionSchemaTable> {
  $$ExtensionSchemaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get extensionId => $composableBuilder(
    column: $table.extensionId,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $$ExtensionSchemaTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$ExtensionSchemaTable> {
  $$ExtensionSchemaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get extensionId => $composableBuilder(
    column: $table.extensionId,
    builder: (column) => column,
  );

  i0.GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$ExtensionSchemaTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$ExtensionSchemaTable,
          i1.ExtensionSchemaData,
          i1.$$ExtensionSchemaTableFilterComposer,
          i1.$$ExtensionSchemaTableOrderingComposer,
          i1.$$ExtensionSchemaTableAnnotationComposer,
          $$ExtensionSchemaTableCreateCompanionBuilder,
          $$ExtensionSchemaTableUpdateCompanionBuilder,
          (
            i1.ExtensionSchemaData,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i1.$ExtensionSchemaTable,
              i1.ExtensionSchemaData
            >,
          ),
          i1.ExtensionSchemaData,
          i0.PrefetchHooks Function()
        > {
  $$ExtensionSchemaTableTableManager(
    i0.GeneratedDatabase db,
    i1.$ExtensionSchemaTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$ExtensionSchemaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$ExtensionSchemaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => i1
              .$$ExtensionSchemaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> extensionId = const i0.Value.absent(),
                i0.Value<int> version = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.ExtensionSchemaCompanion(
                extensionId: extensionId,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String extensionId,
                required int version,
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.ExtensionSchemaCompanion.insert(
                extensionId: extensionId,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<i1.$ExtensionSchemaTable, i1.ExtensionSchemaData>(
                    table,
                  ),
                  i0.BaseReferences<
                    i0.GeneratedDatabase,
                    i1.$ExtensionSchemaTable,
                    i1.ExtensionSchemaData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExtensionSchemaTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$ExtensionSchemaTable,
      i1.ExtensionSchemaData,
      i1.$$ExtensionSchemaTableFilterComposer,
      i1.$$ExtensionSchemaTableOrderingComposer,
      i1.$$ExtensionSchemaTableAnnotationComposer,
      $$ExtensionSchemaTableCreateCompanionBuilder,
      $$ExtensionSchemaTableUpdateCompanionBuilder,
      (
        i1.ExtensionSchemaData,
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$ExtensionSchemaTable,
          i1.ExtensionSchemaData
        >,
      ),
      i1.ExtensionSchemaData,
      i0.PrefetchHooks Function()
    >;

class $ExtensionSchemaTable extends i2.ExtensionSchema
    with i0.TableInfo<$ExtensionSchemaTable, i1.ExtensionSchemaData> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExtensionSchemaTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _extensionIdMeta = const i0.VerificationMeta(
    'extensionId',
  );
  @override
  late final i0.GeneratedColumn<String> extensionId =
      i0.GeneratedColumn<String>(
        'extension_id',
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
  @override
  List<i0.GeneratedColumn> get $columns => [extensionId, version];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'extension_schema';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.ExtensionSchemaData> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('extension_id')) {
      context.handle(
        _extensionIdMeta,
        extensionId.isAcceptableOrUnknown(
          data['extension_id']!,
          _extensionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_extensionIdMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {extensionId};
  @override
  i1.ExtensionSchemaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.ExtensionSchemaData(
      extensionId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}extension_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $ExtensionSchemaTable createAlias(String alias) {
    return $ExtensionSchemaTable(attachedDatabase, alias);
  }
}

class ExtensionSchemaData extends i0.DataClass
    implements i0.Insertable<i1.ExtensionSchemaData> {
  final String extensionId;
  final int version;
  const ExtensionSchemaData({required this.extensionId, required this.version});
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['extension_id'] = i0.Variable<String>(extensionId);
    map['version'] = i0.Variable<int>(version);
    return map;
  }

  i1.ExtensionSchemaCompanion toCompanion(bool nullToAbsent) {
    return i1.ExtensionSchemaCompanion(
      extensionId: i0.Value(extensionId),
      version: i0.Value(version),
    );
  }

  factory ExtensionSchemaData.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return ExtensionSchemaData(
      extensionId: serializer.fromJson<String>(json['extensionId']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'extensionId': serializer.toJson<String>(extensionId),
      'version': serializer.toJson<int>(version),
    };
  }

  i1.ExtensionSchemaData copyWith({String? extensionId, int? version}) =>
      i1.ExtensionSchemaData(
        extensionId: extensionId ?? this.extensionId,
        version: version ?? this.version,
      );
  ExtensionSchemaData copyWithCompanion(i1.ExtensionSchemaCompanion data) {
    return ExtensionSchemaData(
      extensionId: data.extensionId.present
          ? data.extensionId.value
          : this.extensionId,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExtensionSchemaData(')
          ..write('extensionId: $extensionId, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(extensionId, version);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.ExtensionSchemaData &&
          other.extensionId == this.extensionId &&
          other.version == this.version);
}

class ExtensionSchemaCompanion
    extends i0.UpdateCompanion<i1.ExtensionSchemaData> {
  final i0.Value<String> extensionId;
  final i0.Value<int> version;
  final i0.Value<int> rowid;
  const ExtensionSchemaCompanion({
    this.extensionId = const i0.Value.absent(),
    this.version = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  ExtensionSchemaCompanion.insert({
    required String extensionId,
    required int version,
    this.rowid = const i0.Value.absent(),
  }) : extensionId = i0.Value(extensionId),
       version = i0.Value(version);
  static i0.Insertable<i1.ExtensionSchemaData> custom({
    i0.Expression<String>? extensionId,
    i0.Expression<int>? version,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (extensionId != null) 'extension_id': extensionId,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i1.ExtensionSchemaCompanion copyWith({
    i0.Value<String>? extensionId,
    i0.Value<int>? version,
    i0.Value<int>? rowid,
  }) {
    return i1.ExtensionSchemaCompanion(
      extensionId: extensionId ?? this.extensionId,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (extensionId.present) {
      map['extension_id'] = i0.Variable<String>(extensionId.value);
    }
    if (version.present) {
      map['version'] = i0.Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExtensionSchemaCompanion(')
          ..write('extensionId: $extensionId, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}
