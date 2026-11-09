// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:kanaru/src/database/tables/library_track_search.drift.dart'
    as i1;

typedef $TrackSearchCreateCompanionBuilder = i1.TrackSearchCompanion Function({
  required String titleSort,
  required String artistSearch,
  required String albumSearch,
  required String albumArtistSearch,
  required String genreSearch,
  i0.Value<int> rowid,
});
typedef $TrackSearchUpdateCompanionBuilder = i1.TrackSearchCompanion Function({
  i0.Value<String> titleSort,
  i0.Value<String> artistSearch,
  i0.Value<String> albumSearch,
  i0.Value<String> albumArtistSearch,
  i0.Value<String> genreSearch,
  i0.Value<int> rowid,
});

class $TrackSearchFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.TrackSearch> {
  $TrackSearchFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get titleSort => $composableBuilder(
    column: $table.titleSort,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get artistSearch => $composableBuilder(
    column: $table.artistSearch,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get albumSearch => $composableBuilder(
    column: $table.albumSearch,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get albumArtistSearch => $composableBuilder(
    column: $table.albumArtistSearch,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get genreSearch => $composableBuilder(
    column: $table.genreSearch,
    builder: (column) => i0.ColumnFilters(column),
  );
}

class $TrackSearchOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.TrackSearch> {
  $TrackSearchOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get titleSort => $composableBuilder(
    column: $table.titleSort,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get artistSearch => $composableBuilder(
    column: $table.artistSearch,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get albumSearch => $composableBuilder(
    column: $table.albumSearch,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get albumArtistSearch => $composableBuilder(
    column: $table.albumArtistSearch,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get genreSearch => $composableBuilder(
    column: $table.genreSearch,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $TrackSearchAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.TrackSearch> {
  $TrackSearchAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get titleSort =>
      $composableBuilder(column: $table.titleSort, builder: (column) => column);

  i0.GeneratedColumn<String> get artistSearch => $composableBuilder(
    column: $table.artistSearch,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get albumSearch => $composableBuilder(
    column: $table.albumSearch,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get albumArtistSearch => $composableBuilder(
    column: $table.albumArtistSearch,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get genreSearch => $composableBuilder(
    column: $table.genreSearch,
    builder: (column) => column,
  );
}

class $TrackSearchTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.TrackSearch,
          i1.TrackSearchData,
          i1.$TrackSearchFilterComposer,
          i1.$TrackSearchOrderingComposer,
          i1.$TrackSearchAnnotationComposer,
          $TrackSearchCreateCompanionBuilder,
          $TrackSearchUpdateCompanionBuilder,
          (
            i1.TrackSearchData,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i1.TrackSearch,
              i1.TrackSearchData
            >,
          ),
          i1.TrackSearchData,
          i0.PrefetchHooks Function()
        > {
  $TrackSearchTableManager(i0.GeneratedDatabase db, i1.TrackSearch table)
    : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$TrackSearchFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$TrackSearchOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$TrackSearchAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> titleSort = const i0.Value.absent(),
                i0.Value<String> artistSearch = const i0.Value.absent(),
                i0.Value<String> albumSearch = const i0.Value.absent(),
                i0.Value<String> albumArtistSearch = const i0.Value.absent(),
                i0.Value<String> genreSearch = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.TrackSearchCompanion(
                titleSort: titleSort,
                artistSearch: artistSearch,
                albumSearch: albumSearch,
                albumArtistSearch: albumArtistSearch,
                genreSearch: genreSearch,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String titleSort,
                required String artistSearch,
                required String albumSearch,
                required String albumArtistSearch,
                required String genreSearch,
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i1.TrackSearchCompanion.insert(
                titleSort: titleSort,
                artistSearch: artistSearch,
                albumSearch: albumSearch,
                albumArtistSearch: albumArtistSearch,
                genreSearch: genreSearch,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<i1.TrackSearch, i1.TrackSearchData>(table),
                  i0.BaseReferences<
                    i0.GeneratedDatabase,
                    i1.TrackSearch,
                    i1.TrackSearchData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $TrackSearchProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.TrackSearch,
      i1.TrackSearchData,
      i1.$TrackSearchFilterComposer,
      i1.$TrackSearchOrderingComposer,
      i1.$TrackSearchAnnotationComposer,
      $TrackSearchCreateCompanionBuilder,
      $TrackSearchUpdateCompanionBuilder,
      (
        i1.TrackSearchData,
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.TrackSearch,
          i1.TrackSearchData
        >,
      ),
      i1.TrackSearchData,
      i0.PrefetchHooks Function()
    >;

class TrackSearch extends i0.Table
    with
        i0.TableInfo<TrackSearch, i1.TrackSearchData>,
        i0.VirtualTableInfo<TrackSearch, i1.TrackSearchData> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  TrackSearch(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _titleSortMeta = const i0.VerificationMeta(
    'titleSort',
  );
  late final i0.GeneratedColumn<String> titleSort = i0.GeneratedColumn<String>(
    'title_sort',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  static const i0.VerificationMeta _artistSearchMeta =
      const i0.VerificationMeta('artistSearch');
  late final i0.GeneratedColumn<String> artistSearch =
      i0.GeneratedColumn<String>(
        'artist_search',
        aliasedName,
        false,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: '',
      );
  static const i0.VerificationMeta _albumSearchMeta = const i0.VerificationMeta(
    'albumSearch',
  );
  late final i0.GeneratedColumn<String> albumSearch =
      i0.GeneratedColumn<String>(
        'album_search',
        aliasedName,
        false,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: '',
      );
  static const i0.VerificationMeta _albumArtistSearchMeta =
      const i0.VerificationMeta('albumArtistSearch');
  late final i0.GeneratedColumn<String> albumArtistSearch =
      i0.GeneratedColumn<String>(
        'album_artist_search',
        aliasedName,
        false,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: '',
      );
  static const i0.VerificationMeta _genreSearchMeta = const i0.VerificationMeta(
    'genreSearch',
  );
  late final i0.GeneratedColumn<String> genreSearch =
      i0.GeneratedColumn<String>(
        'genre_search',
        aliasedName,
        false,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: '',
      );
  @override
  List<i0.GeneratedColumn> get $columns => [
    titleSort,
    artistSearch,
    albumSearch,
    albumArtistSearch,
    genreSearch,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'track_search';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.TrackSearchData> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('title_sort')) {
      context.handle(
        _titleSortMeta,
        titleSort.isAcceptableOrUnknown(data['title_sort']!, _titleSortMeta),
      );
    } else if (isInserting) {
      context.missing(_titleSortMeta);
    }
    if (data.containsKey('artist_search')) {
      context.handle(
        _artistSearchMeta,
        artistSearch.isAcceptableOrUnknown(
          data['artist_search']!,
          _artistSearchMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_artistSearchMeta);
    }
    if (data.containsKey('album_search')) {
      context.handle(
        _albumSearchMeta,
        albumSearch.isAcceptableOrUnknown(
          data['album_search']!,
          _albumSearchMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_albumSearchMeta);
    }
    if (data.containsKey('album_artist_search')) {
      context.handle(
        _albumArtistSearchMeta,
        albumArtistSearch.isAcceptableOrUnknown(
          data['album_artist_search']!,
          _albumArtistSearchMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_albumArtistSearchMeta);
    }
    if (data.containsKey('genre_search')) {
      context.handle(
        _genreSearchMeta,
        genreSearch.isAcceptableOrUnknown(
          data['genre_search']!,
          _genreSearchMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_genreSearchMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => const {};
  @override
  i1.TrackSearchData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.TrackSearchData(
      titleSort: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}title_sort'],
      )!,
      artistSearch: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}artist_search'],
      )!,
      albumSearch: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}album_search'],
      )!,
      albumArtistSearch: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}album_artist_search'],
      )!,
      genreSearch: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}genre_search'],
      )!,
    );
  }

  @override
  TrackSearch createAlias(String alias) {
    return TrackSearch(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
  @override
  String get moduleAndArgs =>
      'fts5(title_sort, artist_search, album_search, album_artist_search, genre_search, content=\'tracks\', content_rowid=\'id\', tokenize=\'unicode61 remove_diacritics 0\', prefix=\'1 2 3\')';
}

class TrackSearchData extends i0.DataClass
    implements i0.Insertable<i1.TrackSearchData> {
  final String titleSort;
  final String artistSearch;
  final String albumSearch;
  final String albumArtistSearch;
  final String genreSearch;
  const TrackSearchData({
    required this.titleSort,
    required this.artistSearch,
    required this.albumSearch,
    required this.albumArtistSearch,
    required this.genreSearch,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['title_sort'] = i0.Variable<String>(titleSort);
    map['artist_search'] = i0.Variable<String>(artistSearch);
    map['album_search'] = i0.Variable<String>(albumSearch);
    map['album_artist_search'] = i0.Variable<String>(albumArtistSearch);
    map['genre_search'] = i0.Variable<String>(genreSearch);
    return map;
  }

  i1.TrackSearchCompanion toCompanion(bool nullToAbsent) {
    return i1.TrackSearchCompanion(
      titleSort: i0.Value(titleSort),
      artistSearch: i0.Value(artistSearch),
      albumSearch: i0.Value(albumSearch),
      albumArtistSearch: i0.Value(albumArtistSearch),
      genreSearch: i0.Value(genreSearch),
    );
  }

  factory TrackSearchData.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return TrackSearchData(
      titleSort: serializer.fromJson<String>(json['title_sort']),
      artistSearch: serializer.fromJson<String>(json['artist_search']),
      albumSearch: serializer.fromJson<String>(json['album_search']),
      albumArtistSearch: serializer.fromJson<String>(
        json['album_artist_search'],
      ),
      genreSearch: serializer.fromJson<String>(json['genre_search']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'title_sort': serializer.toJson<String>(titleSort),
      'artist_search': serializer.toJson<String>(artistSearch),
      'album_search': serializer.toJson<String>(albumSearch),
      'album_artist_search': serializer.toJson<String>(albumArtistSearch),
      'genre_search': serializer.toJson<String>(genreSearch),
    };
  }

  i1.TrackSearchData copyWith({
    String? titleSort,
    String? artistSearch,
    String? albumSearch,
    String? albumArtistSearch,
    String? genreSearch,
  }) => i1.TrackSearchData(
    titleSort: titleSort ?? this.titleSort,
    artistSearch: artistSearch ?? this.artistSearch,
    albumSearch: albumSearch ?? this.albumSearch,
    albumArtistSearch: albumArtistSearch ?? this.albumArtistSearch,
    genreSearch: genreSearch ?? this.genreSearch,
  );
  TrackSearchData copyWithCompanion(i1.TrackSearchCompanion data) {
    return TrackSearchData(
      titleSort: data.titleSort.present ? data.titleSort.value : this.titleSort,
      artistSearch: data.artistSearch.present
          ? data.artistSearch.value
          : this.artistSearch,
      albumSearch: data.albumSearch.present
          ? data.albumSearch.value
          : this.albumSearch,
      albumArtistSearch: data.albumArtistSearch.present
          ? data.albumArtistSearch.value
          : this.albumArtistSearch,
      genreSearch: data.genreSearch.present
          ? data.genreSearch.value
          : this.genreSearch,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackSearchData(')
          ..write('titleSort: $titleSort, ')
          ..write('artistSearch: $artistSearch, ')
          ..write('albumSearch: $albumSearch, ')
          ..write('albumArtistSearch: $albumArtistSearch, ')
          ..write('genreSearch: $genreSearch')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    titleSort,
    artistSearch,
    albumSearch,
    albumArtistSearch,
    genreSearch,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.TrackSearchData &&
          other.titleSort == this.titleSort &&
          other.artistSearch == this.artistSearch &&
          other.albumSearch == this.albumSearch &&
          other.albumArtistSearch == this.albumArtistSearch &&
          other.genreSearch == this.genreSearch);
}

class TrackSearchCompanion extends i0.UpdateCompanion<i1.TrackSearchData> {
  final i0.Value<String> titleSort;
  final i0.Value<String> artistSearch;
  final i0.Value<String> albumSearch;
  final i0.Value<String> albumArtistSearch;
  final i0.Value<String> genreSearch;
  final i0.Value<int> rowid;
  const TrackSearchCompanion({
    this.titleSort = const i0.Value.absent(),
    this.artistSearch = const i0.Value.absent(),
    this.albumSearch = const i0.Value.absent(),
    this.albumArtistSearch = const i0.Value.absent(),
    this.genreSearch = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  TrackSearchCompanion.insert({
    required String titleSort,
    required String artistSearch,
    required String albumSearch,
    required String albumArtistSearch,
    required String genreSearch,
    this.rowid = const i0.Value.absent(),
  }) : titleSort = i0.Value(titleSort),
       artistSearch = i0.Value(artistSearch),
       albumSearch = i0.Value(albumSearch),
       albumArtistSearch = i0.Value(albumArtistSearch),
       genreSearch = i0.Value(genreSearch);
  static i0.Insertable<i1.TrackSearchData> custom({
    i0.Expression<String>? titleSort,
    i0.Expression<String>? artistSearch,
    i0.Expression<String>? albumSearch,
    i0.Expression<String>? albumArtistSearch,
    i0.Expression<String>? genreSearch,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (titleSort != null) 'title_sort': titleSort,
      if (artistSearch != null) 'artist_search': artistSearch,
      if (albumSearch != null) 'album_search': albumSearch,
      if (albumArtistSearch != null) 'album_artist_search': albumArtistSearch,
      if (genreSearch != null) 'genre_search': genreSearch,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i1.TrackSearchCompanion copyWith({
    i0.Value<String>? titleSort,
    i0.Value<String>? artistSearch,
    i0.Value<String>? albumSearch,
    i0.Value<String>? albumArtistSearch,
    i0.Value<String>? genreSearch,
    i0.Value<int>? rowid,
  }) {
    return i1.TrackSearchCompanion(
      titleSort: titleSort ?? this.titleSort,
      artistSearch: artistSearch ?? this.artistSearch,
      albumSearch: albumSearch ?? this.albumSearch,
      albumArtistSearch: albumArtistSearch ?? this.albumArtistSearch,
      genreSearch: genreSearch ?? this.genreSearch,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (titleSort.present) {
      map['title_sort'] = i0.Variable<String>(titleSort.value);
    }
    if (artistSearch.present) {
      map['artist_search'] = i0.Variable<String>(artistSearch.value);
    }
    if (albumSearch.present) {
      map['album_search'] = i0.Variable<String>(albumSearch.value);
    }
    if (albumArtistSearch.present) {
      map['album_artist_search'] = i0.Variable<String>(albumArtistSearch.value);
    }
    if (genreSearch.present) {
      map['genre_search'] = i0.Variable<String>(genreSearch.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackSearchCompanion(')
          ..write('titleSort: $titleSort, ')
          ..write('artistSearch: $artistSearch, ')
          ..write('albumSearch: $albumSearch, ')
          ..write('albumArtistSearch: $albumArtistSearch, ')
          ..write('genreSearch: $genreSearch, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

i0.Trigger get tracksSearchInsert => i0.Trigger(
  'CREATE TRIGGER tracks_search_insert AFTER INSERT ON tracks BEGIN INSERT INTO track_search ("rowid", title_sort, artist_search, album_search, album_artist_search, genre_search) VALUES (new.id, new.title_sort, new.artist_search, new.album_search, new.album_artist_search, new.genre_search);END',
  'tracks_search_insert',
);
i0.Trigger get tracksSearchDelete => i0.Trigger(
  'CREATE TRIGGER tracks_search_delete AFTER DELETE ON tracks BEGIN INSERT INTO track_search (track_search, "rowid", title_sort, artist_search, album_search, album_artist_search, genre_search) VALUES (\'delete\', old.id, old.title_sort, old.artist_search, old.album_search, old.album_artist_search, old.genre_search);END',
  'tracks_search_delete',
);
i0.Trigger get tracksSearchUpdate => i0.Trigger(
  'CREATE TRIGGER tracks_search_update AFTER UPDATE OF title_sort, artist_search, album_search, album_artist_search, genre_search ON tracks WHEN old.title_sort IS NOT new.title_sort OR old.artist_search IS NOT new.artist_search OR old.album_search IS NOT new.album_search OR old.album_artist_search IS NOT new.album_artist_search OR old.genre_search IS NOT new.genre_search BEGIN INSERT INTO track_search (track_search, "rowid", title_sort, artist_search, album_search, album_artist_search, genre_search) VALUES (\'delete\', old.id, old.title_sort, old.artist_search, old.album_search, old.album_artist_search, old.genre_search);INSERT INTO track_search ("rowid", title_sort, artist_search, album_search, album_artist_search, genre_search) VALUES (new.id, new.title_sort, new.artist_search, new.album_search, new.album_artist_search, new.genre_search);END',
  'tracks_search_update',
);
