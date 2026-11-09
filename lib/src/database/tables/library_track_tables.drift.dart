// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:kanaru/src/database/tables/library_track_tables.drift.dart'
    as i1;
import 'package:kanaru/src/database/tables/library_track_tables.dart' as i2;
import 'package:drift/src/runtime/query_builder/query_builder.dart' as i3;
import 'package:kanaru/src/database/tables/library_source_tables.drift.dart'
    as i4;
import 'package:drift/internal/modular.dart' as i5;

typedef $$TracksTableCreateCompanionBuilder = i1.TracksCompanion Function({
  i0.Value<int> id,
  required String uid,
  required int sourceId,
  required String locator,
  required String relPath,
  i0.Value<String?> revision,
  i0.Value<int?> mtimeMs,
  i0.Value<int?> sizeBytes,
  i0.Value<int?> startMs,
  i0.Value<int?> endMs,
  i0.Value<String?> songKey,
  required String title,
  i0.Value<String> titleSort,
  i0.Value<String?> artist,
  i0.Value<String?> album,
  i0.Value<String?> albumArtist,
  i0.Value<String?> genre,
  i0.Value<String?> composer,
  i0.Value<String?> language,
  i0.Value<String?> albumDisplayArtist,
  i0.Value<String?> artistSort,
  i0.Value<String?> albumSort,
  i0.Value<String?> artistSearch,
  i0.Value<String?> albumSearch,
  i0.Value<String?> albumArtistSearch,
  i0.Value<String?> genreSearch,
  i0.Value<String?> albumArtistKey,
  i0.Value<String?> albumTitleKey,
  i0.Value<String?> coverKey,
  i0.Value<String?> coverUrl,
  i0.Value<int?> trackNo,
  i0.Value<int?> trackTotal,
  i0.Value<int?> discNo,
  i0.Value<int?> discTotal,
  i0.Value<int?> year,
  i0.Value<int?> durationMs,
  i0.Value<int?> bitrate,
  i0.Value<int?> sampleRate,
  i0.Value<int?> bitDepth,
  i0.Value<int?> channels,
  i0.Value<int?> rating,
  i0.Value<int?> ratingUpdatedAt,
  i0.Value<int> lyricsOffsetMs,
  i0.Value<int?> lyricsOffsetUpdatedAt,
  i0.Value<String> status,
  i0.Value<int?> missingSince,
  required int addedAt,
  required int updatedAt,
});
typedef $$TracksTableUpdateCompanionBuilder = i1.TracksCompanion Function({
  i0.Value<int> id,
  i0.Value<String> uid,
  i0.Value<int> sourceId,
  i0.Value<String> locator,
  i0.Value<String> relPath,
  i0.Value<String?> revision,
  i0.Value<int?> mtimeMs,
  i0.Value<int?> sizeBytes,
  i0.Value<int?> startMs,
  i0.Value<int?> endMs,
  i0.Value<String?> songKey,
  i0.Value<String> title,
  i0.Value<String> titleSort,
  i0.Value<String?> artist,
  i0.Value<String?> album,
  i0.Value<String?> albumArtist,
  i0.Value<String?> genre,
  i0.Value<String?> composer,
  i0.Value<String?> language,
  i0.Value<String?> albumDisplayArtist,
  i0.Value<String?> artistSort,
  i0.Value<String?> albumSort,
  i0.Value<String?> artistSearch,
  i0.Value<String?> albumSearch,
  i0.Value<String?> albumArtistSearch,
  i0.Value<String?> genreSearch,
  i0.Value<String?> albumArtistKey,
  i0.Value<String?> albumTitleKey,
  i0.Value<String?> coverKey,
  i0.Value<String?> coverUrl,
  i0.Value<int?> trackNo,
  i0.Value<int?> trackTotal,
  i0.Value<int?> discNo,
  i0.Value<int?> discTotal,
  i0.Value<int?> year,
  i0.Value<int?> durationMs,
  i0.Value<int?> bitrate,
  i0.Value<int?> sampleRate,
  i0.Value<int?> bitDepth,
  i0.Value<int?> channels,
  i0.Value<int?> rating,
  i0.Value<int?> ratingUpdatedAt,
  i0.Value<int> lyricsOffsetMs,
  i0.Value<int?> lyricsOffsetUpdatedAt,
  i0.Value<String> status,
  i0.Value<int?> missingSince,
  i0.Value<int> addedAt,
  i0.Value<int> updatedAt,
});

final class $$TracksTableReferences
    extends i0.BaseReferences<i0.GeneratedDatabase, i1.$TracksTable, i1.Track> {
  $$TracksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static i4.$SourcesTable _sourceIdTable(i0.GeneratedDatabase db) =>
      i5.ReadDatabaseContainer(db)
          .resultSet<i4.$SourcesTable>('sources')
          .createAlias('tracks__source_id__sources__id');

  i4.$$SourcesTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<int>('source_id')!;

    final manager = i4
        .$$SourcesTableTableManager(
          $_db,
          i5.ReadDatabaseContainer($_db).resultSet<i4.$SourcesTable>('sources'),
        )
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static i0.MultiTypedResultKey<i1.$TrackDetailsTable, List<i1.TrackDetail>>
  _trackDetailsRefsTable(i0.GeneratedDatabase db) =>
      i0.MultiTypedResultKey.fromTable(
        i5.ReadDatabaseContainer(db)
            .resultSet<i1.$TrackDetailsTable>('track_details'),
        aliasName: 'tracks__id__track_details__track_id',
      );

  i1.$$TrackDetailsTableProcessedTableManager get trackDetailsRefs {
    final manager = i1
        .$$TrackDetailsTableTableManager(
          $_db,
          i5.ReadDatabaseContainer($_db)
              .resultSet<i1.$TrackDetailsTable>('track_details'),
        )
        .filter((f) => f.trackId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_trackDetailsRefsTable($_db));
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TracksTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$TracksTable> {
  $$TracksTableFilterComposer({
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

  i0.ColumnFilters<String> get locator => $composableBuilder(
    column: $table.locator,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get relPath => $composableBuilder(
    column: $table.relPath,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get mtimeMs => $composableBuilder(
    column: $table.mtimeMs,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get startMs => $composableBuilder(
    column: $table.startMs,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get endMs => $composableBuilder(
    column: $table.endMs,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get songKey => $composableBuilder(
    column: $table.songKey,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get titleSort => $composableBuilder(
    column: $table.titleSort,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get composer => $composableBuilder(
    column: $table.composer,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get albumDisplayArtist => $composableBuilder(
    column: $table.albumDisplayArtist,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get artistSort => $composableBuilder(
    column: $table.artistSort,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get albumSort => $composableBuilder(
    column: $table.albumSort,
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

  i0.ColumnFilters<String> get albumArtistKey => $composableBuilder(
    column: $table.albumArtistKey,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get albumTitleKey => $composableBuilder(
    column: $table.albumTitleKey,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get coverKey => $composableBuilder(
    column: $table.coverKey,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get trackNo => $composableBuilder(
    column: $table.trackNo,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get trackTotal => $composableBuilder(
    column: $table.trackTotal,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get discNo => $composableBuilder(
    column: $table.discNo,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get discTotal => $composableBuilder(
    column: $table.discTotal,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get bitrate => $composableBuilder(
    column: $table.bitrate,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get sampleRate => $composableBuilder(
    column: $table.sampleRate,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get bitDepth => $composableBuilder(
    column: $table.bitDepth,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get channels => $composableBuilder(
    column: $table.channels,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get ratingUpdatedAt => $composableBuilder(
    column: $table.ratingUpdatedAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get lyricsOffsetMs => $composableBuilder(
    column: $table.lyricsOffsetMs,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get lyricsOffsetUpdatedAt => $composableBuilder(
    column: $table.lyricsOffsetUpdatedAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get missingSince => $composableBuilder(
    column: $table.missingSince,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i4.$$SourcesTableFilterComposer get sourceId {
    final i4.$$SourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: i5.ReadDatabaseContainer($db)
          .resultSet<i4.$SourcesTable>('sources'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i4.$$SourcesTableFilterComposer(
            $db: $db,
            $table: i5.ReadDatabaseContainer($db)
                .resultSet<i4.$SourcesTable>('sources'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i0.Expression<bool> trackDetailsRefs(
    i0.Expression<bool> Function(i1.$$TrackDetailsTableFilterComposer f) f,
  ) {
    final i1.$$TrackDetailsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i5.ReadDatabaseContainer($db)
          .resultSet<i1.$TrackDetailsTable>('track_details'),
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i1.$$TrackDetailsTableFilterComposer(
            $db: $db,
            $table: i5.ReadDatabaseContainer($db)
                .resultSet<i1.$TrackDetailsTable>('track_details'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TracksTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$TracksTable> {
  $$TracksTableOrderingComposer({
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

  i0.ColumnOrderings<String> get locator => $composableBuilder(
    column: $table.locator,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get relPath => $composableBuilder(
    column: $table.relPath,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get mtimeMs => $composableBuilder(
    column: $table.mtimeMs,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get startMs => $composableBuilder(
    column: $table.startMs,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get endMs => $composableBuilder(
    column: $table.endMs,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get songKey => $composableBuilder(
    column: $table.songKey,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get titleSort => $composableBuilder(
    column: $table.titleSort,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get composer => $composableBuilder(
    column: $table.composer,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get albumDisplayArtist => $composableBuilder(
    column: $table.albumDisplayArtist,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get artistSort => $composableBuilder(
    column: $table.artistSort,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get albumSort => $composableBuilder(
    column: $table.albumSort,
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

  i0.ColumnOrderings<String> get albumArtistKey => $composableBuilder(
    column: $table.albumArtistKey,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get albumTitleKey => $composableBuilder(
    column: $table.albumTitleKey,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get coverKey => $composableBuilder(
    column: $table.coverKey,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get trackNo => $composableBuilder(
    column: $table.trackNo,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get trackTotal => $composableBuilder(
    column: $table.trackTotal,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get discNo => $composableBuilder(
    column: $table.discNo,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get discTotal => $composableBuilder(
    column: $table.discTotal,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get bitrate => $composableBuilder(
    column: $table.bitrate,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get sampleRate => $composableBuilder(
    column: $table.sampleRate,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get bitDepth => $composableBuilder(
    column: $table.bitDepth,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get channels => $composableBuilder(
    column: $table.channels,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get ratingUpdatedAt => $composableBuilder(
    column: $table.ratingUpdatedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get lyricsOffsetMs => $composableBuilder(
    column: $table.lyricsOffsetMs,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get lyricsOffsetUpdatedAt => $composableBuilder(
    column: $table.lyricsOffsetUpdatedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get missingSince => $composableBuilder(
    column: $table.missingSince,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i4.$$SourcesTableOrderingComposer get sourceId {
    final i4.$$SourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: i5.ReadDatabaseContainer($db)
          .resultSet<i4.$SourcesTable>('sources'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i4.$$SourcesTableOrderingComposer(
            $db: $db,
            $table: i5.ReadDatabaseContainer($db)
                .resultSet<i4.$SourcesTable>('sources'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TracksTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$TracksTable> {
  $$TracksTableAnnotationComposer({
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

  i0.GeneratedColumn<String> get locator =>
      $composableBuilder(column: $table.locator, builder: (column) => column);

  i0.GeneratedColumn<String> get relPath =>
      $composableBuilder(column: $table.relPath, builder: (column) => column);

  i0.GeneratedColumn<String> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  i0.GeneratedColumn<int> get mtimeMs =>
      $composableBuilder(column: $table.mtimeMs, builder: (column) => column);

  i0.GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  i0.GeneratedColumn<int> get startMs =>
      $composableBuilder(column: $table.startMs, builder: (column) => column);

  i0.GeneratedColumn<int> get endMs =>
      $composableBuilder(column: $table.endMs, builder: (column) => column);

  i0.GeneratedColumn<String> get songKey =>
      $composableBuilder(column: $table.songKey, builder: (column) => column);

  i0.GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  i0.GeneratedColumn<String> get titleSort =>
      $composableBuilder(column: $table.titleSort, builder: (column) => column);

  i0.GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  i0.GeneratedColumn<String> get album =>
      $composableBuilder(column: $table.album, builder: (column) => column);

  i0.GeneratedColumn<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  i0.GeneratedColumn<String> get composer =>
      $composableBuilder(column: $table.composer, builder: (column) => column);

  i0.GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  i0.GeneratedColumn<String> get albumDisplayArtist => $composableBuilder(
    column: $table.albumDisplayArtist,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get artistSort => $composableBuilder(
    column: $table.artistSort,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get albumSort =>
      $composableBuilder(column: $table.albumSort, builder: (column) => column);

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

  i0.GeneratedColumn<String> get albumArtistKey => $composableBuilder(
    column: $table.albumArtistKey,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get albumTitleKey => $composableBuilder(
    column: $table.albumTitleKey,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get coverKey =>
      $composableBuilder(column: $table.coverKey, builder: (column) => column);

  i0.GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  i0.GeneratedColumn<int> get trackNo =>
      $composableBuilder(column: $table.trackNo, builder: (column) => column);

  i0.GeneratedColumn<int> get trackTotal => $composableBuilder(
    column: $table.trackTotal,
    builder: (column) => column,
  );

  i0.GeneratedColumn<int> get discNo =>
      $composableBuilder(column: $table.discNo, builder: (column) => column);

  i0.GeneratedColumn<int> get discTotal =>
      $composableBuilder(column: $table.discTotal, builder: (column) => column);

  i0.GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  i0.GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  i0.GeneratedColumn<int> get bitrate =>
      $composableBuilder(column: $table.bitrate, builder: (column) => column);

  i0.GeneratedColumn<int> get sampleRate => $composableBuilder(
    column: $table.sampleRate,
    builder: (column) => column,
  );

  i0.GeneratedColumn<int> get bitDepth =>
      $composableBuilder(column: $table.bitDepth, builder: (column) => column);

  i0.GeneratedColumn<int> get channels =>
      $composableBuilder(column: $table.channels, builder: (column) => column);

  i0.GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  i0.GeneratedColumn<int> get ratingUpdatedAt => $composableBuilder(
    column: $table.ratingUpdatedAt,
    builder: (column) => column,
  );

  i0.GeneratedColumn<int> get lyricsOffsetMs => $composableBuilder(
    column: $table.lyricsOffsetMs,
    builder: (column) => column,
  );

  i0.GeneratedColumn<int> get lyricsOffsetUpdatedAt => $composableBuilder(
    column: $table.lyricsOffsetUpdatedAt,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  i0.GeneratedColumn<int> get missingSince => $composableBuilder(
    column: $table.missingSince,
    builder: (column) => column,
  );

  i0.GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  i0.GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  i4.$$SourcesTableAnnotationComposer get sourceId {
    final i4.$$SourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: i5.ReadDatabaseContainer($db)
          .resultSet<i4.$SourcesTable>('sources'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i4.$$SourcesTableAnnotationComposer(
            $db: $db,
            $table: i5.ReadDatabaseContainer($db)
                .resultSet<i4.$SourcesTable>('sources'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i0.Expression<T> trackDetailsRefs<T extends Object>(
    i0.Expression<T> Function(i1.$$TrackDetailsTableAnnotationComposer a) f,
  ) {
    final i1.$$TrackDetailsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i5.ReadDatabaseContainer($db)
          .resultSet<i1.$TrackDetailsTable>('track_details'),
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i1.$$TrackDetailsTableAnnotationComposer(
            $db: $db,
            $table: i5.ReadDatabaseContainer($db)
                .resultSet<i1.$TrackDetailsTable>('track_details'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TracksTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$TracksTable,
          i1.Track,
          i1.$$TracksTableFilterComposer,
          i1.$$TracksTableOrderingComposer,
          i1.$$TracksTableAnnotationComposer,
          $$TracksTableCreateCompanionBuilder,
          $$TracksTableUpdateCompanionBuilder,
          (i1.Track, i1.$$TracksTableReferences),
          i1.Track,
          i0.PrefetchHooks Function({bool sourceId, bool trackDetailsRefs})
        > {
  $$TracksTableTableManager(i0.GeneratedDatabase db, i1.$TracksTable table)
    : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$TracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$TracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$TracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                i0.Value<String> uid = const i0.Value.absent(),
                i0.Value<int> sourceId = const i0.Value.absent(),
                i0.Value<String> locator = const i0.Value.absent(),
                i0.Value<String> relPath = const i0.Value.absent(),
                i0.Value<String?> revision = const i0.Value.absent(),
                i0.Value<int?> mtimeMs = const i0.Value.absent(),
                i0.Value<int?> sizeBytes = const i0.Value.absent(),
                i0.Value<int?> startMs = const i0.Value.absent(),
                i0.Value<int?> endMs = const i0.Value.absent(),
                i0.Value<String?> songKey = const i0.Value.absent(),
                i0.Value<String> title = const i0.Value.absent(),
                i0.Value<String> titleSort = const i0.Value.absent(),
                i0.Value<String?> artist = const i0.Value.absent(),
                i0.Value<String?> album = const i0.Value.absent(),
                i0.Value<String?> albumArtist = const i0.Value.absent(),
                i0.Value<String?> genre = const i0.Value.absent(),
                i0.Value<String?> composer = const i0.Value.absent(),
                i0.Value<String?> language = const i0.Value.absent(),
                i0.Value<String?> albumDisplayArtist = const i0.Value.absent(),
                i0.Value<String?> artistSort = const i0.Value.absent(),
                i0.Value<String?> albumSort = const i0.Value.absent(),
                i0.Value<String?> artistSearch = const i0.Value.absent(),
                i0.Value<String?> albumSearch = const i0.Value.absent(),
                i0.Value<String?> albumArtistSearch = const i0.Value.absent(),
                i0.Value<String?> genreSearch = const i0.Value.absent(),
                i0.Value<String?> albumArtistKey = const i0.Value.absent(),
                i0.Value<String?> albumTitleKey = const i0.Value.absent(),
                i0.Value<String?> coverKey = const i0.Value.absent(),
                i0.Value<String?> coverUrl = const i0.Value.absent(),
                i0.Value<int?> trackNo = const i0.Value.absent(),
                i0.Value<int?> trackTotal = const i0.Value.absent(),
                i0.Value<int?> discNo = const i0.Value.absent(),
                i0.Value<int?> discTotal = const i0.Value.absent(),
                i0.Value<int?> year = const i0.Value.absent(),
                i0.Value<int?> durationMs = const i0.Value.absent(),
                i0.Value<int?> bitrate = const i0.Value.absent(),
                i0.Value<int?> sampleRate = const i0.Value.absent(),
                i0.Value<int?> bitDepth = const i0.Value.absent(),
                i0.Value<int?> channels = const i0.Value.absent(),
                i0.Value<int?> rating = const i0.Value.absent(),
                i0.Value<int?> ratingUpdatedAt = const i0.Value.absent(),
                i0.Value<int> lyricsOffsetMs = const i0.Value.absent(),
                i0.Value<int?> lyricsOffsetUpdatedAt = const i0.Value.absent(),
                i0.Value<String> status = const i0.Value.absent(),
                i0.Value<int?> missingSince = const i0.Value.absent(),
                i0.Value<int> addedAt = const i0.Value.absent(),
                i0.Value<int> updatedAt = const i0.Value.absent(),
              }) => i1.TracksCompanion(
                id: id,
                uid: uid,
                sourceId: sourceId,
                locator: locator,
                relPath: relPath,
                revision: revision,
                mtimeMs: mtimeMs,
                sizeBytes: sizeBytes,
                startMs: startMs,
                endMs: endMs,
                songKey: songKey,
                title: title,
                titleSort: titleSort,
                artist: artist,
                album: album,
                albumArtist: albumArtist,
                genre: genre,
                composer: composer,
                language: language,
                albumDisplayArtist: albumDisplayArtist,
                artistSort: artistSort,
                albumSort: albumSort,
                artistSearch: artistSearch,
                albumSearch: albumSearch,
                albumArtistSearch: albumArtistSearch,
                genreSearch: genreSearch,
                albumArtistKey: albumArtistKey,
                albumTitleKey: albumTitleKey,
                coverKey: coverKey,
                coverUrl: coverUrl,
                trackNo: trackNo,
                trackTotal: trackTotal,
                discNo: discNo,
                discTotal: discTotal,
                year: year,
                durationMs: durationMs,
                bitrate: bitrate,
                sampleRate: sampleRate,
                bitDepth: bitDepth,
                channels: channels,
                rating: rating,
                ratingUpdatedAt: ratingUpdatedAt,
                lyricsOffsetMs: lyricsOffsetMs,
                lyricsOffsetUpdatedAt: lyricsOffsetUpdatedAt,
                status: status,
                missingSince: missingSince,
                addedAt: addedAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                i0.Value<int> id = const i0.Value.absent(),
                required String uid,
                required int sourceId,
                required String locator,
                required String relPath,
                i0.Value<String?> revision = const i0.Value.absent(),
                i0.Value<int?> mtimeMs = const i0.Value.absent(),
                i0.Value<int?> sizeBytes = const i0.Value.absent(),
                i0.Value<int?> startMs = const i0.Value.absent(),
                i0.Value<int?> endMs = const i0.Value.absent(),
                i0.Value<String?> songKey = const i0.Value.absent(),
                required String title,
                i0.Value<String> titleSort = const i0.Value.absent(),
                i0.Value<String?> artist = const i0.Value.absent(),
                i0.Value<String?> album = const i0.Value.absent(),
                i0.Value<String?> albumArtist = const i0.Value.absent(),
                i0.Value<String?> genre = const i0.Value.absent(),
                i0.Value<String?> composer = const i0.Value.absent(),
                i0.Value<String?> language = const i0.Value.absent(),
                i0.Value<String?> albumDisplayArtist = const i0.Value.absent(),
                i0.Value<String?> artistSort = const i0.Value.absent(),
                i0.Value<String?> albumSort = const i0.Value.absent(),
                i0.Value<String?> artistSearch = const i0.Value.absent(),
                i0.Value<String?> albumSearch = const i0.Value.absent(),
                i0.Value<String?> albumArtistSearch = const i0.Value.absent(),
                i0.Value<String?> genreSearch = const i0.Value.absent(),
                i0.Value<String?> albumArtistKey = const i0.Value.absent(),
                i0.Value<String?> albumTitleKey = const i0.Value.absent(),
                i0.Value<String?> coverKey = const i0.Value.absent(),
                i0.Value<String?> coverUrl = const i0.Value.absent(),
                i0.Value<int?> trackNo = const i0.Value.absent(),
                i0.Value<int?> trackTotal = const i0.Value.absent(),
                i0.Value<int?> discNo = const i0.Value.absent(),
                i0.Value<int?> discTotal = const i0.Value.absent(),
                i0.Value<int?> year = const i0.Value.absent(),
                i0.Value<int?> durationMs = const i0.Value.absent(),
                i0.Value<int?> bitrate = const i0.Value.absent(),
                i0.Value<int?> sampleRate = const i0.Value.absent(),
                i0.Value<int?> bitDepth = const i0.Value.absent(),
                i0.Value<int?> channels = const i0.Value.absent(),
                i0.Value<int?> rating = const i0.Value.absent(),
                i0.Value<int?> ratingUpdatedAt = const i0.Value.absent(),
                i0.Value<int> lyricsOffsetMs = const i0.Value.absent(),
                i0.Value<int?> lyricsOffsetUpdatedAt = const i0.Value.absent(),
                i0.Value<String> status = const i0.Value.absent(),
                i0.Value<int?> missingSince = const i0.Value.absent(),
                required int addedAt,
                required int updatedAt,
              }) => i1.TracksCompanion.insert(
                id: id,
                uid: uid,
                sourceId: sourceId,
                locator: locator,
                relPath: relPath,
                revision: revision,
                mtimeMs: mtimeMs,
                sizeBytes: sizeBytes,
                startMs: startMs,
                endMs: endMs,
                songKey: songKey,
                title: title,
                titleSort: titleSort,
                artist: artist,
                album: album,
                albumArtist: albumArtist,
                genre: genre,
                composer: composer,
                language: language,
                albumDisplayArtist: albumDisplayArtist,
                artistSort: artistSort,
                albumSort: albumSort,
                artistSearch: artistSearch,
                albumSearch: albumSearch,
                albumArtistSearch: albumArtistSearch,
                genreSearch: genreSearch,
                albumArtistKey: albumArtistKey,
                albumTitleKey: albumTitleKey,
                coverKey: coverKey,
                coverUrl: coverUrl,
                trackNo: trackNo,
                trackTotal: trackTotal,
                discNo: discNo,
                discTotal: discTotal,
                year: year,
                durationMs: durationMs,
                bitrate: bitrate,
                sampleRate: sampleRate,
                bitDepth: bitDepth,
                channels: channels,
                rating: rating,
                ratingUpdatedAt: ratingUpdatedAt,
                lyricsOffsetMs: lyricsOffsetMs,
                lyricsOffsetUpdatedAt: lyricsOffsetUpdatedAt,
                status: status,
                missingSince: missingSince,
                addedAt: addedAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<i1.$TracksTable, i1.Track>(table),
                  i1.$$TracksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({sourceId = false, trackDetailsRefs = false}) {
                return i0.PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (trackDetailsRefs)
                      i5.ReadDatabaseContainer(db)
                          .resultSet<i1.$TrackDetailsTable>('track_details'),
                  ],
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
                        if (sourceId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.sourceId,
                            referencedTable: i1.$$TracksTableReferences
                                ._sourceIdTable(db),
                            referencedColumn: i1.$$TracksTableReferences
                                ._sourceIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (trackDetailsRefs)
                        await i0.$_getPrefetchedDataByColumns<
                          i1.Track,
                          i1.$TracksTable,
                          i1.TrackDetail,
                          i1.$TrackDetailsTable
                        >(
                          currentTable: table,
                          referencedTable: i1.$$TracksTableReferences
                              ._trackDetailsRefsTable(db),
                          managerFromTypedResult: (p0) => i1
                              .$$TracksTableReferences(db, table, p0)
                              .trackDetailsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'track_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TracksTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$TracksTable,
      i1.Track,
      i1.$$TracksTableFilterComposer,
      i1.$$TracksTableOrderingComposer,
      i1.$$TracksTableAnnotationComposer,
      $$TracksTableCreateCompanionBuilder,
      $$TracksTableUpdateCompanionBuilder,
      (i1.Track, i1.$$TracksTableReferences),
      i1.Track,
      i0.PrefetchHooks Function({bool sourceId, bool trackDetailsRefs})
    >;
typedef $$TrackDetailsTableCreateCompanionBuilder =
    i1.TrackDetailsCompanion Function({
      i0.Value<int> trackId,
      i0.Value<String?> comment,
      i0.Value<String?> extraTags,
      i0.Value<String?> lrcLocator,
      i0.Value<String?> lrcRevision,
      i0.Value<String?> coverSrc,
    });
typedef $$TrackDetailsTableUpdateCompanionBuilder =
    i1.TrackDetailsCompanion Function({
      i0.Value<int> trackId,
      i0.Value<String?> comment,
      i0.Value<String?> extraTags,
      i0.Value<String?> lrcLocator,
      i0.Value<String?> lrcRevision,
      i0.Value<String?> coverSrc,
    });

final class $$TrackDetailsTableReferences
    extends
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i1.$TrackDetailsTable,
          i1.TrackDetail
        > {
  $$TrackDetailsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static i1.$TracksTable _trackIdTable(i0.GeneratedDatabase db) =>
      i5.ReadDatabaseContainer(db)
          .resultSet<i1.$TracksTable>('tracks')
          .createAlias('track_details__track_id__tracks__id');

  i1.$$TracksTableProcessedTableManager get trackId {
    final $_column = $_itemColumn<int>('track_id')!;

    final manager = i1
        .$$TracksTableTableManager(
          $_db,
          i5.ReadDatabaseContainer($_db).resultSet<i1.$TracksTable>('tracks'),
        )
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TrackDetailsTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$TrackDetailsTable> {
  $$TrackDetailsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get extraTags => $composableBuilder(
    column: $table.extraTags,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get lrcLocator => $composableBuilder(
    column: $table.lrcLocator,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get lrcRevision => $composableBuilder(
    column: $table.lrcRevision,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get coverSrc => $composableBuilder(
    column: $table.coverSrc,
    builder: (column) => i0.ColumnFilters(column),
  );

  i1.$$TracksTableFilterComposer get trackId {
    final i1.$$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: i5.ReadDatabaseContainer($db)
          .resultSet<i1.$TracksTable>('tracks'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i1.$$TracksTableFilterComposer(
            $db: $db,
            $table: i5.ReadDatabaseContainer($db)
                .resultSet<i1.$TracksTable>('tracks'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackDetailsTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$TrackDetailsTable> {
  $$TrackDetailsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get extraTags => $composableBuilder(
    column: $table.extraTags,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get lrcLocator => $composableBuilder(
    column: $table.lrcLocator,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get lrcRevision => $composableBuilder(
    column: $table.lrcRevision,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get coverSrc => $composableBuilder(
    column: $table.coverSrc,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i1.$$TracksTableOrderingComposer get trackId {
    final i1.$$TracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: i5.ReadDatabaseContainer($db)
          .resultSet<i1.$TracksTable>('tracks'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i1.$$TracksTableOrderingComposer(
            $db: $db,
            $table: i5.ReadDatabaseContainer($db)
                .resultSet<i1.$TracksTable>('tracks'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackDetailsTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i1.$TrackDetailsTable> {
  $$TrackDetailsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get comment =>
      $composableBuilder(column: $table.comment, builder: (column) => column);

  i0.GeneratedColumn<String> get extraTags =>
      $composableBuilder(column: $table.extraTags, builder: (column) => column);

  i0.GeneratedColumn<String> get lrcLocator => $composableBuilder(
    column: $table.lrcLocator,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get lrcRevision => $composableBuilder(
    column: $table.lrcRevision,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get coverSrc =>
      $composableBuilder(column: $table.coverSrc, builder: (column) => column);

  i1.$$TracksTableAnnotationComposer get trackId {
    final i1.$$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: i5.ReadDatabaseContainer($db)
          .resultSet<i1.$TracksTable>('tracks'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i1.$$TracksTableAnnotationComposer(
            $db: $db,
            $table: i5.ReadDatabaseContainer($db)
                .resultSet<i1.$TracksTable>('tracks'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TrackDetailsTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i1.$TrackDetailsTable,
          i1.TrackDetail,
          i1.$$TrackDetailsTableFilterComposer,
          i1.$$TrackDetailsTableOrderingComposer,
          i1.$$TrackDetailsTableAnnotationComposer,
          $$TrackDetailsTableCreateCompanionBuilder,
          $$TrackDetailsTableUpdateCompanionBuilder,
          (i1.TrackDetail, i1.$$TrackDetailsTableReferences),
          i1.TrackDetail,
          i0.PrefetchHooks Function({bool trackId})
        > {
  $$TrackDetailsTableTableManager(
    i0.GeneratedDatabase db,
    i1.$TrackDetailsTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i1.$$TrackDetailsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i1.$$TrackDetailsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i1.$$TrackDetailsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<int> trackId = const i0.Value.absent(),
                i0.Value<String?> comment = const i0.Value.absent(),
                i0.Value<String?> extraTags = const i0.Value.absent(),
                i0.Value<String?> lrcLocator = const i0.Value.absent(),
                i0.Value<String?> lrcRevision = const i0.Value.absent(),
                i0.Value<String?> coverSrc = const i0.Value.absent(),
              }) => i1.TrackDetailsCompanion(
                trackId: trackId,
                comment: comment,
                extraTags: extraTags,
                lrcLocator: lrcLocator,
                lrcRevision: lrcRevision,
                coverSrc: coverSrc,
              ),
          createCompanionCallback:
              ({
                i0.Value<int> trackId = const i0.Value.absent(),
                i0.Value<String?> comment = const i0.Value.absent(),
                i0.Value<String?> extraTags = const i0.Value.absent(),
                i0.Value<String?> lrcLocator = const i0.Value.absent(),
                i0.Value<String?> lrcRevision = const i0.Value.absent(),
                i0.Value<String?> coverSrc = const i0.Value.absent(),
              }) => i1.TrackDetailsCompanion.insert(
                trackId: trackId,
                comment: comment,
                extraTags: extraTags,
                lrcLocator: lrcLocator,
                lrcRevision: lrcRevision,
                coverSrc: coverSrc,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<i1.$TrackDetailsTable, i1.TrackDetail>(table),
                  i1.$$TrackDetailsTableReferences(db, table, e),
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
                        referencedTable: i1.$$TrackDetailsTableReferences
                            ._trackIdTable(db),
                        referencedColumn: i1.$$TrackDetailsTableReferences
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

typedef $$TrackDetailsTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i1.$TrackDetailsTable,
      i1.TrackDetail,
      i1.$$TrackDetailsTableFilterComposer,
      i1.$$TrackDetailsTableOrderingComposer,
      i1.$$TrackDetailsTableAnnotationComposer,
      $$TrackDetailsTableCreateCompanionBuilder,
      $$TrackDetailsTableUpdateCompanionBuilder,
      (i1.TrackDetail, i1.$$TrackDetailsTableReferences),
      i1.TrackDetail,
      i0.PrefetchHooks Function({bool trackId})
    >;
i0.Index get tracksPresentTitle => i0.Index(
  'tracks_present_title',
  'CREATE INDEX tracks_present_title ON tracks (title_sort, id) WHERE status = \'present\'',
);

class $TracksTable extends i2.Tracks with i0.TableInfo<$TracksTable, i1.Track> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TracksTable(this.attachedDatabase, [this._alias]);
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
  static const i0.VerificationMeta _sourceIdMeta = const i0.VerificationMeta(
    'sourceId',
  );
  @override
  late final i0.GeneratedColumn<int> sourceId = i0.GeneratedColumn<int>(
    'source_id',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
      'REFERENCES sources (id) ON DELETE RESTRICT',
    ),
  );
  static const i0.VerificationMeta _locatorMeta = const i0.VerificationMeta(
    'locator',
  );
  @override
  late final i0.GeneratedColumn<String> locator = i0.GeneratedColumn<String>(
    'locator',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _relPathMeta = const i0.VerificationMeta(
    'relPath',
  );
  @override
  late final i0.GeneratedColumn<String> relPath = i0.GeneratedColumn<String>(
    'rel_path',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _revisionMeta = const i0.VerificationMeta(
    'revision',
  );
  @override
  late final i0.GeneratedColumn<String> revision = i0.GeneratedColumn<String>(
    'revision',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _mtimeMsMeta = const i0.VerificationMeta(
    'mtimeMs',
  );
  @override
  late final i0.GeneratedColumn<int> mtimeMs = i0.GeneratedColumn<int>(
    'mtime_ms',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _sizeBytesMeta = const i0.VerificationMeta(
    'sizeBytes',
  );
  @override
  late final i0.GeneratedColumn<int> sizeBytes = i0.GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _startMsMeta = const i0.VerificationMeta(
    'startMs',
  );
  @override
  late final i0.GeneratedColumn<int> startMs = i0.GeneratedColumn<int>(
    'start_ms',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _endMsMeta = const i0.VerificationMeta(
    'endMs',
  );
  @override
  late final i0.GeneratedColumn<int> endMs = i0.GeneratedColumn<int>(
    'end_ms',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _songKeyMeta = const i0.VerificationMeta(
    'songKey',
  );
  @override
  late final i0.GeneratedColumn<String> songKey = i0.GeneratedColumn<String>(
    'song_key',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const i0.VerificationMeta _titleSortMeta = const i0.VerificationMeta(
    'titleSort',
  );
  @override
  late final i0.GeneratedColumn<String> titleSort = i0.GeneratedColumn<String>(
    'title_sort',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const i3.Constant(''),
  );
  static const i0.VerificationMeta _artistMeta = const i0.VerificationMeta(
    'artist',
  );
  @override
  late final i0.GeneratedColumn<String> artist = i0.GeneratedColumn<String>(
    'artist',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _albumMeta = const i0.VerificationMeta(
    'album',
  );
  @override
  late final i0.GeneratedColumn<String> album = i0.GeneratedColumn<String>(
    'album',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _albumArtistMeta = const i0.VerificationMeta(
    'albumArtist',
  );
  @override
  late final i0.GeneratedColumn<String> albumArtist =
      i0.GeneratedColumn<String>(
        'album_artist',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const i0.VerificationMeta _genreMeta = const i0.VerificationMeta(
    'genre',
  );
  @override
  late final i0.GeneratedColumn<String> genre = i0.GeneratedColumn<String>(
    'genre',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _composerMeta = const i0.VerificationMeta(
    'composer',
  );
  @override
  late final i0.GeneratedColumn<String> composer = i0.GeneratedColumn<String>(
    'composer',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _languageMeta = const i0.VerificationMeta(
    'language',
  );
  @override
  late final i0.GeneratedColumn<String> language = i0.GeneratedColumn<String>(
    'language',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _albumDisplayArtistMeta =
      const i0.VerificationMeta('albumDisplayArtist');
  @override
  late final i0.GeneratedColumn<String> albumDisplayArtist =
      i0.GeneratedColumn<String>(
        'album_display_artist',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const i0.VerificationMeta _artistSortMeta = const i0.VerificationMeta(
    'artistSort',
  );
  @override
  late final i0.GeneratedColumn<String> artistSort = i0.GeneratedColumn<String>(
    'artist_sort',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _albumSortMeta = const i0.VerificationMeta(
    'albumSort',
  );
  @override
  late final i0.GeneratedColumn<String> albumSort = i0.GeneratedColumn<String>(
    'album_sort',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _artistSearchMeta =
      const i0.VerificationMeta('artistSearch');
  @override
  late final i0.GeneratedColumn<String> artistSearch =
      i0.GeneratedColumn<String>(
        'artist_search',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const i0.VerificationMeta _albumSearchMeta = const i0.VerificationMeta(
    'albumSearch',
  );
  @override
  late final i0.GeneratedColumn<String> albumSearch =
      i0.GeneratedColumn<String>(
        'album_search',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const i0.VerificationMeta _albumArtistSearchMeta =
      const i0.VerificationMeta('albumArtistSearch');
  @override
  late final i0.GeneratedColumn<String> albumArtistSearch =
      i0.GeneratedColumn<String>(
        'album_artist_search',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const i0.VerificationMeta _genreSearchMeta = const i0.VerificationMeta(
    'genreSearch',
  );
  @override
  late final i0.GeneratedColumn<String> genreSearch =
      i0.GeneratedColumn<String>(
        'genre_search',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const i0.VerificationMeta _albumArtistKeyMeta =
      const i0.VerificationMeta('albumArtistKey');
  @override
  late final i0.GeneratedColumn<String> albumArtistKey =
      i0.GeneratedColumn<String>(
        'album_artist_key',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const i0.VerificationMeta _albumTitleKeyMeta =
      const i0.VerificationMeta('albumTitleKey');
  @override
  late final i0.GeneratedColumn<String> albumTitleKey =
      i0.GeneratedColumn<String>(
        'album_title_key',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const i0.VerificationMeta _coverKeyMeta = const i0.VerificationMeta(
    'coverKey',
  );
  @override
  late final i0.GeneratedColumn<String> coverKey = i0.GeneratedColumn<String>(
    'cover_key',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _coverUrlMeta = const i0.VerificationMeta(
    'coverUrl',
  );
  @override
  late final i0.GeneratedColumn<String> coverUrl = i0.GeneratedColumn<String>(
    'cover_url',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _trackNoMeta = const i0.VerificationMeta(
    'trackNo',
  );
  @override
  late final i0.GeneratedColumn<int> trackNo = i0.GeneratedColumn<int>(
    'track_no',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _trackTotalMeta = const i0.VerificationMeta(
    'trackTotal',
  );
  @override
  late final i0.GeneratedColumn<int> trackTotal = i0.GeneratedColumn<int>(
    'track_total',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _discNoMeta = const i0.VerificationMeta(
    'discNo',
  );
  @override
  late final i0.GeneratedColumn<int> discNo = i0.GeneratedColumn<int>(
    'disc_no',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _discTotalMeta = const i0.VerificationMeta(
    'discTotal',
  );
  @override
  late final i0.GeneratedColumn<int> discTotal = i0.GeneratedColumn<int>(
    'disc_total',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _yearMeta = const i0.VerificationMeta(
    'year',
  );
  @override
  late final i0.GeneratedColumn<int> year = i0.GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _durationMsMeta = const i0.VerificationMeta(
    'durationMs',
  );
  @override
  late final i0.GeneratedColumn<int> durationMs = i0.GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _bitrateMeta = const i0.VerificationMeta(
    'bitrate',
  );
  @override
  late final i0.GeneratedColumn<int> bitrate = i0.GeneratedColumn<int>(
    'bitrate',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _sampleRateMeta = const i0.VerificationMeta(
    'sampleRate',
  );
  @override
  late final i0.GeneratedColumn<int> sampleRate = i0.GeneratedColumn<int>(
    'sample_rate',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _bitDepthMeta = const i0.VerificationMeta(
    'bitDepth',
  );
  @override
  late final i0.GeneratedColumn<int> bitDepth = i0.GeneratedColumn<int>(
    'bit_depth',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _channelsMeta = const i0.VerificationMeta(
    'channels',
  );
  @override
  late final i0.GeneratedColumn<int> channels = i0.GeneratedColumn<int>(
    'channels',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _ratingMeta = const i0.VerificationMeta(
    'rating',
  );
  @override
  late final i0.GeneratedColumn<int> rating = i0.GeneratedColumn<int>(
    'rating',
    aliasedName,
    true,
    check: () =>
        i3.ComparableExpr(rating)
            .isBetween(const i3.Constant(0), const i3.Constant(100)),
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _ratingUpdatedAtMeta =
      const i0.VerificationMeta('ratingUpdatedAt');
  @override
  late final i0.GeneratedColumn<int> ratingUpdatedAt = i0.GeneratedColumn<int>(
    'rating_updated_at',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _lyricsOffsetMsMeta =
      const i0.VerificationMeta('lyricsOffsetMs');
  @override
  late final i0.GeneratedColumn<int> lyricsOffsetMs = i0.GeneratedColumn<int>(
    'lyrics_offset_ms',
    aliasedName,
    false,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const i3.Constant(0),
  );
  static const i0.VerificationMeta _lyricsOffsetUpdatedAtMeta =
      const i0.VerificationMeta('lyricsOffsetUpdatedAt');
  @override
  late final i0.GeneratedColumn<int> lyricsOffsetUpdatedAt =
      i0.GeneratedColumn<int>(
        'lyrics_offset_updated_at',
        aliasedName,
        true,
        type: i0.DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const i0.VerificationMeta _statusMeta = const i0.VerificationMeta(
    'status',
  );
  @override
  late final i0.GeneratedColumn<String> status = i0.GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    check: () => status.isIn(i2.TrackStatus.values),
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const i3.Constant(i2.TrackStatus.present),
  );
  static const i0.VerificationMeta _missingSinceMeta =
      const i0.VerificationMeta('missingSince');
  @override
  late final i0.GeneratedColumn<int> missingSince = i0.GeneratedColumn<int>(
    'missing_since',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _addedAtMeta = const i0.VerificationMeta(
    'addedAt',
  );
  @override
  late final i0.GeneratedColumn<int> addedAt = i0.GeneratedColumn<int>(
    'added_at',
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
    id,
    uid,
    sourceId,
    locator,
    relPath,
    revision,
    mtimeMs,
    sizeBytes,
    startMs,
    endMs,
    songKey,
    title,
    titleSort,
    artist,
    album,
    albumArtist,
    genre,
    composer,
    language,
    albumDisplayArtist,
    artistSort,
    albumSort,
    artistSearch,
    albumSearch,
    albumArtistSearch,
    genreSearch,
    albumArtistKey,
    albumTitleKey,
    coverKey,
    coverUrl,
    trackNo,
    trackTotal,
    discNo,
    discTotal,
    year,
    durationMs,
    bitrate,
    sampleRate,
    bitDepth,
    channels,
    rating,
    ratingUpdatedAt,
    lyricsOffsetMs,
    lyricsOffsetUpdatedAt,
    status,
    missingSince,
    addedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracks';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.Track> instance, {
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
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('locator')) {
      context.handle(
        _locatorMeta,
        locator.isAcceptableOrUnknown(data['locator']!, _locatorMeta),
      );
    } else if (isInserting) {
      context.missing(_locatorMeta);
    }
    if (data.containsKey('rel_path')) {
      context.handle(
        _relPathMeta,
        relPath.isAcceptableOrUnknown(data['rel_path']!, _relPathMeta),
      );
    } else if (isInserting) {
      context.missing(_relPathMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('mtime_ms')) {
      context.handle(
        _mtimeMsMeta,
        mtimeMs.isAcceptableOrUnknown(data['mtime_ms']!, _mtimeMsMeta),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    if (data.containsKey('start_ms')) {
      context.handle(
        _startMsMeta,
        startMs.isAcceptableOrUnknown(data['start_ms']!, _startMsMeta),
      );
    }
    if (data.containsKey('end_ms')) {
      context.handle(
        _endMsMeta,
        endMs.isAcceptableOrUnknown(data['end_ms']!, _endMsMeta),
      );
    }
    if (data.containsKey('song_key')) {
      context.handle(
        _songKeyMeta,
        songKey.isAcceptableOrUnknown(data['song_key']!, _songKeyMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('title_sort')) {
      context.handle(
        _titleSortMeta,
        titleSort.isAcceptableOrUnknown(data['title_sort']!, _titleSortMeta),
      );
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    }
    if (data.containsKey('album')) {
      context.handle(
        _albumMeta,
        album.isAcceptableOrUnknown(data['album']!, _albumMeta),
      );
    }
    if (data.containsKey('album_artist')) {
      context.handle(
        _albumArtistMeta,
        albumArtist.isAcceptableOrUnknown(
          data['album_artist']!,
          _albumArtistMeta,
        ),
      );
    }
    if (data.containsKey('genre')) {
      context.handle(
        _genreMeta,
        genre.isAcceptableOrUnknown(data['genre']!, _genreMeta),
      );
    }
    if (data.containsKey('composer')) {
      context.handle(
        _composerMeta,
        composer.isAcceptableOrUnknown(data['composer']!, _composerMeta),
      );
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('album_display_artist')) {
      context.handle(
        _albumDisplayArtistMeta,
        albumDisplayArtist.isAcceptableOrUnknown(
          data['album_display_artist']!,
          _albumDisplayArtistMeta,
        ),
      );
    }
    if (data.containsKey('artist_sort')) {
      context.handle(
        _artistSortMeta,
        artistSort.isAcceptableOrUnknown(data['artist_sort']!, _artistSortMeta),
      );
    }
    if (data.containsKey('album_sort')) {
      context.handle(
        _albumSortMeta,
        albumSort.isAcceptableOrUnknown(data['album_sort']!, _albumSortMeta),
      );
    }
    if (data.containsKey('artist_search')) {
      context.handle(
        _artistSearchMeta,
        artistSearch.isAcceptableOrUnknown(
          data['artist_search']!,
          _artistSearchMeta,
        ),
      );
    }
    if (data.containsKey('album_search')) {
      context.handle(
        _albumSearchMeta,
        albumSearch.isAcceptableOrUnknown(
          data['album_search']!,
          _albumSearchMeta,
        ),
      );
    }
    if (data.containsKey('album_artist_search')) {
      context.handle(
        _albumArtistSearchMeta,
        albumArtistSearch.isAcceptableOrUnknown(
          data['album_artist_search']!,
          _albumArtistSearchMeta,
        ),
      );
    }
    if (data.containsKey('genre_search')) {
      context.handle(
        _genreSearchMeta,
        genreSearch.isAcceptableOrUnknown(
          data['genre_search']!,
          _genreSearchMeta,
        ),
      );
    }
    if (data.containsKey('album_artist_key')) {
      context.handle(
        _albumArtistKeyMeta,
        albumArtistKey.isAcceptableOrUnknown(
          data['album_artist_key']!,
          _albumArtistKeyMeta,
        ),
      );
    }
    if (data.containsKey('album_title_key')) {
      context.handle(
        _albumTitleKeyMeta,
        albumTitleKey.isAcceptableOrUnknown(
          data['album_title_key']!,
          _albumTitleKeyMeta,
        ),
      );
    }
    if (data.containsKey('cover_key')) {
      context.handle(
        _coverKeyMeta,
        coverKey.isAcceptableOrUnknown(data['cover_key']!, _coverKeyMeta),
      );
    }
    if (data.containsKey('cover_url')) {
      context.handle(
        _coverUrlMeta,
        coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta),
      );
    }
    if (data.containsKey('track_no')) {
      context.handle(
        _trackNoMeta,
        trackNo.isAcceptableOrUnknown(data['track_no']!, _trackNoMeta),
      );
    }
    if (data.containsKey('track_total')) {
      context.handle(
        _trackTotalMeta,
        trackTotal.isAcceptableOrUnknown(data['track_total']!, _trackTotalMeta),
      );
    }
    if (data.containsKey('disc_no')) {
      context.handle(
        _discNoMeta,
        discNo.isAcceptableOrUnknown(data['disc_no']!, _discNoMeta),
      );
    }
    if (data.containsKey('disc_total')) {
      context.handle(
        _discTotalMeta,
        discTotal.isAcceptableOrUnknown(data['disc_total']!, _discTotalMeta),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('bitrate')) {
      context.handle(
        _bitrateMeta,
        bitrate.isAcceptableOrUnknown(data['bitrate']!, _bitrateMeta),
      );
    }
    if (data.containsKey('sample_rate')) {
      context.handle(
        _sampleRateMeta,
        sampleRate.isAcceptableOrUnknown(data['sample_rate']!, _sampleRateMeta),
      );
    }
    if (data.containsKey('bit_depth')) {
      context.handle(
        _bitDepthMeta,
        bitDepth.isAcceptableOrUnknown(data['bit_depth']!, _bitDepthMeta),
      );
    }
    if (data.containsKey('channels')) {
      context.handle(
        _channelsMeta,
        channels.isAcceptableOrUnknown(data['channels']!, _channelsMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('rating_updated_at')) {
      context.handle(
        _ratingUpdatedAtMeta,
        ratingUpdatedAt.isAcceptableOrUnknown(
          data['rating_updated_at']!,
          _ratingUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('lyrics_offset_ms')) {
      context.handle(
        _lyricsOffsetMsMeta,
        lyricsOffsetMs.isAcceptableOrUnknown(
          data['lyrics_offset_ms']!,
          _lyricsOffsetMsMeta,
        ),
      );
    }
    if (data.containsKey('lyrics_offset_updated_at')) {
      context.handle(
        _lyricsOffsetUpdatedAtMeta,
        lyricsOffsetUpdatedAt.isAcceptableOrUnknown(
          data['lyrics_offset_updated_at']!,
          _lyricsOffsetUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('missing_since')) {
      context.handle(
        _missingSinceMeta,
        missingSince.isAcceptableOrUnknown(
          data['missing_since']!,
          _missingSinceMeta,
        ),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
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
  Set<i0.GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<i0.GeneratedColumn>> get uniqueKeys => [
    {sourceId, locator},
  ];
  @override
  i1.Track map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.Track(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uid: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      )!,
      locator: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}locator'],
      )!,
      relPath: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}rel_path'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}revision'],
      ),
      mtimeMs: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}mtime_ms'],
      ),
      sizeBytes: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      ),
      startMs: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}start_ms'],
      ),
      endMs: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}end_ms'],
      ),
      songKey: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}song_key'],
      ),
      title: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      titleSort: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}title_sort'],
      )!,
      artist: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}artist'],
      ),
      album: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}album'],
      ),
      albumArtist: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}album_artist'],
      ),
      genre: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}genre'],
      ),
      composer: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}composer'],
      ),
      language: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}language'],
      ),
      albumDisplayArtist: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}album_display_artist'],
      ),
      artistSort: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}artist_sort'],
      ),
      albumSort: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}album_sort'],
      ),
      artistSearch: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}artist_search'],
      ),
      albumSearch: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}album_search'],
      ),
      albumArtistSearch: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}album_artist_search'],
      ),
      genreSearch: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}genre_search'],
      ),
      albumArtistKey: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}album_artist_key'],
      ),
      albumTitleKey: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}album_title_key'],
      ),
      coverKey: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}cover_key'],
      ),
      coverUrl: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}cover_url'],
      ),
      trackNo: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}track_no'],
      ),
      trackTotal: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}track_total'],
      ),
      discNo: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}disc_no'],
      ),
      discTotal: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}disc_total'],
      ),
      year: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      bitrate: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}bitrate'],
      ),
      sampleRate: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}sample_rate'],
      ),
      bitDepth: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}bit_depth'],
      ),
      channels: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}channels'],
      ),
      rating: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}rating'],
      ),
      ratingUpdatedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}rating_updated_at'],
      ),
      lyricsOffsetMs: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}lyrics_offset_ms'],
      )!,
      lyricsOffsetUpdatedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}lyrics_offset_updated_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      missingSince: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}missing_since'],
      ),
      addedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}added_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TracksTable createAlias(String alias) {
    return $TracksTable(attachedDatabase, alias);
  }
}

class Track extends i0.DataClass implements i0.Insertable<i1.Track> {
  final int id;
  final String uid;
  final int sourceId;

  /// Path relative to the mount root, or the provider file id.
  final String locator;
  final String relPath;
  final String? revision;
  final int? mtimeMs;
  final int? sizeBytes;
  final int? startMs;
  final int? endMs;
  final String? songKey;
  final String title;
  final String titleSort;
  final String? artist;
  final String? album;
  final String? albumArtist;
  final String? genre;
  final String? composer;
  final String? language;
  final String? albumDisplayArtist;
  final String? artistSort;
  final String? albumSort;
  final String? artistSearch;
  final String? albumSearch;
  final String? albumArtistSearch;
  final String? genreSearch;
  final String? albumArtistKey;
  final String? albumTitleKey;
  final String? coverKey;
  final String? coverUrl;
  final int? trackNo;
  final int? trackTotal;
  final int? discNo;
  final int? discTotal;
  final int? year;
  final int? durationMs;
  final int? bitrate;
  final int? sampleRate;
  final int? bitDepth;
  final int? channels;
  final int? rating;
  final int? ratingUpdatedAt;
  final int lyricsOffsetMs;
  final int? lyricsOffsetUpdatedAt;
  final String status;

  /// Set when a row becomes `missing`.
  final int? missingSince;
  final int addedAt;
  final int updatedAt;
  const Track({
    required this.id,
    required this.uid,
    required this.sourceId,
    required this.locator,
    required this.relPath,
    this.revision,
    this.mtimeMs,
    this.sizeBytes,
    this.startMs,
    this.endMs,
    this.songKey,
    required this.title,
    required this.titleSort,
    this.artist,
    this.album,
    this.albumArtist,
    this.genre,
    this.composer,
    this.language,
    this.albumDisplayArtist,
    this.artistSort,
    this.albumSort,
    this.artistSearch,
    this.albumSearch,
    this.albumArtistSearch,
    this.genreSearch,
    this.albumArtistKey,
    this.albumTitleKey,
    this.coverKey,
    this.coverUrl,
    this.trackNo,
    this.trackTotal,
    this.discNo,
    this.discTotal,
    this.year,
    this.durationMs,
    this.bitrate,
    this.sampleRate,
    this.bitDepth,
    this.channels,
    this.rating,
    this.ratingUpdatedAt,
    required this.lyricsOffsetMs,
    this.lyricsOffsetUpdatedAt,
    required this.status,
    this.missingSince,
    required this.addedAt,
    required this.updatedAt,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['id'] = i0.Variable<int>(id);
    map['uid'] = i0.Variable<String>(uid);
    map['source_id'] = i0.Variable<int>(sourceId);
    map['locator'] = i0.Variable<String>(locator);
    map['rel_path'] = i0.Variable<String>(relPath);
    if (!nullToAbsent || revision != null) {
      map['revision'] = i0.Variable<String>(revision);
    }
    if (!nullToAbsent || mtimeMs != null) {
      map['mtime_ms'] = i0.Variable<int>(mtimeMs);
    }
    if (!nullToAbsent || sizeBytes != null) {
      map['size_bytes'] = i0.Variable<int>(sizeBytes);
    }
    if (!nullToAbsent || startMs != null) {
      map['start_ms'] = i0.Variable<int>(startMs);
    }
    if (!nullToAbsent || endMs != null) {
      map['end_ms'] = i0.Variable<int>(endMs);
    }
    if (!nullToAbsent || songKey != null) {
      map['song_key'] = i0.Variable<String>(songKey);
    }
    map['title'] = i0.Variable<String>(title);
    map['title_sort'] = i0.Variable<String>(titleSort);
    if (!nullToAbsent || artist != null) {
      map['artist'] = i0.Variable<String>(artist);
    }
    if (!nullToAbsent || album != null) {
      map['album'] = i0.Variable<String>(album);
    }
    if (!nullToAbsent || albumArtist != null) {
      map['album_artist'] = i0.Variable<String>(albumArtist);
    }
    if (!nullToAbsent || genre != null) {
      map['genre'] = i0.Variable<String>(genre);
    }
    if (!nullToAbsent || composer != null) {
      map['composer'] = i0.Variable<String>(composer);
    }
    if (!nullToAbsent || language != null) {
      map['language'] = i0.Variable<String>(language);
    }
    if (!nullToAbsent || albumDisplayArtist != null) {
      map['album_display_artist'] = i0.Variable<String>(albumDisplayArtist);
    }
    if (!nullToAbsent || artistSort != null) {
      map['artist_sort'] = i0.Variable<String>(artistSort);
    }
    if (!nullToAbsent || albumSort != null) {
      map['album_sort'] = i0.Variable<String>(albumSort);
    }
    if (!nullToAbsent || artistSearch != null) {
      map['artist_search'] = i0.Variable<String>(artistSearch);
    }
    if (!nullToAbsent || albumSearch != null) {
      map['album_search'] = i0.Variable<String>(albumSearch);
    }
    if (!nullToAbsent || albumArtistSearch != null) {
      map['album_artist_search'] = i0.Variable<String>(albumArtistSearch);
    }
    if (!nullToAbsent || genreSearch != null) {
      map['genre_search'] = i0.Variable<String>(genreSearch);
    }
    if (!nullToAbsent || albumArtistKey != null) {
      map['album_artist_key'] = i0.Variable<String>(albumArtistKey);
    }
    if (!nullToAbsent || albumTitleKey != null) {
      map['album_title_key'] = i0.Variable<String>(albumTitleKey);
    }
    if (!nullToAbsent || coverKey != null) {
      map['cover_key'] = i0.Variable<String>(coverKey);
    }
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = i0.Variable<String>(coverUrl);
    }
    if (!nullToAbsent || trackNo != null) {
      map['track_no'] = i0.Variable<int>(trackNo);
    }
    if (!nullToAbsent || trackTotal != null) {
      map['track_total'] = i0.Variable<int>(trackTotal);
    }
    if (!nullToAbsent || discNo != null) {
      map['disc_no'] = i0.Variable<int>(discNo);
    }
    if (!nullToAbsent || discTotal != null) {
      map['disc_total'] = i0.Variable<int>(discTotal);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = i0.Variable<int>(year);
    }
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = i0.Variable<int>(durationMs);
    }
    if (!nullToAbsent || bitrate != null) {
      map['bitrate'] = i0.Variable<int>(bitrate);
    }
    if (!nullToAbsent || sampleRate != null) {
      map['sample_rate'] = i0.Variable<int>(sampleRate);
    }
    if (!nullToAbsent || bitDepth != null) {
      map['bit_depth'] = i0.Variable<int>(bitDepth);
    }
    if (!nullToAbsent || channels != null) {
      map['channels'] = i0.Variable<int>(channels);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = i0.Variable<int>(rating);
    }
    if (!nullToAbsent || ratingUpdatedAt != null) {
      map['rating_updated_at'] = i0.Variable<int>(ratingUpdatedAt);
    }
    map['lyrics_offset_ms'] = i0.Variable<int>(lyricsOffsetMs);
    if (!nullToAbsent || lyricsOffsetUpdatedAt != null) {
      map['lyrics_offset_updated_at'] = i0.Variable<int>(lyricsOffsetUpdatedAt);
    }
    map['status'] = i0.Variable<String>(status);
    if (!nullToAbsent || missingSince != null) {
      map['missing_since'] = i0.Variable<int>(missingSince);
    }
    map['added_at'] = i0.Variable<int>(addedAt);
    map['updated_at'] = i0.Variable<int>(updatedAt);
    return map;
  }

  i1.TracksCompanion toCompanion(bool nullToAbsent) {
    return i1.TracksCompanion(
      id: i0.Value(id),
      uid: i0.Value(uid),
      sourceId: i0.Value(sourceId),
      locator: i0.Value(locator),
      relPath: i0.Value(relPath),
      revision: revision == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(revision),
      mtimeMs: mtimeMs == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(mtimeMs),
      sizeBytes: sizeBytes == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(sizeBytes),
      startMs: startMs == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(startMs),
      endMs: endMs == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(endMs),
      songKey: songKey == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(songKey),
      title: i0.Value(title),
      titleSort: i0.Value(titleSort),
      artist: artist == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(artist),
      album: album == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(album),
      albumArtist: albumArtist == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(albumArtist),
      genre: genre == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(genre),
      composer: composer == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(composer),
      language: language == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(language),
      albumDisplayArtist: albumDisplayArtist == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(albumDisplayArtist),
      artistSort: artistSort == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(artistSort),
      albumSort: albumSort == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(albumSort),
      artistSearch: artistSearch == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(artistSearch),
      albumSearch: albumSearch == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(albumSearch),
      albumArtistSearch: albumArtistSearch == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(albumArtistSearch),
      genreSearch: genreSearch == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(genreSearch),
      albumArtistKey: albumArtistKey == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(albumArtistKey),
      albumTitleKey: albumTitleKey == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(albumTitleKey),
      coverKey: coverKey == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(coverKey),
      coverUrl: coverUrl == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(coverUrl),
      trackNo: trackNo == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(trackNo),
      trackTotal: trackTotal == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(trackTotal),
      discNo: discNo == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(discNo),
      discTotal: discTotal == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(discTotal),
      year: year == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(year),
      durationMs: durationMs == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(durationMs),
      bitrate: bitrate == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(bitrate),
      sampleRate: sampleRate == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(sampleRate),
      bitDepth: bitDepth == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(bitDepth),
      channels: channels == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(channels),
      rating: rating == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(rating),
      ratingUpdatedAt: ratingUpdatedAt == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(ratingUpdatedAt),
      lyricsOffsetMs: i0.Value(lyricsOffsetMs),
      lyricsOffsetUpdatedAt: lyricsOffsetUpdatedAt == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(lyricsOffsetUpdatedAt),
      status: i0.Value(status),
      missingSince: missingSince == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(missingSince),
      addedAt: i0.Value(addedAt),
      updatedAt: i0.Value(updatedAt),
    );
  }

  factory Track.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return Track(
      id: serializer.fromJson<int>(json['id']),
      uid: serializer.fromJson<String>(json['uid']),
      sourceId: serializer.fromJson<int>(json['sourceId']),
      locator: serializer.fromJson<String>(json['locator']),
      relPath: serializer.fromJson<String>(json['relPath']),
      revision: serializer.fromJson<String?>(json['revision']),
      mtimeMs: serializer.fromJson<int?>(json['mtimeMs']),
      sizeBytes: serializer.fromJson<int?>(json['sizeBytes']),
      startMs: serializer.fromJson<int?>(json['startMs']),
      endMs: serializer.fromJson<int?>(json['endMs']),
      songKey: serializer.fromJson<String?>(json['songKey']),
      title: serializer.fromJson<String>(json['title']),
      titleSort: serializer.fromJson<String>(json['titleSort']),
      artist: serializer.fromJson<String?>(json['artist']),
      album: serializer.fromJson<String?>(json['album']),
      albumArtist: serializer.fromJson<String?>(json['albumArtist']),
      genre: serializer.fromJson<String?>(json['genre']),
      composer: serializer.fromJson<String?>(json['composer']),
      language: serializer.fromJson<String?>(json['language']),
      albumDisplayArtist: serializer.fromJson<String?>(
        json['albumDisplayArtist'],
      ),
      artistSort: serializer.fromJson<String?>(json['artistSort']),
      albumSort: serializer.fromJson<String?>(json['albumSort']),
      artistSearch: serializer.fromJson<String?>(json['artistSearch']),
      albumSearch: serializer.fromJson<String?>(json['albumSearch']),
      albumArtistSearch: serializer.fromJson<String?>(
        json['albumArtistSearch'],
      ),
      genreSearch: serializer.fromJson<String?>(json['genreSearch']),
      albumArtistKey: serializer.fromJson<String?>(json['albumArtistKey']),
      albumTitleKey: serializer.fromJson<String?>(json['albumTitleKey']),
      coverKey: serializer.fromJson<String?>(json['coverKey']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      trackNo: serializer.fromJson<int?>(json['trackNo']),
      trackTotal: serializer.fromJson<int?>(json['trackTotal']),
      discNo: serializer.fromJson<int?>(json['discNo']),
      discTotal: serializer.fromJson<int?>(json['discTotal']),
      year: serializer.fromJson<int?>(json['year']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      bitrate: serializer.fromJson<int?>(json['bitrate']),
      sampleRate: serializer.fromJson<int?>(json['sampleRate']),
      bitDepth: serializer.fromJson<int?>(json['bitDepth']),
      channels: serializer.fromJson<int?>(json['channels']),
      rating: serializer.fromJson<int?>(json['rating']),
      ratingUpdatedAt: serializer.fromJson<int?>(json['ratingUpdatedAt']),
      lyricsOffsetMs: serializer.fromJson<int>(json['lyricsOffsetMs']),
      lyricsOffsetUpdatedAt: serializer.fromJson<int?>(
        json['lyricsOffsetUpdatedAt'],
      ),
      status: serializer.fromJson<String>(json['status']),
      missingSince: serializer.fromJson<int?>(json['missingSince']),
      addedAt: serializer.fromJson<int>(json['addedAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uid': serializer.toJson<String>(uid),
      'sourceId': serializer.toJson<int>(sourceId),
      'locator': serializer.toJson<String>(locator),
      'relPath': serializer.toJson<String>(relPath),
      'revision': serializer.toJson<String?>(revision),
      'mtimeMs': serializer.toJson<int?>(mtimeMs),
      'sizeBytes': serializer.toJson<int?>(sizeBytes),
      'startMs': serializer.toJson<int?>(startMs),
      'endMs': serializer.toJson<int?>(endMs),
      'songKey': serializer.toJson<String?>(songKey),
      'title': serializer.toJson<String>(title),
      'titleSort': serializer.toJson<String>(titleSort),
      'artist': serializer.toJson<String?>(artist),
      'album': serializer.toJson<String?>(album),
      'albumArtist': serializer.toJson<String?>(albumArtist),
      'genre': serializer.toJson<String?>(genre),
      'composer': serializer.toJson<String?>(composer),
      'language': serializer.toJson<String?>(language),
      'albumDisplayArtist': serializer.toJson<String?>(albumDisplayArtist),
      'artistSort': serializer.toJson<String?>(artistSort),
      'albumSort': serializer.toJson<String?>(albumSort),
      'artistSearch': serializer.toJson<String?>(artistSearch),
      'albumSearch': serializer.toJson<String?>(albumSearch),
      'albumArtistSearch': serializer.toJson<String?>(albumArtistSearch),
      'genreSearch': serializer.toJson<String?>(genreSearch),
      'albumArtistKey': serializer.toJson<String?>(albumArtistKey),
      'albumTitleKey': serializer.toJson<String?>(albumTitleKey),
      'coverKey': serializer.toJson<String?>(coverKey),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'trackNo': serializer.toJson<int?>(trackNo),
      'trackTotal': serializer.toJson<int?>(trackTotal),
      'discNo': serializer.toJson<int?>(discNo),
      'discTotal': serializer.toJson<int?>(discTotal),
      'year': serializer.toJson<int?>(year),
      'durationMs': serializer.toJson<int?>(durationMs),
      'bitrate': serializer.toJson<int?>(bitrate),
      'sampleRate': serializer.toJson<int?>(sampleRate),
      'bitDepth': serializer.toJson<int?>(bitDepth),
      'channels': serializer.toJson<int?>(channels),
      'rating': serializer.toJson<int?>(rating),
      'ratingUpdatedAt': serializer.toJson<int?>(ratingUpdatedAt),
      'lyricsOffsetMs': serializer.toJson<int>(lyricsOffsetMs),
      'lyricsOffsetUpdatedAt': serializer.toJson<int?>(lyricsOffsetUpdatedAt),
      'status': serializer.toJson<String>(status),
      'missingSince': serializer.toJson<int?>(missingSince),
      'addedAt': serializer.toJson<int>(addedAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  i1.Track copyWith({
    int? id,
    String? uid,
    int? sourceId,
    String? locator,
    String? relPath,
    i0.Value<String?> revision = const i0.Value.absent(),
    i0.Value<int?> mtimeMs = const i0.Value.absent(),
    i0.Value<int?> sizeBytes = const i0.Value.absent(),
    i0.Value<int?> startMs = const i0.Value.absent(),
    i0.Value<int?> endMs = const i0.Value.absent(),
    i0.Value<String?> songKey = const i0.Value.absent(),
    String? title,
    String? titleSort,
    i0.Value<String?> artist = const i0.Value.absent(),
    i0.Value<String?> album = const i0.Value.absent(),
    i0.Value<String?> albumArtist = const i0.Value.absent(),
    i0.Value<String?> genre = const i0.Value.absent(),
    i0.Value<String?> composer = const i0.Value.absent(),
    i0.Value<String?> language = const i0.Value.absent(),
    i0.Value<String?> albumDisplayArtist = const i0.Value.absent(),
    i0.Value<String?> artistSort = const i0.Value.absent(),
    i0.Value<String?> albumSort = const i0.Value.absent(),
    i0.Value<String?> artistSearch = const i0.Value.absent(),
    i0.Value<String?> albumSearch = const i0.Value.absent(),
    i0.Value<String?> albumArtistSearch = const i0.Value.absent(),
    i0.Value<String?> genreSearch = const i0.Value.absent(),
    i0.Value<String?> albumArtistKey = const i0.Value.absent(),
    i0.Value<String?> albumTitleKey = const i0.Value.absent(),
    i0.Value<String?> coverKey = const i0.Value.absent(),
    i0.Value<String?> coverUrl = const i0.Value.absent(),
    i0.Value<int?> trackNo = const i0.Value.absent(),
    i0.Value<int?> trackTotal = const i0.Value.absent(),
    i0.Value<int?> discNo = const i0.Value.absent(),
    i0.Value<int?> discTotal = const i0.Value.absent(),
    i0.Value<int?> year = const i0.Value.absent(),
    i0.Value<int?> durationMs = const i0.Value.absent(),
    i0.Value<int?> bitrate = const i0.Value.absent(),
    i0.Value<int?> sampleRate = const i0.Value.absent(),
    i0.Value<int?> bitDepth = const i0.Value.absent(),
    i0.Value<int?> channels = const i0.Value.absent(),
    i0.Value<int?> rating = const i0.Value.absent(),
    i0.Value<int?> ratingUpdatedAt = const i0.Value.absent(),
    int? lyricsOffsetMs,
    i0.Value<int?> lyricsOffsetUpdatedAt = const i0.Value.absent(),
    String? status,
    i0.Value<int?> missingSince = const i0.Value.absent(),
    int? addedAt,
    int? updatedAt,
  }) => i1.Track(
    id: id ?? this.id,
    uid: uid ?? this.uid,
    sourceId: sourceId ?? this.sourceId,
    locator: locator ?? this.locator,
    relPath: relPath ?? this.relPath,
    revision: revision.present ? revision.value : this.revision,
    mtimeMs: mtimeMs.present ? mtimeMs.value : this.mtimeMs,
    sizeBytes: sizeBytes.present ? sizeBytes.value : this.sizeBytes,
    startMs: startMs.present ? startMs.value : this.startMs,
    endMs: endMs.present ? endMs.value : this.endMs,
    songKey: songKey.present ? songKey.value : this.songKey,
    title: title ?? this.title,
    titleSort: titleSort ?? this.titleSort,
    artist: artist.present ? artist.value : this.artist,
    album: album.present ? album.value : this.album,
    albumArtist: albumArtist.present ? albumArtist.value : this.albumArtist,
    genre: genre.present ? genre.value : this.genre,
    composer: composer.present ? composer.value : this.composer,
    language: language.present ? language.value : this.language,
    albumDisplayArtist: albumDisplayArtist.present
        ? albumDisplayArtist.value
        : this.albumDisplayArtist,
    artistSort: artistSort.present ? artistSort.value : this.artistSort,
    albumSort: albumSort.present ? albumSort.value : this.albumSort,
    artistSearch: artistSearch.present ? artistSearch.value : this.artistSearch,
    albumSearch: albumSearch.present ? albumSearch.value : this.albumSearch,
    albumArtistSearch: albumArtistSearch.present
        ? albumArtistSearch.value
        : this.albumArtistSearch,
    genreSearch: genreSearch.present ? genreSearch.value : this.genreSearch,
    albumArtistKey: albumArtistKey.present
        ? albumArtistKey.value
        : this.albumArtistKey,
    albumTitleKey: albumTitleKey.present
        ? albumTitleKey.value
        : this.albumTitleKey,
    coverKey: coverKey.present ? coverKey.value : this.coverKey,
    coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
    trackNo: trackNo.present ? trackNo.value : this.trackNo,
    trackTotal: trackTotal.present ? trackTotal.value : this.trackTotal,
    discNo: discNo.present ? discNo.value : this.discNo,
    discTotal: discTotal.present ? discTotal.value : this.discTotal,
    year: year.present ? year.value : this.year,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    bitrate: bitrate.present ? bitrate.value : this.bitrate,
    sampleRate: sampleRate.present ? sampleRate.value : this.sampleRate,
    bitDepth: bitDepth.present ? bitDepth.value : this.bitDepth,
    channels: channels.present ? channels.value : this.channels,
    rating: rating.present ? rating.value : this.rating,
    ratingUpdatedAt: ratingUpdatedAt.present
        ? ratingUpdatedAt.value
        : this.ratingUpdatedAt,
    lyricsOffsetMs: lyricsOffsetMs ?? this.lyricsOffsetMs,
    lyricsOffsetUpdatedAt: lyricsOffsetUpdatedAt.present
        ? lyricsOffsetUpdatedAt.value
        : this.lyricsOffsetUpdatedAt,
    status: status ?? this.status,
    missingSince: missingSince.present ? missingSince.value : this.missingSince,
    addedAt: addedAt ?? this.addedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Track copyWithCompanion(i1.TracksCompanion data) {
    return Track(
      id: data.id.present ? data.id.value : this.id,
      uid: data.uid.present ? data.uid.value : this.uid,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      locator: data.locator.present ? data.locator.value : this.locator,
      relPath: data.relPath.present ? data.relPath.value : this.relPath,
      revision: data.revision.present ? data.revision.value : this.revision,
      mtimeMs: data.mtimeMs.present ? data.mtimeMs.value : this.mtimeMs,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      startMs: data.startMs.present ? data.startMs.value : this.startMs,
      endMs: data.endMs.present ? data.endMs.value : this.endMs,
      songKey: data.songKey.present ? data.songKey.value : this.songKey,
      title: data.title.present ? data.title.value : this.title,
      titleSort: data.titleSort.present ? data.titleSort.value : this.titleSort,
      artist: data.artist.present ? data.artist.value : this.artist,
      album: data.album.present ? data.album.value : this.album,
      albumArtist: data.albumArtist.present
          ? data.albumArtist.value
          : this.albumArtist,
      genre: data.genre.present ? data.genre.value : this.genre,
      composer: data.composer.present ? data.composer.value : this.composer,
      language: data.language.present ? data.language.value : this.language,
      albumDisplayArtist: data.albumDisplayArtist.present
          ? data.albumDisplayArtist.value
          : this.albumDisplayArtist,
      artistSort: data.artistSort.present
          ? data.artistSort.value
          : this.artistSort,
      albumSort: data.albumSort.present ? data.albumSort.value : this.albumSort,
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
      albumArtistKey: data.albumArtistKey.present
          ? data.albumArtistKey.value
          : this.albumArtistKey,
      albumTitleKey: data.albumTitleKey.present
          ? data.albumTitleKey.value
          : this.albumTitleKey,
      coverKey: data.coverKey.present ? data.coverKey.value : this.coverKey,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      trackNo: data.trackNo.present ? data.trackNo.value : this.trackNo,
      trackTotal: data.trackTotal.present
          ? data.trackTotal.value
          : this.trackTotal,
      discNo: data.discNo.present ? data.discNo.value : this.discNo,
      discTotal: data.discTotal.present ? data.discTotal.value : this.discTotal,
      year: data.year.present ? data.year.value : this.year,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      bitrate: data.bitrate.present ? data.bitrate.value : this.bitrate,
      sampleRate: data.sampleRate.present
          ? data.sampleRate.value
          : this.sampleRate,
      bitDepth: data.bitDepth.present ? data.bitDepth.value : this.bitDepth,
      channels: data.channels.present ? data.channels.value : this.channels,
      rating: data.rating.present ? data.rating.value : this.rating,
      ratingUpdatedAt: data.ratingUpdatedAt.present
          ? data.ratingUpdatedAt.value
          : this.ratingUpdatedAt,
      lyricsOffsetMs: data.lyricsOffsetMs.present
          ? data.lyricsOffsetMs.value
          : this.lyricsOffsetMs,
      lyricsOffsetUpdatedAt: data.lyricsOffsetUpdatedAt.present
          ? data.lyricsOffsetUpdatedAt.value
          : this.lyricsOffsetUpdatedAt,
      status: data.status.present ? data.status.value : this.status,
      missingSince: data.missingSince.present
          ? data.missingSince.value
          : this.missingSince,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Track(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('sourceId: $sourceId, ')
          ..write('locator: $locator, ')
          ..write('relPath: $relPath, ')
          ..write('revision: $revision, ')
          ..write('mtimeMs: $mtimeMs, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs, ')
          ..write('songKey: $songKey, ')
          ..write('title: $title, ')
          ..write('titleSort: $titleSort, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('albumArtist: $albumArtist, ')
          ..write('genre: $genre, ')
          ..write('composer: $composer, ')
          ..write('language: $language, ')
          ..write('albumDisplayArtist: $albumDisplayArtist, ')
          ..write('artistSort: $artistSort, ')
          ..write('albumSort: $albumSort, ')
          ..write('artistSearch: $artistSearch, ')
          ..write('albumSearch: $albumSearch, ')
          ..write('albumArtistSearch: $albumArtistSearch, ')
          ..write('genreSearch: $genreSearch, ')
          ..write('albumArtistKey: $albumArtistKey, ')
          ..write('albumTitleKey: $albumTitleKey, ')
          ..write('coverKey: $coverKey, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('trackNo: $trackNo, ')
          ..write('trackTotal: $trackTotal, ')
          ..write('discNo: $discNo, ')
          ..write('discTotal: $discTotal, ')
          ..write('year: $year, ')
          ..write('durationMs: $durationMs, ')
          ..write('bitrate: $bitrate, ')
          ..write('sampleRate: $sampleRate, ')
          ..write('bitDepth: $bitDepth, ')
          ..write('channels: $channels, ')
          ..write('rating: $rating, ')
          ..write('ratingUpdatedAt: $ratingUpdatedAt, ')
          ..write('lyricsOffsetMs: $lyricsOffsetMs, ')
          ..write('lyricsOffsetUpdatedAt: $lyricsOffsetUpdatedAt, ')
          ..write('status: $status, ')
          ..write('missingSince: $missingSince, ')
          ..write('addedAt: $addedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    uid,
    sourceId,
    locator,
    relPath,
    revision,
    mtimeMs,
    sizeBytes,
    startMs,
    endMs,
    songKey,
    title,
    titleSort,
    artist,
    album,
    albumArtist,
    genre,
    composer,
    language,
    albumDisplayArtist,
    artistSort,
    albumSort,
    artistSearch,
    albumSearch,
    albumArtistSearch,
    genreSearch,
    albumArtistKey,
    albumTitleKey,
    coverKey,
    coverUrl,
    trackNo,
    trackTotal,
    discNo,
    discTotal,
    year,
    durationMs,
    bitrate,
    sampleRate,
    bitDepth,
    channels,
    rating,
    ratingUpdatedAt,
    lyricsOffsetMs,
    lyricsOffsetUpdatedAt,
    status,
    missingSince,
    addedAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.Track &&
          other.id == this.id &&
          other.uid == this.uid &&
          other.sourceId == this.sourceId &&
          other.locator == this.locator &&
          other.relPath == this.relPath &&
          other.revision == this.revision &&
          other.mtimeMs == this.mtimeMs &&
          other.sizeBytes == this.sizeBytes &&
          other.startMs == this.startMs &&
          other.endMs == this.endMs &&
          other.songKey == this.songKey &&
          other.title == this.title &&
          other.titleSort == this.titleSort &&
          other.artist == this.artist &&
          other.album == this.album &&
          other.albumArtist == this.albumArtist &&
          other.genre == this.genre &&
          other.composer == this.composer &&
          other.language == this.language &&
          other.albumDisplayArtist == this.albumDisplayArtist &&
          other.artistSort == this.artistSort &&
          other.albumSort == this.albumSort &&
          other.artistSearch == this.artistSearch &&
          other.albumSearch == this.albumSearch &&
          other.albumArtistSearch == this.albumArtistSearch &&
          other.genreSearch == this.genreSearch &&
          other.albumArtistKey == this.albumArtistKey &&
          other.albumTitleKey == this.albumTitleKey &&
          other.coverKey == this.coverKey &&
          other.coverUrl == this.coverUrl &&
          other.trackNo == this.trackNo &&
          other.trackTotal == this.trackTotal &&
          other.discNo == this.discNo &&
          other.discTotal == this.discTotal &&
          other.year == this.year &&
          other.durationMs == this.durationMs &&
          other.bitrate == this.bitrate &&
          other.sampleRate == this.sampleRate &&
          other.bitDepth == this.bitDepth &&
          other.channels == this.channels &&
          other.rating == this.rating &&
          other.ratingUpdatedAt == this.ratingUpdatedAt &&
          other.lyricsOffsetMs == this.lyricsOffsetMs &&
          other.lyricsOffsetUpdatedAt == this.lyricsOffsetUpdatedAt &&
          other.status == this.status &&
          other.missingSince == this.missingSince &&
          other.addedAt == this.addedAt &&
          other.updatedAt == this.updatedAt);
}

class TracksCompanion extends i0.UpdateCompanion<i1.Track> {
  final i0.Value<int> id;
  final i0.Value<String> uid;
  final i0.Value<int> sourceId;
  final i0.Value<String> locator;
  final i0.Value<String> relPath;
  final i0.Value<String?> revision;
  final i0.Value<int?> mtimeMs;
  final i0.Value<int?> sizeBytes;
  final i0.Value<int?> startMs;
  final i0.Value<int?> endMs;
  final i0.Value<String?> songKey;
  final i0.Value<String> title;
  final i0.Value<String> titleSort;
  final i0.Value<String?> artist;
  final i0.Value<String?> album;
  final i0.Value<String?> albumArtist;
  final i0.Value<String?> genre;
  final i0.Value<String?> composer;
  final i0.Value<String?> language;
  final i0.Value<String?> albumDisplayArtist;
  final i0.Value<String?> artistSort;
  final i0.Value<String?> albumSort;
  final i0.Value<String?> artistSearch;
  final i0.Value<String?> albumSearch;
  final i0.Value<String?> albumArtistSearch;
  final i0.Value<String?> genreSearch;
  final i0.Value<String?> albumArtistKey;
  final i0.Value<String?> albumTitleKey;
  final i0.Value<String?> coverKey;
  final i0.Value<String?> coverUrl;
  final i0.Value<int?> trackNo;
  final i0.Value<int?> trackTotal;
  final i0.Value<int?> discNo;
  final i0.Value<int?> discTotal;
  final i0.Value<int?> year;
  final i0.Value<int?> durationMs;
  final i0.Value<int?> bitrate;
  final i0.Value<int?> sampleRate;
  final i0.Value<int?> bitDepth;
  final i0.Value<int?> channels;
  final i0.Value<int?> rating;
  final i0.Value<int?> ratingUpdatedAt;
  final i0.Value<int> lyricsOffsetMs;
  final i0.Value<int?> lyricsOffsetUpdatedAt;
  final i0.Value<String> status;
  final i0.Value<int?> missingSince;
  final i0.Value<int> addedAt;
  final i0.Value<int> updatedAt;
  const TracksCompanion({
    this.id = const i0.Value.absent(),
    this.uid = const i0.Value.absent(),
    this.sourceId = const i0.Value.absent(),
    this.locator = const i0.Value.absent(),
    this.relPath = const i0.Value.absent(),
    this.revision = const i0.Value.absent(),
    this.mtimeMs = const i0.Value.absent(),
    this.sizeBytes = const i0.Value.absent(),
    this.startMs = const i0.Value.absent(),
    this.endMs = const i0.Value.absent(),
    this.songKey = const i0.Value.absent(),
    this.title = const i0.Value.absent(),
    this.titleSort = const i0.Value.absent(),
    this.artist = const i0.Value.absent(),
    this.album = const i0.Value.absent(),
    this.albumArtist = const i0.Value.absent(),
    this.genre = const i0.Value.absent(),
    this.composer = const i0.Value.absent(),
    this.language = const i0.Value.absent(),
    this.albumDisplayArtist = const i0.Value.absent(),
    this.artistSort = const i0.Value.absent(),
    this.albumSort = const i0.Value.absent(),
    this.artistSearch = const i0.Value.absent(),
    this.albumSearch = const i0.Value.absent(),
    this.albumArtistSearch = const i0.Value.absent(),
    this.genreSearch = const i0.Value.absent(),
    this.albumArtistKey = const i0.Value.absent(),
    this.albumTitleKey = const i0.Value.absent(),
    this.coverKey = const i0.Value.absent(),
    this.coverUrl = const i0.Value.absent(),
    this.trackNo = const i0.Value.absent(),
    this.trackTotal = const i0.Value.absent(),
    this.discNo = const i0.Value.absent(),
    this.discTotal = const i0.Value.absent(),
    this.year = const i0.Value.absent(),
    this.durationMs = const i0.Value.absent(),
    this.bitrate = const i0.Value.absent(),
    this.sampleRate = const i0.Value.absent(),
    this.bitDepth = const i0.Value.absent(),
    this.channels = const i0.Value.absent(),
    this.rating = const i0.Value.absent(),
    this.ratingUpdatedAt = const i0.Value.absent(),
    this.lyricsOffsetMs = const i0.Value.absent(),
    this.lyricsOffsetUpdatedAt = const i0.Value.absent(),
    this.status = const i0.Value.absent(),
    this.missingSince = const i0.Value.absent(),
    this.addedAt = const i0.Value.absent(),
    this.updatedAt = const i0.Value.absent(),
  });
  TracksCompanion.insert({
    this.id = const i0.Value.absent(),
    required String uid,
    required int sourceId,
    required String locator,
    required String relPath,
    this.revision = const i0.Value.absent(),
    this.mtimeMs = const i0.Value.absent(),
    this.sizeBytes = const i0.Value.absent(),
    this.startMs = const i0.Value.absent(),
    this.endMs = const i0.Value.absent(),
    this.songKey = const i0.Value.absent(),
    required String title,
    this.titleSort = const i0.Value.absent(),
    this.artist = const i0.Value.absent(),
    this.album = const i0.Value.absent(),
    this.albumArtist = const i0.Value.absent(),
    this.genre = const i0.Value.absent(),
    this.composer = const i0.Value.absent(),
    this.language = const i0.Value.absent(),
    this.albumDisplayArtist = const i0.Value.absent(),
    this.artistSort = const i0.Value.absent(),
    this.albumSort = const i0.Value.absent(),
    this.artistSearch = const i0.Value.absent(),
    this.albumSearch = const i0.Value.absent(),
    this.albumArtistSearch = const i0.Value.absent(),
    this.genreSearch = const i0.Value.absent(),
    this.albumArtistKey = const i0.Value.absent(),
    this.albumTitleKey = const i0.Value.absent(),
    this.coverKey = const i0.Value.absent(),
    this.coverUrl = const i0.Value.absent(),
    this.trackNo = const i0.Value.absent(),
    this.trackTotal = const i0.Value.absent(),
    this.discNo = const i0.Value.absent(),
    this.discTotal = const i0.Value.absent(),
    this.year = const i0.Value.absent(),
    this.durationMs = const i0.Value.absent(),
    this.bitrate = const i0.Value.absent(),
    this.sampleRate = const i0.Value.absent(),
    this.bitDepth = const i0.Value.absent(),
    this.channels = const i0.Value.absent(),
    this.rating = const i0.Value.absent(),
    this.ratingUpdatedAt = const i0.Value.absent(),
    this.lyricsOffsetMs = const i0.Value.absent(),
    this.lyricsOffsetUpdatedAt = const i0.Value.absent(),
    this.status = const i0.Value.absent(),
    this.missingSince = const i0.Value.absent(),
    required int addedAt,
    required int updatedAt,
  }) : uid = i0.Value(uid),
       sourceId = i0.Value(sourceId),
       locator = i0.Value(locator),
       relPath = i0.Value(relPath),
       title = i0.Value(title),
       addedAt = i0.Value(addedAt),
       updatedAt = i0.Value(updatedAt);
  static i0.Insertable<i1.Track> custom({
    i0.Expression<int>? id,
    i0.Expression<String>? uid,
    i0.Expression<int>? sourceId,
    i0.Expression<String>? locator,
    i0.Expression<String>? relPath,
    i0.Expression<String>? revision,
    i0.Expression<int>? mtimeMs,
    i0.Expression<int>? sizeBytes,
    i0.Expression<int>? startMs,
    i0.Expression<int>? endMs,
    i0.Expression<String>? songKey,
    i0.Expression<String>? title,
    i0.Expression<String>? titleSort,
    i0.Expression<String>? artist,
    i0.Expression<String>? album,
    i0.Expression<String>? albumArtist,
    i0.Expression<String>? genre,
    i0.Expression<String>? composer,
    i0.Expression<String>? language,
    i0.Expression<String>? albumDisplayArtist,
    i0.Expression<String>? artistSort,
    i0.Expression<String>? albumSort,
    i0.Expression<String>? artistSearch,
    i0.Expression<String>? albumSearch,
    i0.Expression<String>? albumArtistSearch,
    i0.Expression<String>? genreSearch,
    i0.Expression<String>? albumArtistKey,
    i0.Expression<String>? albumTitleKey,
    i0.Expression<String>? coverKey,
    i0.Expression<String>? coverUrl,
    i0.Expression<int>? trackNo,
    i0.Expression<int>? trackTotal,
    i0.Expression<int>? discNo,
    i0.Expression<int>? discTotal,
    i0.Expression<int>? year,
    i0.Expression<int>? durationMs,
    i0.Expression<int>? bitrate,
    i0.Expression<int>? sampleRate,
    i0.Expression<int>? bitDepth,
    i0.Expression<int>? channels,
    i0.Expression<int>? rating,
    i0.Expression<int>? ratingUpdatedAt,
    i0.Expression<int>? lyricsOffsetMs,
    i0.Expression<int>? lyricsOffsetUpdatedAt,
    i0.Expression<String>? status,
    i0.Expression<int>? missingSince,
    i0.Expression<int>? addedAt,
    i0.Expression<int>? updatedAt,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (uid != null) 'uid': uid,
      if (sourceId != null) 'source_id': sourceId,
      if (locator != null) 'locator': locator,
      if (relPath != null) 'rel_path': relPath,
      if (revision != null) 'revision': revision,
      if (mtimeMs != null) 'mtime_ms': mtimeMs,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (startMs != null) 'start_ms': startMs,
      if (endMs != null) 'end_ms': endMs,
      if (songKey != null) 'song_key': songKey,
      if (title != null) 'title': title,
      if (titleSort != null) 'title_sort': titleSort,
      if (artist != null) 'artist': artist,
      if (album != null) 'album': album,
      if (albumArtist != null) 'album_artist': albumArtist,
      if (genre != null) 'genre': genre,
      if (composer != null) 'composer': composer,
      if (language != null) 'language': language,
      if (albumDisplayArtist != null)
        'album_display_artist': albumDisplayArtist,
      if (artistSort != null) 'artist_sort': artistSort,
      if (albumSort != null) 'album_sort': albumSort,
      if (artistSearch != null) 'artist_search': artistSearch,
      if (albumSearch != null) 'album_search': albumSearch,
      if (albumArtistSearch != null) 'album_artist_search': albumArtistSearch,
      if (genreSearch != null) 'genre_search': genreSearch,
      if (albumArtistKey != null) 'album_artist_key': albumArtistKey,
      if (albumTitleKey != null) 'album_title_key': albumTitleKey,
      if (coverKey != null) 'cover_key': coverKey,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (trackNo != null) 'track_no': trackNo,
      if (trackTotal != null) 'track_total': trackTotal,
      if (discNo != null) 'disc_no': discNo,
      if (discTotal != null) 'disc_total': discTotal,
      if (year != null) 'year': year,
      if (durationMs != null) 'duration_ms': durationMs,
      if (bitrate != null) 'bitrate': bitrate,
      if (sampleRate != null) 'sample_rate': sampleRate,
      if (bitDepth != null) 'bit_depth': bitDepth,
      if (channels != null) 'channels': channels,
      if (rating != null) 'rating': rating,
      if (ratingUpdatedAt != null) 'rating_updated_at': ratingUpdatedAt,
      if (lyricsOffsetMs != null) 'lyrics_offset_ms': lyricsOffsetMs,
      if (lyricsOffsetUpdatedAt != null)
        'lyrics_offset_updated_at': lyricsOffsetUpdatedAt,
      if (status != null) 'status': status,
      if (missingSince != null) 'missing_since': missingSince,
      if (addedAt != null) 'added_at': addedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  i1.TracksCompanion copyWith({
    i0.Value<int>? id,
    i0.Value<String>? uid,
    i0.Value<int>? sourceId,
    i0.Value<String>? locator,
    i0.Value<String>? relPath,
    i0.Value<String?>? revision,
    i0.Value<int?>? mtimeMs,
    i0.Value<int?>? sizeBytes,
    i0.Value<int?>? startMs,
    i0.Value<int?>? endMs,
    i0.Value<String?>? songKey,
    i0.Value<String>? title,
    i0.Value<String>? titleSort,
    i0.Value<String?>? artist,
    i0.Value<String?>? album,
    i0.Value<String?>? albumArtist,
    i0.Value<String?>? genre,
    i0.Value<String?>? composer,
    i0.Value<String?>? language,
    i0.Value<String?>? albumDisplayArtist,
    i0.Value<String?>? artistSort,
    i0.Value<String?>? albumSort,
    i0.Value<String?>? artistSearch,
    i0.Value<String?>? albumSearch,
    i0.Value<String?>? albumArtistSearch,
    i0.Value<String?>? genreSearch,
    i0.Value<String?>? albumArtistKey,
    i0.Value<String?>? albumTitleKey,
    i0.Value<String?>? coverKey,
    i0.Value<String?>? coverUrl,
    i0.Value<int?>? trackNo,
    i0.Value<int?>? trackTotal,
    i0.Value<int?>? discNo,
    i0.Value<int?>? discTotal,
    i0.Value<int?>? year,
    i0.Value<int?>? durationMs,
    i0.Value<int?>? bitrate,
    i0.Value<int?>? sampleRate,
    i0.Value<int?>? bitDepth,
    i0.Value<int?>? channels,
    i0.Value<int?>? rating,
    i0.Value<int?>? ratingUpdatedAt,
    i0.Value<int>? lyricsOffsetMs,
    i0.Value<int?>? lyricsOffsetUpdatedAt,
    i0.Value<String>? status,
    i0.Value<int?>? missingSince,
    i0.Value<int>? addedAt,
    i0.Value<int>? updatedAt,
  }) {
    return i1.TracksCompanion(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      sourceId: sourceId ?? this.sourceId,
      locator: locator ?? this.locator,
      relPath: relPath ?? this.relPath,
      revision: revision ?? this.revision,
      mtimeMs: mtimeMs ?? this.mtimeMs,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
      songKey: songKey ?? this.songKey,
      title: title ?? this.title,
      titleSort: titleSort ?? this.titleSort,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumArtist: albumArtist ?? this.albumArtist,
      genre: genre ?? this.genre,
      composer: composer ?? this.composer,
      language: language ?? this.language,
      albumDisplayArtist: albumDisplayArtist ?? this.albumDisplayArtist,
      artistSort: artistSort ?? this.artistSort,
      albumSort: albumSort ?? this.albumSort,
      artistSearch: artistSearch ?? this.artistSearch,
      albumSearch: albumSearch ?? this.albumSearch,
      albumArtistSearch: albumArtistSearch ?? this.albumArtistSearch,
      genreSearch: genreSearch ?? this.genreSearch,
      albumArtistKey: albumArtistKey ?? this.albumArtistKey,
      albumTitleKey: albumTitleKey ?? this.albumTitleKey,
      coverKey: coverKey ?? this.coverKey,
      coverUrl: coverUrl ?? this.coverUrl,
      trackNo: trackNo ?? this.trackNo,
      trackTotal: trackTotal ?? this.trackTotal,
      discNo: discNo ?? this.discNo,
      discTotal: discTotal ?? this.discTotal,
      year: year ?? this.year,
      durationMs: durationMs ?? this.durationMs,
      bitrate: bitrate ?? this.bitrate,
      sampleRate: sampleRate ?? this.sampleRate,
      bitDepth: bitDepth ?? this.bitDepth,
      channels: channels ?? this.channels,
      rating: rating ?? this.rating,
      ratingUpdatedAt: ratingUpdatedAt ?? this.ratingUpdatedAt,
      lyricsOffsetMs: lyricsOffsetMs ?? this.lyricsOffsetMs,
      lyricsOffsetUpdatedAt:
          lyricsOffsetUpdatedAt ?? this.lyricsOffsetUpdatedAt,
      status: status ?? this.status,
      missingSince: missingSince ?? this.missingSince,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (sourceId.present) {
      map['source_id'] = i0.Variable<int>(sourceId.value);
    }
    if (locator.present) {
      map['locator'] = i0.Variable<String>(locator.value);
    }
    if (relPath.present) {
      map['rel_path'] = i0.Variable<String>(relPath.value);
    }
    if (revision.present) {
      map['revision'] = i0.Variable<String>(revision.value);
    }
    if (mtimeMs.present) {
      map['mtime_ms'] = i0.Variable<int>(mtimeMs.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = i0.Variable<int>(sizeBytes.value);
    }
    if (startMs.present) {
      map['start_ms'] = i0.Variable<int>(startMs.value);
    }
    if (endMs.present) {
      map['end_ms'] = i0.Variable<int>(endMs.value);
    }
    if (songKey.present) {
      map['song_key'] = i0.Variable<String>(songKey.value);
    }
    if (title.present) {
      map['title'] = i0.Variable<String>(title.value);
    }
    if (titleSort.present) {
      map['title_sort'] = i0.Variable<String>(titleSort.value);
    }
    if (artist.present) {
      map['artist'] = i0.Variable<String>(artist.value);
    }
    if (album.present) {
      map['album'] = i0.Variable<String>(album.value);
    }
    if (albumArtist.present) {
      map['album_artist'] = i0.Variable<String>(albumArtist.value);
    }
    if (genre.present) {
      map['genre'] = i0.Variable<String>(genre.value);
    }
    if (composer.present) {
      map['composer'] = i0.Variable<String>(composer.value);
    }
    if (language.present) {
      map['language'] = i0.Variable<String>(language.value);
    }
    if (albumDisplayArtist.present) {
      map['album_display_artist'] = i0.Variable<String>(
        albumDisplayArtist.value,
      );
    }
    if (artistSort.present) {
      map['artist_sort'] = i0.Variable<String>(artistSort.value);
    }
    if (albumSort.present) {
      map['album_sort'] = i0.Variable<String>(albumSort.value);
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
    if (albumArtistKey.present) {
      map['album_artist_key'] = i0.Variable<String>(albumArtistKey.value);
    }
    if (albumTitleKey.present) {
      map['album_title_key'] = i0.Variable<String>(albumTitleKey.value);
    }
    if (coverKey.present) {
      map['cover_key'] = i0.Variable<String>(coverKey.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = i0.Variable<String>(coverUrl.value);
    }
    if (trackNo.present) {
      map['track_no'] = i0.Variable<int>(trackNo.value);
    }
    if (trackTotal.present) {
      map['track_total'] = i0.Variable<int>(trackTotal.value);
    }
    if (discNo.present) {
      map['disc_no'] = i0.Variable<int>(discNo.value);
    }
    if (discTotal.present) {
      map['disc_total'] = i0.Variable<int>(discTotal.value);
    }
    if (year.present) {
      map['year'] = i0.Variable<int>(year.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = i0.Variable<int>(durationMs.value);
    }
    if (bitrate.present) {
      map['bitrate'] = i0.Variable<int>(bitrate.value);
    }
    if (sampleRate.present) {
      map['sample_rate'] = i0.Variable<int>(sampleRate.value);
    }
    if (bitDepth.present) {
      map['bit_depth'] = i0.Variable<int>(bitDepth.value);
    }
    if (channels.present) {
      map['channels'] = i0.Variable<int>(channels.value);
    }
    if (rating.present) {
      map['rating'] = i0.Variable<int>(rating.value);
    }
    if (ratingUpdatedAt.present) {
      map['rating_updated_at'] = i0.Variable<int>(ratingUpdatedAt.value);
    }
    if (lyricsOffsetMs.present) {
      map['lyrics_offset_ms'] = i0.Variable<int>(lyricsOffsetMs.value);
    }
    if (lyricsOffsetUpdatedAt.present) {
      map['lyrics_offset_updated_at'] = i0.Variable<int>(
        lyricsOffsetUpdatedAt.value,
      );
    }
    if (status.present) {
      map['status'] = i0.Variable<String>(status.value);
    }
    if (missingSince.present) {
      map['missing_since'] = i0.Variable<int>(missingSince.value);
    }
    if (addedAt.present) {
      map['added_at'] = i0.Variable<int>(addedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = i0.Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TracksCompanion(')
          ..write('id: $id, ')
          ..write('uid: $uid, ')
          ..write('sourceId: $sourceId, ')
          ..write('locator: $locator, ')
          ..write('relPath: $relPath, ')
          ..write('revision: $revision, ')
          ..write('mtimeMs: $mtimeMs, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs, ')
          ..write('songKey: $songKey, ')
          ..write('title: $title, ')
          ..write('titleSort: $titleSort, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('albumArtist: $albumArtist, ')
          ..write('genre: $genre, ')
          ..write('composer: $composer, ')
          ..write('language: $language, ')
          ..write('albumDisplayArtist: $albumDisplayArtist, ')
          ..write('artistSort: $artistSort, ')
          ..write('albumSort: $albumSort, ')
          ..write('artistSearch: $artistSearch, ')
          ..write('albumSearch: $albumSearch, ')
          ..write('albumArtistSearch: $albumArtistSearch, ')
          ..write('genreSearch: $genreSearch, ')
          ..write('albumArtistKey: $albumArtistKey, ')
          ..write('albumTitleKey: $albumTitleKey, ')
          ..write('coverKey: $coverKey, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('trackNo: $trackNo, ')
          ..write('trackTotal: $trackTotal, ')
          ..write('discNo: $discNo, ')
          ..write('discTotal: $discTotal, ')
          ..write('year: $year, ')
          ..write('durationMs: $durationMs, ')
          ..write('bitrate: $bitrate, ')
          ..write('sampleRate: $sampleRate, ')
          ..write('bitDepth: $bitDepth, ')
          ..write('channels: $channels, ')
          ..write('rating: $rating, ')
          ..write('ratingUpdatedAt: $ratingUpdatedAt, ')
          ..write('lyricsOffsetMs: $lyricsOffsetMs, ')
          ..write('lyricsOffsetUpdatedAt: $lyricsOffsetUpdatedAt, ')
          ..write('status: $status, ')
          ..write('missingSince: $missingSince, ')
          ..write('addedAt: $addedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

i0.Index get tracksStatus => i0.Index(
  'tracks_status',
  'CREATE INDEX tracks_status ON tracks (status, source_id)',
);
i0.Index get tracksAddedAt => i0.Index(
  'tracks_added_at',
  'CREATE INDEX tracks_added_at ON tracks (added_at)',
);
i0.Index get tracksAlbumKey => i0.Index(
  'tracks_album_key',
  'CREATE INDEX tracks_album_key ON tracks (album_artist_key, album_title_key)',
);
i0.Index get tracksSongKey => i0.Index(
  'tracks_song_key',
  'CREATE INDEX tracks_song_key ON tracks (song_key)',
);
i0.Index get tracksRelPath => i0.Index(
  'tracks_rel_path',
  'CREATE INDEX tracks_rel_path ON tracks (source_id, rel_path)',
);
i0.Index get tracksLanguage => i0.Index(
  'tracks_language',
  'CREATE INDEX tracks_language ON tracks (language)',
);

class $TrackDetailsTable extends i2.TrackDetails
    with i0.TableInfo<$TrackDetailsTable, i1.TrackDetail> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackDetailsTable(this.attachedDatabase, [this._alias]);
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
  static const i0.VerificationMeta _commentMeta = const i0.VerificationMeta(
    'comment',
  );
  @override
  late final i0.GeneratedColumn<String> comment = i0.GeneratedColumn<String>(
    'comment',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _extraTagsMeta = const i0.VerificationMeta(
    'extraTags',
  );
  @override
  late final i0.GeneratedColumn<String> extraTags = i0.GeneratedColumn<String>(
    'extra_tags',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _lrcLocatorMeta = const i0.VerificationMeta(
    'lrcLocator',
  );
  @override
  late final i0.GeneratedColumn<String> lrcLocator = i0.GeneratedColumn<String>(
    'lrc_locator',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _lrcRevisionMeta = const i0.VerificationMeta(
    'lrcRevision',
  );
  @override
  late final i0.GeneratedColumn<String> lrcRevision =
      i0.GeneratedColumn<String>(
        'lrc_revision',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const i0.VerificationMeta _coverSrcMeta = const i0.VerificationMeta(
    'coverSrc',
  );
  @override
  late final i0.GeneratedColumn<String> coverSrc = i0.GeneratedColumn<String>(
    'cover_src',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<i0.GeneratedColumn> get $columns => [
    trackId,
    comment,
    extraTags,
    lrcLocator,
    lrcRevision,
    coverSrc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'track_details';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.TrackDetail> instance, {
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
    if (data.containsKey('comment')) {
      context.handle(
        _commentMeta,
        comment.isAcceptableOrUnknown(data['comment']!, _commentMeta),
      );
    }
    if (data.containsKey('extra_tags')) {
      context.handle(
        _extraTagsMeta,
        extraTags.isAcceptableOrUnknown(data['extra_tags']!, _extraTagsMeta),
      );
    }
    if (data.containsKey('lrc_locator')) {
      context.handle(
        _lrcLocatorMeta,
        lrcLocator.isAcceptableOrUnknown(data['lrc_locator']!, _lrcLocatorMeta),
      );
    }
    if (data.containsKey('lrc_revision')) {
      context.handle(
        _lrcRevisionMeta,
        lrcRevision.isAcceptableOrUnknown(
          data['lrc_revision']!,
          _lrcRevisionMeta,
        ),
      );
    }
    if (data.containsKey('cover_src')) {
      context.handle(
        _coverSrcMeta,
        coverSrc.isAcceptableOrUnknown(data['cover_src']!, _coverSrcMeta),
      );
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => {trackId};
  @override
  i1.TrackDetail map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.TrackDetail(
      trackId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}track_id'],
      )!,
      comment: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}comment'],
      ),
      extraTags: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}extra_tags'],
      ),
      lrcLocator: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}lrc_locator'],
      ),
      lrcRevision: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}lrc_revision'],
      ),
      coverSrc: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}cover_src'],
      ),
    );
  }

  @override
  $TrackDetailsTable createAlias(String alias) {
    return $TrackDetailsTable(attachedDatabase, alias);
  }
}

class TrackDetail extends i0.DataClass
    implements i0.Insertable<i1.TrackDetail> {
  final int trackId;
  final String? comment;

  /// JSON of tags without a column.
  final String? extraTags;

  /// Sidecar `.lrc` locator (path or file id).
  final String? lrcLocator;
  final String? lrcRevision;

  /// External cover image (locator or server image id).
  final String? coverSrc;
  const TrackDetail({
    required this.trackId,
    this.comment,
    this.extraTags,
    this.lrcLocator,
    this.lrcRevision,
    this.coverSrc,
  });
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    map['track_id'] = i0.Variable<int>(trackId);
    if (!nullToAbsent || comment != null) {
      map['comment'] = i0.Variable<String>(comment);
    }
    if (!nullToAbsent || extraTags != null) {
      map['extra_tags'] = i0.Variable<String>(extraTags);
    }
    if (!nullToAbsent || lrcLocator != null) {
      map['lrc_locator'] = i0.Variable<String>(lrcLocator);
    }
    if (!nullToAbsent || lrcRevision != null) {
      map['lrc_revision'] = i0.Variable<String>(lrcRevision);
    }
    if (!nullToAbsent || coverSrc != null) {
      map['cover_src'] = i0.Variable<String>(coverSrc);
    }
    return map;
  }

  i1.TrackDetailsCompanion toCompanion(bool nullToAbsent) {
    return i1.TrackDetailsCompanion(
      trackId: i0.Value(trackId),
      comment: comment == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(comment),
      extraTags: extraTags == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(extraTags),
      lrcLocator: lrcLocator == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(lrcLocator),
      lrcRevision: lrcRevision == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(lrcRevision),
      coverSrc: coverSrc == null && nullToAbsent
          ? const i0.Value.absent()
          : i0.Value(coverSrc),
    );
  }

  factory TrackDetail.fromJson(
    Map<String, dynamic> json, {
    i0.ValueSerializer? serializer,
  }) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return TrackDetail(
      trackId: serializer.fromJson<int>(json['trackId']),
      comment: serializer.fromJson<String?>(json['comment']),
      extraTags: serializer.fromJson<String?>(json['extraTags']),
      lrcLocator: serializer.fromJson<String?>(json['lrcLocator']),
      lrcRevision: serializer.fromJson<String?>(json['lrcRevision']),
      coverSrc: serializer.fromJson<String?>(json['coverSrc']),
    );
  }
  @override
  Map<String, dynamic> toJson({i0.ValueSerializer? serializer}) {
    serializer ??= i0.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trackId': serializer.toJson<int>(trackId),
      'comment': serializer.toJson<String?>(comment),
      'extraTags': serializer.toJson<String?>(extraTags),
      'lrcLocator': serializer.toJson<String?>(lrcLocator),
      'lrcRevision': serializer.toJson<String?>(lrcRevision),
      'coverSrc': serializer.toJson<String?>(coverSrc),
    };
  }

  i1.TrackDetail copyWith({
    int? trackId,
    i0.Value<String?> comment = const i0.Value.absent(),
    i0.Value<String?> extraTags = const i0.Value.absent(),
    i0.Value<String?> lrcLocator = const i0.Value.absent(),
    i0.Value<String?> lrcRevision = const i0.Value.absent(),
    i0.Value<String?> coverSrc = const i0.Value.absent(),
  }) => i1.TrackDetail(
    trackId: trackId ?? this.trackId,
    comment: comment.present ? comment.value : this.comment,
    extraTags: extraTags.present ? extraTags.value : this.extraTags,
    lrcLocator: lrcLocator.present ? lrcLocator.value : this.lrcLocator,
    lrcRevision: lrcRevision.present ? lrcRevision.value : this.lrcRevision,
    coverSrc: coverSrc.present ? coverSrc.value : this.coverSrc,
  );
  TrackDetail copyWithCompanion(i1.TrackDetailsCompanion data) {
    return TrackDetail(
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      comment: data.comment.present ? data.comment.value : this.comment,
      extraTags: data.extraTags.present ? data.extraTags.value : this.extraTags,
      lrcLocator: data.lrcLocator.present
          ? data.lrcLocator.value
          : this.lrcLocator,
      lrcRevision: data.lrcRevision.present
          ? data.lrcRevision.value
          : this.lrcRevision,
      coverSrc: data.coverSrc.present ? data.coverSrc.value : this.coverSrc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackDetail(')
          ..write('trackId: $trackId, ')
          ..write('comment: $comment, ')
          ..write('extraTags: $extraTags, ')
          ..write('lrcLocator: $lrcLocator, ')
          ..write('lrcRevision: $lrcRevision, ')
          ..write('coverSrc: $coverSrc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    trackId,
    comment,
    extraTags,
    lrcLocator,
    lrcRevision,
    coverSrc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is i1.TrackDetail &&
          other.trackId == this.trackId &&
          other.comment == this.comment &&
          other.extraTags == this.extraTags &&
          other.lrcLocator == this.lrcLocator &&
          other.lrcRevision == this.lrcRevision &&
          other.coverSrc == this.coverSrc);
}

class TrackDetailsCompanion extends i0.UpdateCompanion<i1.TrackDetail> {
  final i0.Value<int> trackId;
  final i0.Value<String?> comment;
  final i0.Value<String?> extraTags;
  final i0.Value<String?> lrcLocator;
  final i0.Value<String?> lrcRevision;
  final i0.Value<String?> coverSrc;
  const TrackDetailsCompanion({
    this.trackId = const i0.Value.absent(),
    this.comment = const i0.Value.absent(),
    this.extraTags = const i0.Value.absent(),
    this.lrcLocator = const i0.Value.absent(),
    this.lrcRevision = const i0.Value.absent(),
    this.coverSrc = const i0.Value.absent(),
  });
  TrackDetailsCompanion.insert({
    this.trackId = const i0.Value.absent(),
    this.comment = const i0.Value.absent(),
    this.extraTags = const i0.Value.absent(),
    this.lrcLocator = const i0.Value.absent(),
    this.lrcRevision = const i0.Value.absent(),
    this.coverSrc = const i0.Value.absent(),
  });
  static i0.Insertable<i1.TrackDetail> custom({
    i0.Expression<int>? trackId,
    i0.Expression<String>? comment,
    i0.Expression<String>? extraTags,
    i0.Expression<String>? lrcLocator,
    i0.Expression<String>? lrcRevision,
    i0.Expression<String>? coverSrc,
  }) {
    return i0.RawValuesInsertable({
      if (trackId != null) 'track_id': trackId,
      if (comment != null) 'comment': comment,
      if (extraTags != null) 'extra_tags': extraTags,
      if (lrcLocator != null) 'lrc_locator': lrcLocator,
      if (lrcRevision != null) 'lrc_revision': lrcRevision,
      if (coverSrc != null) 'cover_src': coverSrc,
    });
  }

  i1.TrackDetailsCompanion copyWith({
    i0.Value<int>? trackId,
    i0.Value<String?>? comment,
    i0.Value<String?>? extraTags,
    i0.Value<String?>? lrcLocator,
    i0.Value<String?>? lrcRevision,
    i0.Value<String?>? coverSrc,
  }) {
    return i1.TrackDetailsCompanion(
      trackId: trackId ?? this.trackId,
      comment: comment ?? this.comment,
      extraTags: extraTags ?? this.extraTags,
      lrcLocator: lrcLocator ?? this.lrcLocator,
      lrcRevision: lrcRevision ?? this.lrcRevision,
      coverSrc: coverSrc ?? this.coverSrc,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (trackId.present) {
      map['track_id'] = i0.Variable<int>(trackId.value);
    }
    if (comment.present) {
      map['comment'] = i0.Variable<String>(comment.value);
    }
    if (extraTags.present) {
      map['extra_tags'] = i0.Variable<String>(extraTags.value);
    }
    if (lrcLocator.present) {
      map['lrc_locator'] = i0.Variable<String>(lrcLocator.value);
    }
    if (lrcRevision.present) {
      map['lrc_revision'] = i0.Variable<String>(lrcRevision.value);
    }
    if (coverSrc.present) {
      map['cover_src'] = i0.Variable<String>(coverSrc.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackDetailsCompanion(')
          ..write('trackId: $trackId, ')
          ..write('comment: $comment, ')
          ..write('extraTags: $extraTags, ')
          ..write('lrcLocator: $lrcLocator, ')
          ..write('lrcRevision: $lrcRevision, ')
          ..write('coverSrc: $coverSrc')
          ..write(')'))
        .toString();
  }
}
